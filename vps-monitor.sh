#!/bin/bash

# EtherDrops Monitor Bot - VPS Monitoring Script
# For 4GB RAM VPS deployment

echo "🔍 EtherDrops Monitor Bot - VPS System Check"
echo "============================================"

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
print_info "System Resources Check"
echo "-------------------------"

# CPU Usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
if (( $(echo "$CPU_USAGE < 80" | bc -l) )); then
    print_status "CPU Usage: ${CPU_USAGE}%"
else
    print_warning "CPU Usage: ${CPU_USAGE}% (High)"
fi

# Memory Usage
MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
MEMORY_TOTAL=$(free -m | awk 'NR==2{print $2}')

if (( MEMORY_USED < 3500 )); then
    print_status "Memory Usage: ${MEMORY_USAGE} (${MEMORY_USED}MB/${MEMORY_TOTAL}MB)"
else
    print_warning "Memory Usage: ${MEMORY_USAGE} (${MEMORY_USED}MB/${MEMORY_TOTAL}MB) - High"
fi

# Disk Usage
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
DISK_AVAILABLE=$(df -h / | awk 'NR==2{print $4}')

if (( DISK_USAGE < 80 )); then
    print_status "Disk Usage: ${DISK_USAGE}% (${DISK_AVAILABLE} available)"
else
    print_warning "Disk Usage: ${DISK_USAGE}% (${DISK_AVAILABLE} available) - High"
fi

echo ""
print_info "Bot Status Check"
echo "------------------"

# Check if PM2 is installed
if command -v pm2 &> /dev/null; then
    print_status "PM2 is installed"
    
    # Check bot status
    if pm2 list | grep -q "etherdrops-monitor.*online"; then
        print_status "Bot is running (online)"
    elif pm2 list | grep -q "etherdrops-monitor.*stopped"; then
        print_error "Bot is stopped"
    elif pm2 list | grep -q "etherdrops-monitor.*error"; then
        print_error "Bot has errors"
    else
        print_error "Bot not found in PM2"
    fi
else
    print_error "PM2 not installed"
fi

echo ""
print_info "Network Connectivity"
echo "----------------------"

# Test BSC RPC
if curl -s --connect-timeout 5 "https://bsc-rpc.publicnode.com" > /dev/null; then
    print_status "BSC RPC: Accessible"
else
    print_error "BSC RPC: Not accessible"
fi

# Test Telegram API
if curl -s --connect-timeout 5 "https://api.telegram.org" > /dev/null; then
    print_status "Telegram API: Accessible"
else
    print_error "Telegram API: Not accessible"
fi

echo ""
print_info "Security Status"
echo "-----------------"

# Check UFW status
if ufw status | grep -q "Status: active"; then
    print_status "Firewall (UFW): Active"
else
    print_warning "Firewall (UFW): Inactive"
fi

# Check Fail2ban status
if systemctl is-active --quiet fail2ban; then
    print_status "Fail2ban: Active"
else
    print_warning "Fail2ban: Inactive"
fi

echo ""
print_info "Recent Logs (Last 5 lines)"
echo "------------------------------"

# Check bot logs
if [[ -f "/opt/etherdrops-monitor/logs/err.log" ]]; then
    echo "Error Log:"
    tail -5 /opt/etherdrops-monitor/logs/err.log 2>/dev/null || echo "No recent errors"
else
    print_warning "Error log not found"
fi

if [[ -f "/opt/etherdrops-monitor/logs/out.log" ]]; then
    echo ""
    echo "Output Log:"
    tail -5 /opt/etherdrops-monitor/logs/out.log 2>/dev/null || echo "No recent output"
else
    print_warning "Output log not found"
fi

echo ""
print_info "Quick Actions"
echo "---------------"

echo "1. View bot logs: pm2 logs etherdrops-monitor"
echo "2. Restart bot: pm2 restart etherdrops-monitor"
echo "3. Monitor resources: pm2 monit"
echo "4. Check system: htop"
echo "5. View disk usage: df -h"
echo "6. Check memory: free -h"

