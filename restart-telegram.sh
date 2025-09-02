#!/bin/bash
# Script to restart the EtherDrops Monitor with improved Telegram settings

echo "🔄 Restarting EtherDrops Monitor with improved Telegram connectivity..."

# Kill existing process if running
pkill -f "node index.js" || true
pkill -f "etherdrops-monitor" || true

# Wait a moment for clean shutdown
sleep 2

echo "🚀 Starting EtherDrops Monitor with enhanced timeout settings..."

# Start with PM2 if available, otherwise use node directly
if command -v pm2 &> /dev/null; then
    pm2 restart ecosystem.config.js --update-env || pm2 start ecosystem.config.js
    echo "✅ Started with PM2"
    pm2 logs etherdrops-monitor --lines 20
else
    # Start with node directly in background
    nohup node index.js > monitor.log 2>&1 &
    echo "✅ Started with Node.js (PID: $!)"
    echo "📄 Logs available in monitor.log"
    echo "🔍 To monitor logs: tail -f monitor.log"
fi

echo ""
echo "🔧 Applied fixes:"
echo "   ✓ Increased Telegram timeout from 10s to 25s"
echo "   ✓ Added exponential backoff retry strategy"
echo "   ✓ Improved error handling for different timeout scenarios"
echo "   ✓ Enhanced HTTP connection management with keepalive"
echo "   ✓ Increased max retries from 3 to 5"
echo ""
echo "📊 Monitor the logs for improved connection stability!"
