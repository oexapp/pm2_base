#!/bin/bash

# 🌐 Network Test Script for EtherDrops Monitor Bot
# Tests Telegram API endpoints, DNS resolution, and network connectivity

echo "🔍 EtherDrops Monitor Bot - Network Diagnostics"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BOT_TOKEN="7635407880:AAErwTX6VicCsvMOH9I6OKH4W62SkY6sPUA"
CHAT_ID="5833826595"

# Test endpoints
TELEGRAM_ENDPOINTS=(
    "https://api.telegram.org"
    "https://api.telegram.org:443"
    "https://149.154.167.220"
    "https://149.154.175.50"
    "https://149.154.167.91"
)

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Function to test basic connectivity
test_basic_connectivity() {
    echo "🌐 Testing Basic Network Connectivity..."
    echo "----------------------------------------"
    
    # Test internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_status "OK" "Internet connectivity: OK"
    else
        print_status "ERROR" "Internet connectivity: FAILED"
        return 1
    fi
    
    # Test DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        print_status "OK" "DNS resolution: OK"
    else
        print_status "ERROR" "DNS resolution: FAILED"
        return 1
    fi
    
    echo ""
}

# Function to test DNS resolution for Telegram
test_telegram_dns() {
    echo "🔍 Testing Telegram DNS Resolution..."
    echo "-------------------------------------"
    
    local domains=("api.telegram.org" "149.154.167.220" "149.154.175.50" "149.154.167.91")
    
    for domain in "${domains[@]}"; do
        if nslookup "$domain" >/dev/null 2>&1; then
            local ip=$(nslookup "$domain" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
            print_status "OK" "$domain -> $ip"
        else
            print_status "ERROR" "$domain -> DNS resolution failed"
        fi
    done
    
    echo ""
}

# Function to test Telegram API endpoints
test_telegram_endpoints() {
    echo "📡 Testing Telegram API Endpoints..."
    echo "------------------------------------"
    
    local success_count=0
    local total_count=${#TELEGRAM_ENDPOINTS[@]}
    
    for endpoint in "${TELEGRAM_ENDPOINTS[@]}"; do
        echo -n "Testing $endpoint... "
        
        # Test with curl
        local start_time=$(date +%s%N)
        local response=$(curl -s -w "%{http_code}" --connect-timeout 10 --max-time 25 \
            -H "User-Agent: EtherDrops-Monitor/1.0" \
            "$endpoint/bot$BOT_TOKEN/getMe" 2>/dev/null)
        local end_time=$(date +%s%N)
        
        local http_code="${response: -3}"
        local response_body="${response%???}"
        local duration=$(( (end_time - start_time) / 1000000 ))
        
        if [ "$http_code" = "200" ]; then
            print_status "OK" "OK (${duration}ms)"
            success_count=$((success_count + 1))
            
            # Parse bot info if available
            if echo "$response_body" | grep -q '"ok":true'; then
                local bot_name=$(echo "$response_body" | grep -o '"first_name":"[^"]*"' | cut -d'"' -f4)
                local bot_username=$(echo "$response_body" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
                echo "   🤖 Bot: $bot_name (@$bot_username)"
            fi
        else
            print_status "ERROR" "HTTP $http_code (${duration}ms)"
        fi
    done
    
    echo ""
    print_status "INFO" "Success rate: $success_count/$total_count endpoints"
    
    if [ $success_count -eq 0 ]; then
        print_status "ERROR" "All Telegram endpoints failed!"
        return 1
    elif [ $success_count -lt $total_count ]; then
        print_status "WARN" "Some endpoints failed, but others are working"
    else
        print_status "OK" "All endpoints working correctly"
    fi
    
    echo ""
}

# Function to test message sending
test_message_sending() {
    echo "📨 Testing Message Sending..."
    echo "-----------------------------"
    
    local test_message="🔍 Network test message from EtherDrops Monitor Bot\n⏰ Time: $(date)\n🌐 Endpoint: Network Test Script"
    
    # Try to send message using the first working endpoint
    for endpoint in "${TELEGRAM_ENDPOINTS[@]}"; do
        echo -n "Testing message send via $endpoint... "
        
        local response=$(curl -s -w "%{http_code}" --connect-timeout 10 --max-time 30 \
            -H "User-Agent: EtherDrops-Monitor/1.0" \
            -H "Content-Type: application/json" \
            -d "{\"chat_id\":\"$CHAT_ID\",\"text\":\"$test_message\",\"parse_mode\":\"Markdown\"}" \
            "$endpoint/bot$BOT_TOKEN/sendMessage" 2>/dev/null)
        
        local http_code="${response: -3}"
        local response_body="${response%???}"
        
        if [ "$http_code" = "200" ]; then
            print_status "OK" "Message sent successfully!"
            echo "   📝 Message ID: $(echo "$response_body" | grep -o '"message_id":[0-9]*' | cut -d':' -f2)"
            echo ""
            return 0
        else
            print_status "ERROR" "HTTP $http_code"
            if [ "$http_code" = "403" ]; then
                echo "   ⚠️  Bot may not have permission to send messages to this chat"
            elif [ "$http_code" = "400" ]; then
                echo "   ⚠️  Bad request - check bot token and chat ID"
            fi
        fi
    done
    
    print_status "ERROR" "Failed to send message via any endpoint"
    echo ""
    return 1
}

# Function to test network latency
test_network_latency() {
    echo "⏱️  Testing Network Latency..."
    echo "-------------------------------"
    
    local endpoints=("8.8.8.8" "1.1.1.1" "api.telegram.org")
    
    for endpoint in "${endpoints[@]}"; do
        echo -n "Pinging $endpoint... "
        
        if ping -c 3 "$endpoint" >/dev/null 2>&1; then
            local avg_ping=$(ping -c 3 "$endpoint" 2>/dev/null | grep "avg" | awk -F'/' '{print $5}')
            if [ -n "$avg_ping" ]; then
                print_status "OK" "Average: ${avg_ping}ms"
            else
                print_status "OK" "Response received"
            fi
        else
            print_status "ERROR" "No response"
        fi
    done
    
    echo ""
}

# Function to test specific ports
test_ports() {
    echo "🔌 Testing Common Ports..."
    echo "---------------------------"
    
    local ports=("80" "443" "53")
    local test_host="api.telegram.org"
    
    for port in "${ports[@]}"; do
        echo -n "Testing $test_host:$port... "
        
        if timeout 5 bash -c "</dev/tcp/$test_host/$port" 2>/dev/null; then
            print_status "OK" "Port $port is open"
        else
            print_status "ERROR" "Port $port is closed or blocked"
        fi
    done
    
    echo ""
}

# Function to check system resources
check_system_resources() {
    echo "💻 System Resources Check..."
    echo "----------------------------"
    
    # Check available memory
    local mem_available=$(free -m | awk 'NR==2{printf "%.1f", $7*100/$2}')
    if (( $(echo "$mem_available > 20" | bc -l) )); then
        print_status "OK" "Available memory: ${mem_available}%"
    else
        print_status "WARN" "Low available memory: ${mem_available}%"
    fi
    
    # Check disk space
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 90 ]; then
        print_status "OK" "Disk usage: ${disk_usage}%"
    else
        print_status "WARN" "High disk usage: ${disk_usage}%"
    fi
    
    # Check CPU load
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    if (( $(echo "$cpu_load < 2.0" | bc -l) )); then
        print_status "OK" "CPU load: $cpu_load"
    else
        print_status "WARN" "High CPU load: $cpu_load"
    fi
    
    echo ""
}

# Function to check firewall/iptables
check_firewall() {
    echo "🔥 Firewall Check..."
    echo "-------------------"
    
    if command -v iptables >/dev/null 2>&1; then
        local rules_count=$(iptables -L -n | wc -l)
        if [ "$rules_count" -gt 3 ]; then
            print_status "INFO" "iptables rules found: $rules_count"
            
            # Check for specific rules that might block outbound connections
            if iptables -L OUTPUT -n | grep -q "DROP"; then
                print_status "WARN" "Found DROP rules in OUTPUT chain"
            fi
        else
            print_status "INFO" "No custom iptables rules found"
        fi
    else
        print_status "INFO" "iptables not available"
    fi
    
    echo ""
}

# Function to provide recommendations
provide_recommendations() {
    echo "💡 Recommendations..."
    echo "-------------------"
    
    echo "1. If all endpoints fail:"
    echo "   • Check internet connectivity"
    echo "   • Verify DNS resolution"
    echo "   • Check firewall settings"
    echo "   • Contact VPS provider about network restrictions"
    echo ""
    
    echo "2. If some endpoints fail:"
    echo "   • The bot will automatically use working endpoints"
    echo "   • Consider updating config.js with working endpoints"
    echo "   • Monitor logs for endpoint rotation"
    echo ""
    
    echo "3. If message sending fails:"
    echo "   • Verify bot token is correct"
    echo "   • Check if bot has permission to send messages"
    echo "   • Ensure chat ID is correct"
    echo ""
    
    echo "4. Performance optimization:"
    echo "   • Use endpoints with lowest latency"
    echo "   • Consider using IP addresses instead of domain names"
    echo "   • Monitor system resources regularly"
    echo ""
}

# Main execution
main() {
    echo "🚀 Starting comprehensive network diagnostics..."
    echo "⏰ Started at: $(date)"
    echo ""
    
    # Run all tests
    test_basic_connectivity
    test_telegram_dns
    test_telegram_endpoints
    test_message_sending
    test_network_latency
    test_ports
    check_system_resources
    check_firewall
    
    echo "📊 Test Summary"
    echo "==============="
    echo "✅ Basic connectivity tests completed"
    echo "✅ Telegram API endpoint tests completed"
    echo "✅ Message sending test completed"
    echo "✅ System resource check completed"
    echo ""
    
    provide_recommendations
    
    echo "🎯 Next Steps:"
    echo "1. Review the test results above"
    echo "2. If issues found, check the recommendations"
    echo "3. Restart the bot: ./restart-vps.sh"
    echo "4. Monitor logs: pm2 logs etherdrops-monitor"
    echo ""
    
    echo "⏰ Completed at: $(date)"
    echo "🔍 Network diagnostics completed!"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Warning: Running as root. Some tests may not work correctly."
    echo ""
fi

# Check dependencies
if ! command -v curl >/dev/null 2>&1; then
    echo "❌ Error: curl is not installed. Please install it first:"
    echo "   Ubuntu/Debian: sudo apt-get install curl"
    echo "   CentOS/RHEL: sudo yum install curl"
    exit 1
fi

if ! command -v ping >/dev/null 2>&1; then
    echo "❌ Error: ping is not available. Some tests will be skipped."
fi

# Run main function
main "$@"
