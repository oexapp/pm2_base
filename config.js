// Configuration file for EtherDrops Monitor Bot

module.exports = {
  // BASE RPC WebSocket endpoint (primary)
  BSC_RPC_WSS: "wss://base-rpc.publicnode.com",
  
  // Multiple RPC endpoints for fallback (BASE)
  RPC_ENDPOINTS: [
    "wss://base-rpc.publicnode.com",
    "wss://base.gateway.tenderly.co",
    // HTTPS fallbacks
    "https://base.llamarpc.com",
    "https://api.zan.top/base-mainnet",
    "https://base.drpc.org",
    "https://base-mainnet.public.blastapi.io",
    "https://base-public.nodies.app",
    "https://base.gateway.tenderly.co",
    "https://gateway.tenderly.co/public/base",
    "https://endpoints.omniatech.io/v1/base/mainnet/public",
    "https://base.lava.build",
    "https://mainnet.base.org",
    "https://developer-access-mainnet.base.org",
    "https://base.public.blockpi.network/v1/rpc/public",
    "https://rpc.owlracle.info/base/70d38ce1826c4a60bb2a8e05a6c8b20f",
    "https://base-rpc.publicnode.com"
  ],
  
  // Telegram Bot Configuration
  TELEGRAM_BOT_TOKEN: "7635407880:AAErwTX6VicCsvMOH9I6OKH4W62SkY6sPUA",
  TELEGRAM_CHAT_ID: "5833826595",
  
  // Router for price calculation (UniswapV2-style on Base)
  PANCAKE_ROUTER: "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24",
  
  // Token addresses for price calculation (Base Mainnet)
  // Use USDC as quote token on Base
  BUSD: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC
  USDT: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC (used as quote)
  WBNB: "0x4200000000000000000000000000000000000006", // WETH on Base
  
  // Wallet name mapping (add your wallet names here)
  WALLET_NAMES: {
    "0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef": "HELLO ALMI",
    // Add more wallet names here as needed
    // "0x4C26F7Fdc32e91f469bFc54e1711E71CE3ea0f1C": "Another Wallet",
  },
  
  // Processing delay in milliseconds (to collect multiple transfers in same transaction)
  PROCESSING_DELAY: 2000,
  
  // Address file path
  ADDRESS_FILE: "address.txt",
  
  // Telegram command checking interval (milliseconds)
  TELEGRAM_CHECK_INTERVAL: 5000,
  
  // VPS Optimization Settings
  // Enable auto-restart on critical errors
  AUTO_RESTART: true,
  
  // Memory threshold for auto-restart (MB)
  MEMORY_THRESHOLD: 500,
  
  // Max consecutive errors before restart
  MAX_CONSECUTIVE_ERRORS: 50,
  
  // Connection timeout settings (milliseconds)
  CONNECTION_TIMEOUT: 30000, // Increased to 30 seconds for better reliability
  TELEGRAM_TIMEOUT: 25000, // Specific timeout for Telegram API calls
  PRICE_CALCULATION_TIMEOUT: 5000,
  
  // Retry settings
  MAX_RECONNECT_ATTEMPTS: 10,
  RECONNECT_DELAY: 5000,
  TELEGRAM_MAX_RETRIES: 5, // Increased retries for Telegram
  TELEGRAM_BASE_DELAY: 2000, // Base delay between retries
  
  // Watchdog settings for VPS stability
  WATCHDOG_RECONNECT_THRESHOLD: 20, // Max reconnects before restart
  WATCHDOG_TIME_WINDOW: 30 * 60 * 1000, // 30 minutes
  MIN_CONNECTION_UPTIME: 5 * 60 * 1000, // 5 minutes minimum uptime
  ENDPOINT_ROTATION_COOLDOWN: 2 * 60 * 1000, // 2 minutes between rotations
  
  // WSS failure handling
  WSS_FAILURE_THRESHOLD: 3,
  WSS_DISABLE_DURATION: 10 * 60 * 1000, // 10 minutes
  
  // Memory cleanup settings
  MEMORY_CLEANUP_INTERVAL: 10 * 60 * 1000, // 10 minutes
  PENDING_TRANSFER_TIMEOUT: 5 * 60 * 1000, // 5 minutes
  
  // Network resilience settings
  TELEGRAM_KEEPALIVE: true, // Keep HTTP connections alive
  TELEGRAM_MAX_SOCKETS: 10, // Maximum concurrent sockets
  HTTP_TIMEOUT: 30000, // General HTTP timeout
  DNS_TIMEOUT: 15000, // DNS resolution timeout
  
  // Telegram API endpoints with fallback
  TELEGRAM_API_ENDPOINTS: [
    "https://api.telegram.org",
    "https://api.telegram.org:443",
    "https://149.154.167.220", // Telegram IP fallback
    "https://149.154.175.50",  // Telegram IP fallback
    "https://149.154.167.91"   // Telegram IP fallback
  ],
  
  // Advanced timeout settings
  TELEGRAM_CONNECT_TIMEOUT: 10000, // Connection timeout (10s)
  TELEGRAM_SOCKET_TIMEOUT: 60000,  // Socket timeout (60s)
  TELEGRAM_PROXY_TIMEOUT: 15000,   // Proxy timeout (15s)
};
