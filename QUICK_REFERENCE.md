# ⚡ Claude Preview - Quick Reference

## 🚀 One-Time Setup

```bash
# 1. Open this repo in GitHub Codespaces
# 2. Wait for devcontainer to build (~2-3 min)
# 3. Services auto-start
```

That's it! The system is now running.

---

## 📋 Daily Usage

### Start Your Session

```bash
# Check if services are running
pm2 list

# If not, start them
bash .devcontainer/start-services.sh
```

### Open Preview

**Option A: VSCode Simple Browser (Side-by-side)**
1. `Cmd/Ctrl+Shift+P`
2. Type: "Simple Browser: Show"
3. URL: `https://YOUR-CODESPACE-NAME-3000.app.github.dev`

**Option B: Dashboard (Full monitoring)**
- URL: `https://YOUR-CODESPACE-NAME-8080.app.github.dev`

**Option C: Separate Tab**
- Ports tab → Port 3000 → Click globe icon

### Use with Claude

1. Ask Claude to build/modify your app
2. Claude commits to `claude/*` branch
3. Wait ~10-15 seconds
4. Preview auto-updates! ✨

---

## 🛠️ Helper Commands

```bash
# Install helper CLI (one-time)
ln -s .codespace-automation/scripts/claude-preview /usr/local/bin/claude-preview

# Then use:
claude-preview start      # Start all services
claude-preview status     # Show status
claude-preview logs       # View logs
claude-preview preview    # Open preview URL
claude-preview dashboard  # Open dashboard
claude-preview current    # Show current branch
claude-preview health     # Health check
claude-preview help       # Show all commands
```

---

## 📊 Common PM2 Commands

```bash
pm2 list                  # Show all processes
pm2 logs                  # View all logs
pm2 logs branch-watcher   # View watcher logs
pm2 logs dev-server       # View dev server logs
pm2 restart all           # Restart everything
pm2 restart dev-server    # Restart dev server only
pm2 monit                 # Resource monitor
pm2 save                  # Save process list
```

---

## 🔍 Troubleshooting

### Preview Not Updating?

```bash
# Check watcher status
pm2 logs branch-watcher

# Manually fetch latest
git fetch origin
git branch -r | grep claude
```

### Dev Server Crashed?

```bash
# Check logs
pm2 logs dev-server

# Restart
pm2 restart dev-server
```

### Services Not Running After Restart?

```bash
# Start services
bash .devcontainer/start-services.sh

# Or individually
pm2 start .codespace-automation/scripts/branch-watcher.js --name branch-watcher
pm2 start npm --name dev-server -- run dev
```

### Reset Everything

```bash
# Nuclear option: stop all, clear state, restart
claude-preview reset
```

---

## 📂 Important Files

```
.devcontainer/devcontainer.json        # Codespace config
.devcontainer/start-services.sh        # Service startup
.codespace-automation/scripts/
  ├── branch-watcher.js                # Main watcher
  ├── dashboard-server.js              # Dashboard
  └── claude-preview                   # Helper CLI
.codespace-automation/logs/            # All logs
.codespace-automation/config/          # State files
```

---

## 🎯 Performance

| Action | Time |
|--------|------|
| Claude commits | 0s |
| Watcher detects | ~3s |
| Branch checkout | ~2s |
| Install deps (if needed) | ~10-20s |
| Dev server restart | ~5s |
| **Total (no deps)** | **~10-15s** |
| **Total (with deps)** | **~20-30s** |

---

## 🔗 Quick Links

- **Preview:** Port 3000
- **Dashboard:** Port 8080
- **Logs:** `.codespace-automation/logs/`
- **Config:** `.codespace-automation/config/`
- **Full Docs:** `.codespace-automation/README.md`
- **Setup Guide:** `CLAUDE_PREVIEW_SETUP.md`
- **Summary:** `IMPLEMENTATION_SUMMARY.md`

---

## 💡 Pro Tips

1. Keep Codespace tab open (prevents timeout)
2. Use Simple Browser in split pane for side-by-side coding
3. Monitor dashboard for detailed status
4. Run `pm2 save` after making PM2 changes
5. Check logs regularly: `pm2 logs`

---

**Happy coding! 🚀**
