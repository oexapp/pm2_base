// Configuration template for EtherDrops Monitor Bot
// Copy this file to config.js and fill in your actual values

module.exports = {
  // BASE RPC WebSocket endpoint
  BSC_RPC_WSS: "wss://base-rpc.publicnode.com",
  
  // Telegram Bot Configuration
  // Get bot token from @BotFather on Telegram
  TELEGRAM_BOT_TOKEN: "YOUR_BOT_TOKEN_HERE",
  // Get chat ID by sending a message to your bot and visiting:
  // https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
  TELEGRAM_CHAT_ID: "YOUR_CHAT_ID_HERE",
  
  // Router for price calculation (UniswapV2-style on Base)
  PANCAKE_ROUTER: "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24",
  
  // Token addresses for price calculation (Base Mainnet)
  // Use USDC as quote token
  BUSD: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC
  USDT: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC
  WBNB: "0x4200000000000000000000000000000000000006", // WETH on Base
  
  // Wallet name mapping (add your wallet names here)
  WALLET_NAMES: {
    "0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef": "HELLO MOTTHERFCKER",
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
  MAX_CONSECUTIVE_ERRORS: 50
};
