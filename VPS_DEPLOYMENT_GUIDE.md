# EtherDrops Monitor Bot - Enhanced VPS Deployment Guide

## 🚀 Enhanced Stability Features

This version includes advanced stability features specifically designed for VPS environments that experience frequent disconnections:

### 🔧 Key Improvements

1. **Enhanced Watchdog System**
   - Monitors reconnect attempts within a time window
   - Auto-restarts when excessive reconnects are detected
   - Configurable thresholds for different VPS environments

2. **Improved WSS/HTTPS Fallback**
   - Smart endpoint selection based on health and latency
   - Automatic WSS disable after repeated failures
   - Preferential HTTPS usage for better stability

3. **Advanced Connection Management**
   - Endpoint rotation with cooldown periods
   - Failure tracking per endpoint
   - Connection uptime monitoring

4. **Memory and Resource Management**
   - Automatic memory cleanup
   - Memory threshold monitoring
   - Graceful restart mechanisms

## 📊 Watchdog Configuration

The watchdog system monitors connection stability and automatically restarts the bot when:

```javascript
// Watchdog settings in config.js
WATCHDOG_RECONNECT_THRESHOLD: 20,        // Max reconnects before restart
WATCHDOG_TIME_WINDOW: 30 * 60 * 1000,    // 30 minutes window
MIN_CONNECTION_UPTIME: 5 * 60 * 1000,    // 5 minutes minimum uptime
ENDPOINT_ROTATION_COOLDOWN: 2 * 60 * 1000, // 2 minutes between rotations
```

### Watchdog Triggers

1. **Excessive Reconnects**: If 20+ reconnects occur within 30 minutes
2. **No Stable Connection**: If no successful connection for 30+ minutes
3. **Memory Threshold**: If memory usage exceeds 500MB
4. **Consecutive Errors**: If 50+ consecutive errors occur

## 🔄 Auto-Restart Mechanisms

### 1. PM2 Process Manager
```bash
# Start with PM2
pm2 start ecosystem.config.js --env production

# Monitor status
pm2 status
pm2 logs etherdrops-monitor

# Restart if needed
pm2 restart etherdrops-monitor
```

### 2. Systemd Service
```bash
# Enable and start service
systemctl enable etherdrops-monitor
systemctl start etherdrops-monitor

# Check status
systemctl status etherdrops-monitor
journalctl -u etherdrops-monitor -f
```

## 📈 Enhanced Monitoring

### Health Check Output
The bot now provides detailed connection statistics:

```
🏥 HEALTH CHECK - 2024-01-15 10:30:00
⏰ Uptime: 2h 15m 30s
🔗 Connection Status: ✅ Connected
📊 Transfers Processed: 1250
❌ Errors: 5 (Consecutive: 0)
💾 Memory Usage: 245MB / 512MB
📝 Watchlist Size: 15

🔄 Connection Stats:
   Total Reconnects: 3
   Watchdog Reconnects: 0/20
   WSS Failures: 1
   HTTPS Fallbacks: 2
   Connection Uptime: 1350s
   Last Successful: 1350s ago

🔗 Current Endpoint: https://bsc-dataseed.bnbchain.org (HTTPS)
   Health: ✅
   Latency: 245ms
   Failures: 0
```

## 🛠️ Deployment Options

### Option 1: Automated Deployment Script
```bash
# Run the deployment script
chmod +x deploy-vps.sh
./deploy-vps.sh
```

