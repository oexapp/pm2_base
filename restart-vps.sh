#!/bin/bash

# EtherDrops Monitor Bot - VPS Restart Script
# Enhanced version with improved timeout configuration

echo "🔄 Restarting EtherDrops Monitor Bot..."

# Check if PM2 is running
if ! command -v pm2 &> /dev/null; then
    echo "❌ PM2 is not installed. Please run ./start-vps.sh first."
    exit 1
fi

# Stop the current process
echo "🛑 Stopping current process..."
pm2 stop etherdrops-monitor 2>/dev/null || true
pm2 delete etherdrops-monitor 2>/dev/null || true

# Wait for clean shutdown
sleep 3

# Clear old logs
echo "🧹 Clearing old logs..."
pm2 flush 2>/dev/null || true

# Start with new configuration
echo "🚀 Starting with enhanced timeout configuration..."
pm2 start ecosystem.config.js

# Check if restart was successful
sleep 3
if pm2 list | grep -q "etherdrops-monitor.*online"; then
    echo "✅ Restart successful!"
    echo ""
    echo "🔧 Enhanced timeout configuration active:"
    echo "   ✓ Telegram timeout: 25s (was 10s)"
    echo "   ✓ Connection timeout: 30s (was 10s)"
    echo "   ✓ Max retries: 5 (was 3)"
    echo "   ✓ Exponential backoff retry strategy"
    echo "   ✓ HTTP keep-alive connections"
    echo "   ✓ DNS timeout: 15s"
    echo ""
    echo "📊 Current status:"
    pm2 list
    echo ""
    echo "📝 To view logs: pm2 logs etherdrops-monitor"
    echo "📝 To monitor: pm2 monit"
else
    echo "❌ Restart failed. Check logs:"
    pm2 logs etherdrops-monitor --lines 20
    exit 1
fi

# Save PM2 configuration
pm2 save

echo ""
echo "🎉 Restart completed successfully!"

