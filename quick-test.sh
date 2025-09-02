#!/bin/bash

# 🚀 Quick Network Test for EtherDrops Monitor Bot
# Simple and fast connectivity check

echo "🔍 Quick Network Test - EtherDrops Monitor Bot"
echo "=============================================="
echo ""

BOT_TOKEN="7635407880:AAErwTX6VicCsvMOH9I6OKH4W62SkY6sPUA"
CHAT_ID="5833826595"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🌐 Testing basic connectivity..."
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Internet: OK${NC}"
else
    echo -e "${RED}❌ Internet: FAILED${NC}"
    exit 1
fi

echo ""
echo "📡 Testing Telegram API endpoints..."

ENDPOINTS=(
    "https://api.telegram.org"
    "https://149.154.167.220"
    "https://149.154.175.50"
)

for endpoint in "${ENDPOINTS[@]}"; do
    echo -n "Testing $endpoint... "
    
    response=$(curl -s -w "%{http_code}" --connect-timeout 5 --max-time 15 \
        -H "User-Agent: EtherDrops-Monitor/1.0" \
        "$endpoint/bot$BOT_TOKEN/getMe" 2>/dev/null)
    
    http_code="${response: -3}"
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ OK${NC}"
        
        # Test message sending
        echo -n "  Sending test message... "
        msg_response=$(curl -s -w "%{http_code}" --connect-timeout 5 --max-time 20 \
            -H "User-Agent: EtherDrops-Monitor/1.0" \
            -H "Content-Type: application/json" \
            -d "{\"chat_id\":\"$CHAT_ID\",\"text\":\"🔍 Quick test message from EtherDrops Monitor Bot - $(date)\",\"parse_mode\":\"Markdown\"}" \
            "$endpoint/bot$BOT_TOKEN/sendMessage" 2>/dev/null)
        
        msg_http_code="${msg_response: -3}"
        if [ "$msg_http_code" = "200" ]; then
            echo -e "${GREEN}✅ Message sent!${NC}"
        else
            echo -e "${RED}❌ Message failed (HTTP $msg_http_code)${NC}"
        fi
        
        echo ""
        echo "🎉 This endpoint is working! The bot should use this one."
        exit 0
    else
        echo -e "${RED}❌ HTTP $http_code${NC}"
    fi
done

echo ""
echo -e "${RED}❌ All endpoints failed!${NC}"
echo ""
echo "🔧 Troubleshooting steps:"
echo "1. Check internet connection"
echo "2. Verify bot token: $BOT_TOKEN"
echo "3. Check chat ID: $CHAT_ID"
echo "4. Run full test: ./test-network.sh"
echo "5. Check firewall settings"
echo "6. Contact VPS provider about network restrictions"
