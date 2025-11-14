#!/bin/bash
set -e

echo "🔄 Starting Claude Preview automation services..."

# Navigate to project root
cd /workspaces/$(basename "$PWD") || cd "$PWD"

# Start the git branch watcher
echo "👀 Starting git branch watcher..."
pm2 start .codespace-automation/scripts/branch-watcher.js \
  --name "branch-watcher" \
  --watch false \
  --restart-delay 3000 \
  --max-restarts 10 \
  --error .codespace-automation/logs/watcher-error.log \
  --output .codespace-automation/logs/watcher-output.log

# Start the dev server with auto-restart
echo "🌐 Starting dev server with PM2 auto-healing..."
pm2 start pnpm \
  --name "dev-server" \
  --watch false \
  -- run dev \
  --max-restarts 10 \
  --restart-delay 2000 \
  --error .codespace-automation/logs/dev-error.log \
  --output .codespace-automation/logs/dev-output.log

# Start the preview dashboard (optional)
echo "📊 Starting preview dashboard..."
pm2 start .codespace-automation/scripts/dashboard-server.js \
  --name "preview-dashboard" \
  --watch false \
  --restart-delay 3000 \
  --error .codespace-automation/logs/dashboard-error.log \
  --output .codespace-automation/logs/dashboard-output.log

# Save PM2 process list
pm2 save

echo "✅ All services started!"
echo ""
echo "📊 Service status:"
pm2 list

echo ""
echo "💡 Useful commands:"
echo "  pm2 logs             - View all logs"
echo "  pm2 logs dev-server  - View dev server logs"
echo "  pm2 restart all      - Restart all services"
echo "  pm2 monit            - Monitor resources"
echo ""
echo "🎯 Preview URL: https://${CODESPACE_NAME}-3000.app.github.dev"
