# 🌐 Network Scripts Documentation - EtherDrops Monitor Bot

## 📋 Overview

Dokumen ini menjelaskan semua script network testing dan diagnostic yang telah dibuat untuk mengatasi masalah Telegram timeout pada EtherDrops Monitor Bot.

## 🚀 Scripts Available

### 1. **`run-all-tests.sh`** - Complete Test Suite
**Description**: Script utama yang menjalankan semua test secara berurutan dan memberikan solusi komprehensif.

**Usage**:
```bash
./run-all-tests.sh
```

**What it does**:
- ✅ Quick connectivity test
- ✅ Full network diagnostics
- ✅ Endpoint optimization
- ✅ Automatic configuration update
- ✅ Comprehensive solution guide

**Best for**: First-time setup atau troubleshooting lengkap

---

### 2. **`quick-test.sh`** - Fast Connectivity Check
**Description**: Test cepat untuk konektivitas dasar dan Telegram API.

**Usage**:
```bash
./quick-test.sh
```

**What it tests**:
- 🌐 Internet connectivity
- 📡 Telegram API endpoints (3 utama)
- 📨 Message sending capability
- ⚡ Fast results (under 1 minute)

**Best for**: Quick check sebelum restart bot atau daily monitoring

---

### 3. **`test-network.sh`** - Comprehensive Diagnostics
**Description**: Test lengkap untuk semua aspek network dan sistem.

**Usage**:
```bash
./test-network.sh
```

**What it tests**:
- 🌐 Basic network connectivity
- 🔍 DNS resolution for Telegram
- 📡 All Telegram API endpoints (8 endpoints)
- 📨 Message sending via all endpoints
- ⏱️ Network latency measurements
- 🔌 Port availability (80, 443, 53)
- 💻 System resources (memory, disk, CPU)
- 🔥 Firewall/iptables check
- 💡 Detailed recommendations

**Best for**: Deep troubleshooting dan performance analysis

---

### 4. **`update-endpoints.sh`** - Automatic Endpoint Optimization
**Description**: Otomatis menemukan dan mengkonfigurasi endpoint Telegram tercepat.

**Usage**:
```bash
./update-endpoints.sh
```

**What it does**:
- 🔍 Tests all possible endpoints (8 variants)
- ⏱️ Measures latency for each endpoint
- 🏆 Sorts by performance (fastest first)
- 🔧 Updates config.js automatically
- 💾 Creates backup before changes
- 📋 Shows new configuration

**Best for**: Optimizing performance dan fixing endpoint issues

---

### 5. **`restart-vps.sh`** - Bot Restart with New Config
**Description**: Restart bot dengan konfigurasi baru yang telah dioptimasi.

**Usage**:
```bash
./restart-vps.sh
```

**What it does**:
- 🛑 Stops bot process
- 🧹 Cleans up logs
- 🚀 Starts bot with new configuration
- 📊 Shows enhanced timeout configuration

**Best for**: Applying new configurations setelah update endpoints

---

### 6. **`monitor.sh`** - Health Monitoring
**Description**: Monitoring kesehatan bot dan sistem secara real-time.

**Usage**:
```bash
./monitor.sh
```

**What it monitors**:
- 🤖 Bot process status
- 💻 System resources
- 🌐 Network connectivity
- 📊 Error patterns
- ⚠️ Resource warnings

**Best for**: Ongoing monitoring dan early warning detection

---

## 🔧 How to Use

### **Step-by-Step Solution for Telegram Timeout**

#### **Option 1: Complete Automated Solution**
```bash
# 1. Run complete test suite
./run-all-tests.sh

# 2. Script will automatically:
#    - Test all endpoints
#    - Update configuration
#    - Provide restart instructions
```

#### **Option 2: Manual Step-by-Step**
```bash
# 1. Quick test first
./quick-test.sh

# 2. If issues found, run full diagnostics
./test-network.sh

# 3. Update endpoints automatically
./update-endpoints.sh

# 4. Restart bot with new config
./restart-vps.sh

# 5. Monitor results
./monitor.sh
```

#### **Option 3: Individual Testing**
```bash
# Test specific aspects as needed
./quick-test.sh          # Quick connectivity
./test-network.sh        # Full diagnostics
./update-endpoints.sh    # Endpoint optimization
```

---

## 📊 Expected Results

### **Before Fixes (Original)**
- ❌ Timeout: 10 detik
- ❌ Max retries: 3
- ❌ Single endpoint
- ❌ Basic error handling
- ❌ Frequent timeout failures

