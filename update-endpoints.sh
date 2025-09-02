#!/bin/bash

# 🔧 Update Telegram Endpoints Script
# Automatically updates config.js with working endpoints

echo "🔧 EtherDrops Monitor Bot - Endpoint Updater"
echo "============================================"
echo ""

BOT_TOKEN="7635407880:AAErwTX6VicCsvMOH9I6OKH4W62SkY6sPUA"
CHAT_ID="5833826595"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# All possible endpoints to test
ALL_ENDPOINTS=(
    "https://api.telegram.org"
    "https://api.telegram.org:443"
    "https://149.154.167.220"
    "https://149.154.175.50"
    "https://149.154.167.91"
    "https://149.154.167.220:443"
    "https://149.154.175.50:443"
    "https://149.154.167.91:443"
)

# Function to test endpoint
test_endpoint() {
    local endpoint=$1
    local response=$(curl -s -w "%{http_code}" --connect-timeout 5 --max-time 15 \
        -H "User-Agent: EtherDrops-Monitor/1.0" \
        "$endpoint/bot$BOT_TOKEN/getMe" 2>/dev/null)
    
    local http_code="${response: -3}"
    if [ "$http_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Function to measure endpoint latency
measure_latency() {
    local endpoint=$1
    local start_time=$(date +%s%N)
    
    curl -s --connect-timeout 5 --max-time 15 \
        -H "User-Agent: EtherDrops-Monitor/1.0" \
        "$endpoint/bot$BOT_TOKEN/getMe" >/dev/null 2>&1
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    echo $duration
}

echo "🔍 Testing all Telegram endpoints..."
echo ""

# Test all endpoints and collect working ones
working_endpoints=()
endpoint_latencies=()

for endpoint in "${ALL_ENDPOINTS[@]}"; do
    echo -n "Testing $endpoint... "
    
    if test_endpoint "$endpoint"; then
        echo -e "${GREEN}✅ OK${NC}"
        working_endpoints+=("$endpoint")
        
        # Measure latency
        latency=$(measure_latency "$endpoint")
        endpoint_latencies+=("$endpoint:$latency")
        echo "   ⏱️  Latency: ${latency}ms"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
done

echo ""
echo "📊 Test Results:"
echo "================="
echo "Total endpoints tested: ${#ALL_ENDPOINTS[@]}"
echo "Working endpoints: ${#working_endpoints[@]}"
echo ""

if [ ${#working_endpoints[@]} -eq 0 ]; then
    echo -e "${RED}❌ No working endpoints found!${NC}"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "1. Check internet connectivity"
    echo "2. Verify bot token is correct"
    echo "3. Check firewall settings"
    echo "4. Contact VPS provider about network restrictions"
    exit 1
fi

# Sort endpoints by latency (fastest first)
IFS=$'\n' sorted_endpoints=($(sort -t: -k2 -n <<<"${endpoint_latencies[*]}"))
unset IFS

echo "🏆 Working endpoints (sorted by latency):"
for i in "${!sorted_endpoints[@]}"; do
    local endpoint_info="${sorted_endpoints[$i]}"
    local endpoint="${endpoint_info%:*}"
    local latency="${endpoint_info##*:}"
    echo "   $((i+1)). $endpoint (${latency}ms)"
done

echo ""
echo "🔧 Updating config.js with working endpoints..."

# Create backup
if [ -f "config.js" ]; then
    cp config.js "config.js.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backup created: config.js.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Extract working endpoints (without latency info)
working_endpoints_clean=()
for endpoint_info in "${sorted_endpoints[@]}"; do
    working_endpoints_clean+=("${endpoint_info%:*}")
done

# Create new config content
cat > config.js << EOF
// Configuration file for EtherDrops Monitor Bot

module.exports = {
  // BSC RPC WebSocket endpoints (multiple for fallback)
  BSC_RPC_WSS: "wss://bsc-rpc.publicnode.com",
  
  // Multiple RPC endpoints for fallback
  RPC_ENDPOINTS: [
    "wss://bsc-rpc.publicnode.com",
    "wss://bsc-ws-node.nariox.org:443",
    "wss://bsc.publicnode.com",
    "wss://go.getblock.asia/da6d74ba19684edaac1ec20b3b6c6afb"
  ],
  
  // Telegram Bot Configuration
  TELEGRAM_BOT_TOKEN: "7635407880:AAErwTX6VicCsvMOH9I6OKH4W62SkY6sPUA",
  TELEGRAM_CHAT_ID: "5833826595",
  
  // PancakeSwap Router for price calculation
  PANCAKE_ROUTER: "0x10ED43C718714eb63d5aA57B78B54704E256024E",
  
  // Token addresses for price calculation
  BUSD: "0xe9e7cea3dedca5984780bafc599bd69add087d56",
  USDT: "0x55d398326f99059fF775485246999027B3197955",
  WBNB: "0xBB4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
  
  // Wallet name mapping (add your wallet names here)
  WALLET_NAMES: {
    "0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef": "HELLO ALMI",
    // Add more wallet names here as needed
    // "0x4C26F7Fdc32e91f469bFc54e1711E71CE3ea0f1C": "Another Wallet",
  },
  
  // Processing delay in milliseconds (to collect multiple transfers in same transaction)
  PROCESSING_DELAY: 2000,
  
  // Address file path
  ADDRESS_FILE: "address.txt",
  
  // Telegram command checking interval (milliseconds)
  TELEGRAM_CHECK_INTERVAL: 5000,
  
  // VPS Optimization Settings
  // Enable auto-restart on critical errors
  AUTO_RESTART: true,
  
  // Memory threshold for auto-restart (MB)
  MEMORY_THRESHOLD: 500,
  
  // Max consecutive errors before restart
  MAX_CONSECUTIVE_ERRORS: 50,
  
  // Connection timeout settings (milliseconds)
  CONNECTION_TIMEOUT: 30000, // Increased to 30 seconds for better reliability
  TELEGRAM_TIMEOUT: 25000, // Specific timeout for Telegram API calls
  PRICE_CALCULATION_TIMEOUT: 5000,
  
  // Retry settings
  MAX_RECONNECT_ATTEMPTS: 10,
  RECONNECT_DELAY: 5000,
  TELEGRAM_MAX_RETRIES: 5, // Increased retries for Telegram
  TELEGRAM_BASE_DELAY: 2000, // Base delay between retries
  
  // Watchdog settings for VPS stability
  WATCHDOG_RECONNECT_THRESHOLD: 20, // Max reconnects before restart
  WATCHDOG_TIME_WINDOW: 30 * 60 * 1000, // 30 minutes
  MIN_CONNECTION_UPTIME: 5 * 60 * 1000, // 5 minutes minimum uptime
  ENDPOINT_ROTATION_COOLDOWN: 2 * 60 * 1000, // 2 minutes between rotations
  
  // WSS failure handling
  WSS_FAILURE_THRESHOLD: 3,
  WSS_DISABLE_DURATION: 10 * 60 * 1000, // 10 minutes
  
  // Memory cleanup settings
  MEMORY_CLEANUP_INTERVAL: 10 * 60 * 1000, // 10 minutes
  PENDING_TRANSFER_TIMEOUT: 5 * 60 * 1000, // 5 minutes
  
  // Network resilience settings
  TELEGRAM_KEEPALIVE: true, // Keep HTTP connections alive
  TELEGRAM_MAX_SOCKETS: 10, // Maximum concurrent sockets
  HTTP_TIMEOUT: 30000, // General HTTP timeout
  DNS_TIMEOUT: 15000, // DNS resolution timeout
  
  // Telegram API endpoints with fallback (Updated by endpoint updater)
  TELEGRAM_API_ENDPOINTS: [
$(printf '    "%s",\n' "${working_endpoints_clean[@]}" | sed '$s/,$//')
  ],
  
  // Advanced timeout settings
  TELEGRAM_CONNECT_TIMEOUT: 10000, // Connection timeout (10s)
  TELEGRAM_SOCKET_TIMEOUT: 60000,  // Socket timeout (60s)
  TELEGRAM_PROXY_TIMEOUT: 15000,   // Proxy timeout (15s)
};
EOF

echo "✅ config.js updated with ${#working_endpoints_clean[@]} working endpoints"
echo ""

# Show the new configuration
echo "📋 New Telegram endpoints configuration:"
for endpoint in "${working_endpoints_clean[@]}"; do
    echo "   • $endpoint"
done

echo ""
echo "🔄 Next steps:"
echo "1. Restart the bot: ./restart-vps.sh"
echo "2. Monitor logs: pm2 logs etherdrops-monitor"
echo "3. Test connectivity: ./quick-test.sh"
echo ""

echo "🎉 Endpoint update completed successfully!"
echo "   The bot will now use the fastest working endpoints automatically."
