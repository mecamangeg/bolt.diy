# 🚀 Claude Preview Automation - Portable Package

**Automated preview system for Claude.ai + GitHub Codespaces**

This is a self-contained, portable package that you can copy to any project to enable automated previews when using Claude.ai.

---

## 📦 What's Inside

```
claude-preview-automation/
├── devcontainer/           # Codespace configuration files
│   ├── devcontainer.json   # Main Codespace config
│   ├── setup.sh            # One-time setup script
│   └── start-services.sh   # Auto-start services on boot
│
├── vscode/                 # VSCode integration files
│   ├── tasks.json          # Quick tasks (start, logs, preview)
│   ├── settings.json       # Auto-refresh, git config
│   └── extensions.json     # Recommended extensions
│
├── scripts/                # Automation scripts
│   ├── branch-watcher.js   # Main git branch watcher (400+ lines)
│   ├── dashboard-server.js # Monitoring dashboard (300+ lines)
│   ├── claude-preview      # Helper CLI (300+ lines)
│   └── init.sh             # Initialization script
│
├── docs/                   # Documentation
│   ├── README.md           # Detailed documentation
│   ├── SETUP.md            # Quick start guide
│   ├── QUICK_REFERENCE.md  # Daily usage cheat sheet
│   └── IMPLEMENTATION_SUMMARY.md  # Technical overview
│
├── logs/                   # Log files (auto-created, gitignored)
├── config/                 # State files (auto-created, gitignored)
│
├── package.json            # Node.js dependencies
├── install.sh              # One-command installer
└── README.md               # This file
```

---

## ⚡ Quick Install (Copy to New Project)

### Method 1: One-Command Install (Recommended)

```bash
# 1. Copy this entire folder to your new project
cp -r /path/to/claude-preview-automation /path/to/your-project/

# 2. Run the installer
cd /path/to/your-project
bash claude-preview-automation/install.sh

# Done! The installer will:
# - Create .devcontainer/ folder
# - Create .vscode/ folder
# - Set up .codespace-automation/ (with symlinks to scripts)
# - Copy documentation to project root
# - Set proper permissions
```

### Method 2: Git Submodule (Best for Multiple Projects)

```bash
# In your project root
git submodule add https://github.com/YOUR-USERNAME/claude-preview-automation.git

# Run installer
bash claude-preview-automation/install.sh

# Update in future
git submodule update --remote
```

### Method 3: Manual Copy

```bash
# Copy the entire folder
cp -r /path/to/claude-preview-automation /path/to/your-project/

# Manually create symlinks/copies
cd /path/to/your-project
mkdir -p .devcontainer .vscode .codespace-automation

# Copy devcontainer files
cp claude-preview-automation/devcontainer/* .devcontainer/

# Copy vscode files
cp claude-preview-automation/vscode/* .vscode/

# Symlink scripts (for auto-updates)
ln -s ../claude-preview-automation/scripts .codespace-automation/scripts

# Copy package.json
cp claude-preview-automation/package.json .codespace-automation/
```

---

## 🎯 What It Does

Eliminates the manual workflow when using Claude.ai with GitHub Codespaces:

### Before (Manual - 30-80 seconds)
```
1. Claude commits to branch
2. You copy branch name
3. You copy commit hash
4. You run slash command
5. You wait for checkout + restart
6. You see preview
```

### After (Automated - 10-30 seconds)
```
1. Claude commits to branch
2. System auto-detects in ~3s
3. System auto-checks out branch
4. System auto-restarts dev server
5. Preview auto-updates!
```

**Result: 50-75% faster + zero manual work**

---

## 🚀 How to Use

### Step 1: Install in Your Project

```bash
# Copy folder to your project
cp -r /path/to/claude-preview-automation /path/to/your-project/

# Run installer
cd /path/to/your-project
bash claude-preview-automation/install.sh
```

### Step 2: Commit and Push

```bash
git add .devcontainer .vscode .codespace-automation *.md
git commit -m "Add Claude Preview Automation"
git push
```

### Step 3: Open in Codespaces

```bash
# From GitHub UI: Code → Codespaces → Create codespace
# Services will auto-start
```

### Step 4: Open Preview

Choose your method:
- **Simple Browser** (VSCode split pane): `Cmd/Ctrl+Shift+P` → "Simple Browser: Show"
- **Dashboard** (monitoring): `https://YOUR-CODESPACE-8080.app.github.dev`
- **New Tab**: Ports → 3000 → Click globe

### Step 5: Use Claude.ai

Ask Claude to build/modify your app, and watch the preview auto-update in ~10-30 seconds!

---

## 🔧 Configuration

### Adjust Polling Speed

Edit `.codespace-automation/scripts/branch-watcher.js`:

```javascript
const CONFIG = {
  pollInterval: 3000,  // Change to 1000, 5000, etc.
  // ...
};
```

### Change Ports

Edit `devcontainer/devcontainer.json`:

```json
{
  "forwardPorts": [3000, 5173, 8080],
  // Add your custom ports
}
```

### Disable Auto-Install Dependencies

Edit `.codespace-automation/scripts/branch-watcher.js`:

```javascript
const CONFIG = {
  autoInstallDeps: false,  // Skip npm install
  // ...
};
```

---

## 📚 Documentation

After installation, you'll have these docs in your project root:

