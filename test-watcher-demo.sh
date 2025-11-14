#!/bin/bash

# Demonstration of how the branch watcher works
# This simulates what happens when Claude.ai makes a commit

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Claude Preview Automation - Watcher Demo${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Show current branch
echo -e "${YELLOW}📍 Step 1: Current State${NC}"
echo -e "Branch: ${GREEN}$(git rev-parse --abbrev-ref HEAD)${NC}"
echo -e "Commit: ${GREEN}$(git rev-parse --short HEAD)${NC}"
echo -e "Message: ${GREEN}$(git log -1 --format=%s)${NC}"
echo ""
sleep 1

# Step 2: Simulate watcher polling
echo -e "${YELLOW}👀 Step 2: Watcher Polling (every 3 seconds)${NC}"
echo -e "${CYAN}git fetch origin${NC}"
git fetch origin 2>&1 | head -5
echo ""
sleep 1

# Step 3: Get Claude branches
echo -e "${YELLOW}🌿 Step 3: Detecting Claude Branches${NC}"
echo -e "${CYAN}git branch -r | grep claude/${NC}"
CLAUDE_BRANCHES=$(git branch -r | grep "origin/claude/" | head -5)
echo "$CLAUDE_BRANCHES"
echo ""
sleep 1

# Step 4: Get latest commit on current branch
echo -e "${YELLOW}🔍 Step 4: Checking Latest Commit${NC}"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
LATEST_COMMIT=$(git rev-parse HEAD)
LATEST_COMMIT_SHORT=$(git rev-parse --short HEAD)
echo -e "Latest commit on ${GREEN}$CURRENT_BRANCH${NC}:"
echo -e "  Hash: ${GREEN}$LATEST_COMMIT_SHORT${NC}"
echo -e "  Author: ${GREEN}$(git log -1 --format='%an <%ae>')${NC}"
echo -e "  Date: ${GREEN}$(git log -1 --format='%ar')${NC}"
echo -e "  Message: ${GREEN}$(git log -1 --format=%s)${NC}"
echo ""
sleep 1

# Step 5: Simulate detection logic
echo -e "${YELLOW}🎯 Step 5: Detection Logic${NC}"
echo -e "${CYAN}if (newCommit !== lastCommit) {${NC}"
echo -e "${CYAN}  handleNewCommit(branch, commit);${NC}"
echo -e "${CYAN}}${NC}"
echo ""
echo -e "${GREEN}✓ New commit detected!${NC}"
echo ""
sleep 1

# Step 6: Show what would happen
echo -e "${YELLOW}⚡ Step 6: Automated Actions (What Would Happen)${NC}"
echo ""

echo -e "  ${BLUE}1. Auto-checkout:${NC}"
echo -e "     ${CYAN}git checkout $CURRENT_BRANCH${NC}"
echo -e "     ${CYAN}git pull origin $CURRENT_BRANCH${NC}"
echo -e "     ${GREEN}✓ Branch checked out${NC}"
echo ""

echo -e "  ${BLUE}2. Check dependencies:${NC}"
PREV_COMMIT=$(git rev-parse HEAD~1 2>/dev/null || echo "none")
if [ "$PREV_COMMIT" != "none" ]; then
    PACKAGE_CHANGED=$(git diff $PREV_COMMIT HEAD -- package.json | wc -l)
    if [ "$PACKAGE_CHANGED" -gt 0 ]; then
        echo -e "     ${YELLOW}⚠ package.json changed${NC}"
        echo -e "     ${CYAN}npm install${NC}"
        echo -e "     ${GREEN}✓ Dependencies installed${NC}"
    else
        echo -e "     ${GREEN}✓ No dependency changes${NC}"
    fi
else
    echo -e "     ${GREEN}✓ First commit, no comparison${NC}"
fi
echo ""

echo -e "  ${BLUE}3. Restart dev server:${NC}"
echo -e "     ${CYAN}pm2 restart dev-server${NC}"
echo -e "     ${CYAN}sleep 3  # Wait for server to start${NC}"
echo -e "     ${GREEN}✓ Dev server restarted${NC}"
echo ""

echo -e "  ${BLUE}4. Update state:${NC}"
echo -e "     ${CYAN}Save to: .codespace-automation/config/watcher-state.json${NC}"
echo -e "     ${GREEN}✓ State saved${NC}"
echo ""

echo -e "  ${BLUE}5. Notify user:${NC}"
if [ -n "$CODESPACE_NAME" ]; then
    PREVIEW_URL="https://$CODESPACE_NAME-3000.app.github.dev"
else
    PREVIEW_URL="http://localhost:3000"
fi
echo -e "     ${GREEN}🌐 Preview: $PREVIEW_URL${NC}"
echo -e "     ${GREEN}✓ Auto-refresh triggered${NC}"
echo ""

# Step 7: Timeline
echo -e "${YELLOW}⏱️  Step 7: Performance Timeline${NC}"
echo ""
echo -e "  ${CYAN}Claude commits${NC}           →  0s"
echo -e "  ${CYAN}Watcher detects${NC}          →  ~3s   (polling interval)"
echo -e "  ${CYAN}Branch checkout${NC}          →  ~2s   (git operations)"
echo -e "  ${CYAN}npm install${NC}              →  ~10-20s (if package.json changed)"
echo -e "  ${CYAN}Dev server restart${NC}       →  ~5s   (PM2 process restart)"
echo -e "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Total (no deps):${NC}         ${GREEN}~10-15s${NC}"
echo -e "  ${GREEN}Total (with deps):${NC}       ${GREEN}~20-30s${NC}"
echo ""
echo -e "  ${YELLOW}vs. Manual workflow:${NC}     ${YELLOW}30-80s${NC}"
echo -e "  ${GREEN}Improvement:${NC}             ${GREEN}50-75% faster ✨${NC}"
echo ""

# Step 8: Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Demo Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📚 What This Demonstrates:${NC}"
echo ""
echo -e "  • Watcher polls GitHub every 3 seconds"
echo -e "  • Detects new commits on claude/* branches"
echo -e "  • Auto-checks out the latest branch"
echo -e "  • Installs dependencies if needed"
echo -e "  • Restarts dev server automatically"
echo -e "  • User sees preview in ~10-30 seconds"
echo ""
echo -e "${CYAN}🚀 To Test for Real:${NC}"
echo ""
echo -e "  1. Open this repo in GitHub Codespaces"
echo -e "  2. Services will auto-start (PM2)"
echo -e "  3. Use Claude.ai to make changes"
echo -e "  4. Watch preview auto-update!"
echo ""
echo -e "${CYAN}📊 Monitor in Real-Time:${NC}"
echo ""
echo -e "  ${GREEN}pm2 logs branch-watcher${NC}  # Watch detection logs"
echo -e "  ${GREEN}pm2 logs dev-server${NC}      # Watch server restarts"
echo -e "  ${GREEN}claude-preview status${NC}    # Check current state"
echo ""
