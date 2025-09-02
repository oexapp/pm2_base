#!/bin/bash

# EtherDrops Monitor Bot - Network Fix Script
# This script diagnoses and fixes network connectivity issues

echo "🌐 EtherDrops Monitor Bot - Network Diagnostics & Fix"
echo "===================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo ""
print_info "Network Connectivity Test"
echo "----------------------------"

# Test DNS resolution
echo "Testing DNS resolution..."
if nslookup bsc-rpc.publicnode.com > /dev/null 2>&1; then
    print_status "DNS resolution: Working"
else
    print_error "DNS resolution: Failed"
fi

if nslookup api.telegram.org > /dev/null 2>&1; then
    print_status "Telegram DNS: Working"
else
    print_error "Telegram DNS: Failed"
fi

echo ""
print_info "Testing RPC Endpoints"
echo "-------------------------"

# Test multiple RPC endpoints
RPC_ENDPOINTS=(
    "https://bsc-rpc.publicnode.com"
    "https://bsc.publicnode.com"
    "https://bsc-ws-node.nariox.org"
)

for endpoint in "${RPC_ENDPOINTS[@]}"; do
    echo "Testing: $endpoint"
    if curl -s --connect-timeout 10 "$endpoint" > /dev/null; then
        print_status "✅ $endpoint - Accessible"
    else
        print_warning "⚠️ $endpoint - Not accessible"
    fi
done

echo ""
print_info "Testing WebSocket Connections"
echo "---------------------------------"

# Test WebSocket endpoints
WS_ENDPOINTS=(
    "wss://bsc-rpc.publicnode.com"
    "wss://bsc.publicnode.com"
    "wss://bsc-ws-node.nariox.org:443"
)

for ws_endpoint in "${WS_ENDPOINTS[@]}"; do
    echo "Testing WebSocket: $ws_endpoint"
    # Use wscat if available, otherwise use curl for HTTP upgrade
    if command -v wscat &> /dev/null; then
        timeout 10 wscat -c "$ws_endpoint" -x '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_status "✅ $ws_endpoint - WebSocket working"
        else
            print_warning "⚠️ $ws_endpoint - WebSocket failed"
        fi
    else
        # Fallback to HTTP test
        http_endpoint=$(echo "$ws_endpoint" | sed 's/wss:/https:/')
        if curl -s --connect-timeout 10 "$http_endpoint" > /dev/null; then
            print_status "✅ $ws_endpoint - HTTP accessible (WebSocket untested)"
        else
            print_warning "⚠️ $ws_endpoint - Not accessible"
        fi
    fi
done

echo ""
print_info "Testing Telegram API"
echo "-----------------------"

if curl -s --connect-timeout 10 "https://api.telegram.org" > /dev/null; then
    print_status "Telegram API: Accessible"
else
    print_error "Telegram API: Not accessible"
fi

echo ""
print_info "Network Configuration Check"
echo "-------------------------------"

# Check firewall status
if ufw status | grep -q "Status: active"; then
    print_status "Firewall: Active"
else
    print_warning "Firewall: Inactive"
fi

# Check DNS configuration
echo "Current DNS servers:"
cat /etc/resolv.conf | grep nameserver || print_warning "No DNS servers configured"

# Check network interfaces
echo "Network interfaces:"
ip addr show | grep -E "inet.*global" || print_warning "No global IP addresses found"

echo ""
print_info "Potential Fixes"
echo "------------------"

# Check if we need to add better DNS servers
if ! grep -q "8.8.8.8\|1.1.1.1" /etc/resolv.conf; then
    print_warning "Consider adding Google DNS or Cloudflare DNS for better connectivity"
    echo "Add to /etc/resolv.conf:"
    echo "nameserver 8.8.8.8"
    echo "nameserver 1.1.1.1"
fi

# Check if we need to restart networking
if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    print_error "Basic internet connectivity failed"
    echo "Try: systemctl restart networking"
fi

echo ""
print_info "Recommended Actions"
echo "----------------------"

echo "1. If DNS issues detected:"
echo "   echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"
echo "   echo 'nameserver 1.1.1.1' >> /etc/resolv.conf"

echo ""
echo "2. If firewall blocking:"
echo "   ufw allow out 443"
echo "   ufw allow out 80"

echo ""
echo "3. If network interface issues:"
echo "   systemctl restart networking"

echo ""
echo "4. Restart bot after fixes:"
echo "   pm2 restart etherdrops-monitor"

echo ""
print_info "Current Bot Status"
echo "-------------------"

if pm2 list | grep -q "etherdrops-monitor.*online"; then
    print_status "Bot is running"
    pm2 list | grep etherdrops-monitor
else
    print_warning "Bot is not running"
fi

echo ""
echo "📝 Recent network-related logs:"
pm2 logs etherdrops-monitor --lines 10 | grep -i "network\|error\|connection" || echo "No network-related logs found"

echo ""
echo "✅ Network diagnostics completed!"
echo "Run this script again after applying fixes to verify connectivity."
