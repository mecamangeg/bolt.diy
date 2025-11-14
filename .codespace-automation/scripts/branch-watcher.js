#!/usr/bin/env node

/**
 * Claude Branch Watcher
 *
 * Watches for new commits on claude/* branches and automatically:
 * 1. Fetches the latest changes
 * 2. Checks out the new branch
 * 3. Installs dependencies if needed
 * 4. Restarts the dev server
 * 5. Notifies VSCode to refresh the preview
 */

const { execSync, exec } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  pollInterval: 3000, // Poll every 3 seconds
  claudeBranchPattern: /^claude\//,
  logFile: path.join(__dirname, '../logs/branch-watcher.log'),
  stateFile: path.join(__dirname, '../config/watcher-state.json'),
  autoInstallDeps: true,
  autoOpenPreview: true,
};

// State management
let currentState = {
  lastCommit: null,
  lastBranch: null,
  lastCheck: null,
  processedCommits: new Set(),
};

// Logger
function log(message, level = 'INFO') {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] [${level}] ${message}`;
  console.log(logMessage);

  // Append to log file
  fs.appendFileSync(CONFIG.logFile, logMessage + '\n');
}

// Load saved state
function loadState() {
  try {
    if (fs.existsSync(CONFIG.stateFile)) {
      const data = JSON.parse(fs.readFileSync(CONFIG.stateFile, 'utf8'));
      currentState = {
        ...data,
        processedCommits: new Set(data.processedCommits || []),
      };
      log(`Loaded state: ${JSON.stringify(data)}`);
    }
  } catch (error) {
    log(`Failed to load state: ${error.message}`, 'WARN');
  }
}

// Save state
function saveState() {
  try {
    const data = {
      ...currentState,
      processedCommits: Array.from(currentState.processedCommits),
    };
    fs.writeFileSync(CONFIG.stateFile, JSON.stringify(data, null, 2));
  } catch (error) {
    log(`Failed to save state: ${error.message}`, 'ERROR');
  }
}

// Execute command and return output
function runCommand(command, options = {}) {
  try {
    const output = execSync(command, {
      encoding: 'utf8',
      stdio: options.silent ? 'pipe' : 'inherit',
      ...options,
    });
    return { success: true, output: output?.trim() };
  } catch (error) {
    log(`Command failed: ${command}\n${error.message}`, 'ERROR');
    return { success: false, error: error.message, output: error.stdout?.toString() };
  }
}

// Get all claude/* branches
function getClaudeBranches() {
  const result = runCommand('git branch -r', { silent: true });
  if (!result.success) return [];

  const branches = result.output
    .split('\n')
    .map(b => b.trim())
    .filter(b => CONFIG.claudeBranchPattern.test(b.replace('origin/', '')))
    .map(b => b.replace('origin/', ''));

  return branches;
}

// Get latest commit hash for a branch
function getLatestCommit(branch) {
  const result = runCommand(`git rev-parse origin/${branch}`, { silent: true });
  return result.success ? result.output : null;
}

// Get commit details
function getCommitInfo(commitHash) {
  const result = runCommand(
    `git log -1 --format="%H|%an|%ae|%ai|%s" ${commitHash}`,
    { silent: true }
  );

  if (!result.success) return null;

  const [hash, author, email, date, message] = result.output.split('|');
  return { hash, author, email, date, message };
}

// Check if dependencies changed
function dependenciesChanged(fromCommit, toCommit) {
  const result = runCommand(
    `git diff ${fromCommit} ${toCommit} -- package.json package-lock.json`,
    { silent: true }
  );
  return result.success && result.output.length > 0;
}

// Handle new commit
async function handleNewCommit(branch, commitHash) {
  log(`🎯 New commit detected on ${branch}: ${commitHash}`);

  const commitInfo = getCommitInfo(commitHash);
  if (!commitInfo) {
    log('Failed to get commit info', 'ERROR');
    return;
  }

  log(`📝 Commit: ${commitInfo.message}`);
  log(`👤 Author: ${commitInfo.author} <${commitInfo.email}>`);
  log(`📅 Date: ${commitInfo.date}`);

  // Step 1: Fetch latest changes
  log('📥 Fetching latest changes...');
  runCommand('git fetch origin');

  // Step 2: Checkout the branch
  log(`🔀 Checking out branch: ${branch}`);
  const checkoutResult = runCommand(`git checkout ${branch}`);

  if (!checkoutResult.success) {
    // Try creating local branch if it doesn't exist
    log('Creating local tracking branch...');
    runCommand(`git checkout -b ${branch} origin/${branch}`);
  }

  // Pull latest
  runCommand(`git pull origin ${branch}`);

  // Step 3: Check if dependencies changed
  if (CONFIG.autoInstallDeps && currentState.lastCommit) {
    const depsChanged = dependenciesChanged(currentState.lastCommit, commitHash);

    if (depsChanged) {
      log('📦 Dependencies changed, running npm install...');
      runCommand('npm install');
    }
  }

  // Step 4: Restart dev server
  log('🔄 Restarting dev server...');
  runCommand('pm2 restart dev-server');

  // Wait for server to start
  await new Promise(resolve => setTimeout(resolve, 3000));

  // Step 5: Notify VSCode (if in Codespaces)
  if (process.env.CODESPACE_NAME) {
    const previewUrl = `https://${process.env.CODESPACE_NAME}-3000.app.github.dev`;
    log(`🌐 Preview available at: ${previewUrl}`);

    // Create notification file for VSCode extension to pick up
    const notificationFile = path.join(__dirname, '../config/preview-notification.json');
    fs.writeFileSync(notificationFile, JSON.stringify({
      branch,
      commit: commitHash,
      message: commitInfo.message,
      previewUrl,
      timestamp: new Date().toISOString(),
    }, null, 2));
  }

  // Step 6: Update state
  currentState.lastCommit = commitHash;
  currentState.lastBranch = branch;
  currentState.lastCheck = new Date().toISOString();
  currentState.processedCommits.add(commitHash);
  saveState();

  log('✅ Preview updated successfully!');
}

