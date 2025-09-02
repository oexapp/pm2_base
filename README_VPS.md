# EtherDrops Monitor Bot - VPS Deployment Guide

## 🚀 Enhanced VPS Deployment dengan Perbaikan Telegram Timeout

### 📋 Overview
Guide ini menjelaskan deployment EtherDrops Monitor Bot di VPS dengan konfigurasi timeout yang telah dioptimasi untuk mengatasi masalah Telegram timeout yang sering terjadi.

### 🔧 Perbaikan yang Telah Diterapkan

#### 1. **Enhanced Timeout Configuration**
```javascript
// config.js
CONNECTION_TIMEOUT: 30000,        // 30 detik (dari 10s)
TELEGRAM_TIMEOUT: 25000,          // 25 detik (dari 10s)
TELEGRAM_MAX_RETRIES: 5,          // 5 attempts (dari 3)
TELEGRAM_BASE_DELAY: 2000,        // Base delay 2s
```

#### 2. **Network Resilience Settings**
```javascript
TELEGRAM_KEEPALIVE: true,         // HTTP keep-alive
TELEGRAM_MAX_SOCKETS: 10,         // Max concurrent sockets
HTTP_TIMEOUT: 30000,              // General HTTP timeout
DNS_TIMEOUT: 15000,               // DNS resolution timeout
```

#### 3. **Smart Retry Strategy**
- **Exponential Backoff**: Delay meningkat secara exponential
- **Error-Specific Handling**: Delay berbeda per jenis error
- **Maximum Delay Cap**: 30 detik maksimum

### 🚀 Quick Start

#### Step 1: Clone & Setup
```bash
git clone <repository-url>
cd etherdrops-monitor
chmod +x *.sh
```

#### Step 2: Configure Bot
```bash
# Edit config.js dengan bot token dan chat ID baru
nano config.js

# Bot Token: 7635407880:AAErwTX6VicCsvMOH9I6OKH4W62SkY6sPUA
# Chat ID: 5833826595
```

#### Step 3: Deploy
```bash
# Deploy otomatis dengan semua konfigurasi
./deploy-vps.sh

# Atau deploy manual
./start-vps.sh
```

### 📁 Script Management

#### **Start Script** (`start-vps.sh`)
```bash
./start-vps.sh
```
- ✅ Instalasi PM2 otomatis
- ✅ Dependency check
- ✅ Memory threshold monitoring
- ✅ Auto-restart configuration

#### **Stop Script** (`stop-vps.sh`)
```bash
./stop-vps.sh
```
- 🛑 Graceful shutdown
- 📊 Status verification
- 🔄 Clean process termination

#### **Restart Script** (`restart-vps.sh`)
```bash
./restart-vps.sh
```
- 🔄 Clean restart dengan konfigurasi baru
- 🧹 Log cleanup
- ⚙️ Enhanced timeout activation

#### **Status Script** (`status-vps.sh`)
```bash
./status-vps.sh
```
- 📊 PM2 status
- 📝 Recent logs
- 💻 System resources
- 🔍 Process information

#### **Health Monitor** (`monitor.sh`)
```bash
./monitor.sh
```
- 🏥 Comprehensive health check
- 🌐 Network connectivity test
- 📊 Error pattern analysis
- ⚠️ Resource usage warnings

### 🔍 Monitoring & Troubleshooting

#### **Real-time Monitoring**
```bash
# View logs
pm2 logs etherdrops-monitor -f

# Monitor resources
pm2 monit

# Check status
pm2 status
```

#### **Health Check**
```bash
# Comprehensive health check
./monitor.sh

# Quick status
./status-vps.sh
```

### 📊 Expected Performance Improvements

#### **Before (Original)**
- ❌ Timeout: 10 detik
- ❌ Max retries: 3
- ❌ No exponential backoff
- ❌ Basic error handling
- ❌ Frequent timeout failures

#### **After (Enhanced)**
- ✅ Timeout: 25-30 detik
- ✅ Max retries: 5
- ✅ Exponential backoff retry
- ✅ Smart error handling
- ✅ Network resilience
- ✅ HTTP keep-alive
- ✅ DNS optimization

### 🚨 Troubleshooting

#### **Common Issues & Solutions**

1. **Bot Not Starting**
```bash
# Check logs
pm2 logs etherdrops-monitor

# Restart with enhanced config
./restart-vps.sh
```

2. **High Memory Usage**
```bash
# Monitor resources
./monitor.sh

# Restart if needed
./restart-vps.sh
```

3. **Network Issues**
```bash
# Check connectivity
./monitor.sh

# Verify RPC endpoints
curl -s https://bsc-rpc.publicnode.com
```

4. **Telegram Errors**
```bash
# Check bot token
grep "TELEGRAM_BOT_TOKEN" config.js

# Verify chat ID
grep "TELEGRAM_CHAT_ID" config.js
```

### 🔧 Advanced Configuration

#### **PM2 Ecosystem** (`ecosystem.config.js`)
```javascript
max_start_time: '60s',        // Startup stability
kill_timeout: 10000,          // Graceful shutdown
listen_timeout: 30000,        // Network stability
max_memory_restart: '500M',   // Memory threshold
```

#### **Auto-restart Features**
- 🚨 Watchdog restart on excessive reconnects
- 💾 Memory threshold restart (500MB)
- 🔄 Endpoint rotation on failures
- 🌐 WSS fallback to HTTPS

### 📈 Performance Metrics

#### **Monitoring Commands**
```bash
# System resources
htop
free -h
df -h

# Process monitoring
pm2 monit
pm2 show etherdrops-monitor

# Log analysis
pm2 logs etherdrops-monitor --lines 100 | grep -c "error"
```

### 🎯 Best Practices

1. **Regular Maintenance**
   - Run `./monitor.sh` daily
   - Check logs weekly
   - Restart monthly for fresh start

2. **Resource Management**
   - Monitor memory usage
   - Check disk space
   - Watch restart count

3. **Network Stability**
   - Use multiple RPC endpoints
   - Monitor connection health
   - Check DNS resolution

### 🔄 Update & Maintenance

#### **Update Bot**
```bash
# Pull latest changes
git pull origin main

# Restart with new config
./restart-vps.sh
```

#### **Configuration Changes**
```bash
# Edit config
nano config.js

# Restart to apply
./restart-vps.sh
```

### 📞 Support

Jika mengalami masalah:
1. Jalankan `./monitor.sh` untuk diagnosis
2. Check logs dengan `pm2 logs etherdrops-monitor`
3. Restart dengan `./restart-vps.sh`
4. Verify configuration di `config.js`

---

**🎉 Dengan konfigurasi yang telah dioptimasi, bot seharusnya berjalan lebih stabil dan timeout errors berkurang drastis!**