### **After Fixes (Enhanced)**
- ✅ Timeout: 25-30 detik
- ✅ Max retries: 5
- ✅ Multiple endpoints with fallback
- ✅ Exponential backoff retry
- ✅ Smart error handling
- ✅ Network resilience
- ✅ HTTP keep-alive
- ✅ DNS optimization

---

## 🎯 Troubleshooting Guide

### **Common Issues & Solutions**

#### **1. All Endpoints Fail**
**Symptoms**: `❌ All endpoints failed!`
**Solutions**:
- Check internet connectivity
- Verify bot token is correct
- Check firewall settings
- Contact VPS provider about network restrictions

#### **2. Some Endpoints Work**
**Symptoms**: `⚠️ Some endpoints failed, but others are working`
**Solutions**:
- Bot will automatically use working endpoints
- Monitor logs for endpoint rotation
- Consider updating config.js with working endpoints

#### **3. Message Sending Fails**
**Symptoms**: `❌ Message failed (HTTP 403/400)`
**Solutions**:
- Verify bot token is correct
- Check if bot has permission to send messages
- Ensure chat ID is correct

#### **4. High Latency**
**Symptoms**: `Latency: 5000ms+`
**Solutions**:
- Use endpoints with lowest latency
- Consider using IP addresses instead of domain names
- Check network quality to Telegram servers

---

## 🔍 Monitoring & Maintenance

### **Daily Monitoring**
```bash
# Quick health check
./quick-test.sh

# Full system status
./status-vps.sh
```

### **Weekly Maintenance**
```bash
# Comprehensive health check
./monitor.sh

# Full network diagnostics
./test-network.sh
```

### **Monthly Optimization**
```bash
# Update endpoints for best performance
./update-endpoints.sh

# Restart bot for fresh start
./restart-vps.sh
```

---

## 📈 Performance Metrics

### **Success Rate Targets**
- **Endpoint Success Rate**: >90%
- **Message Delivery Rate**: >95%
- **Timeout Error Reduction**: >80%
- **Connection Stability**: >95%

### **Latency Targets**
- **Optimal**: <1000ms
- **Good**: 1000-3000ms
- **Acceptable**: 3000-5000ms
- **Poor**: >5000ms

---

## 🚨 Emergency Procedures

### **Bot Not Responding**
```bash
# 1. Check status
./status-vps.sh

# 2. Quick connectivity test
./quick-test.sh

# 3. If network issues, update endpoints
./update-endpoints.sh

# 4. Restart bot
./restart-vps.sh
```

### **High Error Rate**
```bash
# 1. Check logs
pm2 logs etherdrops-monitor

# 2. Run diagnostics
./test-network.sh

# 3. Monitor resources
./monitor.sh

# 4. Restart if needed
./restart-vps.sh
```

---

## 💡 Best Practices

### **1. Regular Testing**
- Run `./quick-test.sh` daily
- Run `./test-network.sh` weekly
- Run `./update-endpoints.sh` monthly

### **2. Monitoring**
- Use `./monitor.sh` for ongoing health checks
- Check logs regularly with `pm2 logs`
- Monitor system resources

### **3. Maintenance**
- Keep scripts updated
- Backup configurations before major changes
- Document any custom modifications

---

## 🔧 Technical Details

### **Script Dependencies**
- `curl` - HTTP requests and testing
- `ping` - Network connectivity testing
- `nslookup` - DNS resolution testing
- `bash` - Script execution
- `pm2` - Process management

### **Configuration Files**
- `config.js` - Main bot configuration
- `ecosystem.config.js` - PM2 process configuration
- Backup files created automatically

### **Network Protocols**
- HTTPS (port 443) - Primary Telegram API
- HTTP (port 80) - Fallback testing
- DNS (port 53) - Resolution testing

---

## 📞 Support & Troubleshooting

### **If Scripts Don't Work**
1. Check file permissions: `chmod +x *.sh`
2. Verify dependencies: `which curl ping nslookup`
3. Check bash version: `bash --version`
4. Run with verbose output: `bash -x script_name.sh`

### **Getting Help**
1. Check script output for error messages
2. Review logs: `pm2 logs etherdrops-monitor`
3. Run individual tests to isolate issues
4. Check system resources and network status

---

## 🎉 Conclusion

Script-script ini memberikan solusi komprehensif untuk masalah Telegram timeout:

- **Quick testing** untuk daily monitoring
- **Comprehensive diagnostics** untuk troubleshooting
- **Automatic optimization** untuk performance
- **Ongoing monitoring** untuk stability
- **Easy maintenance** untuk long-term operation

Dengan menggunakan script-script ini secara teratur, bot Telegram Anda akan berjalan lebih stabil, reliable, dan performant.

**🚀 Happy monitoring!**
