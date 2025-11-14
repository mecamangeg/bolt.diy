# 🧪 Automation Test Demonstration

This file demonstrates how the Claude Preview Automation system works.

## Test Scenario

### 1. Claude.ai Commits to Branch

```
Branch: claude/study-bolt-preview-workflow-01RQHQYKZbTbMxtuTFioPiH3
Commit: <current-commit-hash>
File Added: test-automation-demo.md
```

### 2. Watcher Detects Commit

The branch watcher running in PM2 would:

```javascript
// Polling every 3 seconds
git fetch origin

// Get all claude/* branches
git branch -r | grep "claude/"

// Get latest commit
git rev-parse origin/claude/study-bolt-preview-workflow-01RQHQYKZbTbMxtuTFioPiH3

// Compare with last known commit
if (newCommit !== lastCommit) {
  handleNewCommit(branch, newCommit);
}
```

### 3. Auto-Checkout Triggered

```bash
# Watcher executes:
git fetch origin
git checkout claude/study-bolt-preview-workflow-01RQHQYKZbTbMxtuTFioPiH3
git pull origin claude/study-bolt-preview-workflow-01RQHQYKZbTbMxtuTFioPiH3
```

### 4. Dependency Check

```bash
# Check if package.json changed
git diff <prev-commit> <new-commit> -- package.json

# If changed:
npm install
```

### 5. Dev Server Restart

```bash
# PM2 restarts the dev server
pm2 restart dev-server

# Wait 3 seconds for server to start
sleep 3
```

### 6. Preview Updates

```
Preview URL: https://codespace-name-3000.app.github.dev
Dashboard: https://codespace-name-8080.app.github.dev

User sees: Updated app with new changes!
```

## Expected Timeline

| Step | Time | Total |
|------|------|-------|
| Claude commits | 0s | 0s |
| Watcher detects (poll) | ~3s | 3s |
| Git fetch + checkout | ~2s | 5s |
| npm install (if needed) | 0-20s | 5-25s |
| PM2 restart | ~5s | 10-30s |
| **User sees preview** | - | **10-30s** |

vs. Manual workflow: **30-80 seconds**

## Test Status

✅ **Installation successful**
- .devcontainer/ configured
- .vscode/ configured
- .codespace-automation/ set up with symlinked scripts
- Documentation copied
- PM2 installed

🔄 **Ready for Testing**
- Commit this file
- Push to remote
- In a real Codespace, watcher would auto-detect
- Dev server would restart
- Preview would update automatically

## Validation Checklist

- [ ] PM2 services start automatically
- [ ] Branch watcher detects new commits
- [ ] Auto-checkout works correctly
- [ ] Dependency installation triggers when needed
- [ ] Dev server restarts successfully
- [ ] Preview URL updates
- [ ] Dashboard shows current state
- [ ] Logs are captured properly

## Next Steps for Real Testing

1. **In GitHub Codespace:**
   ```bash
   # Open this repo in Codespaces
   # Services will auto-start via devcontainer

   # Check status
   pm2 list

   # View logs
   pm2 logs branch-watcher
   ```

2. **Make Changes with Claude.ai:**
   ```
   Ask Claude: "Add a new feature to the app"
   Claude commits to new branch: claude/xyz-123
   Wait 10-30 seconds
   See preview auto-update!
   ```

3. **Monitor Dashboard:**
   ```
   Open: https://YOUR-CODESPACE-8080.app.github.dev
   Watch: Real-time updates as commits are detected
   ```

---

**Test Created:** $(date)
**Status:** Ready for real Codespace testing
