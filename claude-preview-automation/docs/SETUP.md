# 🚀 Claude Preview Automation - Setup Guide

## Overview

This system automates the workflow between **Claude.ai** and **GitHub Codespaces**, eliminating the manual 30-80 second preview process.

### Before (Manual)
```
You: "Claude, build me a todo app"
Claude: *commits to branch claude/xyz-123*
You: *copy branch name*
You: *copy commit hash*
You: *run slash command*
You: *wait 30-80 seconds*
You: *finally see preview*
```

### After (Automated)
```
You: "Claude, build me a todo app"
Claude: *commits to branch claude/xyz-123*
System: *auto-detects commit in 3s*
System: *auto-checks out branch*
System: *auto-restarts dev server*
You: *preview auto-updates in 10-15s* ✨
```

---

## 🎯 Quick Start (5 Minutes)

### Step 1: Open in Codespace

1. **Create a Codespace** for this repository
   ```bash
   # From GitHub web UI:
   # Code → Codespaces → Create codespace on main
   ```

2. **Wait for devcontainer to build** (~2-3 minutes first time)
   - The `.devcontainer/devcontainer.json` will automatically set everything up
   - PM2, dependencies, and automation scripts will be installed

3. **Services auto-start** on Codespace launch
   ```bash
   # Check if services are running:
   pm2 list

   # You should see:
   # - branch-watcher (online)
   # - dev-server (online)
   # - preview-dashboard (online)
   ```

### Step 2: Open Preview

**Method 1: Simple Browser (Recommended for side-by-side coding)**

1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows)
2. Type: "Simple Browser: Show"
3. Enter URL: `https://YOUR-CODESPACE-NAME-3000.app.github.dev`
   - Replace `YOUR-CODESPACE-NAME` with your actual Codespace name
   - Or use the forwarded URL from the "Ports" tab
4. Drag the Simple Browser to a split pane

**Method 2: Dashboard (Recommended for full monitoring)**

1. Open Ports tab in VSCode
2. Find port `8080` (Preview Dashboard)
3. Click the globe icon to open
4. Dashboard shows:
   - Current branch/commit
   - Process status
   - Embedded preview
   - Recent Claude branches
   - Quick restart buttons

**Method 3: Separate Tab (Recommended for fullscreen preview)**

1. Open Ports tab
2. Find port `3000` (Dev Server)
3. Click globe icon
4. Opens in new browser tab

### Step 3: Use with Claude.ai

1. **Open Claude.ai** in your browser
2. **Connect to this GitHub repository** (if not already)
   - Projects → Settings → GitHub Integration
3. **Start coding:**
   ```
   You: "Create a Next.js todo app with Tailwind CSS"
   Claude: *generates code and commits to claude/xyz-123*
   ```
4. **Watch the magic:**
   - Check terminal: You'll see branch-watcher detect the commit
   - Wait ~10-15 seconds
   - Preview auto-updates!

---

## 🔍 How It Works

### The Magic Behind the Scenes

```mermaid
sequenceDiagram
    participant You
    participant Claude.ai
    participant GitHub
    participant Watcher
    participant DevServer
    participant Preview

    You->>Claude.ai: "Build todo app"
    Claude.ai->>GitHub: Commits to claude/xyz-123
    Note over Watcher: Polls every 3 seconds
    GitHub->>Watcher: Detects new commit
    Watcher->>Watcher: git fetch origin
    Watcher->>Watcher: git checkout claude/xyz-123
    Watcher->>Watcher: npm install (if needed)
    Watcher->>DevServer: pm2 restart dev-server
    DevServer->>DevServer: Restart with new code
    DevServer->>Preview: Serve on localhost:3000
    Preview->>You: Auto-refresh! 🎉
```

### Components

1. **Git Branch Watcher** (`.codespace-automation/scripts/branch-watcher.js`)
   - Polls GitHub every 3 seconds
   - Detects new commits on `claude/*` branches
   - Auto-checks out the latest branch
   - Triggers dependency installation if needed
   - Restarts dev server

2. **PM2 Process Manager**
   - Keeps dev server alive
   - Auto-restarts on crashes
   - Survives Codespace restarts
   - Logs everything for debugging

3. **Preview Dashboard** (Port 8080)
   - Real-time status monitoring
   - Embedded preview
   - Quick actions (restart, logs, etc.)

4. **VSCode Integration**
   - Tasks for common operations
   - Auto-refresh Simple Browser
   - Git auto-fetch

---

## 🛠️ Manual Setup (If Auto-Setup Failed)

If services didn't start automatically:

```bash
# Install PM2
npm install -g pm2

# Install project dependencies
npm install

# Start services
bash .devcontainer/start-services.sh

# Verify
pm2 list
```

---

## 📊 Monitoring & Debugging

### Check Service Status

```bash
# List all processes
pm2 list

# View logs in real-time
pm2 logs

# View specific service logs
pm2 logs branch-watcher
pm2 logs dev-server

# Monitor resources
pm2 monit
```

### Dashboard

Open dashboard at `https://YOUR-CODESPACE-NAME-8080.app.github.dev`

Shows:
- ✅ Current branch and commit
- ✅ Process status (online/stopped/crashed)
- ✅ Recent Claude branches
- ✅ Embedded preview
- ✅ Auto-refresh every 5 seconds

