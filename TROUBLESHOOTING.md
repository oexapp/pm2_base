# EtherDrops Monitor Bot - Troubleshooting Guide

## Common Issues and Solutions

### 1. BUFFER_OVERRUN Error
**Error:** `data out-of-bounds (buffer=0x, length=0, offset=32, code=BUFFER_OVERRUN)`

**Cause:** Invalid or corrupted blockchain data received from RPC endpoint.

**Solutions:**
- ✅ **Fixed in v2.0:** Enhanced data validation before parsing
- ✅ **Fixed in v2.0:** Multiple RPC endpoint fallback
- ✅ **Fixed in v2.0:** Better error handling for malformed logs

**Manual Fix:**
```bash
# Restart the bot to use fallback RPC endpoints
pm2 restart etherdrops-monitor
```

### 2. EAI_AGAIN DNS Resolution Error
**Error:** `getaddrinfo EAI_AGAIN api.telegram.org` or `getaddrinfo EAI_AGAIN bsc-rpc.publicnode.com`

**Cause:** DNS resolution failure or network connectivity issues.

**Solutions:**
- ✅ **Fixed in v2.0:** Retry mechanism with exponential backoff
- ✅ **Fixed in v2.0:** Multiple RPC endpoints for redundancy
- ✅ **Fixed in v2.0:** Connection timeout handling

**Manual Fix:**
```bash
# Check DNS resolution
nslookup api.telegram.org
nslookup bsc-rpc.publicnode.com

# If DNS issues persist, try using different DNS servers
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
```

### 3. Memory Leak After Long Running
**Symptoms:** High memory usage, slow performance after 15+ hours

**Solutions:**
- ✅ **Fixed in v2.0:** Automatic memory cleanup every 10 minutes
- ✅ **Fixed in v2.0:** Garbage collection enabled
- ✅ **Fixed in v2.0:** Pending transfer cleanup
- ✅ **Fixed in v2.0:** Memory threshold monitoring

**Manual Fix:**
```bash
# Check memory usage
pm2 monit

# Force restart if memory usage is high
pm2 restart etherdrops-monitor

# Clear PM2 logs to free space
pm2 flush
```

### 4. Connection Drops and Reconnection Issues
**Symptoms:** Bot stops monitoring, connection lost errors

**Solutions:**
- ✅ **Fixed in v2.0:** Automatic RPC endpoint switching
- ✅ **Fixed in v2.0:** Enhanced reconnection logic
- ✅ **Fixed in v2.0:** Connection health monitoring

**Manual Fix:**
```bash
# Check connection status
bash monitor.sh

# Restart with fresh connection
pm2 restart etherdrops-monitor
```

### 5. Telegram API Errors
**Error:** Failed to send messages to Telegram

**Solutions:**
- ✅ **Fixed in v2.0:** Retry mechanism for failed messages
- ✅ **Fixed in v2.0:** Timeout handling
- ✅ **Fixed in v2.0:** Better error logging

**Manual Fix:**
```bash
# Check Telegram bot token
# Verify bot token in config.js is correct
# Test bot manually: https://api.telegram.org/bot<YOUR_TOKEN>/getMe
```

## Quick Fix Commands

### Emergency Restart
```bash
# Stop all processes
pm2 stop all
pm2 delete all

# Clear logs
pm2 flush

# Restart with fresh setup
bash start-vps.sh
```

### Check Bot Status
```bash
# View real-time status
bash monitor.sh

# Check PM2 status
pm2 list

# View recent logs
pm2 logs etherdrops-monitor --lines 20
```

### Memory Issues
```bash
# Check memory usage
pm2 monit

# Force garbage collection (if available)
node -e "if (global.gc) global.gc(); console.log('GC triggered')"

# Restart if memory usage > 500MB
pm2 restart etherdrops-monitor
```

### Network Issues
```bash
# Test connectivity
curl -s https://bsc-rpc.publicnode.com
curl -s https://api.telegram.org

# Check DNS
nslookup bsc-rpc.publicnode.com
nslookup api.telegram.org
```

## Prevention Tips

### 1. Regular Maintenance
```bash
# Run weekly maintenance
pm2 flush                    # Clear old logs
pm2 restart etherdrops-monitor  # Fresh restart
```

### 2. Monitor System Resources
```bash
# Check system health
htop
df -h
free -h
```

### 3. Update Dependencies
```bash
# Update packages monthly
npm update
pm2 update
```

### 4. Backup Configuration
```bash
# Backup important files
cp config.js config.js.backup
cp address.txt address.txt.backup
```

## Log Analysis

### Error Patterns to Watch For:
- `BUFFER_OVERRUN`: Data corruption (handled in v2.0)
- `EAI_AGAIN`: DNS issues (handled in v2.0)
- `ECONNRESET`: Connection drops (handled in v2.0)
- `ETIMEDOUT`: Timeout issues (handled in v2.0)

### Healthy Log Indicators:
- `✅ Connected to BSC WebSocket`
- `📊 Transfers Processed: X`
- `🔗 Connection Status: ✅ Connected`
- `🧹 Memory cleanup: removed X old pending transfers`

## Support

If issues persist after trying these solutions:

1. **Check logs:** `pm2 logs etherdrops-monitor --lines 100`
2. **Run diagnostics:** `bash monitor.sh`
3. **Restart fresh:** `bash start-vps.sh`
4. **Check system resources:** `htop`, `df -h`, `free -h`

## Version History

### v2.0 (Current) - Enhanced Stability
- ✅ Multiple RPC endpoint fallback
- ✅ Enhanced error handling for BUFFER_OVERRUN
- ✅ Retry mechanism for network errors
- ✅ Automatic memory cleanup
- ✅ Garbage collection enabled
- ✅ Better connection monitoring
- ✅ Improved logging and diagnostics

### v1.0 (Previous)
- Basic functionality
- Single RPC endpoint
- Limited error handling
- Memory leak issues
- Connection stability problems
