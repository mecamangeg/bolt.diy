#!/bin/bash
# Disable Existing Automation Script

echo "🛑 Disabling existing automation..."
echo ""

# Stop PM2 processes
if command -v pm2 >/dev/null 2>&1; then
  PM2_COUNT=$(pm2 list | grep -c "online" || echo "0")
  if [ "$PM2_COUNT" -gt 0 ]; then
    echo "Stopping PM2 processes..."
    pm2 stop all
    pm2 delete all
    echo "✅ PM2 processes stopped"
  fi
fi

# Kill processes on common ports
for PORT in 3000 5173 8080; do
  if lsof -i :$PORT >/dev/null 2>&1; then
    echo "Killing process on port $PORT..."
    lsof -ti :$PORT | xargs kill -9 2>/dev/null || true
    echo "✅ Port $PORT freed"
  fi
done

# Backup existing .devcontainer
if [ -d ".devcontainer" ]; then
  echo "Backing up .devcontainer/ → .devcontainer.backup/"
  mv .devcontainer .devcontainer.backup
  echo "✅ .devcontainer backed up"
fi

# Backup existing .vscode files
if [ -f ".vscode/settings.json" ]; then
  echo "Backing up .vscode/settings.json → .vscode/settings.json.pre-automation"
  cp .vscode/settings.json .vscode/settings.json.pre-automation
fi

if [ -f ".vscode/tasks.json" ]; then
  echo "Backing up .vscode/tasks.json → .vscode/tasks.json.pre-automation"
  cp .vscode/tasks.json .vscode/tasks.json.pre-automation
fi

echo ""
echo "✅ Existing automation disabled and backed up!"
echo "Safe to proceed with installation."