### Log Files

Located in `.codespace-automation/logs/`:
- `watcher-output.log` - Branch watcher activity
- `watcher-error.log` - Branch watcher errors
- `dev-output.log` - Dev server output
- `dev-error.log` - Dev server errors

---

## 🎛️ Configuration

### Adjust Polling Speed

Edit `.codespace-automation/scripts/branch-watcher.js`:

```javascript
const CONFIG = {
  pollInterval: 3000, // Change to 1000 for 1-second polling
  // ... rest of config
};
```

**Trade-offs:**
- **1-2s:** Fastest updates, higher CPU usage
- **3-5s:** Balanced (recommended)
- **10s+:** Slower updates, minimal CPU

### Change Dev Server Port

1. Update `.devcontainer/devcontainer.json`:
   ```json
   "forwardPorts": [3000, 5173, 8080],
   ```

2. Update dashboard server (if using custom port):
   ```javascript
   // In dashboard-server.js
   const previewUrl = 'https://${CODESPACE_NAME}-YOUR_PORT.app.github.dev';
   ```

### Disable Auto-Install

If you don't want automatic `npm install`:

```javascript
// In branch-watcher.js
const CONFIG = {
  autoInstallDeps: false,
  // ...
};
```

---

## 🚨 Troubleshooting

### Preview Not Updating

1. **Check if watcher detected the commit:**
   ```bash
   pm2 logs branch-watcher --lines 50
   # Look for "New commit detected"
   ```

2. **Manually trigger update:**
   ```bash
   git fetch origin
   git checkout $(git branch -r | grep claude | head -1 | sed 's/origin\///')
   pm2 restart dev-server
   ```

3. **Check git connectivity:**
   ```bash
   git fetch origin --dry-run
   ```

### Dev Server Not Starting

1. **Check logs:**
   ```bash
   pm2 logs dev-server
   ```

2. **Check port availability:**
   ```bash
   lsof -i :3000
   # Should show node process, or nothing if port is free
   ```

3. **Restart manually:**
   ```bash
   pm2 restart dev-server
   # Or
   npm run dev
   ```

### Services Not Running After Codespace Restart

1. **Check PM2 startup:**
   ```bash
   pm2 startup
   pm2 save
   ```

2. **Manually start:**
   ```bash
   bash .devcontainer/start-services.sh
   ```

### Watcher Not Detecting Commits

1. **Check git fetch permissions:**
   ```bash
   git config --get credential.helper
   # Should show GitHub credential helper
   ```

2. **Check branch pattern:**
   ```bash
   git branch -r | grep claude
   # Should show claude/* branches
   ```

3. **Increase logging:**
   ```javascript
   // In branch-watcher.js, change log level
   function log(message, level = 'DEBUG') {
     // ... will show more detailed logs
   }
   ```

---

## ⚡ Performance Optimization

### Benchmarks

| Scenario | Time |
|----------|------|
| Claude commits (simple change) | ~10-15s |
| Claude commits (with new deps) | ~20-30s |
| Manual workflow (before) | 30-80s |
| **Improvement** | **50-75% faster** |

### Tips for Faster Previews

1. **Use faster Codespace machine:**
   - Settings → Codespaces → Machine type → 4-core or higher

2. **Pre-install common dependencies:**
   - Add to `.devcontainer/postCreateCommand`

3. **Skip builds if using HMR:**
   - Next.js and Vite have Hot Module Replacement
   - No need for full rebuilds

4. **Use npm cache aggressively:**
   ```bash
   npm config set cache-min 9999999
   ```

---

## 🎨 Customization

### Run Tests on New Commits

Edit `branch-watcher.js`, in `handleNewCommit`:

```javascript
// After checkout, before restart
log('🧪 Running tests...');
const testResult = runCommand('npm test');
if (!testResult.success) {
  log('⚠️ Tests failed!', 'WARN');
  // Optionally notify user
}
```

### Send Notifications

```javascript
// In handleNewCommit, after successful preview
fetch('https://your-webhook.com/notify', {
  method: 'POST',
  body: JSON.stringify({
    message: `New preview ready: ${commitInfo.message}`,
    url: previewUrl
  })
});
```

### Add Deployment Preview

```javascript
// After dev server restart
log('🚀 Deploying to preview environment...');
runCommand('vercel deploy --preview');
```

---

## 📋 Workflow Best Practices

1. **Always work in branches:** Never commit directly to main
2. **Review before merging:** Use the preview to validate changes
3. **Monitor logs:** Catch errors early
4. **Keep Codespace alive:** Use largest machine, avoid timeouts
5. **Clear old branches:** Delete merged Claude branches periodically

---

## 🎯 Next Steps

Now that you have the system running:

1. ✅ Test with a simple Claude request
2. ✅ Watch the automated preview update
3. ✅ Explore the dashboard
4. ✅ Customize polling interval if needed
5. ✅ Add custom actions (tests, linting, etc.)

---

## 🆘 Need Help?

- **Check logs:** `pm2 logs`
- **View status:** `pm2 list`
- **Restart services:** `pm2 restart all`
- **Read detailed docs:** `.codespace-automation/README.md`

---

## 🎉 You're All Set!

Your automated Claude preview system is ready. Enjoy the 50-75% faster workflow!

**Happy coding! 🚀**
