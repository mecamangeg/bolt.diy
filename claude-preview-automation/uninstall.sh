#!/bin/bash

# Claude Preview Automation - Uninstaller
# Removes all installed files from a project

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="${1:-$(pwd)}"

echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}Claude Preview Automation - Uninstaller${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}This will remove:${NC}"
echo -e "  • .devcontainer/ folder"
echo -e "  • .vscode/ files (tasks.json, settings.json, extensions.json)"
echo -e "  • .codespace-automation/ folder"
echo -e "  • CLAUDE_PREVIEW_SETUP.md"
echo -e "  • QUICK_REFERENCE.md"
echo ""
echo -e "${RED}⚠️  WARNING: This action cannot be undone!${NC}"
echo ""
read -p "Continue with uninstall? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Uninstall cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Uninstalling...${NC}"
echo ""

# Stop PM2 processes first
if command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}Stopping PM2 processes...${NC}"
    pm2 delete branch-watcher 2>/dev/null || true
    pm2 delete dev-server 2>/dev/null || true
    pm2 delete preview-dashboard 2>/dev/null || true
    pm2 save --force 2>/dev/null || true
    echo -e "${GREEN}✓ PM2 processes stopped${NC}"
fi

# Remove .devcontainer
if [ -d "$PROJECT_ROOT/.devcontainer" ]; then
    echo -e "${YELLOW}Removing .devcontainer...${NC}"
    rm -rf "$PROJECT_ROOT/.devcontainer"
    echo -e "${GREEN}✓ .devcontainer removed${NC}"
fi

# Remove .vscode files (only the ones we added)
if [ -d "$PROJECT_ROOT/.vscode" ]; then
    echo -e "${YELLOW}Removing .vscode files...${NC}"

    # Restore backups if they exist
    if [ -f "$PROJECT_ROOT/.vscode/settings.json.backup" ]; then
        mv "$PROJECT_ROOT/.vscode/settings.json.backup" "$PROJECT_ROOT/.vscode/settings.json"
        echo -e "${GREEN}  ✓ Restored settings.json from backup${NC}"
    else
        rm -f "$PROJECT_ROOT/.vscode/settings.json"
        echo -e "${GREEN}  ✓ Removed settings.json${NC}"
    fi

    if [ -f "$PROJECT_ROOT/.vscode/tasks.json.backup" ]; then
        mv "$PROJECT_ROOT/.vscode/tasks.json.backup" "$PROJECT_ROOT/.vscode/tasks.json"
        echo -e "${GREEN}  ✓ Restored tasks.json from backup${NC}"
    else
        rm -f "$PROJECT_ROOT/.vscode/tasks.json"
        echo -e "${GREEN}  ✓ Removed tasks.json${NC}"
    fi

    rm -f "$PROJECT_ROOT/.vscode/extensions.json"
    echo -e "${GREEN}  ✓ Removed extensions.json${NC}"

    # Remove .vscode directory if empty
    if [ -z "$(ls -A $PROJECT_ROOT/.vscode)" ]; then
        rmdir "$PROJECT_ROOT/.vscode"
        echo -e "${GREEN}  ✓ Removed empty .vscode directory${NC}"
    fi
fi

# Remove .codespace-automation
if [ -d "$PROJECT_ROOT/.codespace-automation" ]; then
    echo -e "${YELLOW}Removing .codespace-automation...${NC}"
    rm -rf "$PROJECT_ROOT/.codespace-automation"
    echo -e "${GREEN}✓ .codespace-automation removed${NC}"
fi

# Remove documentation
echo -e "${YELLOW}Removing documentation...${NC}"
rm -f "$PROJECT_ROOT/CLAUDE_PREVIEW_SETUP.md"
rm -f "$PROJECT_ROOT/QUICK_REFERENCE.md"
echo -e "${GREEN}✓ Documentation removed${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Uninstall complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Note: The claude-preview-automation/ folder was NOT removed.${NC}"
echo -e "${BLUE}You can delete it manually if you no longer need it:${NC}"
echo -e "  ${YELLOW}rm -rf claude-preview-automation${NC}"
echo ""
