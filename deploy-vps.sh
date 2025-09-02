#!/bin/bash

# EtherDrops Monitor Bot - VPS Deployment Script
# Enhanced version with watchdog and stability features

set -e

echo "🚀 EtherDrops Monitor Bot - VPS Deployment Script"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_warning "This script is running as root"
else
   print_error "This script must be run as root"
   exit 1
fi

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install Node.js and npm
print_status "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install PM2 globally
print_status "Installing PM2 process manager..."
npm install -g pm2

# Create application directory and PM2 app name
APP_DIR="/root/etherdrops-monitor-base"
PM2_APP_NAME="etherdrops-monitor-base"
print_status "Setting up application directory: $APP_DIR"
mkdir -p $APP_DIR
cd $APP_DIR

# Create logs directory
mkdir -p logs

# Copy application files (assuming they're in current directory)
print_status "Copying application files..."
cp -r . $APP_DIR/ 2>/dev/null || print_warning "No files to copy (running from target directory)"

# Install dependencies
print_status "Installing Node.js dependencies..."
npm install

# Create logs directory if it doesn't exist
mkdir -p logs

# Set proper permissions
chmod +x *.sh
chown -R root:root $APP_DIR

# Create PM2 ecosystem file if it doesn't exist
if [ ! -f "ecosystem.config.js" ]; then
    print_status "Creating PM2 ecosystem configuration..."
    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'etherdrops-monitor-base',
    script: 'index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    ignore_watch: ['node_modules', 'logs', 'address.txt'],
    restart_delay: 5000,
    max_restarts: 10,
    min_uptime: '10s',
    max_start_time: '30s',
    kill_timeout: 5000,
    listen_timeout: 8000,
    shutdown_with_message: true,
    autorestart: true,
    max_memory_restart: '500M',
    node_args: '--max-old-space-size=512',
    env_production: {
      NODE_ENV: 'production'
    }
  }]
};
EOF
fi

# Create systemd service file
print_status "Creating systemd service file..."
cat > /etc/systemd/system/etherdrops-monitor-base.service << 'EOF'
[Unit]
Description=EtherDrops Monitor Bot (Base)
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/etherdrops-monitor-base
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=etherdrops-monitor-base

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

# Environment variables
Environment=NODE_ENV=production
Environment=NODE_OPTIONS=--max-old-space-size=512

# Restart policy
StartLimitInterval=60
StartLimitBurst=3

# Kill timeout
TimeoutStopSec=30
KillMode=mixed
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Create management scripts
print_status "Creating management scripts..."

# Start script
cat > start-vps.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting EtherDrops Monitor Bot..."
cd /root/etherdrops-monitor-base

# Check if config exists
if [ ! -f "config.js" ]; then
    echo "❌ config.js not found! Please create it first."
    exit 1
fi

# Show versions (informative only)
if command -v node >/dev/null 2>&1; then
  echo "✅ Node.js version: $(node -v)"
fi
if command -v pm2 >/dev/null 2>&1; then
  echo "✅ PM2 version: $(pm2 -v)"
fi

# Install deps (safe to run repeatedly)
echo "📦 Installing dependencies..."
npm install --silent || npm install

# Start only this app with PM2 (do not touch other processes)
pm2 start ecosystem.config.js --env production --only etherdrops-monitor-base || pm2 restart etherdrops-monitor-base

echo "✅ Bot started with PM2"
echo "📊 Check status: pm2 status etherdrops-monitor-base"
echo "📋 View logs: pm2 logs etherdrops-monitor-base"
EOF

# Stop script
cat > stop-vps.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping EtherDrops Monitor Bot..."
pm2 stop etherdrops-monitor-base
pm2 delete etherdrops-monitor-base
echo "✅ Bot stopped"
EOF

# Restart script
cat > restart-vps.sh << 'EOF'
#!/bin/bash
echo "🔄 Restarting EtherDrops Monitor Bot..."
pm2 restart etherdrops-monitor-base
echo "✅ Bot restarted"
EOF

# Status script
cat > status-vps.sh << 'EOF'
#!/bin/bash
echo "📊 EtherDrops Monitor Bot Status"
echo "================================"
pm2 status etherdrops-monitor-base
echo ""
echo "📋 Recent logs:"
pm2 logs etherdrops-monitor-base --lines 20
EOF

# Make scripts executable
chmod +x start-vps.sh stop-vps.sh restart-vps.sh status-vps.sh

# Create address.txt if it doesn't exist
if [ ! -f "address.txt" ]; then
    print_status "Creating empty address.txt file..."
    touch address.txt
    echo "# Add wallet addresses to monitor (one per line)" > address.txt
    echo "# Example: 0x1234567890123456789012345678901234567890" >> address.txt
fi

# Check if config.js exists
if [ ! -f "config.js" ]; then
    print_warning "config.js not found!"
    print_status "Creating example config file..."
    cat > config.example.js << 'EOF'
// Configuration file for EtherDrops Monitor Bot (Base Mainnet)

