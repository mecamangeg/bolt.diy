#!/bin/bash
# Conflict Detection Script

echo "🔍 Checking for existing automation conflicts..."
echo ""

CONFLICTS=0

# Check for existing .devcontainer
if [ -d ".devcontainer" ]; then
  echo "⚠️  Found existing .devcontainer/"
  echo "   Files: $(ls -1 .devcontainer | wc -l)"
  echo "   Action: Will backup to .devcontainer.backup/"
  CONFLICTS=$((CONFLICTS + 1))
fi

# Check for existing .vscode
if [ -f ".vscode/settings.json" ] || [ -f ".vscode/tasks.json" ]; then
  echo "⚠️  Found existing .vscode configuration"
  echo "   Will backup: settings.json, tasks.json"
  CONFLICTS=$((CONFLICTS + 1))
fi

# Check for running PM2 processes
if command -v pm2 >/dev/null 2>&1; then
  PM2_COUNT=$(pm2 list | grep -c "online" || echo "0")
  if [ "$PM2_COUNT" -gt 0 ]; then
    echo "⚠️  Found $PM2_COUNT running PM2 processes"
    echo "   Run: pm2 list to see them"
    echo "   Action: Will prompt to stop before installation"
    CONFLICTS=$((CONFLICTS + 1))
  fi
fi

# Check for port conflicts
for PORT in 3000 5173 8080; do
  if lsof -i :$PORT >/dev/null 2>&1; then
    PID=$(lsof -t -i :$PORT)
    PROC=$(ps -p $PID -o comm= 2>/dev/null || echo "unknown")
    echo "⚠️  Port $PORT is in use by process: $PROC (PID: $PID)"
    CONFLICTS=$((CONFLICTS + 1))
  fi
done

echo ""
if [ $CONFLICTS -eq 0 ]; then
  echo "✅ No conflicts detected! Safe to proceed with installation."
  exit 0
else
  echo "⚠️  Found $CONFLICTS potential conflict(s)"
  echo ""
  echo "Recommended actions:"
  echo "  1. Run: bash claude-preview-automation/scripts/disable-existing.sh"
  echo "  2. Or manually backup/stop conflicting services"
  echo "  3. Then proceed with installation"
  exit 1
fi
