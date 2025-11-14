# Claude Preview Automation

This folder contains the automation system for Claude.ai → GitHub Codespaces previews.

## 📂 Folder Structure

```
.codespace-automation/
├── scripts/          → Symlink to source scripts (auto-updates)
├── logs/             → Log files (gitignored)
├── config/           → State files (gitignored)
├── package.json      → Dependencies
└── .gitignore        → Ignore logs and state
```

## 🔗 Symlinked Scripts

The `scripts/` folder is a symlink to the original source:
`/home/user/bolt.diy/claude-preview-automation/scripts`

This means:
- Updates to the source automatically apply here
- You can modify scripts in either location
- Easy to keep multiple projects in sync

## 📚 Documentation

See project root for:
- `CLAUDE_PREVIEW_SETUP.md` - Quick start guide
- `QUICK_REFERENCE.md` - Daily usage cheat sheet

Full documentation: `/home/user/bolt.diy/claude-preview-automation/docs/README.md`

## 🔄 Updating

To update the automation system:

```bash
# If using git submodule (recommended)
cd /home/user/bolt.diy/claude-preview-automation
git pull

# If copied directly
# Re-run the installer from the updated source
```

## 🛠️ Quick Commands

```bash
# Start all services
bash .devcontainer/start-services.sh

# View status
pm2 list

# View logs
pm2 logs

# Use helper CLI (after setup)
claude-preview start
claude-preview status
claude-preview logs
```

---

Installed from: `/home/user/bolt.diy/claude-preview-automation`
Installation date: Fri Nov 14 06:39:40 UTC 2025
