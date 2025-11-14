#!/bin/bash

# Claude Preview Automation - One-Command Installer
# Installs the complete automation system in any project

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="${1:-$(pwd)}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Claude Preview Automation - Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Installation directory:${NC} $PROJECT_ROOT"
echo -e "${YELLOW}Source directory:${NC} $SCRIPT_DIR"
echo ""

# Confirm installation
read -p "Install Claude Preview Automation here? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Starting installation...${NC}"
echo ""

# Create .devcontainer directory
echo -e "${BLUE}📁 Setting up .devcontainer...${NC}"
mkdir -p "$PROJECT_ROOT/.devcontainer"
cp "$SCRIPT_DIR/devcontainer/devcontainer.json" "$PROJECT_ROOT/.devcontainer/"
cp "$SCRIPT_DIR/devcontainer/setup.sh" "$PROJECT_ROOT/.devcontainer/"
cp "$SCRIPT_DIR/devcontainer/start-services.sh" "$PROJECT_ROOT/.devcontainer/"
chmod +x "$PROJECT_ROOT/.devcontainer"/*.sh
echo -e "${GREEN}✓ .devcontainer configured${NC}"

# Create .vscode directory
echo -e "${BLUE}📁 Setting up .vscode...${NC}"
mkdir -p "$PROJECT_ROOT/.vscode"

# Merge with existing VSCode settings if they exist
if [ -f "$PROJECT_ROOT/.vscode/settings.json" ]; then
    echo -e "${YELLOW}  Note: Existing .vscode/settings.json found${NC}"
    echo -e "${YELLOW}  Backing up to .vscode/settings.json.backup${NC}"
    cp "$PROJECT_ROOT/.vscode/settings.json" "$PROJECT_ROOT/.vscode/settings.json.backup"
fi

if [ -f "$PROJECT_ROOT/.vscode/tasks.json" ]; then
    echo -e "${YELLOW}  Note: Existing .vscode/tasks.json found${NC}"
    echo -e "${YELLOW}  Backing up to .vscode/tasks.json.backup${NC}"
    cp "$PROJECT_ROOT/.vscode/tasks.json" "$PROJECT_ROOT/.vscode/tasks.json.backup"
fi

cp "$SCRIPT_DIR/vscode/settings.json" "$PROJECT_ROOT/.vscode/"
cp "$SCRIPT_DIR/vscode/tasks.json" "$PROJECT_ROOT/.vscode/"
cp "$SCRIPT_DIR/vscode/extensions.json" "$PROJECT_ROOT/.vscode/"
echo -e "${GREEN}✓ .vscode configured${NC}"

# Create .codespace-automation directory (with symlink to scripts)
echo -e "${BLUE}📁 Setting up .codespace-automation...${NC}"
mkdir -p "$PROJECT_ROOT/.codespace-automation"
mkdir -p "$PROJECT_ROOT/.codespace-automation/logs"
mkdir -p "$PROJECT_ROOT/.codespace-automation/config"

# Create symlink to scripts (so updates to source automatically propagate)
if [ -L "$PROJECT_ROOT/.codespace-automation/scripts" ]; then
    rm "$PROJECT_ROOT/.codespace-automation/scripts"
fi
ln -s "$SCRIPT_DIR/scripts" "$PROJECT_ROOT/.codespace-automation/scripts"

# Copy package.json
cp "$SCRIPT_DIR/package.json" "$PROJECT_ROOT/.codespace-automation/"

# Create .gitignore for automation folder
cat > "$PROJECT_ROOT/.codespace-automation/.gitignore" <<EOF
# Logs
logs/*.log

# State files
config/*.json

# Node modules
node_modules/

# PM2 files
.pm2/
EOF

echo -e "${GREEN}✓ .codespace-automation configured${NC}"

# Create initial state file
echo -e "${BLUE}💾 Creating initial state...${NC}"
cat > "$PROJECT_ROOT/.codespace-automation/config/watcher-state.json" <<EOF
{
  "lastCommit": null,
  "lastBranch": null,
  "lastCheck": null,
  "processedCommits": []
}
EOF
echo -e "${GREEN}✓ State file created${NC}"

# Copy documentation
echo -e "${BLUE}📚 Copying documentation...${NC}"
cp "$SCRIPT_DIR/docs/SETUP.md" "$PROJECT_ROOT/CLAUDE_PREVIEW_SETUP.md"
cp "$SCRIPT_DIR/docs/QUICK_REFERENCE.md" "$PROJECT_ROOT/QUICK_REFERENCE.md"
echo -e "${GREEN}✓ Documentation copied${NC}"

# Make scripts executable
echo -e "${BLUE}🔧 Setting permissions...${NC}"
chmod +x "$SCRIPT_DIR/scripts"/*.sh 2>/dev/null || true
chmod +x "$SCRIPT_DIR/scripts/claude-preview" 2>/dev/null || true
chmod +x "$PROJECT_ROOT/.devcontainer"/*.sh 2>/dev/null || true
echo -e "${GREEN}✓ Permissions set${NC}"

# Create helpful README in automation folder
cat > "$PROJECT_ROOT/.codespace-automation/README.md" <<EOF
# Claude Preview Automation

This folder contains the automation system for Claude.ai → GitHub Codespaces previews.

## 📂 Folder Structure

\`\`\`
.codespace-automation/
├── scripts/          → Symlink to source scripts (auto-updates)
├── logs/             → Log files (gitignored)
├── config/           → State files (gitignored)
├── package.json      → Dependencies
└── .gitignore        → Ignore logs and state
\`\`\`

## 🔗 Symlinked Scripts

The \`scripts/\` folder is a symlink to the original source:
\`$SCRIPT_DIR/scripts\`

This means:
- Updates to the source automatically apply here
- You can modify scripts in either location
- Easy to keep multiple projects in sync

## 📚 Documentation

See project root for:
- \`CLAUDE_PREVIEW_SETUP.md\` - Quick start guide
- \`QUICK_REFERENCE.md\` - Daily usage cheat sheet

Full documentation: \`$SCRIPT_DIR/docs/README.md\`

## 🔄 Updating

To update the automation system:

\`\`\`bash
# If using git submodule (recommended)
cd $SCRIPT_DIR
git pull

# If copied directly
# Re-run the installer from the updated source
\`\`\`

## 🛠️ Quick Commands

\`\`\`bash
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
\`\`\`

---

Installed from: \`$SCRIPT_DIR\`
Installation date: $(date)
EOF

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 What was installed:${NC}"
echo ""
echo -e "  ${GREEN}✓${NC} .devcontainer/         (Codespace auto-setup)"
echo -e "  ${GREEN}✓${NC} .vscode/               (VSCode integration)"
echo -e "  ${GREEN}✓${NC} .codespace-automation/ (Automation system)"
echo -e "  ${GREEN}✓${NC} CLAUDE_PREVIEW_SETUP.md"
echo -e "  ${GREEN}✓${NC} QUICK_REFERENCE.md"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo ""
echo -e "  1. ${YELLOW}Commit the changes:${NC}"
echo -e "     git add .devcontainer .vscode .codespace-automation *.md"
echo -e "     git commit -m \"Add Claude Preview Automation\""
echo ""
echo -e "  2. ${YELLOW}Open in GitHub Codespaces:${NC}"
echo -e "     The devcontainer will automatically set everything up"
echo ""
echo -e "  3. ${YELLOW}Install helper CLI (optional):${NC}"
echo -e "     ln -s $PROJECT_ROOT/.codespace-automation/scripts/claude-preview /usr/local/bin/"
echo ""
echo -e "  4. ${YELLOW}Start using:${NC}"
echo -e "     Read CLAUDE_PREVIEW_SETUP.md for quick start"
echo ""
echo -e "${CYAN}💡 Tip: Scripts are symlinked, so updates to the source automatically propagate!${NC}"
echo ""
