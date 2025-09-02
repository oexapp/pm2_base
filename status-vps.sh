#!/bin/bash

# EtherDrops Monitor Bot - VPS Status Script

echo "📊 EtherDrops Monitor Bot Status"
echo "================================="

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo "❌ PM2 is not installed. Please run ./start-vps.sh first."
    exit 1
fi

# Show PM2 status
echo ""
echo "🔍 PM2 Status:"
pm2 list

# Show recent logs
echo ""
echo "📝 Recent Logs (last 20 lines):"
pm2 logs etherdrops-monitor --lines 20 --nostream

# Show system resources
echo ""
echo "💻 System Resources:"
echo "Memory Usage:"
free -h | grep -E "Mem|Swap"
echo ""
echo "Disk Usage:"
df -h | grep -E "Filesystem|/dev/"

# Show process info
echo ""
echo "📊 Process Information:"
if pm2 list | grep -q "etherdrops-monitor.*online"; then
    echo "✅ Bot is running"
    pm2 show etherdrops-monitor | grep -E "status|uptime|memory|cpu|restarts"
else
    echo "❌ Bot is not running"
fi

echo ""
echo "🔧 Management Commands:"
echo "  Start:   ./start-vps.sh"
echo "  Stop:    ./stop-vps.sh"
echo "  Restart: ./restart-vps.sh"
echo "  Logs:    pm2 logs etherdrops-monitor -f"
echo "  Monitor: pm2 monit"

