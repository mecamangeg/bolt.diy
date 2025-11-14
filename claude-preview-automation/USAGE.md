# 🎯 Quick Usage Guide - Port to Any Project

## 3-Step Installation

### Step 1: Copy the Folder

```bash
# Copy to your project
cp -r /path/to/claude-preview-automation /path/to/your-project/

# Or clone if using git
cd /path/to/your-project
git clone https://github.com/your-username/claude-preview-automation.git
```

### Step 2: Run Installer

```bash
cd /path/to/your-project
bash claude-preview-automation/install.sh
```

### Step 3: Commit & Use

```bash
# Commit the changes
git add .devcontainer .vscode .codespace-automation *.md
git commit -m "Add Claude Preview Automation"
git push

# Open in Codespaces
# GitHub → Code → Codespaces → Create
```

---

## 📋 Examples

### Example 1: Next.js App

```bash
# Your Next.js project
cd ~/projects/my-nextjs-app

# Copy automation
cp -r ~/claude-preview-automation .

# Install
bash claude-preview-automation/install.sh

# Commit
git add -A
git commit -m "Add Claude Preview Automation"
git push

# Open in Codespaces - Done! 🎉
```

### Example 2: Vite + React

```bash
# Your Vite project
cd ~/projects/my-vite-app

# Copy automation
cp -r ~/claude-preview-automation .

# Customize port if not using 3000
# Edit: claude-preview-automation/devcontainer/devcontainer.json
# Change: "forwardPorts": [5173, 8080]

# Install
bash claude-preview-automation/install.sh

# Commit & push
git add -A
git commit -m "Add Claude Preview Automation"
git push
```

### Example 3: T3 Stack

```bash
# Your T3 app
cd ~/projects/my-t3-app

# Copy automation
cp -r ~/claude-preview-automation .

# Install
bash claude-preview-automation/install.sh

# Test locally first (optional)
npm install -g pm2
bash .devcontainer/start-services.sh
pm2 logs

# Commit & push
git add -A
git commit -m "Add Claude Preview Automation"
git push
```

---

## 🔧 Customization

### Change Dev Server Port

If your app uses a different port (e.g., 5173 for Vite):

```bash
# Edit devcontainer config
nano claude-preview-automation/devcontainer/devcontainer.json

# Change:
"forwardPorts": [5173, 8080],  # Your port + dashboard

# Then install
bash claude-preview-automation/install.sh
```

### Change Dev Server Command

If your app uses a different command (e.g., `pnpm dev`):

```bash
# Edit start-services.sh
nano claude-preview-automation/devcontainer/start-services.sh

# Change:
pm2 start pnpm \
  --name "dev-server" \
  -- dev

# Then install
bash claude-preview-automation/install.sh
```

### Adjust Polling Speed

```bash
# Edit branch watcher
nano claude-preview-automation/scripts/branch-watcher.js

# Change:
const CONFIG = {
  pollInterval: 1000,  # Faster (1s)
  // or
  pollInterval: 5000,  # Slower (5s)
};
```

---

## 🚀 Multiple Projects Workflow

### Scenario: You have 3 Next.js projects

```bash
# Keep one source folder
~/claude-preview-automation/

# Install in each project
cd ~/projects/project-1
bash ~/claude-preview-automation/install.sh

cd ~/projects/project-2
bash ~/claude-preview-automation/install.sh

cd ~/projects/project-3
bash ~/claude-preview-automation/install.sh
```

**Benefits:**
- Scripts are symlinked to source
- Update source → all projects update automatically
- No code duplication

---

## 📦 Sharing with Team

### Method 1: Commit Directly

```bash
# In your project
cp -r ~/claude-preview-automation .
bash claude-preview-automation/install.sh
git add -A
git commit -m "Add Claude Preview Automation"
git push

# Team members just need to:
# 1. Pull changes
# 2. Open in Codespaces
# Auto-setup happens automatically via devcontainer!
```

### Method 2: Git Submodule

```bash
# In your project
git submodule add https://github.com/you/claude-preview-automation.git
bash claude-preview-automation/install.sh
git add -A
git commit -m "Add Claude Preview Automation"
git push

# Team members:
git pull
git submodule update --init --recursive
bash claude-preview-automation/install.sh
```

---

## 🗑️ Uninstall

```bash
# From your project root
bash claude-preview-automation/uninstall.sh

# Removes:
# - .devcontainer/
# - .vscode/ files (restores backups if exist)
# - .codespace-automation/
# - Documentation files

# Manually remove the source folder if done
rm -rf claude-preview-automation
```

---

## 💡 Pro Tips

### Tip 1: Test Locally First

```bash
# Before pushing to Codespaces, test locally
npm install -g pm2
bash .devcontainer/start-services.sh
pm2 logs

# If working, commit and push
```

### Tip 2: Use as Template

```bash
# Create a template repository with automation pre-installed
# Then use it for all new projects:
gh repo create my-nextjs-template --template my-org/nextjs-with-automation
```

### Tip 3: Customize Per Framework

```bash
# Keep different versions for different frameworks
~/claude-preview-automation-nextjs/
~/claude-preview-automation-vite/
~/claude-preview-automation-t3/

# Each with customized configs
```

### Tip 4: One-Liner Install

```bash
# Create an alias
alias install-claude-preview='bash ~/claude-preview-automation/install.sh'

# Use anywhere
cd /path/to/any-project
install-claude-preview
```

---

## 📊 Checklist

Before using in a project, ensure:

- [ ] Project has `package.json`
- [ ] Project has dev server script (`npm run dev`)
- [ ] Project uses Git
- [ ] You have GitHub Codespaces access
- [ ] (Optional) Customize ports if needed
- [ ] (Optional) Customize dev command if needed

---

## 🆘 Troubleshooting

### "Services not starting"

```bash
# Check if PM2 is installed
pm2 --version

# If not, install globally
npm install -g pm2

# Restart services
bash .devcontainer/start-services.sh
```

### "Preview not updating"

```bash
# Check watcher logs
pm2 logs branch-watcher

# Verify branch pattern matches
# Default: claude/*
# If Claude uses different pattern, edit branch-watcher.js
```

### "Port already in use"

```bash
# Check what's using port 3000
lsof -i :3000

# Kill it or change port in devcontainer.json
```

---

## 📚 More Help

- **README.md** - Main documentation
- **docs/SETUP.md** - Detailed setup guide
- **docs/QUICK_REFERENCE.md** - Daily usage commands
- **docs/IMPLEMENTATION_SUMMARY.md** - Technical details

---

## ✨ That's It!

You can now copy `claude-preview-automation/` to any project and enable automated previews in 3 commands:

```bash
cp -r ~/claude-preview-automation .
bash claude-preview-automation/install.sh
git add -A && git commit -m "Add automation" && git push
```

**Happy coding! 🚀**
