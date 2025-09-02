#!/bin/bash

# EtherDrops Monitor Bot - Advanced VPS Health Monitoring Script

echo "🏥 EtherDrops Monitor Bot - Health Check"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo -e "${RED}❌ PM2 is not installed. Please run ./start-vps.sh first.${NC}"
    exit 1
fi

# Function to check bot status
check_bot_status() {
    echo -e "\n${BLUE}🔍 Bot Status Check:${NC}"
    if pm2 list | grep -q "etherdrops-monitor.*online"; then
        echo -e "${GREEN}✅ Bot is running${NC}"
        local uptime=$(pm2 show etherdrops-monitor | grep "uptime" | awk '{print $4}')
        local memory=$(pm2 show etherdrops-monitor | grep "memory" | awk '{print $4}')
        local cpu=$(pm2 show etherdrops-monitor | grep "cpu" | awk '{print $4}')
        local restarts=$(pm2 show etherdrops-monitor | grep "restarts" | awk '{print $4}')
        
        echo "   Uptime: $uptime"
        echo "   Memory: $memory"
        echo "   CPU: $cpu"
        echo "   Restarts: $restarts"
        
        # Check for excessive restarts
        if [ "$restarts" -gt 10 ]; then
            echo -e "${YELLOW}⚠️  High restart count detected${NC}"
        fi
    else
        echo -e "${RED}❌ Bot is not running${NC}"
        return 1
    fi
}

# Function to check system resources
check_system_resources() {
    echo -e "\n${BLUE}💻 System Resources:${NC}"
    
    # Memory check
    local mem_info=$(free -m | grep "Mem:")
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$((mem_used * 100 / mem_total))
    
    echo "Memory Usage: ${mem_used}MB / ${mem_total}MB (${mem_usage}%)"
    
    if [ $mem_usage -gt 80 ]; then
        echo -e "${YELLOW}⚠️  High memory usage detected${NC}"
    elif [ $mem_usage -gt 90 ]; then
        echo -e "${RED}🚨 Critical memory usage!${NC}"
    else
        echo -e "${GREEN}✅ Memory usage is normal${NC}"
    fi
    
    # Disk check
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "Disk Usage: ${disk_usage}%"
    
    if [ $disk_usage -gt 80 ]; then
        echo -e "${YELLOW}⚠️  High disk usage detected${NC}"
    elif [ $disk_usage -gt 90 ]; then
        echo -e "${RED}🚨 Critical disk usage!${NC}"
    else
        echo -e "${GREEN}✅ Disk usage is normal${NC}"
    fi
}

# Function to check network connectivity
check_network() {
    echo -e "\n${BLUE}🌐 Network Connectivity:${NC}"
    
    # Check BSC RPC
    if curl -s --max-time 10 "https://bsc-rpc.publicnode.com" > /dev/null; then
        echo -e "${GREEN}✅ BSC RPC: Connected${NC}"
    else
        echo -e "${RED}❌ BSC RPC: Connection failed${NC}"
    fi
    
    # Check Telegram API
    if curl -s --max-time 10 "https://api.telegram.org" > /dev/null; then
        echo -e "${GREEN}✅ Telegram API: Connected${NC}"
    else
        echo -e "${RED}❌ Telegram API: Connection failed${NC}"
    fi
}

# Function to check recent logs
check_logs() {
    echo -e "\n${BLUE}📝 Recent Log Analysis:${NC}"
    
    # Check for error patterns
    local error_count=$(pm2 logs etherdrops-monitor --lines 100 --nostream 2>/dev/null | grep -c "ERROR\|error\|Error" || echo "0")
    local timeout_count=$(pm2 logs etherdrops-monitor --lines 100 --nostream 2>/dev/null | grep -c "timeout" || echo "0")
    local telegram_errors=$(pm2 logs etherdrops-monitor --lines 100 --nostream 2>/dev/null | grep -c "Telegram error" || echo "0")
    
    echo "Errors in last 100 lines: $error_count"
    echo "Timeout errors: $timeout_count"
    echo "Telegram errors: $telegram_errors"
    
    if [ $error_count -gt 20 ]; then
        echo -e "${YELLOW}⚠️  High error rate detected${NC}"
    fi
    
    if [ $timeout_count -gt 5 ]; then
        echo -e "${YELLOW}⚠️  Multiple timeout errors detected${NC}"
    fi
}

# Function to show configuration summary
show_config_summary() {
    echo -e "\n${BLUE}⚙️  Configuration Summary:${NC}"
    echo "Enhanced timeout configuration:"
    echo "   ✓ Telegram timeout: 25s"
    echo "   ✓ Connection timeout: 30s"
    echo "   ✓ Max retries: 5"
    echo "   ✓ Exponential backoff retry strategy"
    echo "   ✓ HTTP keep-alive connections"
    echo "   ✓ DNS timeout: 15s"
}

# Main execution
main() {
    check_bot_status
    check_system_resources
    check_network
    check_logs
    show_config_summary
    
    echo -e "\n${BLUE}🔧 Management Commands:${NC}"
    echo "  Start:   ./start-vps.sh"
    echo "  Stop:    ./stop-vps.sh"
    echo "  Restart: ./restart-vps.sh"
    echo "  Status:  ./status-vps.sh"
    echo "  Logs:    pm2 logs etherdrops-monitor -f"
    echo "  Monitor: pm2 monit"
    
    echo -e "\n${GREEN}✅ Health check completed!${NC}"
}

# Run main function
main
