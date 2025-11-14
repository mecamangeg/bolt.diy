# Claude Preview Automation for GitHub Codespaces

Automated preview system that watches for Claude.ai commits and instantly previews them in your Codespace.

## 🎯 What It Does

This system automates the tedious workflow of:
1. ❌ ~~Manually copying the branch name Claude created~~
2. ❌ ~~Manually copying the commit hash~~
3. ❌ ~~Running a slash command to checkout and preview~~
4. ❌ ~~Waiting 30-80 seconds for the preview~~

**Now it's fully automated:**
1. ✅ Claude commits to a `claude/*` branch
2. ✅ Watcher detects the commit in ~3 seconds
3. ✅ Auto-checks out the branch
4. ✅ Auto-restarts dev server
5. ✅ Preview updates in ~10-15 seconds
6. ✅ VSCode Simple Browser auto-refreshes

---

## 🏗️ Architecture

```
Claude.ai (commits) → GitHub (push) → Codespace Watcher (polls)
                                             ↓
                                    Auto-checkout branch
                                             ↓
                                    Restart dev server (PM2)
                                             ↓
                                    Preview at localhost:3000
                                             ↓
                                    VSCode Simple Browser
```

---

## 📦 Components

### 1. **Git Branch Watcher** (`scripts/branch-watcher.js`)
- Polls GitHub every 3 seconds for new commits on `claude/*` branches
- Automatically checks out the latest branch
- Installs dependencies if `package.json` changed
- Restarts the dev server
- Logs all activities

### 2. **Dev Server Manager** (PM2)
- Keeps dev server running with auto-restart
- Auto-heals on crashes
- Survives Codespace restarts

### 3. **Preview Dashboard** (`scripts/dashboard-server.js`)
- Web UI at port 8080
- Shows current branch, commit, process status
- Embedded preview iframe
- Quick actions (restart, logs, etc.)

### 4. **VSCode Integration**
- Tasks for opening preview, viewing logs
- Simple Browser auto-refresh
- Status bar integration (optional)

---

## 🚀 Setup Instructions

### Step 1: Initialize Codespace

When you first open the Codespace, the `.devcontainer` will automatically:
1. Install PM2 for process management
2. Install project dependencies
3. Create automation directories
4. Set up git configuration

### Step 2: Start Services

Services auto-start on Codespace launch, but you can manually start them:

```bash
# Start all services
bash .devcontainer/start-services.sh

# Or individually
pm2 start .codespace-automation/scripts/branch-watcher.js --name branch-watcher
pm2 start npm --name dev-server -- run dev
pm2 start .codespace-automation/scripts/dashboard-server.js --name preview-dashboard
```

### Step 3: Open Preview

**Option A: VSCode Simple Browser (Recommended)**
1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
2. Type "Simple Browser: Show"
3. Enter URL: `https://${CODESPACE_NAME}-3000.app.github.dev`
4. Position it in a split pane

**Option B: Dashboard**
1. Open: `https://${CODESPACE_NAME}-8080.app.github.dev`
2. See full preview with embedded iframe

**Option C: Separate Tab**
1. Click on "Ports" tab in VSCode
2. Click the globe icon next to port 3000

### Step 4: Use Claude.ai

Now just use Claude.ai normally:
1. Ask Claude to build/modify your app
2. Claude commits to a `claude/*` branch
3. Wait ~10-15 seconds
4. Preview auto-updates!

---

## 🔧 Configuration

### Adjust Polling Interval

Edit `.codespace-automation/scripts/branch-watcher.js`:

```javascript
const CONFIG = {
  pollInterval: 3000, // 3 seconds (change this)
  // ...
};
```

**Trade-offs:**
- Faster polling (1-2s): Quicker updates, more CPU usage
- Slower polling (5-10s): Less CPU, slightly slower updates

### Auto-Install Dependencies

By default, the watcher checks if `package.json` changed and runs `npm install`.

Disable by setting:

```javascript
const CONFIG = {
  autoInstallDeps: false, // Disable auto-install
  // ...
};
```

### Change Dev Server Port

If your app uses a different port, update:

1. `.devcontainer/devcontainer.json` - Add to `forwardPorts`
2. `.codespace-automation/scripts/dashboard-server.js` - Update `previewUrl`

---

## 📊 Monitoring

### View Logs

```bash
# All logs
pm2 logs

# Specific process
pm2 logs branch-watcher
pm2 logs dev-server
pm2 logs preview-dashboard

# Follow logs in real-time
pm2 logs --lines 100
```

### Check Status

```bash
# Process list
pm2 list

# Detailed monitoring
pm2 monit

# Process info
pm2 info dev-server
```

### Log Files

Logs are also saved to:
- `.codespace-automation/logs/watcher-output.log`
- `.codespace-automation/logs/watcher-error.log`
- `.codespace-automation/logs/dev-output.log`
- `.codespace-automation/logs/dev-error.log`

---

## 🛠️ Troubleshooting

### Preview Not Updating

1. **Check if watcher is running:**
   ```bash
   pm2 list
   # Should show "branch-watcher" as "online"
   ```

2. **Check watcher logs:**
   ```bash
   pm2 logs branch-watcher
   # Should show "Polling for changes..."
   ```

3. **Manually trigger fetch:**
   ```bash
   git fetch origin
   git branch -r | grep claude
   ```

