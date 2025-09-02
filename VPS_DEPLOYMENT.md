# 🚀 VPS Deployment Guide - EtherDrops Monitor Bot

## 📋 Overview

This guide will help you deploy the EtherDrops Monitor Bot on a VPS for 24/7 operation with auto-restart, health monitoring, and robust error handling.

## 🎯 Features for VPS Operation

- ✅ **Auto-reconnect** to BSC WebSocket on connection loss
- ✅ **Health monitoring** every 30 minutes
- ✅ **Memory monitoring** with auto-restart on threshold
- ✅ **Error tracking** with auto-restart on consecutive failures
- ✅ **Graceful shutdown** handling
- ✅ **PM2 process management** for production deployment
- ✅ **Log rotation** and monitoring
- ✅ **Uncaught exception** handling

## 🖥️ VPS Requirements

### Minimum Specifications:
- **CPU**: 1 vCPU
- **RAM**: 1GB (2GB recommended)
- **Storage**: 20GB SSD
- **OS**: Ubuntu 20.04+ / CentOS 7+ / Windows Server 2019+
- **Network**: Stable internet connection

### Recommended Specifications:
- **CPU**: 2 vCPU
- **RAM**: 4GB
- **Storage**: 50GB SSD
- **OS**: Ubuntu 22.04 LTS
- **Network**: High-speed, low-latency connection

## 🚀 Quick Start (Linux/Mac)

### 1. **Clone Repository**
```bash
git clone https://github.com/username/etherdrops-monitor.git
cd etherdrops-monitor
```

### 2. **Configure Bot**
```bash
cp config.example.js config.js
nano config.js  # Edit with your settings
```

### 3. **Run VPS Startup Script**
```bash
chmod +x start-vps.sh
./start-vps.sh
```

## 🚀 Quick Start (Windows)

### 1. **Clone Repository**
```cmd
git clone https://github.com/username/etherdrops-monitor.git
cd etherdrops-monitor
```

### 2. **Configure Bot**
```cmd
copy config.example.js config.js
notepad config.js  # Edit with your settings
```

### 3. **Run VPS Startup Script**
```cmd
start-vps.bat
```

## ⚙️ Manual Setup

### 1. **Install Dependencies**
```bash
npm install
npm install -g pm2
```

### 2. **Create Logs Directory**
```bash
mkdir logs
```

### 3. **Start with PM2**
```bash
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

## 🔧 PM2 Management Commands

### **Basic Commands:**
```bash
pm2 status                    # Check bot status
pm2 logs etherdrops-monitor  # View real-time logs
pm2 restart etherdrops-monitor # Restart bot
pm2 stop etherdrops-monitor   # Stop bot
pm2 delete etherdrops-monitor # Remove from PM2
```

### **Monitoring Commands:**
```bash
pm2 monit                     # Monitor CPU/Memory usage
pm2 dashboard                 # Web dashboard (http://localhost:9615)
pm2 show etherdrops-monitor  # Detailed process info
```

### **Log Management:**
```bash
pm2 flush                     # Clear all logs
pm2 reloadLogs                # Reload log files
pm2 install pm2-logrotate     # Install log rotation
```

## 📊 Health Monitoring

### **Automatic Health Checks:**
- **Interval**: Every 30 minutes
- **Metrics**: Uptime, connection status, transfers, errors, memory usage
- **Actions**: Auto-restart on memory threshold or consecutive errors

### **Health Check Output:**
```
============================================================
🏥 HEALTH CHECK - 27/08/2025 14:30:45
⏰ Uptime: 2h 15m 30s
🔗 Connection Status: ✅ Connected
📊 Transfers Processed: 156
❌ Errors: 3 (Consecutive: 0)
💾 Memory Usage: 45MB / 67MB
📝 Watchlist Size: 2980
============================================================
```

## 🔄 Auto-Restart Features

### **Memory Threshold Restart:**
- **Default**: 500MB
- **Configurable**: Edit `config.MEMORY_THRESHOLD` in `config.js`
- **Cooldown**: 5 minutes between restarts

### **Error-Based Restart:**
- **Default**: 50 consecutive errors
- **Configurable**: Edit `config.MAX_CONSECUTIVE_ERRORS` in `config.js`
- **Cooldown**: 5 minutes between restarts

### **Connection Loss Restart:**
- **Automatic**: On WebSocket disconnection
- **Retry Logic**: Exponential backoff (5s, 10s, 15s...)
- **Max Attempts**: 10 reconnection attempts

## 📝 Log Management

### **Log Files:**
- **Error Logs**: `./logs/err.log`
- **Output Logs**: `./logs/out.log`
- **Combined Logs**: `./logs/combined.log`

### **Log Rotation:**
```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
```

### **View Logs:**
```bash
# Real-time logs
pm2 logs etherdrops-monitor --lines 100