module.exports = {
  // BASE RPC WebSocket endpoint (primary)
  BSC_RPC_WSS: "wss://base-rpc.publicnode.com",
  
  // Multiple RPC endpoints for fallback (BASE) - ordered by reliability preference
  RPC_ENDPOINTS: [
    // WSS first (subscriptions)
    "wss://base.gateway.tenderly.co",
    "wss://base-rpc.publicnode.com",
    // HTTPS preferred
    "https://base.public.blockpi.network/v1/rpc/public",
    "https://gateway.tenderly.co/public/base",
    "https://base.gateway.tenderly.co",
    "https://base.drpc.org",
    "https://mainnet.base.org",
    "https://developer-access-mainnet.base.org",
    "https://base-rpc.publicnode.com",
    "https://endpoints.omniatech.io/v1/base/mainnet/public",
    "https://api.zan.top/base-mainnet",
    "https://base.llamarpc.com",
    "https://base-mainnet.public.blastapi.io",
    "https://base-public.nodies.app",
    "https://base.lava.build",
    "https://rpc.owlracle.info/base/70d38ce1826c4a60bb2a8e05a6c8b20f"
  ],
  
  // Telegram Bot Configuration
  TELEGRAM_BOT_TOKEN: "7635407880:AAErwTX6VicCsvMOH9I6OKH4W62SkY6sPUA",
  TELEGRAM_CHAT_ID: "5833826595",
  
  // Uniswap V2 Router on Base for price calculation
  PANCAKE_ROUTER: "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24",
  
  // Token addresses for price calculation (Base Mainnet)
  // Use USDC as quote token on Base
  BUSD: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC
  USDT: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC
  WBNB: "0x4200000000000000000000000000000000000006", // WETH on Base
  
  // Wallet name mapping (add your wallet names here)
  WALLET_NAMES: {
    "0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef": "HELLO ALMI",
  },
  
  // Processing delay in milliseconds (to collect multiple transfers in same transaction)
  PROCESSING_DELAY: 2000,
  
  // Address file path
  ADDRESS_FILE: "address.txt",
  
  // Telegram command checking interval (milliseconds)
  TELEGRAM_CHECK_INTERVAL: 5000,
  
  // VPS Optimization Settings
  AUTO_RESTART: true,
  MEMORY_THRESHOLD: 500,
  MAX_CONSECUTIVE_ERRORS: 50,
  
  // Connection timeout settings (milliseconds)
  CONNECTION_TIMEOUT: 30000,
  TELEGRAM_TIMEOUT: 25000,
  PRICE_CALCULATION_TIMEOUT: 5000,
  
  // Retry settings
  MAX_RECONNECT_ATTEMPTS: 10,
  RECONNECT_DELAY: 5000,
  TELEGRAM_MAX_RETRIES: 5,
  TELEGRAM_BASE_DELAY: 2000,
  
  // Watchdog settings for VPS stability
  WATCHDOG_RECONNECT_THRESHOLD: 20,
  WATCHDOG_TIME_WINDOW: 30 * 60 * 1000,
  MIN_CONNECTION_UPTIME: 5 * 60 * 1000,
  ENDPOINT_ROTATION_COOLDOWN: 2 * 60 * 1000,
  
  // WSS failure handling
  WSS_FAILURE_THRESHOLD: 3,
  WSS_DISABLE_DURATION: 10 * 60 * 1000,
  
  // Memory cleanup settings
  MEMORY_CLEANUP_INTERVAL: 10 * 60 * 1000,
  PENDING_TRANSFER_TIMEOUT: 5 * 60 * 1000,
  
  // Network resilience settings
  TELEGRAM_KEEPALIVE: true,
  TELEGRAM_MAX_SOCKETS: 10,
  HTTP_TIMEOUT: 30000,
  DNS_TIMEOUT: 15000,
  
  // Telegram API endpoints with fallback
  TELEGRAM_API_ENDPOINTS: [
    "https://api.telegram.org",
    "https://api.telegram.org:443",
    "https://149.154.167.220",
    "https://149.154.175.50",
    "https://149.154.167.91"
  ],
  
  // Advanced timeout settings
  TELEGRAM_CONNECT_TIMEOUT: 10000,
  TELEGRAM_SOCKET_TIMEOUT: 60000,
  TELEGRAM_PROXY_TIMEOUT: 15000,
};
EOF
    print_warning "Please copy config.example.js to config.js and configure your settings!"
fi

print_success "Deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Edit config.js with your Telegram bot token and chat ID"
echo "2. Add wallet addresses to address.txt"
echo "3. Start the bot: ./start-vps.sh"
echo ""
echo "🔧 Management commands:"
echo "  Start:   ./start-vps.sh"
echo "  Stop:    ./stop-vps.sh"
echo "  Restart: ./restart-vps.sh"
echo "  Status:  ./status-vps.sh"
echo ""
echo "📊 PM2 commands:"
echo "  pm2 status                    - Check bot status"
echo "  pm2 logs etherdrops-monitor   - View logs"
echo "  pm2 restart etherdrops-monitor - Restart bot"
echo ""
echo "🔄 Auto-restart features enabled:"
echo "  - Watchdog restart on excessive reconnects"
echo "  - Memory threshold restart (500MB)"
echo "  - Endpoint rotation on failures"
echo "  - WSS fallback to HTTPS"
echo ""
print_success "Your EtherDrops Monitor Bot is ready for VPS deployment!"
