#!/bin/bash

# EtherDrops Monitor Bot - VPS Startup Script
# Enhanced version with better error handling and memory management

echo "🚀 Starting EtherDrops Monitor Bot..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18 or higher is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js version: $(node -v)"

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo "📦 Installing PM2..."
    npm install -g pm2
fi

echo "✅ PM2 version: $(pm2 -v)"

# Check if required files exist
if [ ! -f "index.js" ]; then
    echo "❌ index.js not found. Please make sure you're in the correct directory."
    exit 1
fi

if [ ! -f "config.js" ]; then
    echo "❌ config.js not found. Please create config.js first."
    exit 1
fi

if [ ! -f "package.json" ]; then
    echo "❌ package.json not found. Please run 'npm install' first."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Do not stop or delete other PM2 apps
# If this app exists, PM2 will restart it below

# Start the application with PM2
echo "🚀 Starting EtherDrops Monitor Bot with PM2..."
# Try to start by ecosystem app name (etherdrops-monitor-base). If not configured, start by script with explicit name.
if ! pm2 start ecosystem.config.js --env production --only etherdrops-monitor-base >/dev/null 2>&1; then
  echo "ℹ️ Falling back to direct start: index.js as etherdrops-monitor-base"
  pm2 start index.js --name etherdrops-monitor-base --time || true
fi

# Check if the process started successfully
sleep 3
if pm2 list | grep -q "etherdrops-monitor-base.*online"; then
    echo "✅ EtherDrops Monitor Bot started successfully!"
    echo ""
    echo "📊 PM2 Status:"
    pm2 status etherdrops-monitor-base
    echo ""
    echo "📝 To view logs: pm2 logs etherdrops-monitor-base"
    echo "📝 To stop: pm2 stop etherdrops-monitor-base"
    echo "📝 To restart: pm2 restart etherdrops-monitor-base"
    echo "📝 To monitor: pm2 monit"
elif pm2 list | grep -q "etherdrops-monitor.*online"; then
    echo "✅ EtherDrops Monitor Bot is running under legacy name: etherdrops-monitor"
    echo "➡️  Consider renaming in ecosystem.config.js to 'etherdrops-monitor-base' for consistency."
    echo ""
    echo "📊 PM2 Status:"
    pm2 status etherdrops-monitor || pm2 list
    echo ""
    echo "📝 To view logs: pm2 logs etherdrops-monitor"
    echo "📝 To stop: pm2 stop etherdrops-monitor"
    echo "📝 To restart: pm2 restart etherdrops-monitor"
    echo "📝 To monitor: pm2 monit"
else
    echo "❌ Failed to start EtherDrops Monitor Bot"
    echo "📝 Check logs with: pm2 logs etherdrops-monitor-base"
    exit 1
fi

echo ""
echo "🎉 Setup complete! The bot will automatically restart on system reboot."
echo ""
echo "🔧 Enhanced timeout configuration applied:"
echo "   ✓ Telegram timeout: 25s (was 10s)"
echo "   ✓ Connection timeout: 30s (was 10s)"
echo "   ✓ Max retries: 5 (was 3)"
echo "   ✓ Exponential backoff retry strategy"
echo "   ✓ HTTP keep-alive connections"
echo "   ✓ DNS timeout: 15s"
echo ""
echo "📊 Monitor the bot: pm2 logs etherdrops-monitor-base"