- **`CLAUDE_PREVIEW_SETUP.md`** - Quick start guide (5 min)
- **`QUICK_REFERENCE.md`** - Daily usage cheat sheet

Full documentation is in `claude-preview-automation/docs/`:

- **`README.md`** - Detailed guide
- **`IMPLEMENTATION_SUMMARY.md`** - Technical overview

---

## 🛠️ Requirements

### Your Project Must Have:
- Node.js project (`package.json`)
- Dev server script (`npm run dev`)
- Git repository

### Supported Frameworks:
- ✅ Next.js (tested)
- ✅ Vite (tested)
- ✅ React (Create React App)
- ✅ Vue
- ✅ Svelte
- ✅ Any framework with `npm run dev`

### Codespace Requirements:
- 4-core or higher recommended
- 8GB+ RAM recommended
- Node.js 18+ (auto-installed via devcontainer)

---

## 🔄 Updating

### If Installed via Installer (Symlinks)

Scripts are symlinked, so just update the source:

```bash
cd claude-preview-automation
git pull  # If using git submodule
# Or manually update files
```

Changes automatically apply to all linked projects!

### If Manually Copied

Re-run the installer:

```bash
bash claude-preview-automation/install.sh
```

---

## 🎨 Customization

### Add Custom Actions on Commit

Edit `.codespace-automation/scripts/branch-watcher.js`:

```javascript
async function handleNewCommit(branch, commitHash) {
  // ... existing code ...

  // Add your custom logic:
  runCommand('npm test');           // Run tests
  runCommand('npm run lint');       // Run linter
  runCommand('npm run build');      // Build production
  // Send notification, deploy, etc.

  // ... rest of code ...
}
```

### Add New Ports to Dashboard

Edit `.codespace-automation/scripts/dashboard-server.js`:

```javascript
const PORT = 8080;  // Change dashboard port
```

---

## 🐛 Troubleshooting

### Services Not Starting

```bash
# Check status
pm2 list

# Start manually
bash .devcontainer/start-services.sh

# View logs
pm2 logs
```

### Preview Not Updating

```bash
# Check watcher logs
pm2 logs branch-watcher

# Manually trigger
git fetch origin
claude-preview current
pm2 restart dev-server
```

### Scripts Not Executable

```bash
chmod +x .devcontainer/*.sh
chmod +x claude-preview-automation/scripts/*.sh
chmod +x claude-preview-automation/scripts/claude-preview
```

---

## 💡 Pro Tips

1. **Use Git Submodule** for easy updates across projects
2. **Customize for Your Stack** - Edit configs for your framework
3. **Monitor Dashboard** - `https://YOUR-CODESPACE-8080.app.github.dev`
4. **Use Helper CLI** - Install `claude-preview` command for quick actions
5. **Keep Codespace Alive** - Use largest machine to prevent timeouts

---

## 📊 Performance

| Metric | Time |
|--------|------|
| Claude commits | 0s |
| Watcher detects | ~3s |
| Branch checkout | ~2s |
| npm install (if needed) | ~10-20s |
| Dev server restart | ~5s |
| **Total (no deps)** | **~10-15s** |
| **Total (with deps)** | **~20-30s** |
| **vs Manual** | **30-80s** |
| **Improvement** | **50-75% faster** |

---

## 🤝 Sharing with Team

### Option 1: Git Submodule
```bash
# In your project
git submodule add https://your-repo/claude-preview-automation.git
git commit -m "Add Claude Preview Automation"
git push

# Team members
git submodule update --init --recursive
bash claude-preview-automation/install.sh
```

### Option 2: Copy to Project
```bash
# Copy folder, commit it
git add claude-preview-automation
git commit -m "Add Claude Preview Automation"
git push

# Team members
bash claude-preview-automation/install.sh
```

---

## 🎯 Example: Installing in a Next.js Project

```bash
# 1. Clone your Next.js project
git clone https://github.com/you/nextjs-app.git
cd nextjs-app

# 2. Copy automation folder
cp -r /path/to/claude-preview-automation .

# 3. Run installer
bash claude-preview-automation/install.sh

# 4. Commit
git add .devcontainer .vscode .codespace-automation *.md
git commit -m "Add Claude Preview Automation"
git push

# 5. Open in Codespaces
# GitHub → Code → Codespaces → Create

# 6. Wait for setup (~2-3 min first time)

# 7. Open preview
# Simple Browser: https://YOUR-CODESPACE-3000.app.github.dev

# 8. Use Claude.ai
# Ask: "Add a new feature to the homepage"
# Watch: Preview auto-updates in ~10-15s!
```

---

## 📄 License

MIT - Use freely in any project!

---

## 🙏 Credits

Inspired by **bolt.diy**'s instant preview architecture.

Adapted for GitHub Codespaces + Claude.ai workflow.

---

## 🆘 Support

- **Documentation**: See `docs/` folder
- **Quick Start**: `CLAUDE_PREVIEW_SETUP.md` in project root after install
- **Issues**: Check logs with `pm2 logs`
- **Reset**: Run `claude-preview reset` (after installing CLI)

---

## 🎉 You're Ready!

This portable package contains everything you need for automated Claude.ai previews.

**Just copy, install, and enjoy 50-75% faster workflow!**

```bash
# Copy to any project
cp -r claude-preview-automation /path/to/new-project/

# Install
cd /path/to/new-project
bash claude-preview-automation/install.sh

# Done! 🎉
```

**Happy coding! 🚀**
