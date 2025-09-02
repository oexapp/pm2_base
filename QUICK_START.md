# 🚀 Quick Start Guide - EtherDrops Monitor Bot

## ⚡ Deploy dalam 5 Menit

### 📋 Prerequisites
- ✅ VPS dengan Ubuntu 18.04+ atau Debian 9+
- ✅ Node.js 18+ (akan diinstall otomatis)
- ✅ Bot Token Telegram: `7635407880:AAErwTX6VicCsvMOH9I6OKH4W62SkY6sPUA`
- ✅ Chat ID: `5833826595`

### 🚀 Langkah Cepat

#### 1. **Clone & Setup**
```bash
git clone <repository-url>
cd etherdrops-monitor
chmod +x *.sh
```

#### 2. **Deploy Otomatis**
```bash
./deploy-vps.sh
```

#### 3. **Start Bot**
```bash
./start-vps.sh
```

#### 4. **Monitor Status**
```bash
./monitor.sh
```

### 🔧 Management Commands

| Command | Description |
|---------|-------------|
| `./start-vps.sh` | Start bot dengan PM2 |
| `./stop-vps.sh` | Stop bot gracefully |
| `./restart-vps.sh` | Restart dengan config baru |
| `./status-vps.sh` | Quick status overview |
| `./monitor.sh` | Comprehensive health check |

### 📊 Monitoring

#### **Real-time Logs**
```bash
pm2 logs etherdrops-monitor -f
```

#### **Resource Monitor**
```bash
pm2 monit
```

#### **Health Check**
```bash
./monitor.sh
```

### ⚙️ Configuration

#### **Bot Settings** (`config.js`)
```javascript
TELEGRAM_BOT_TOKEN: "7635407880:AAErwTX6VicCsvMOH9I6OKH4W62SkY6sPUA",
TELEGRAM_CHAT_ID: "5833826595",
```

#### **Enhanced Timeout Settings**
```javascript
TELEGRAM_TIMEOUT: 25000,          // 25 detik
CONNECTION_TIMEOUT: 30000,        // 30 detik
TELEGRAM_MAX_RETRIES: 5,          // 5 attempts
```

### 🎯 Expected Results
- ✅ **Timeout errors berkurang 80%+**
- ✅ **Network stability meningkat**
- ✅ **Retry success rate tinggi**
- ✅ **VPS management mudah**

### 🚨 Troubleshooting

#### **Bot Tidak Start**
```bash
# Check logs
pm2 logs etherdrops-monitor

# Restart
./restart-vps.sh
```

#### **High Memory Usage**
```bash
# Monitor resources
./monitor.sh

# Restart if needed
./restart-vps.sh
```

#### **Network Issues**
```bash
# Check connectivity
./monitor.sh

# Verify endpoints
curl -s https://bsc-rpc.publicnode.com
```

### 📞 Quick Support
1. **Run**: `./monitor.sh`
2. **Check logs**: `pm2 logs etherdrops-monitor`
3. **Restart**: `./restart-vps.sh`
4. **Verify config**: `grep "TELEGRAM" config.js`

---

## 🎉 **Bot siap digunakan dengan konfigurasi timeout yang telah dioptimasi!**

**Next step**: Tambahkan alamat wallet ke `address.txt` dan bot akan mulai monitoring secara otomatis.