### Option 2: Manual PM2 Setup
```bash
# Install dependencies
npm install

# Start with PM2
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

### Option 3: Systemd Service
```bash
# Copy service file
sudo cp etherdrops-monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable etherdrops-monitor
sudo systemctl start etherdrops-monitor
```

## 🔧 Management Commands

### Quick Management Scripts
```bash
./start-vps.sh    # Start the bot
./stop-vps.sh     # Stop the bot
./restart-vps.sh  # Restart the bot
./status-vps.sh   # Check status and logs
```

### PM2 Commands
```bash
pm2 status                    # Check all processes
pm2 logs etherdrops-monitor   # View real-time logs
pm2 monit                     # Monitor resources
pm2 restart etherdrops-monitor # Restart bot
pm2 delete etherdrops-monitor  # Remove from PM2
```

### Systemd Commands
```bash
systemctl status etherdrops-monitor    # Check service status
systemctl restart etherdrops-monitor   # Restart service
systemctl stop etherdrops-monitor      # Stop service
journalctl -u etherdrops-monitor -f    # Follow logs
```

## 📋 Configuration

### Essential Settings
```javascript
// config.js
module.exports = {
  // Telegram settings
  TELEGRAM_BOT_TOKEN: "YOUR_BOT_TOKEN",
  TELEGRAM_CHAT_ID: "YOUR_CHAT_ID",
  
  // VPS stability settings
  AUTO_RESTART: true,
  MEMORY_THRESHOLD: 500,
  WATCHDOG_RECONNECT_THRESHOLD: 20,
  WATCHDOG_TIME_WINDOW: 30 * 60 * 1000,
  
  // Connection settings
  MAX_RECONNECT_ATTEMPTS: 10,
  RECONNECT_DELAY: 5000,
  WSS_FAILURE_THRESHOLD: 3,
  WSS_DISABLE_DURATION: 10 * 60 * 1000,
};
```

### Address Management
```bash
# Add addresses to monitor
echo "0x1234567890123456789012345678901234567890" >> address.txt
echo "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd" >> address.txt
```

## 🔍 Troubleshooting

### Common Issues

1. **Frequent Reconnects**
   - Check network stability
   - Adjust `WATCHDOG_RECONNECT_THRESHOLD`
   - Monitor endpoint health

2. **High Memory Usage**
   - Increase `MEMORY_THRESHOLD`
   - Check for memory leaks
   - Restart bot manually

3. **Connection Failures**
   - Verify RPC endpoints
   - Check firewall settings
   - Monitor VPS resources

### Log Analysis
```bash
# View recent logs
pm2 logs etherdrops-monitor --lines 50

# Monitor real-time
pm2 logs etherdrops-monitor -f

# Check error patterns
grep "ERROR\|WARN" logs/combined.log
```

## 🚨 Emergency Procedures

### Force Restart
```bash
# PM2
pm2 delete etherdrops-monitor
pm2 start ecosystem.config.js

# Systemd
systemctl restart etherdrops-monitor

# Manual
pkill -f "node index.js"
node index.js
```

### Reset Watchdog
```bash
# Restart PM2
pm2 restart etherdrops-monitor

# Or restart systemd service
systemctl restart etherdrops-monitor
```

## 📊 Performance Optimization

### For Low-RAM VPS (1-2GB)
```javascript
// Reduce memory usage
MEMORY_THRESHOLD: 300,
MAX_CONSECUTIVE_ERRORS: 30,
WATCHDOG_RECONNECT_THRESHOLD: 15,
```

### For High-RAM VPS (4GB+)
```javascript
// Increase thresholds
MEMORY_THRESHOLD: 1000,
MAX_CONSECUTIVE_ERRORS: 100,
WATCHDOG_RECONNECT_THRESHOLD: 30,
```

## ✅ Success Indicators

Your bot is running optimally when you see:

- ✅ Connection Status: Connected
- ✅ Watchdog Reconnects: 0/20
- ✅ Memory Usage: < 50% of threshold
- ✅ No consecutive errors
- ✅ Regular transfer notifications

## 🔄 Maintenance

### Daily Checks
- Monitor health check output
- Check memory usage
- Verify connection stability

### Weekly Tasks
- Review logs for patterns
- Update dependencies
- Backup configuration

### Monthly Tasks
- Analyze performance metrics
- Update RPC endpoints
- Review watchdog settings

---

**Note**: This enhanced version is specifically designed for VPS environments with unstable connections. The watchdog system ensures your bot stays operational even during network issues.