### Dev Server Not Starting

1. **Check server logs:**
   ```bash
   pm2 logs dev-server
   ```

2. **Restart manually:**
   ```bash
   pm2 restart dev-server
   ```

3. **Check port availability:**
   ```bash
   lsof -i :3000
   # Should show node process
   ```

### Codespace Keeps Timing Out

The devcontainer is configured to keep alive, but if it still times out:

1. **Check PM2 persistence:**
   ```bash
   pm2 save
   pm2 startup
   ```

2. **Add to `.bashrc` (manual fallback):**
   ```bash
   echo "cd /workspaces/YOUR_REPO && pm2 resurrect" >> ~/.bashrc
   ```

### Dependencies Not Installing

If `npm install` fails after branch switch:

1. **Check logs:**
   ```bash
   cat .codespace-automation/logs/watcher-output.log | grep "npm install"
   ```

2. **Manually install:**
   ```bash
   npm install
   pm2 restart dev-server
   ```

---

## 🎨 Customization

### Add Custom Actions on Commit

Edit `.codespace-automation/scripts/branch-watcher.js`, in the `handleNewCommit` function:

```javascript
async function handleNewCommit(branch, commitHash) {
  // ... existing code ...

  // 🎯 Add your custom logic here:

  // Example: Run tests
  runCommand('npm test');

  // Example: Run linter
  runCommand('npm run lint');

  // Example: Build production bundle
  runCommand('npm run build');

  // Example: Send notification
  runCommand('curl -X POST https://your-webhook.com -d "New commit: ${commitHash}"');

  // ... rest of code ...
}
```

### Add Webhook Support (Instead of Polling)

To use GitHub webhooks instead of polling:

1. **Create webhook endpoint:**
   ```javascript
   // In dashboard-server.js, add:
   if (req.url === '/webhook' && req.method === 'POST') {
     let body = '';
     req.on('data', chunk => body += chunk);
     req.on('end', () => {
       const payload = JSON.parse(body);
       // Trigger branch checkout
       handleWebhook(payload);
     });
   }
   ```

2. **Configure GitHub webhook:**
   - Go to GitHub repo → Settings → Webhooks
   - Add webhook: `https://${CODESPACE_NAME}-4000.app.github.dev/webhook`
   - Select "Push" events
   - Save

3. **Update watcher to listen instead of poll:**
   ```javascript
   // Remove setInterval, listen for webhook trigger instead
   ```

---

## 📈 Performance

### Benchmarks (Typical)

| Metric | Time |
|--------|------|
| Claude commits | 0s |
| Watcher detects | ~3s |
| Branch checkout | ~2s |
| Dependency install (if needed) | ~10-20s |
| Dev server restart | ~5s |
| **Total (no deps change)** | **~10-15s** |
| **Total (deps changed)** | **~20-30s** |

**vs. Manual workflow: 30-80s** ✅ **50-70% faster!**

### Optimizations

1. **Pre-install common deps:** Add to `.devcontainer/postCreateCommand`
2. **Use npm cache:** Configure npm to use aggressive caching
3. **Skip unnecessary builds:** Vite/Next.js HMR means no full rebuild needed
4. **Parallel operations:** Watcher fetches while server restarts

---

## 🔐 Security Notes

- Branch watcher only checks out branches matching `claude/*` pattern
- No automatic merges to main
- All operations are logged
- Webhook endpoint (if used) should validate GitHub signatures

---

## 📝 Quick Reference

### Common Commands

```bash
# Start everything
bash .devcontainer/start-services.sh

# View all logs
pm2 logs

# Restart dev server
pm2 restart dev-server

# Restart watcher
pm2 restart branch-watcher

# Stop everything
pm2 stop all

# Delete all processes
pm2 delete all

# Save PM2 state
pm2 save

# Open dashboard
code --open-url https://${CODESPACE_NAME}-8080.app.github.dev

# Open preview
code --open-url https://${CODESPACE_NAME}-3000.app.github.dev
```

### File Locations

- **Config:** `.devcontainer/devcontainer.json`
- **Scripts:** `.codespace-automation/scripts/`
- **Logs:** `.codespace-automation/logs/`
- **State:** `.codespace-automation/config/watcher-state.json`
- **VSCode:** `.vscode/tasks.json`, `.vscode/settings.json`

---

## 🎯 Roadmap / Future Enhancements

- [ ] GitHub webhook support (eliminate polling)
- [ ] Multi-branch preview (A/B testing)
- [ ] Visual diff view in dashboard
- [ ] Slack/Discord notifications on new commits
- [ ] Auto-merge approved branches
- [ ] Performance metrics dashboard
- [ ] Mobile-friendly dashboard
- [ ] VSCode extension for status bar integration
- [ ] Playwright/Cypress test auto-run

---

## 💡 Tips & Best Practices

1. **Keep Codespace Running:** Use largest available machine for best performance
2. **Monitor Resource Usage:** Run `pm2 monit` to check CPU/memory
3. **Clear Logs Periodically:** Logs can grow large, use `pm2 flush`
4. **Use Dashboard:** Easier to see what's happening than CLI
5. **Test with Small Changes First:** Make sure system works before big refactors
6. **Pin Dependencies:** Avoid surprises from auto-install

---

## 🤝 Contributing

Have ideas to improve this? Create an issue or PR!

---

## 📄 License

MIT - Use freely!
