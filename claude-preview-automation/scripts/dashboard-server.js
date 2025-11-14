#!/usr/bin/env node

/**
 * Preview Dashboard Server
 *
 * Provides a simple web dashboard showing:
 * - Current branch/commit
 * - Preview status
 * - Recent commits
 * - Quick actions (restart server, switch branches, etc.)
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync, exec } = require('child_process');
const net = require('net');

const PORT = 8080;
const STATE_FILE = path.join(__dirname, '../config/watcher-state.json');
const NOTIFICATION_FILE = path.join(__dirname, '../config/preview-notification.json');
const DEV_PORT_FILE = path.join(__dirname, '../config/dev-port.txt');
const HEALTH_CHECK_INTERVAL = 30000; // 30 seconds

// Get current state
function getState() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    }
  } catch (error) {
    console.error('Failed to load state:', error.message);
  }
  return {};
}

// Get notification
function getNotification() {
  try {
    if (fs.existsSync(NOTIFICATION_FILE)) {
      return JSON.parse(fs.readFileSync(NOTIFICATION_FILE, 'utf8'));
    }
  } catch (error) {
    console.error('Failed to load notification:', error.message);
  }
  return null;
}

// Get git info
function getGitInfo() {
  try {
    const branch = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8' }).trim();
    const commit = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim();
    const shortCommit = execSync('git rev-parse --short HEAD', { encoding: 'utf8' }).trim();
    const message = execSync('git log -1 --format=%s', { encoding: 'utf8' }).trim();
    const author = execSync('git log -1 --format=%an', { encoding: 'utf8' }).trim();
    const date = execSync('git log -1 --format=%ai', { encoding: 'utf8' }).trim();

    return { branch, commit, shortCommit, message, author, date };
  } catch (error) {
    return null;
  }
}

// Get recent claude branches
function getClaudeBranches() {
  try {
    const branches = execSync('git branch -r', { encoding: 'utf8' })
      .split('\n')
      .map(b => b.trim())
      .filter(b => b.includes('claude/'))
      .map(b => b.replace('origin/', ''))
      .slice(0, 10); // Last 10 branches

    return branches;
  } catch (error) {
    return [];
  }
}

// Get PM2 process status
function getProcessStatus() {
  try {
    const output = execSync('pm2 jlist', { encoding: 'utf8' });
    const processes = JSON.parse(output);

    return processes.map(p => ({
      name: p.name,
      status: p.pm2_env.status,
      uptime: Math.floor((Date.now() - p.pm2_env.pm_uptime) / 1000),
      restarts: p.pm2_env.restart_time,
      cpu: p.monit.cpu,
      memory: Math.floor(p.monit.memory / 1024 / 1024), // MB
    }));
  } catch (error) {
    return [];
  }
}

// Health monitoring: Check if a port is accessible
function checkPort(port) {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    const timeout = 2000; // 2 seconds

    socket.setTimeout(timeout);
    socket.on('connect', () => {
      socket.destroy();
      resolve(true);
    });
    socket.on('timeout', () => {
      socket.destroy();
      resolve(false);
    });
    socket.on('error', () => {
      resolve(false);
    });

    socket.connect(port, '127.0.0.1');
  });
}

// Get dev server port
function getDevPort() {
  try {
    if (fs.existsSync(DEV_PORT_FILE)) {
      return parseInt(fs.readFileSync(DEV_PORT_FILE, 'utf8').trim(), 10);
    }
  } catch (error) {
    console.error('Failed to read dev port:', error.message);
  }
  return 5173; // Default to Vite port
}

// Health check and auto-recovery
async function performHealthCheck() {
  const devPort = getDevPort();
  const processes = getProcessStatus();
  const devServer = processes.find(p => p.name === 'dev-server');

  // Check if dev server is running in PM2 but port is not accessible
  if (devServer && devServer.status === 'online') {
    const portAccessible = await checkPort(devPort);

    if (!portAccessible) {
      console.log(`⚠️  Dev server shows online but port ${devPort} is not accessible. Auto-recovering...`);
      exec('pm2 restart dev-server', (error) => {
        if (error) {
          console.error('Failed to restart dev-server:', error.message);
        } else {
          console.log('✅ Dev server restarted successfully');
        }
      });
    }
  } else if (!devServer || devServer.status !== 'online') {
    console.log('⚠️  Dev server is not running. Attempting to start...');
    exec('pm2 start dev-server', (error) => {
      if (error) {
        console.error('Failed to start dev-server:', error.message);
      } else {
        console.log('✅ Dev server started successfully');
      }
    });
  }
}

// HTML template
function generateHTML(data) {
  const gitInfo = data.gitInfo || {};
  const notification = data.notification || {};
  const state = data.state || {};
  const processes = data.processes || [];
  const branches = data.branches || [];
  const devPort = getDevPort();
  const previewUrl = process.env.CODESPACE_NAME
    ? `https://${process.env.CODESPACE_NAME}-${devPort}.app.github.dev`
    : `http://localhost:${devPort}`;

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Claude Preview Dashboard</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #333;
      min-height: 100vh;
      padding: 20px;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
    }
    .header {
      background: white;
      padding: 30px;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.1);
      margin-bottom: 20px;
    }
    h1 {
      color: #667eea;
      margin-bottom: 10px;
      font-size: 32px;
    }
    .subtitle {
      color: #666;
      font-size: 14px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
      margin-bottom: 20px;
    }
    .card {
      background: white;
      padding: 25px;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.1);
    }
    .card h2 {
      font-size: 18px;
      margin-bottom: 15px;
      color: #667eea;
      border-bottom: 2px solid #f0f0f0;
      padding-bottom: 10px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #f0f0f0;
    }
    .info-row:last-child {
      border-bottom: none;
    }
    .label {
      font-weight: 600;
      color: #666;
    }
    .value {
      color: #333;
      font-family: 'Courier New', monospace;
      font-size: 13px;
    }
    .status {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
    }
    .status.online {
      background: #d4edda;
      color: #155724;
    }
    .status.stopped {
      background: #f8d7da;
      color: #721c24;
    }
    .preview-iframe {
      width: 100%;
      height: 600px;
      border: none;
      border-radius: 8px;
      background: white;
    }
    .branch-list {
      list-style: none;
      max-height: 300px;
      overflow-y: auto;
    }
    .branch-item {
      padding: 8px;
      margin: 5px 0;
      background: #f8f9fa;
      border-radius: 6px;
      font-size: 13px;
      font-family: 'Courier New', monospace;
    }
    .branch-item.active {
      background: #d4edda;
      border-left: 4px solid #28a745;
    }
    .btn {
      display: inline-block;
      padding: 10px 20px;
      background: #667eea;
      color: white;
      text-decoration: none;
      border-radius: 6px;
      margin: 5px;
      font-size: 14px;
      border: none;
      cursor: pointer;
      transition: background 0.3s;
    }
    .btn:hover {
      background: #5568d3;
    }
    .actions {
      margin-top: 15px;
    }
    .timestamp {
      color: #999;
      font-size: 12px;
      margin-top: 10px;
    }
  </style>
  <script>
    // Auto-refresh every 5 seconds
    setTimeout(() => location.reload(), 5000);
  </script>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>⚡ Claude Preview Dashboard</h1>
      <p class="subtitle">Automated preview system for Claude.ai code commits</p>
    </div>

    <div class="grid">
      <!-- Current Branch/Commit -->
      <div class="card">
        <h2>📍 Current State</h2>
        <div class="info-row">
          <span class="label">Branch:</span>
          <span class="value">${gitInfo.branch || 'N/A'}</span>
        </div>
        <div class="info-row">
          <span class="label">Commit:</span>
          <span class="value">${gitInfo.shortCommit || 'N/A'}</span>
        </div>
        <div class="info-row">
          <span class="label">Message:</span>
          <span class="value">${gitInfo.message || 'N/A'}</span>
        </div>
        <div class="info-row">
          <span class="label">Author:</span>
          <span class="value">${gitInfo.author || 'N/A'}</span>
        </div>
        <div class="info-row">
          <span class="label">Date:</span>
          <span class="value">${gitInfo.date || 'N/A'}</span>
        </div>
      </div>

      <!-- Process Status -->
      <div class="card">
        <h2>🔧 Process Status</h2>
        ${processes.map(p => `
          <div class="info-row">
            <span class="label">${p.name}</span>
            <span class="status ${p.status}">${p.status} (${p.restarts} restarts)</span>
          </div>
        `).join('')}
        <div class="actions">
          <button class="btn" onclick="fetch('/api/restart-all').then(() => location.reload())">
            🔄 Restart All
          </button>
        </div>
      </div>

      <!-- Watcher State -->
      <div class="card">
        <h2>👀 Watcher State</h2>
        <div class="info-row">
          <span class="label">Last Check:</span>
          <span class="value">${state.lastCheck || 'Never'}</span>
        </div>
        <div class="info-row">
          <span class="label">Last Branch:</span>
          <span class="value">${state.lastBranch || 'None'}</span>
        </div>
        <div class="info-row">
          <span class="label">Last Commit:</span>
          <span class="value">${state.lastCommit ? state.lastCommit.substring(0, 7) : 'None'}</span>
        </div>
        <div class="info-row">
          <span class="label">Processed:</span>
          <span class="value">${state.processedCommits?.length || 0} commits</span>
        </div>
      </div>
    </div>

    <!-- Recent Branches -->
    <div class="card">
      <h2>🌿 Recent Claude Branches</h2>
      <ul class="branch-list">
        ${branches.map(branch => `
          <li class="branch-item ${branch === gitInfo.branch ? 'active' : ''}">${branch}</li>
        `).join('')}
      </ul>
    </div>

    <!-- Preview -->
    <div class="card">
      <h2>🌐 Live Preview</h2>
      <div class="info-row">
        <span class="label">Preview URL:</span>
        <a href="${previewUrl}" target="_blank" class="value">${previewUrl}</a>
      </div>
      <iframe src="${previewUrl}" class="preview-iframe"></iframe>
      <p class="timestamp">Auto-refreshing every 5 seconds...</p>
    </div>
  </div>
</body>
</html>
  `;
}

// API handlers
function handleAPI(req, res, action) {
  if (action === 'restart-all') {
    try {
      execSync('pm2 restart all');
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true }));
    } catch (error) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: error.message }));
    }
    return;
  }

  res.writeHead(404);
  res.end('Not found');
}

// Create server
const server = http.createServer((req, res) => {
  if (req.url.startsWith('/api/')) {
    const action = req.url.replace('/api/', '');
    handleAPI(req, res, action);
    return;
  }

  // Serve dashboard
  const data = {
    gitInfo: getGitInfo(),
    notification: getNotification(),
    state: getState(),
    processes: getProcessStatus(),
    branches: getClaudeBranches(),
  };

  const html = generateHTML(data);

  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(html);
});

server.listen(PORT, () => {
  console.log(`📊 Dashboard server running at http://localhost:${PORT}`);
  if (process.env.CODESPACE_NAME) {
    console.log(`🌐 Public URL: https://${process.env.CODESPACE_NAME}-${PORT}.app.github.dev`);
  }

  // Start health monitoring
  console.log(`🏥 Health monitoring enabled (checking every ${HEALTH_CHECK_INTERVAL / 1000}s)`);
  setInterval(performHealthCheck, HEALTH_CHECK_INTERVAL);

  // Run initial health check after 10 seconds
  setTimeout(performHealthCheck, 10000);
});
