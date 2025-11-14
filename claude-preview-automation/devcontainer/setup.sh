#!/bin/bash
set -e

echo "🚀 Setting up Claude Preview Codespace..."

# Install PM2 globally for process management
echo "📦 Installing PM2 for auto-healing dev server..."
npm install -g pm2

# Install project dependencies
echo "📦 Installing project dependencies..."
npm install

# Create directories for automation scripts
mkdir -p .codespace-automation/{logs,scripts,config}

# Install additional tools
echo "🔧 Installing automation tools..."
npm install -g nodemon chokidar-cli concurrently

# Set up git configuration
echo "🔧 Configuring git..."
git config --global fetch.prune true
git config --global pull.rebase true
git config --global core.autocrlf input

# Create symlink for easy access to automation scripts
ln -sf .codespace-automation/scripts ~/automation

# Make all scripts executable
chmod +x .devcontainer/*.sh
chmod +x .codespace-automation/scripts/*.sh 2>/dev/null || true

# Set up PM2 to start on boot (persistence)
pm2 startup systemd -u node --hp /home/node || true
pm2 save

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run 'npm run dev' to start the dev server"
echo "2. The branch watcher will auto-start"
echo "3. Open Simple Browser to preview your app"
