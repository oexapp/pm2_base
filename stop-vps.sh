#!/bin/bash

# EtherDrops Monitor Bot - VPS Stop Script

echo "🛑 Stopping EtherDrops Monitor Bot..."

# Check if PM2 is running
if ! command -v pm2 &> /dev/null; then
    echo "❌ PM2 is not installed."
    exit 1
fi

# Stop the process
echo "🔄 Stopping etherdrops-monitor..."
pm2 stop etherdrops-monitor 2>/dev/null || true

# Check if process is stopped
if pm2 list | grep -q "etherdrops-monitor.*stopped"; then
    echo "✅ Bot stopped successfully!"
    echo ""
    echo "📊 Current PM2 status:"
    pm2 list
else
    echo "❌ Failed to stop the bot. Current status:"
    pm2 list
    exit 1
fi

echo ""
echo "📝 To start again: ./start-vps.sh"
echo "📝 To restart: ./restart-vps.sh"