echo ""
print_info "Performance Recommendations"
echo "-------------------------------"

# Memory recommendations
if (( MEMORY_USED > 3500 )); then
    print_warning "High memory usage detected. Consider:"
    echo "  - Restart bot: pm2 restart etherdrops-monitor"
    echo "  - Check for memory leaks: pm2 monit"
    echo "  - Review log files for errors"
fi

# Disk recommendations
if (( DISK_USAGE > 80 )); then
    print_warning "High disk usage detected. Consider:"
    echo "  - Clean old logs: pm2 flush"
    echo "  - Remove old backups: ls -la /opt/backups/"
    echo "  - Check for large files: du -sh /opt/etherdrops-monitor/*"
fi

# CPU recommendations
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    print_warning "High CPU usage detected. Consider:"
    echo "  - Check running processes: htop"
    echo "  - Restart bot: pm2 restart etherdrops-monitor"
    echo "  - Monitor for unusual activity"
fi

echo ""
print_info "Maintenance Commands"
echo "----------------------"

echo "🔧 Bot Management:"
echo "  pm2 list                    # List all processes"
echo "  pm2 restart etherdrops-monitor  # Restart bot"
echo "  pm2 stop etherdrops-monitor     # Stop bot"
echo "  pm2 delete etherdrops-monitor   # Remove from PM2"
echo "  pm2 logs etherdrops-monitor --lines 50  # View recent logs"

echo ""
echo "📊 System Monitoring:"
echo "  htop                        # Interactive system monitor"
echo "  df -h                       # Disk usage"
echo "  free -h                     # Memory usage"
echo "  iostat                      # I/O statistics"

echo ""
echo "🛡️ Security:"
echo "  ufw status                  # Firewall status"
echo "  fail2ban-client status      # Fail2ban status"
echo "  last                        # Recent logins"

echo ""
echo "🧹 Maintenance:"
echo "  pm2 flush                   # Clear PM2 logs"
echo "  /opt/backup-bot.sh          # Manual backup"
echo "  logrotate -f /etc/logrotate.d/etherdrops-monitor  # Force log rotation"

echo ""
print_info "Emergency Commands"
echo "---------------------"

echo "🚨 If bot is not responding:"
echo "  pm2 restart etherdrops-monitor"
echo "  pm2 logs etherdrops-monitor --lines 100"
echo "  systemctl restart fail2ban"

echo ""
echo "🚨 If system is slow:"
echo "  htop"
echo "  free -h"
echo "  df -h"

echo ""
echo "🚨 If network issues:"
echo "  ping bsc-rpc.publicnode.com"
echo "  curl -s https://api.telegram.org"
echo "  nslookup api.telegram.org"

echo ""
print_info "Health Check Summary"
echo "----------------------"

# Overall health score
HEALTH_SCORE=100

if (( MEMORY_USED > 3500 )); then
    HEALTH_SCORE=$((HEALTH_SCORE - 20))
fi

if (( DISK_USAGE > 80 )); then
    HEALTH_SCORE=$((HEALTH_SCORE - 20))
fi

if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    HEALTH_SCORE=$((HEALTH_SCORE - 20))
fi

if ! pm2 list | grep -q "etherdrops-monitor.*online"; then
    HEALTH_SCORE=$((HEALTH_SCORE - 40))
fi

if [[ $HEALTH_SCORE -ge 80 ]]; then
    print_status "Overall Health: EXCELLENT (${HEALTH_SCORE}/100)"
elif [[ $HEALTH_SCORE -ge 60 ]]; then
    print_warning "Overall Health: GOOD (${HEALTH_SCORE}/100)"
elif [[ $HEALTH_SCORE -ge 40 ]]; then
    print_warning "Overall Health: FAIR (${HEALTH_SCORE}/100)"
else
    print_error "Overall Health: POOR (${HEALTH_SCORE}/100) - Action required!"
fi

echo ""
echo "✅ VPS monitoring check completed!"
echo "Run this script regularly to monitor your bot's health."