# Error logs only
pm2 logs etherdrops-monitor --err --lines 50

# Specific log file
tail -f logs/err.log
```

## 🚨 Troubleshooting

### **Common Issues:**

#### 1. **Bot Not Starting**
```bash
# Check PM2 status
pm2 status

# View error logs
pm2 logs etherdrops-monitor --err

# Check config file
node -c index.js
```

#### 2. **High Memory Usage**
```bash
# Check memory usage
pm2 monit

# Restart bot
pm2 restart etherdrops-monitor

# Check for memory leaks
pm2 show etherdrops-monitor
```

#### 3. **Connection Issues**
```bash
# Check network connectivity
ping bsc-rpc.publicnode.com

# Test WebSocket connection
node -e "const { WebSocket } = require('ws'); const ws = new WebSocket('wss://bsc-rpc.publicnode.com'); ws.on('open', () => console.log('Connected')); ws.on('error', console.error);"
```

#### 4. **PM2 Issues**
```bash
# Reset PM2
pm2 kill
pm2 start ecosystem.config.js --env production

# Clear PM2 logs
pm2 flush
```

## 🔒 Security Considerations

### **Firewall Setup:**
```bash
# Ubuntu/Debian
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP (if needed)
sudo ufw allow 443   # HTTPS (if needed)
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

### **User Permissions:**
```bash
# Create dedicated user
sudo adduser etherdrops
sudo usermod -aG sudo etherdrops

# Set proper file permissions
sudo chown -R etherdrops:etherdrops /path/to/bot
chmod 600 config.js
```

## 📈 Performance Optimization

### **Node.js Optimization:**
```bash
# Add to ecosystem.config.js
node_args: '--max-old-space-size=512 --optimize-for-size'
```

### **System Optimization:**
```bash
# Increase file descriptor limit
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize TCP settings
echo "net.core.somaxconn = 65536" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## 🔄 Update & Maintenance

### **Update Bot:**
```bash
# Pull latest changes
git pull origin main

# Install new dependencies
npm install

# Restart bot
pm2 restart etherdrops-monitor
```

### **Update PM2:**
```bash
npm update -g pm2
pm2 update
```

### **System Updates:**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

## 📊 Monitoring & Alerts

### **PM2 Dashboard:**
- **URL**: http://your-vps-ip:9615
- **Features**: Real-time monitoring, logs, process management

### **External Monitoring:**
- **Uptime Robot**: Monitor bot availability
- **Grafana**: Advanced metrics visualization
- **Prometheus**: Metrics collection

### **Alert Setup:**
```bash
# Email alerts on restart
pm2 set pm2-logrotate:email your-email@domain.com

# Slack/Discord webhooks can be added to config.js
```

## 💡 Best Practices

1. **Regular Backups**: Backup `address.txt` and `config.js` regularly
2. **Monitor Logs**: Check logs daily for errors or issues
3. **Update Regularly**: Keep bot and dependencies updated
4. **Resource Monitoring**: Monitor CPU, memory, and network usage
5. **Security Updates**: Keep VPS OS and packages updated
6. **Test Changes**: Test configuration changes in development first

## 🆘 Support

### **Logs to Check:**
- `pm2 logs etherdrops-monitor --err`
- `./logs/err.log`
- `./logs/out.log`

### **Common Commands:**
```bash
# Full restart
pm2 delete etherdrops-monitor && pm2 start ecosystem.config.js

# Check system resources
htop
df -h
free -h

# Check network
netstat -tulpn
ss -tulpn
```

### **Emergency Stop:**
```bash
pm2 stop etherdrops-monitor
pm2 delete etherdrops-monitor
```

---

**🎉 Your EtherDrops Monitor Bot is now ready for 24/7 VPS operation!**
