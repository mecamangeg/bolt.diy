#!/bin/bash
# Verify Installation Script

echo "🔍 Verifying Claude Preview Automation installation..."
echo ""

ERRORS=0

# Check directory structure
echo "📁 Checking directory structure..."
for DIR in .devcontainer .vscode .codespace-automation; do
  if [ -d "$DIR" ]; then
    echo "  ✅ $DIR/ exists"
  else
    echo "  ❌ $DIR/ missing"
    ERRORS=$((ERRORS + 1))
  fi
done
echo ""

# Check key files
echo "📄 Checking key files..."
FILES=(
  ".devcontainer/devcontainer.json"
  ".devcontainer/setup.sh"
  ".devcontainer/start-services.sh"
  ".codespace-automation/scripts/claude-preview"
  ".codespace-automation/scripts/branch-watcher.js"
  ".codespace-automation/scripts/dashboard-server.js"
)

for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    echo "  ✅ $FILE"
  else
    echo "  ❌ $FILE missing"
    ERRORS=$((ERRORS + 1))
  fi
done
echo ""

# Check executability
echo "🔧 Checking executable permissions..."
EXECUTABLES=(
  ".devcontainer/setup.sh"
  ".devcontainer/start-services.sh"
  ".codespace-automation/scripts/claude-preview"
)

for EXEC in "${EXECUTABLES[@]}"; do
  if [ -x "$EXEC" ]; then
    echo "  ✅ $EXEC is executable"
  else
    echo "  ❌ $EXEC not executable"
    ERRORS=$((ERRORS + 1))
  fi
done
echo ""

# Check PM2
echo "📦 Checking PM2 installation..."
if command -v pm2 >/dev/null 2>&1; then
  echo "  ✅ PM2 installed ($(pm2 --version))"
else
  echo "  ⚠️  PM2 not installed (will be installed on first run)"
fi
echo ""

# Check node_modules
echo "📚 Checking dependencies..."
if [ -d "node_modules" ]; then
  echo "  ✅ node_modules exists"
else
  echo "  ⚠️  node_modules not found (run: pnpm install)"
fi
echo ""

# Final verdict
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
  echo "✅ Installation verified successfully!"
  echo ""
  echo "Next steps:"
  echo "  1. Start services: bash .codespace-automation/scripts/claude-preview start"
  echo "  2. Check status: bash .codespace-automation/scripts/claude-preview status"
  echo "  3. View dashboard: https://\${CODESPACE_NAME}-8080.app.github.dev"
  exit 0
else
  echo "❌ Installation verification failed with $ERRORS error(s)"
  echo ""
  echo "Please re-run installation or check the documentation."
  exit 1
fi