// Main polling loop
async function pollForChanges() {
  try {
    // Fetch from remote
    runCommand('git fetch origin', { silent: true });

    // Get all claude/* branches
    const branches = getClaudeBranches();

    if (branches.length === 0) {
      // No claude branches yet
      return;
    }

    // Sort branches by most recent (alphabetically, claude branches have timestamps)
    branches.sort().reverse();

    // Check the most recent claude branch
    const latestBranch = branches[0];
    const latestCommit = getLatestCommit(latestBranch);

    if (!latestCommit) {
      return;
    }

    // Check if this is a new commit we haven't processed
    if (
      latestCommit !== currentState.lastCommit &&
      !currentState.processedCommits.has(latestCommit)
    ) {
      await handleNewCommit(latestBranch, latestCommit);
    }

  } catch (error) {
    log(`Polling error: ${error.message}`, 'ERROR');
  }
}

// Graceful shutdown
function shutdown() {
  log('Shutting down branch watcher...');
  saveState();
  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

// Initialize
async function main() {
  log('🚀 Starting Claude Branch Watcher');
  log(`📁 Working directory: ${process.cwd()}`);
  log(`⏱️  Poll interval: ${CONFIG.pollInterval}ms`);
  log(`🔍 Watching for branches matching: ${CONFIG.claudeBranchPattern}`);

  // Load previous state
  loadState();

  // Initial check
  await pollForChanges();

  // Start polling
  setInterval(pollForChanges, CONFIG.pollInterval);

  log('✅ Branch watcher is running');
}

main().catch(error => {
  log(`Fatal error: ${error.message}`, 'ERROR');
  process.exit(1);
});
