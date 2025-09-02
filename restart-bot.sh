#!/bin/bash

# EtherDrops Monitor Bot - Clean Restart Script
# This script restarts the bot with clean state to fix network issues

echo "🔄 EtherDrops Monitor Bot - Clean Restart"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

print_step "1. Stopping current bot process..."
pm2 stop etherdrops-monitor 2>/dev/null || true
pm2 delete etherdrops-monitor 2>/dev/null || true

print_step "2. Clearing PM2 logs..."
pm2 flush 2>/dev/null || true

print_step "3. Waiting for processes to stop..."
sleep 5

print_step "4. Checking for any remaining Node.js processes..."
pkill -f "node.*index.js" 2>/dev/null || true
sleep 2

print_step "5. Testing network connectivity..."
# Test BSC RPC connectivity
if curl -s --connect-timeout 10 "https://bsc-rpc.publicnode.com" > /dev/null; then
    print_status "BSC RPC: Accessible"
else
    print_warning "BSC RPC: Not accessible - will retry with fallback endpoints"
fi

# Test Telegram API
if curl -s --connect-timeout 10 "https://api.telegram.org" > /dev/null; then
    print_status "Telegram API: Accessible"
else
    print_warning "Telegram API: Not accessible"
fi

print_step "6. Starting bot with clean state..."
cd /opt/etherdrops-monitor

# Start with PM2
pm2 start ecosystem.config.js

# Wait for startup
sleep 10

print_step "7. Checking bot status..."
if pm2 list | grep -q "etherdrops-monitor.*online"; then
    print_status "✅ Bot started successfully!"
else
    print_warning "⚠️ Bot may not be running properly"
    print_status "Checking logs..."
    pm2 logs etherdrops-monitor --lines 10
fi

print_step "8. Saving PM2 configuration..."
pm2 save

echo ""
echo "🎉 Clean restart completed!"
echo "========================"
echo ""
echo "📊 Bot Status:"
pm2 list | grep etherdrops-monitor || echo "Bot not found in PM2"

echo ""
echo "📝 Recent Logs:"
pm2 logs etherdrops-monitor --lines 5

echo ""
echo "🔧 Useful Commands:"
echo "pm2 logs etherdrops-monitor    # View logs"
echo "pm2 monit                      # Monitor resources"
echo "pm2 restart etherdrops-monitor # Restart bot"
echo "pm2 stop etherdrops-monitor    # Stop bot"

echo ""
echo "✅ Clean restart process completed!"
