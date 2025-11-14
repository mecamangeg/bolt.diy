#!/bin/bash
set -e

echo "🎯 Initializing Claude Preview Automation..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create necessary directories
echo -e "${BLUE}📁 Creating directories...${NC}"
mkdir -p .codespace-automation/{logs,scripts,config}
echo -e "${GREEN}✓ Directories created${NC}"

# Create log files
echo -e "${BLUE}📝 Creating log files...${NC}"
touch .codespace-automation/logs/{watcher-output.log,watcher-error.log,dev-output.log,dev-error.log,dashboard-output.log,dashboard-error.log}
echo -e "${GREEN}✓ Log files created${NC}"

# Create initial state file
echo -e "${BLUE}💾 Creating initial state...${NC}"
cat > .codespace-automation/config/watcher-state.json <<EOF
{
  "lastCommit": null,
  "lastBranch": null,
  "lastCheck": null,
  "processedCommits": []
}
EOF
echo -e "${GREEN}✓ State file created${NC}"

# Create .gitignore for automation folder
echo -e "${BLUE}🚫 Creating .gitignore...${NC}"
cat > .codespace-automation/.gitignore <<EOF
# Logs
logs/*.log

# State files
config/*.json

# Node modules (if any)
node_modules/

# PM2 files
.pm2/
EOF
echo -e "${GREEN}✓ .gitignore created${NC}"

# Make scripts executable
echo -e "${BLUE}🔧 Making scripts executable...${NC}"
chmod +x .codespace-automation/scripts/*.sh 2>/dev/null || true
chmod +x .codespace-automation/scripts/*.js 2>/dev/null || true
chmod +x .devcontainer/*.sh 2>/dev/null || true
echo -e "${GREEN}✓ Scripts are executable${NC}"

# Check if PM2 is installed
echo -e "${BLUE}📦 Checking PM2 installation...${NC}"
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}⚠️  PM2 not found, installing...${NC}"
    npm install -g pm2
    echo -e "${GREEN}✓ PM2 installed${NC}"
else
    echo -e "${GREEN}✓ PM2 already installed${NC}"
fi

# Check if project dependencies are installed
echo -e "${BLUE}📦 Checking project dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  Dependencies not found, installing...${NC}"
    npm install
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${GREEN}✓ Dependencies already installed${NC}"
fi

# Install automation dependencies
echo -e "${BLUE}📦 Installing automation dependencies...${NC}"
cd .codespace-automation
npm install --no-save chokidar 2>/dev/null || echo "Note: chokidar install optional"
cd ..
echo -e "${GREEN}✓ Automation dependencies installed${NC}"

# Setup PM2 startup
echo -e "${BLUE}🚀 Setting up PM2 startup...${NC}"
pm2 startup systemd -u $(whoami) --hp $HOME 2>/dev/null || echo "Note: PM2 startup may require sudo"
echo -e "${GREEN}✓ PM2 startup configured${NC}"

# Print summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Initialization complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo ""
echo -e "  1. Start services:"
echo -e "     ${YELLOW}bash .devcontainer/start-services.sh${NC}"
echo ""
echo -e "  2. Check status:"
echo -e "     ${YELLOW}pm2 list${NC}"
echo ""
echo -e "  3. View logs:"
echo -e "     ${YELLOW}pm2 logs${NC}"
echo ""
echo -e "  4. Open preview:"
echo -e "     ${YELLOW}https://\$CODESPACE_NAME-3000.app.github.dev${NC}"
echo ""
echo -e "  5. Open dashboard:"
echo -e "     ${YELLOW}https://\$CODESPACE_NAME-8080.app.github.dev${NC}"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo -e "  • ${YELLOW}CLAUDE_PREVIEW_SETUP.md${NC} - Quick start guide"
echo -e "  • ${YELLOW}.codespace-automation/README.md${NC} - Detailed docs"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
