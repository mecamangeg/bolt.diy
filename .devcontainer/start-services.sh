#!/bin/bash
set -e

echo "🔄 Starting Claude Preview automation services..."

# Navigate to project root
cd /workspaces/$(basename "$PWD") || cd "$PWD"

# Detect package manager
echo "🔍 Detecting package manager..."
if [ -f "pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
  echo "✅ Detected pnpm"
elif [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
  echo "✅ Detected yarn"
elif [ -f "package-lock.json" ]; then
  PKG_MANAGER="npm"
  echo "✅ Detected npm"
else
  PKG_MANAGER="npm"
  echo "⚠️  No lock file found, defaulting to npm"
fi

# Quick Win #2: Pre-check dependencies
echo "🔍 Checking dependencies..."
if [ ! -d "node_modules" ]; then
  echo "📦 node_modules not found, installing dependencies..."
  $PKG_MANAGER install
else
  echo "✅ Dependencies already installed"
fi

# Quick Win #3: Detect dev server port
echo "🔍 Detecting dev server port..."
if [ -f "vite.config.ts" ] || [ -f "vite.config.js" ]; then
  # Check for port in vite config
  DEV_PORT=$(grep -r "server.*port" vite.config.* 2>/dev/null | grep -oE '[0-9]+' | head -1 || echo "5173")
  echo "✅ Detected Vite dev server on port $DEV_PORT"
elif [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
  DEV_PORT="3000"
  echo "✅ Detected Next.js dev server on port $DEV_PORT"
else
  # Default to 5173 (Vite default)
  DEV_PORT="5173"
  echo "⚠️  No config found, defaulting to port $DEV_PORT"
fi

# Store port for other scripts to use
echo "$DEV_PORT" > .codespace-automation/config/dev-port.txt

# Start the git branch watcher
echo "👀 Starting git branch watcher..."
pm2 start .codespace-automation/scripts/branch-watcher.js \
  --name "branch-watcher" \
  --watch false \
  --restart-delay 3000 \
  --max-restarts 10 \
  --error .codespace-automation/logs/watcher-error.log \
  --output .codespace-automation/logs/watcher-output.log

# Start the dev server with auto-restart (using detected package manager)
echo "🌐 Starting dev server with PM2 auto-healing..."
pm2 start $PKG_MANAGER \
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
echo "  claude-preview       - Quick access to all commands"
echo ""
echo "🎯 Preview URL: https://${CODESPACE_NAME}-${DEV_PORT}.app.github.dev"
echo "📊 Dashboard URL: https://${CODESPACE_NAME}-8080.app.github.dev"
