const { ethers } = require("ethers");
const fs = require("fs");
const axios = require("axios");
const http = require("http");
const https = require("https");
const config = require("./config");

// Configure HTTP agents for better connection management
const httpAgent = new http.Agent({
  keepAlive: config.TELEGRAM_KEEPALIVE || true,
  keepAliveMsecs: 30000,
  maxSockets: config.TELEGRAM_MAX_SOCKETS || 10,
  timeout: config.DNS_TIMEOUT || 15000,
  // Additional connection options
  family: 4, // Force IPv4
  rejectUnauthorized: false // Allow self-signed certificates if needed
});

const httpsAgent = new https.Agent({
  keepAlive: config.TELEGRAM_KEEPALIVE || true,
  keepAliveMsecs: 30000,
  maxSockets: config.TELEGRAM_MAX_SOCKETS || 10,
  timeout: config.DNS_TIMEOUT || 15000,
  // Additional connection options
  family: 4, // Force IPv4
  rejectUnauthorized: false, // Allow self-signed certificates if needed
  // Advanced timeout settings
  connectTimeout: config.TELEGRAM_CONNECT_TIMEOUT || 10000,
  socketTimeout: config.TELEGRAM_SOCKET_TIMEOUT || 60000
});

// Configure axios defaults
axios.defaults.httpAgent = httpAgent;
axios.defaults.httpsAgent = httpsAgent;
axios.defaults.timeout = config.HTTP_TIMEOUT || 30000;

// --- CONFIG ---
const {
  BSC_RPC_WSS,
  TELEGRAM_BOT_TOKEN,
  TELEGRAM_CHAT_ID,
  PANCAKE_ROUTER,
  BUSD,
  USDT,
  WBNB,
  WALLET_NAMES,
  PROCESSING_DELAY,
  ADDRESS_FILE,
  TELEGRAM_CHECK_INTERVAL
} = config;
// --- END CONFIG ---

// Multiple RPC endpoints for fallback/rotation (mix WSS + HTTPS) - BASE
// Each endpoint includes its protocol type to build the right provider.
const ENDPOINTS = [
  // WSS
  { url: "wss://base.gateway.tenderly.co", type: "wss" },
  { url: "wss://base-rpc.publicnode.com", type: "wss" },

  // HTTPS (fallback with polling) - prefer more reliable first
  { url: "https://base.public.blockpi.network/v1/rpc/public", type: "https" },
  { url: "https://gateway.tenderly.co/public/base", type: "https" },
  { url: "https://base.gateway.tenderly.co", type: "https" },
  { url: "https://base.drpc.org", type: "https" },
  { url: "https://mainnet.base.org", type: "https" },
  { url: "https://developer-access-mainnet.base.org", type: "https" },
  { url: "https://base-rpc.publicnode.com", type: "https" },
  { url: "https://endpoints.omniatech.io/v1/base/mainnet/public", type: "https" },
  { url: "https://api.zan.top/base-mainnet", type: "https" },
  { url: "https://base.llamarpc.com", type: "https" },
  { url: "https://base-mainnet.public.blastapi.io", type: "https" },
  { url: "https://base-public.nodies.app", type: "https" },
  { url: "https://base.lava.build", type: "https" },
  { url: "https://rpc.owlracle.info/base/70d38ce1826c4a60bb2a8e05a6c8b20f", type: "https" }
];

// --- Enhanced Connection Management Variables ---
let provider = null;
let router = null;
let isConnected = false;
let reconnectAttempts = 0;
let currentEndpointIndex = 0;
let lastChosenEndpoint = null;
let connectivityCheckIntervalId = null;
let telegramUpdatesIntervalId = null;
let healthCheckIntervalId = null;
let memoryCleanupIntervalId = null;
let pollerIntervalId = null;
let lastProcessedBlock = null;
let activeLogListeners = [];
let isReconnectingInProgress = false;
let pollingErrorCount = 0; // count consecutive polling failures

// Enhanced watchdog and stability variables
let watchdogReconnectCount = 0;
let lastSuccessfulConnection = 0;
let connectionUptime = 0;
let lastConnectionStart = 0;
let totalReconnects = 0;
let wssFailureCount = 0;
let httpsFallbackCount = 0;
let lastEndpointRotation = 0;

// Configuration constants from config
const MAX_RECONNECT_ATTEMPTS = config.MAX_RECONNECT_ATTEMPTS;
const RECONNECT_DELAY = config.RECONNECT_DELAY;
const HTTPS_POLLING_INTERVAL_MS = 15000; // Polling when using HTTPS provider
const PREFER_HTTPS_FIRST = true; // Prefer HTTPS to avoid WSS handshake issues on public RPC

// Watchdog thresholds for VPS stability
const WATCHDOG_RECONNECT_THRESHOLD = config.WATCHDOG_RECONNECT_THRESHOLD;
const WATCHDOG_TIME_WINDOW = config.WATCHDOG_TIME_WINDOW;
const MIN_CONNECTION_UPTIME = config.MIN_CONNECTION_UPTIME;
const ENDPOINT_ROTATION_COOLDOWN = config.ENDPOINT_ROTATION_COOLDOWN;

// Adaptive WSS backoff (disable WSS for a cooldown after repeated failures)
const WSS_FAILURE_THRESHOLD = config.WSS_FAILURE_THRESHOLD;
let wssDisableUntil = 0; // timestamp ms

// In-memory endpoint health stats
const endpointStats = new Map(); // url -> { healthy, latencyMs, lastTriedAt, supportsSubscriptions, failureCount }

function setEndpointStat(url, data) {
  const prev = endpointStats.get(url) || {};
  endpointStats.set(url, { ...prev, ...data });
}

function getEndpointStat(url) {
  return endpointStats.get(url) || { 
    healthy: false, 
    latencyMs: Number.MAX_SAFE_INTEGER, 
    lastTriedAt: 0, 
    supportsSubscriptions: false,
    failureCount: 0 
  };
}

function createProviderForEndpoint(endpoint) {
  if (endpoint.type === "wss") {
    // If WSS is temporarily disabled due to repeated failures, skip usage
    if (Date.now() < wssDisableUntil) {
      throw new Error("wss-disabled-temporarily");
    }
    return new ethers.WebSocketProvider(endpoint.url, undefined, {
      timeout: 30000,
      retryCount: 3,
      retryDelay: 5000
    });
  }
  const httpProvider = new ethers.JsonRpcProvider(endpoint.url, 8453, {
    staticNetwork: 8453,
  });
  // Enable polling for filters/events
  httpProvider.pollingInterval = HTTPS_POLLING_INTERVAL_MS;
  return httpProvider;
}

async function probeEndpoint(endpoint, timeoutMs = 4000) {
  let tempProvider;
  const startedAt = Date.now();
  try {
    if (endpoint.type === 'wss' && Date.now() < wssDisableUntil) {
      return { healthy: false, error: new Error('wss-disabled-temporarily') };
    }
    tempProvider = createProviderForEndpoint(endpoint);
    // Race a simple call with timeout
    const result = await Promise.race([
      tempProvider.getBlockNumber(),
      new Promise((_, reject) => setTimeout(() => reject(new Error("probe-timeout")), timeoutMs))
    ]);
    const latency = Date.now() - startedAt;
    // For WSS endpoints, verify eth_subscribe capability to avoid providers that block subscriptions
    let supportsSubscriptions = false;
    if (endpoint.type === 'wss') {
      try {
        const subId = await Promise.race([
          tempProvider.send('eth_subscribe', ['newHeads']),
          new Promise((_, reject) => setTimeout(() => reject(new Error('probe-subscribe-timeout')), timeoutMs))
        ]);
        supportsSubscriptions = !!subId;
        // Attempt to unsubscribe, ignore failures
        try { if (subId) { await tempProvider.send('eth_unsubscribe', [subId]); } } catch {}
      } catch (subErr) {
        // If the node explicitly says Method not found or subscription not allowed, treat as not supporting subscriptions
        supportsSubscriptions = false;
      }
    }
    // For HTTPS, ethers uses polling and does not require subscriptions
    if (endpoint.type === 'https') supportsSubscriptions = true;
    
    // If WSS without subscriptions, mark unhealthy to skip it (we rely on HTTPS polling instead)
    const healthy = endpoint.type === 'wss' ? supportsSubscriptions : true;
    setEndpointStat(endpoint.url, { 
      healthy, 
      latencyMs: latency, 
      lastTriedAt: Date.now(), 
      supportsSubscriptions,
      failureCount: 0 // Reset failure count on success
    });
    // Cleanup websockets immediately after probe
    try {
      if (tempProvider && typeof tempProvider.destroy === 'function') tempProvider.destroy();
    } catch {}
    return { healthy, latencyMs: latency, blockNumber: result, supportsSubscriptions };
  } catch (e) {
    const currentStat = getEndpointStat(endpoint.url);
    setEndpointStat(endpoint.url, { 
      healthy: false, 
      latencyMs: Number.MAX_SAFE_INTEGER, 
      lastTriedAt: Date.now(),
      failureCount: currentStat.failureCount + 1
    });
    try {
      if (tempProvider && typeof tempProvider.destroy === 'function') tempProvider.destroy();
    } catch {}
    return { healthy: false, error: e };
  }
}

async function selectBestEndpoint() {
  console.log("🔍 Probing endpoints for best connection...");
  // Always probe full list to pick the most reliable endpoint, preferring HTTPS
  const fullResults = await Promise.all(ENDPOINTS.map((ep, i) => probeEndpoint(ep).then(r => ({ ...r, index: i, endpoint: ep }))));
  let allHealthy = fullResults.filter(r => r.healthy);
  
  // Sort by reliability (HTTPS first, then by latency, then by failure count)
  allHealthy.sort((a, b) => {
    // Prefer HTTPS for stability
    if (PREFER_HTTPS_FIRST && a.endpoint.type !== b.endpoint.type) {
      return a.endpoint.type === 'https' ? -1 : 1;
    }
    // Then by latency
    if (Math.abs(a.latencyMs - b.latencyMs) > 1000) {
      return a.latencyMs - b.latencyMs;
    }
    // Then by failure count (prefer less failed endpoints)
    const aFailures = getEndpointStat(a.endpoint.url).failureCount;
    const bFailures = getEndpointStat(b.endpoint.url).failureCount;
    return aFailures - bFailures;
  });
  
  if (allHealthy.length > 0) {
    const chosen = allHealthy[0];
    currentEndpointIndex = chosen.index;
    console.log(`✅ Selected endpoint: ${chosen.endpoint.url} (${chosen.endpoint.type.toUpperCase()}) - Latency: ${chosen.latencyMs}ms`);
    return chosen.endpoint;
  }
  
  // Fallback to current index even if unhealthy
  console.log(`⚠️ No healthy endpoints found, using fallback: ${ENDPOINTS[currentEndpointIndex].url}`);
  return ENDPOINTS[currentEndpointIndex];
}

// --- Enhanced Initialize Provider with Watchdog ---
async function initializeProvider() {
  try {
    if (isReconnectingInProgress) {
      console.log("⚠️ Reconnection already in progress, skipping...");
      return;
    }
    
    isReconnectingInProgress = true;
    const startTime = Date.now();
    
    // Check watchdog conditions before attempting connection
    if (shouldTriggerWatchdogRestart()) {
      console.log("🚨 Watchdog restart triggered - too many reconnects in short time");
      await gracefulRestart();
      return;
    }
    
    const chosen = await selectBestEndpoint();
    console.log(`🔗 Connecting to RPC: ${chosen.url} (${chosen.type.toUpperCase()})`);
    
    // Create provider based on endpoint type
    provider = createProviderForEndpoint(chosen);
    lastChosenEndpoint = chosen;
    lastConnectionStart = Date.now();
    
    router = new ethers.Contract(PANCAKE_ROUTER, ["function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts)"], provider);
    
    // Setup enhanced event listeners
    provider.on("network", () => {
      if (!isConnected) {
        console.log(`🔗 Connected to BASE via ${lastChosenEndpoint.type.toUpperCase()}`);
        lastSuccessfulConnection = Date.now();
        connectionUptime = 0;
      }
      isConnected = true;
      reconnectAttempts = 0;
      resetErrorStats();
      resetWatchdogStats();
    });
    
    // Enhanced error handling
    provider.on("error", (error) => {
      console.log(`⚠️ Provider error (${lastChosenEndpoint.type.toUpperCase()}):`, error.message);
      
      const isNetworkError = error.code === 'NETWORK_ERROR' ||
        (error.message && error.message.includes('network is not available')) ||
        (error.message && error.message.includes('Unexpected server response')) ||
        (error.message && error.message.includes('ECONNRESET')) ||
        (error.message && error.message.includes('ENOTFOUND'));
      
      if (isNetworkError) {
        console.log("🔄 Network error detected, initiating endpoint rotation...");
        isConnected = false;
        
        // Update endpoint statistics
        if (lastChosenEndpoint) {
          const currentStat = getEndpointStat(lastChosenEndpoint.url);
          setEndpointStat(lastChosenEndpoint.url, {
            ...currentStat,
            healthy: false,
            failureCount: currentStat.failureCount + 1
          });
          
          // Handle WSS-specific failures
          if (lastChosenEndpoint.type === 'wss') {
            wssFailureCount++;
            if (wssFailureCount >= WSS_FAILURE_THRESHOLD) {
              wssDisableUntil = Date.now() + config.WSS_DISABLE_DURATION;
              console.log(`⏸️ WSS disabled temporarily for ${config.WSS_DISABLE_DURATION / 60000} minutes due to repeated failures`);
              wssFailureCount = 0;
            }
          } else {
            httpsFallbackCount++;
          }
        }
        
        handleReconnect();
      }
    });
    
    // Enhanced connectivity monitoring
    if (connectivityCheckIntervalId) {
      clearInterval(connectivityCheckIntervalId);
    }
    
    connectivityCheckIntervalId = setInterval(async () => {
      try {
        if (provider) {
          await provider.getNetwork();
          if (!isConnected) {
            console.log("🔗 Connection restored");
            isConnected = true;
            reconnectAttempts = 0;
            resetErrorStats();
            resetWatchdogStats();
          }
          // Update connection uptime
          if (isConnected && lastConnectionStart > 0) {
            connectionUptime = Date.now() - lastConnectionStart;
          }
        } else {
          if (isConnected) {
            console.log("❌ Connection lost - Provider not ready");
            isConnected = false;
            handleReconnect();
          }
        }
      } catch (error) {
        if (isConnected) {
          console.log("❌ Connection lost during health check:", error.message);
          isConnected = false;
          handleReconnect();
        }
      }
    }, 15000); // Check every 15 seconds
    
    // Setup transfer listener
    setupTransferListener();
    
    // Verify provider readiness
    try {
      await provider.getNetwork();
      if (!isConnected) {
        isConnected = true;
        reconnectAttempts = 0;
        lastSuccessfulConnection = Date.now();
      }
      console.log("🔍 Listening to all token transfers on BASE...");
      console.log(`📊 Connection established in ${Date.now() - startTime}ms`);
    } catch (e) {
      console.log("⚠️ Provider not ready yet:", e.message);
      isConnected = false;
      handleReconnect();
    }
    
  } catch (error) {
    console.error("❌ Failed to initialize provider:", error.message);
    updateErrorStats();
    handleReconnect();
  } finally {
    isReconnectingInProgress = false;
  }
}

// --- Enhanced Reconnection Handler with Watchdog ---
function handleReconnect() {
  if (isReconnectingInProgress) {
    return;
  }
  
  // Update watchdog counters
  watchdogReconnectCount++;
  totalReconnects++;
  
  console.log(`🔄 Reconnect attempt ${reconnectAttempts + 1}/${MAX_RECONNECT_ATTEMPTS} (Total: ${totalReconnects})`);
  
  // Check if we should trigger watchdog restart
  if (shouldTriggerWatchdogRestart()) {
    console.log("🚨 Watchdog restart triggered - excessive reconnects detected");
    gracefulRestart();
    return;
  }
  
  if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
    console.error(`❌ Max reconnection attempts (${MAX_RECONNECT_ATTEMPTS}) reached. Rotating endpoint...`);
    rotateEndpoint();
    reconnectAttempts = 0;
  }
  
  reconnectAttempts++;
  
  // Calculate delay with exponential backoff and endpoint rotation cooldown
  const now = Date.now();
  const timeSinceLastRotation = now - lastEndpointRotation;
  const baseDelay = RECONNECT_DELAY * Math.min(reconnectAttempts, 5); // Cap exponential backoff
  
  let delay = baseDelay;
  if (timeSinceLastRotation < ENDPOINT_ROTATION_COOLDOWN) {
    delay = Math.max(delay, ENDPOINT_ROTATION_COOLDOWN - timeSinceLastRotation);
  }
  
  console.log(`⏳ Reconnecting in ${delay}ms...`);
  
  setTimeout(() => {
    try {
      if (isReconnectingInProgress) {
        return;
      }
      
      // Cleanup existing provider
      if (provider) {
        try {
          provider.removeAllListeners && provider.removeAllListeners();
          if (typeof provider.destroy === 'function') provider.destroy();
        } catch (destroyError) {
          // Ignore destroy errors
        }
      }
      
      // Clear intervals to prevent duplicates
      if (connectivityCheckIntervalId) {
        clearInterval(connectivityCheckIntervalId);
        connectivityCheckIntervalId = null;
      }
      
      // Re-initialize with best endpoint selection
      initializeProvider();
    } catch (error) {
      console.error("❌ Reconnection failed:", error.message);
      updateErrorStats();
      handleReconnect();
    }
  }, delay);
}

// --- Endpoint Rotation Logic ---
function rotateEndpoint() {
  const now = Date.now();
  if (now - lastEndpointRotation < ENDPOINT_ROTATION_COOLDOWN) {
    console.log("⏳ Endpoint rotation cooldown active, skipping...");
    return;
  }
  
  lastEndpointRotation = now;
  currentEndpointIndex = (currentEndpointIndex + 1) % ENDPOINTS.length;
  console.log(`🔄 Rotating to endpoint ${currentEndpointIndex + 1}/${ENDPOINTS.length}`);
}

// --- Watchdog Functions ---
function shouldTriggerWatchdogRestart() {
  const now = Date.now();
  const timeWindow = now - WATCHDOG_TIME_WINDOW;
  
  // Check if we've had too many reconnects in the time window
  if (watchdogReconnectCount >= WATCHDOG_RECONNECT_THRESHOLD) {
    console.log(`🚨 Watchdog: ${watchdogReconnectCount} reconnects in ${WATCHDOG_TIME_WINDOW / 60000} minutes`);
    return true;
  }
  
  // Check if we haven't had a stable connection for too long
  if (lastSuccessfulConnection > 0 && (now - lastSuccessfulConnection) > WATCHDOG_TIME_WINDOW) {
    console.log(`🚨 Watchdog: No stable connection for ${(now - lastSuccessfulConnection) / 60000} minutes`);
    return true;
  }
  
  return false;
}

function resetWatchdogStats() {
  const now = Date.now();
  // Reset watchdog counter if we've had a stable connection for a while
  if (now - lastSuccessfulConnection > MIN_CONNECTION_UPTIME) {
    watchdogReconnectCount = 0;
    console.log("✅ Watchdog stats reset - stable connection established");
  }
}

async function gracefulRestart() {
  console.log("🔄 Initiating graceful restart due to watchdog trigger...");
  console.log("📊 Final stats before restart:");
  console.log(`   Total reconnects: ${totalReconnects}`);
  console.log(`   Watchdog reconnects: ${watchdogReconnectCount}`);
  console.log(`   WSS failures: ${wssFailureCount}`);
  console.log(`   HTTPS fallbacks: ${httpsFallbackCount}`);
  console.log(`   Uptime: ${Math.floor(process.uptime())} seconds`);
  
  // Cleanup
  if (provider) {
    try {
      provider.removeAllListeners && provider.removeAllListeners();
      if (typeof provider.destroy === 'function') provider.destroy();
    } catch (error) {
      console.log("⚠️ Error destroying provider:", error.message);
    }
  }
  
  if (connectivityCheckIntervalId) {
    clearInterval(connectivityCheckIntervalId);
  }
  
  // Exit with error code to trigger restart (pm2/systemd)
  setTimeout(() => {
    console.log("🔄 Exiting for restart...");
    process.exit(1);
  }, 3000);
}

// --- Setup Transfer Listener ---
function setupTransferListener() {
  if (!provider) return;
  
  const transferTopic = ethers.id("Transfer(address,address,uint256)");

  // Clear any existing poller to avoid duplicates on reconnect
  if (pollerIntervalId) {
    clearInterval(pollerIntervalId);
    pollerIntervalId = null;
  }

  const useWssSubscriptions = lastChosenEndpoint && lastChosenEndpoint.type === 'wss' && Date.now() >= wssDisableUntil;

  if (useWssSubscriptions && typeof provider.on === 'function') {
    provider.on({ topics: [transferTopic] }, async (log) => {
      await handleTransferLog(log);
    });
    return;
  }

  // HTTPS polling fallback: use getLogs instead of eth_newFilter
  pollerIntervalId = setInterval(async () => {
    try {
      const currentBlock = await provider.getBlockNumber();
      if (lastProcessedBlock === null) {
        lastProcessedBlock = Math.max(0, currentBlock - 1);
      }
      const toBlock = currentBlock;
      const fromBlock = toBlock; // only latest block to reduce load
      if (toBlock < fromBlock) return;

      const params = { fromBlock: toBlock, toBlock, topics: [transferTopic] };
      const logs = await Promise.race([
        provider.getLogs(params),
        new Promise((_, reject) => setTimeout(() => reject(new Error('getLogs-timeout')), 5000))
      ]);
      if (logs && logs.length) {
        console.log(`📡 Polled logs: ${logs.length} (block ${toBlock})`);
      }
      for (const log of logs) {
        await handleTransferLog(log);
      }
      lastProcessedBlock = toBlock;
      pollingErrorCount = 0; // reset on success
    } catch (e) {
      pollingErrorCount++;
      logError(`Polling error: ${e.message}`);
      const immediateRotate = e && (String(e.message).includes('no response') || String(e.message).includes('getLogs-timeout'));
      if (pollingErrorCount >= 2 || immediateRotate) {
        console.log("🔄 Too many polling errors, rotating endpoint immediately...");
        // Force bypass cooldown and reconnect quickly
        lastEndpointRotation = 0;
        rotateEndpoint();
        reconnectAttempts = 0;
        isConnected = false;
        setTimeout(() => handleReconnect(), 1000);
        pollingErrorCount = 0;
      }
    }
  }, HTTPS_POLLING_INTERVAL_MS);
}

async function handleTransferLog(log) {
  // Enhanced validation for log data
  if (!log || !log.data || log.data.length < 66) {
    return;
  }

  try {
    // Validate log structure before parsing
    if (!log.address || !ethers.isAddress(log.address)) {
      return;
    }

    const token = new ethers.Contract(log.address, erc20Abi, provider);
    
    // Safe parsing with error handling
    let parsed;
    try {
      parsed = token.interface.parseLog(log);
    } catch (parseError) {
      return;
    }

    if (!parsed || !parsed.args) {
      return;
    }

    const { from, to, value } = parsed.args;
    
    // Validate addresses
    if (!from || !to || !ethers.isAddress(from) || !ethers.isAddress(to)) {
      return;
    }

    // Ignore self-transfers
    if (from.toLowerCase() === to.toLowerCase()) {
      return;
    }

    const fromWatched = watchList.has(from.toLowerCase());
    const toWatched = watchList.has(to.toLowerCase());

    if (!fromWatched && !toWatched) return;

    // --- Token info with decimal validation ---
    let symbol, decimals;
    try {
      symbol = await token.symbol();
      decimals = await token.decimals();
      if (!decimals || decimals < 0 || decimals > 30) decimals = 18; // fallback
    } catch (error) {
      symbol = "UNKNOWN";
      decimals = 18;
      logError(`Using fallback token info: ${error.message}`);
    }

    const amount = parseFloat(ethers.formatUnits(value, decimals));
    if (!amount || amount <= 0) {
      return;
    }

    const watchedAddress = toWatched ? to : from;
    const otherAddress = toWatched ? from : to;

    // --- Get USD price ---
    let usdPrice = 0;
    // On Base, use USDC as quote for all tokens including WETH
    usdPrice = await getOnChainPrice(log.address, USDT, amount, decimals);

    // --- Format amount ---
    let formattedAmount;
    if (amount >= 1000000) {
      formattedAmount = amount.toLocaleString('en-US', { maximumFractionDigits: 0 });
    } else if (amount >= 1) {
      formattedAmount = amount.toFixed(2);
    } else {
      formattedAmount = amount.toFixed(8);
    }

    // --- Determine transaction type ---
    const transactionType = toWatched ? "Received" : "Terkirim";

    // --- Store transfer data ---
    const transferData = {
      tokenAddress: log.address,
      symbol,
      formattedAmount,
      usdPrice,
      transactionType,
      watchedAddress,
      otherAddress,
      toWatched
    };

    if (!pendingTransfers.has(log.transactionHash)) {
      pendingTransfers.set(log.transactionHash, {
        transfers: [],
        timestamp: Date.now()
      });
    }
    pendingTransfers.get(log.transactionHash).transfers.push(transferData);

    // --- Process after a short delay to collect all transfers in the same transaction ---
    setTimeout(() => {
      processPendingTransfers(log.transactionHash);
    }, PROCESSING_DELAY);

  } catch (err) {
    console.error("Error processing transfer:", err.message);
    updateErrorStats();
  }
}

const erc20Abi = [
  "event Transfer(address indexed from, address indexed to, uint256 value)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)"
];

// --- Load addresses ---
let watchList = new Set();
function loadAddresses() {
  try {
    const allAddresses = fs.readFileSync(ADDRESS_FILE, "utf-8")
      .split(/\r?\n/)
      .map(a => a.trim().toLowerCase())
      .filter(Boolean);
    watchList = new Set(allAddresses);
    console.log(`✅ Loaded ${watchList.size} addresses to monitor.`);
  } catch (error) {
    console.error("❌ Error loading addresses:", error.message);
    updateErrorStats();
    // Create empty file if it doesn't exist
    try {
      fs.writeFileSync(ADDRESS_FILE, "");
      watchList = new Set();
      console.log("✅ Created new address.txt file");
    } catch (writeError) {
      console.error("❌ Failed to create address.txt:", writeError.message);
    }
  }
}

function saveAddresses() {
  try {
    const addresses = Array.from(watchList).join('\n');
    fs.writeFileSync(ADDRESS_FILE, addresses);
    console.log(`💾 Saved ${watchList.size} addresses to ${ADDRESS_FILE}`);
  } catch (error) {
    console.error("❌ Error saving addresses:", error.message);
    updateErrorStats();
  }
}

function addAddress(address) {
  try {
    const cleanAddress = address.trim().toLowerCase();
    if (ethers.isAddress(cleanAddress)) {
      if (!watchList.has(cleanAddress)) {
        watchList.add(cleanAddress);
        saveAddresses();
        console.log(`✅ Added address: ${cleanAddress} (Total: ${watchList.size})`);
        return { success: true, message: `✅ Address \`${cleanAddress}\` added successfully!\n📊 Total addresses: ${watchList.size}` };
      } else {
        return { success: false, message: `⚠️ Address \`${cleanAddress}\` already exists in watchlist.` };
      }
    } else {
      return { success: false, message: `❌ Invalid address format: \`${address}\`\n\nPlease use a valid Ethereum address format:\n\`0x1234567890123456789012345678901234567890\`` };
    }
  } catch (error) {
    console.error("❌ Error adding address:", error.message);
    updateErrorStats();
    return { success: false, message: `❌ Error adding address: ${error.message}` };
  }
}

function removeAddress(address) {
  try {
    const cleanAddress = address.trim().toLowerCase();
    if (watchList.has(cleanAddress)) {
      watchList.delete(cleanAddress);
      saveAddresses();
      console.log(`✅ Removed address: ${cleanAddress} (Total: ${watchList.size})`);
      return { success: true, message: `✅ Address \`${cleanAddress}\` removed successfully!\n📊 Total addresses: ${watchList.size}` };
    } else {
      return { success: false, message: `⚠️ Address \`${cleanAddress}\` not found in watchlist.` };
    }
  } catch (error) {
    console.error("❌ Error removing address:", error.message);
    updateErrorStats();
    return { success: false, message: `❌ Error removing address: ${error.message}` };
  }
}

function listAddresses() {
  try {
    const addresses = Array.from(watchList);
    if (addresses.length === 0) {
      return "📝 No addresses in watchlist.";
    }
    
    let message = `📝 **Watchlist (${addresses.length} addresses):**\n\n`;
    addresses.forEach((addr, index) => {
      const walletName = getWalletName(addr);
      const displayName = walletName === "Unknown Wallet" ? addr : `${walletName} (${addr})`;
      message += `${index + 1}. ${displayName}\n`;
    });
    return message;
  } catch (error) {
    console.error("❌ Error listing addresses:", error.message);
    updateErrorStats();
    return "❌ Error listing addresses. Please try again.";
  }
}

loadAddresses();

// --- Telegram ---
async function sendTelegram(msg, chatId = null) {
  const maxRetries = config.TELEGRAM_MAX_RETRIES || 5;
  let retryCount = 0;
  const endpoints = config.TELEGRAM_API_ENDPOINTS || ["https://api.telegram.org"];
  let currentEndpointIndex = 0;
  
  while (retryCount < maxRetries) {
    try {
      const currentEndpoint = endpoints[currentEndpointIndex % endpoints.length];
      const url = `${currentEndpoint}/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
      
      console.log(`📡 Attempting Telegram API call to: ${currentEndpoint} (attempt ${retryCount + 1}/${maxRetries})`);
      
      const response = await axios.post(url, {
        chat_id: chatId || TELEGRAM_CHAT_ID,
        text: msg,
        parse_mode: "Markdown"
      }, {
        timeout: config.TELEGRAM_TIMEOUT || 25000,
        headers: {
          'User-Agent': 'EtherDrops-Monitor/1.0',
          'Connection': 'keep-alive',
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        // Advanced timeout configuration
        connectTimeout: config.TELEGRAM_CONNECT_TIMEOUT || 10000,
        socketTimeout: config.TELEGRAM_SOCKET_TIMEOUT || 60000,
        // Add axios retry configuration
        validateStatus: function (status) {
          return status < 500; // Resolve only if the status code is less than 500
        },
        // Force IPv4 and allow self-signed certificates
        family: 4,
        rejectUnauthorized: false
      });
      
      // Log successful message
      if (retryCount > 0) {
        console.log(`✅ Telegram message sent successfully after ${retryCount} retries via ${currentEndpoint}`);
      } else {
        console.log(`✅ Telegram message sent successfully via ${currentEndpoint}`);
      }
      return; // Success, exit retry loop
      
    } catch (err) {
      retryCount++;
      const currentEndpoint = endpoints[currentEndpointIndex % endpoints.length];
      console.error(`Telegram error (attempt ${retryCount}/${maxRetries}) via ${currentEndpoint}:`, err.message);
      
      // Calculate exponential backoff delay
      const baseDelay = config.TELEGRAM_BASE_DELAY || 2000;
      let delayMs = baseDelay * Math.pow(2, retryCount - 1); // Exponential backoff
      
      // Cap maximum delay at 30 seconds
      delayMs = Math.min(delayMs, 30000);
      
      // Handle specific error types with adjusted delays
      if (err.code === 'EAI_AGAIN' || err.code === 'ENOTFOUND') {
        console.log(`🔄 DNS resolution failed, waiting ${delayMs/1000} seconds before retry...`);
        delayMs *= 1.5; // Longer wait for DNS issues
        // Try next endpoint on DNS issues
        currentEndpointIndex++;
      } else if (err.code === 'ECONNRESET' || err.code === 'ETIMEDOUT' || err.message.includes('timeout')) {
        console.log(`🔄 Connection timeout, waiting ${delayMs/1000} seconds before retry...`);
        // Try next endpoint on timeout
        currentEndpointIndex++;
      } else if (err.response && err.response.status === 429) {
        // Rate limiting - wait longer
        console.log(`🔄 Rate limited by Telegram, waiting ${delayMs/1000} seconds before retry...`);
        delayMs *= 2;
      } else if (err.response && err.response.status >= 500) {
        // Server errors - try next endpoint
        console.log(`🔄 Telegram server error (${err.response.status}), trying next endpoint...`);
        currentEndpointIndex++;
      } else {
        console.log(`🔄 Network error, waiting ${delayMs/1000} seconds before retry...`);
        // Try next endpoint on general network errors
        currentEndpointIndex++;
      }
      
      // Wait before retry
      await new Promise(resolve => setTimeout(resolve, delayMs));
      
      if (retryCount >= maxRetries) {
        console.error("❌ Failed to send Telegram message after all retries");
        console.error(`Last error: ${err.message}`);
        console.error(`Tried endpoints: ${endpoints.slice(0, Math.min(currentEndpointIndex, endpoints.length)).join(', ')}`);
        updateErrorStats();
      }
    }
  }
}

// --- Handle Telegram Commands ---
async function handleTelegramMessage(update) {
  try {
    const message = update.message;
    if (!message || !message.text) return;

  const chatId = message.chat.id;
  const text = message.text.trim();
  const userName = message.from.first_name || message.from.username || 'Unknown User';

  // Check if user is authorized (optional - you can remove this check)
  // if (chatId.toString() !== TELEGRAM_CHAT_ID) return;

  console.log(`📨 Received command from ${userName}: ${text}`);

  if (text === '/start') {
    const welcomeMessage = `🚀 **Welcome to DropRaff Bot - Almi Monitor Bot!**

This bot monitors Base token transfers for addresses in your watchlist.

📝 **Available Commands:**
• \`/add <address>\` - Add address to watchlist
• \`/remove <address>\` - Remove address from watchlist
• \`/list\` - Show all addresses in watchlist
• \`/help\` - Show detailed help
• \`/status\` - Show bot status

**Quick Start:**
Use \`/add <address>\` to add a wallet address to monitor.

**Example:**
\`/add 0x1234567890123456789012345678901234567890\``;
    await sendTelegram(welcomeMessage, chatId);
  }
  else if (text.startsWith('/add ')) {
    const address = text.replace('/add ', '').trim();
    const result = addAddress(address);
    await sendTelegram(result.message, chatId);
  }
  else if (text.startsWith('/remove ')) {
    const address = text.replace('/remove ', '').trim();
    const result = removeAddress(address);
    await sendTelegram(result.message, chatId);
  }
  else if (text === '/list') {
    const listMessage = listAddresses();
    await sendTelegram(listMessage, chatId);
  }
  else if (text === '/help') {
    const helpMessage = `🤖 **DropRaff Monitor Bot Commands:**

📝 **Address Management:**
• \`/add <address>\` - Add address to watchlist
• \`/remove <address>\` - Remove address from watchlist
• \`/list\` - Show all addresses in watchlist

📊 **Info:**
• \`/help\` - Show this help message
• \`/status\` - Show bot status

**Examples:**
• \`/add 0x1234567890123456789012345678901234567890\`
• \`/remove 0x1234567890123456789012345678901234567890\`
• \`/list\``;
    await sendTelegram(helpMessage, chatId);
  }
  else if (text === '/status') {
    const statusMessage = `🤖 **Bot Status:**
📊 Monitoring: ${watchList.size} addresses
🔗 Network: Base (Chain ID 8453)
⏰ Uptime: ${Math.floor(process.uptime())} seconds
📝 Last update: ${new Date().toLocaleString()}`;
    await sendTelegram(statusMessage, chatId);
  }
  else if (text.startsWith('/')) {
    await sendTelegram("❓ Unknown command. Use /help to see available commands.", chatId);
  }
  } catch (error) {
    console.error("❌ Error handling Telegram message:", error.message);
    updateErrorStats();
  }
}

// --- Telegram Webhook/Updates Handler ---
let lastUpdateId = 0;

async function checkTelegramUpdates() {
  const endpoints = config.TELEGRAM_API_ENDPOINTS || ["https://api.telegram.org"];
  let currentEndpointIndex = 0;
  
  for (let attempt = 0; attempt < endpoints.length; attempt++) {
    try {
      const currentEndpoint = endpoints[currentEndpointIndex % endpoints.length];
      const url = `${currentEndpoint}/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${lastUpdateId + 1}&timeout=1`;
      
      const response = await axios.get(url, {
        timeout: config.TELEGRAM_TIMEOUT || 25000,
        headers: {
          'User-Agent': 'EtherDrops-Monitor/1.0',
          'Connection': 'keep-alive',
          'Accept': 'application/json'
        },
        // Advanced timeout configuration
        connectTimeout: config.TELEGRAM_CONNECT_TIMEOUT || 10000,
        socketTimeout: config.TELEGRAM_SOCKET_TIMEOUT || 60000,
        // Force IPv4 and allow self-signed certificates
        family: 4,
        rejectUnauthorized: false
      });
      
      const updates = response.data.result;
      
      if (updates && updates.length > 0) {
        for (const update of updates) {
          try {
            await handleTelegramMessage(update);
            lastUpdateId = update.update_id;
          } catch (updateError) {
            console.error("❌ Error processing update:", updateError.message);
            updateErrorStats();
          }
        }
      }
      
      // Success, exit loop
      return;
      
    } catch (err) {
      const currentEndpoint = endpoints[currentEndpointIndex % endpoints.length];
      
      // Only log errors that are not related to rate limiting, connection issues, or timeout
      if (err.response && err.response.status !== 409 && err.response.status !== 429) {
        console.error(`Error checking Telegram updates via ${currentEndpoint}:`, err.message);
        updateErrorStats();
      } else if (err.code === 'ECONNRESET' || err.code === 'ETIMEDOUT' || err.message.includes('timeout')) {
        // Silently ignore timeout errors for updates check - this is normal
        console.log(`📡 Updates check timeout via ${currentEndpoint}, trying next endpoint...`);
      }
      
      // Try next endpoint
      currentEndpointIndex++;
      
      // If we've tried all endpoints, exit
      if (attempt === endpoints.length - 1) {
        console.log(`📡 All Telegram endpoints failed for updates check`);
      }
    }
  }
}

// Network diagnostic function
async function diagnoseNetwork() {
  console.log("🔍 Running network diagnostics...");
  
  const endpoints = config.TELEGRAM_API_ENDPOINTS || ["https://api.telegram.org"];
  
  for (const endpoint of endpoints) {
    try {
      console.log(`📡 Testing ${endpoint}...`);
      const startTime = Date.now();
      
      const response = await axios.get(`${endpoint}/bot${TELEGRAM_BOT_TOKEN}/getMe`, {
        timeout: 10000,
        headers: { 'User-Agent': 'EtherDrops-Monitor/1.0' },
        family: 4,
        rejectUnauthorized: false
      });
      
      const latency = Date.now() - startTime;
      console.log(`✅ ${endpoint}: OK (${latency}ms)`);
      
      if (response.data && response.data.ok) {
        console.log(`🤖 Bot info: ${response.data.result.first_name} (@${response.data.result.username})`);
      }
      
    } catch (err) {
      console.log(`❌ ${endpoint}: ${err.message}`);
    }
  }
  
  // Test DNS resolution
  try {
    console.log("🌐 Testing DNS resolution...");
    const dnsStart = Date.now();
    const { lookup } = require('dns').promises;
    await lookup('api.telegram.org', { family: 4 });
    const dnsLatency = Date.now() - dnsStart;
    console.log(`✅ DNS resolution: OK (${dnsLatency}ms)`);
  } catch (err) {
    console.log(`❌ DNS resolution: ${err.message}`);
  }
  
  console.log("🔍 Network diagnostics completed");
}

// Run network diagnostics on startup
setTimeout(diagnoseNetwork, 5000);

// Check for Telegram messages
setInterval(checkTelegramUpdates, TELEGRAM_CHECK_INTERVAL);

// Connection monitoring
setInterval(() => {
  if (!isConnected) {
    console.log("⚠️ Connection lost, attempting to reconnect...");
    handleReconnect();
  }
}, 60 * 1000); // Check every minute

// Log startup completion
console.log(`✅ Bot initialization complete. Checking Telegram commands every ${TELEGRAM_CHECK_INTERVAL/1000} seconds.`);
console.log(`🔍 Connection monitoring enabled (every 1 minute)`);

// --- Get on-chain price ---
async function getOnChainPrice(tokenAddress, quoteAddress, amount, decimals) {
  try {
    if (!router || !provider || !isConnected) {
      console.log("⚠️ Router not ready, skipping price calculation");
      return 0;
    }
    
    // Validate inputs
    if (!tokenAddress || !quoteAddress || !amount || amount <= 0) {
      console.log("⚠️ Invalid inputs for price calculation");
      return 0;
    }
    
    // Validate addresses
    if (!ethers.isAddress(tokenAddress) || !ethers.isAddress(quoteAddress)) {
      console.log("⚠️ Invalid addresses for price calculation");
      return 0;
    }
    
    // Use coarse rounding for cache key to avoid cache misses
    const roundedAmount = amount > 1 ? Math.round(amount) : Number(amount.toFixed(6));
    const cacheKey = `${tokenAddress}|${quoteAddress}|${roundedAmount}`;
    const cached = priceCache.get(cacheKey);
    if (cached && Date.now() - cached.cachedAt < PRICE_TTL_MS) {
      return cached.price;
    }

    const amountIn = ethers.parseUnits(roundedAmount.toString(), decimals);
    const path = [tokenAddress, quoteAddress];
    
    // Add timeout to prevent hanging
    const amounts = await Promise.race([
      router.getAmountsOut(amountIn, path),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Price calculation timeout')), 5000)
      )
    ]);
    
    const price = Number(ethers.formatUnits(amounts[amounts.length - 1], 18));
    priceCache.set(cacheKey, { price, cachedAt: Date.now() });
    return price;
     } catch (error) {
     logError(`Price calculation failed: ${error.message}`);
     return 0;
   }
}

// --- Format address ---
function formatAddress(address) {
  try {
    if (!address || address.length < 8) return address;
    return `${address.slice(0, 4)}..${address.slice(-4)}`;
  } catch (error) {
    updateErrorStats();
    return address;
  }
}

// --- Get current timestamp ---
function getCurrentTimestamp() {
  try {
    const now = new Date();
    const day = String(now.getDate()).padStart(2, '0');
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const year = now.getFullYear();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    return `${day}/${month}/${year} ${hours}:${minutes}`;
  } catch (error) {
    updateErrorStats();
    return "Unknown Time";
  }
}

// --- Get wallet name ---
function getWalletName(address) {
  try {
    return WALLET_NAMES[address.toLowerCase()] || "Unknown Wallet";
  } catch (error) {
    updateErrorStats();
    return "Unknown Wallet";
  }
}

// --- Store pending transfers by transaction hash ---
const pendingTransfers = new Map();

// Error counters to reduce spam
let invalidLogCount = 0;
let lastErrorLogTime = 0;
const ERROR_LOG_INTERVAL = 60000; // Log errors only once per minute

// Caches to reduce RPC load
const tokenMetaCache = new Map(); // token -> { symbol, decimals, cachedAt }
const TOKEN_META_TTL_MS = 24 * 60 * 60 * 1000; // 24h
const priceCache = new Map(); // key(token|amountRounded) -> { price, cachedAt }
const PRICE_TTL_MS = 15 * 1000; // 15s

// Function to log errors with rate limiting
function logError(message) {
  invalidLogCount++;
  const now = Date.now();
  
  if (now - lastErrorLogTime > ERROR_LOG_INTERVAL) {
    console.log(`⚠️ ${message} (${invalidLogCount} total in last minute)`);
    lastErrorLogTime = now;
    invalidLogCount = 0;
  }
}

// --- Process and send grouped transfers ---
async function processPendingTransfers(txHash) {
  try {
    const transferData = pendingTransfers.get(txHash);
    if (!transferData || !transferData.transfers || transferData.transfers.length === 0) return;
    
    const transfers = transferData.transfers;

    // Clean up old pending transfers to prevent memory leak
    const now = Date.now();
    for (const [hash, transferData] of pendingTransfers.entries()) {
      if (now - transferData.timestamp > 60000) { // Remove transfers older than 1 minute
        pendingTransfers.delete(hash);
      }
    }

  // Group by wallet address
  const groupedByWallet = {};
  transfers.forEach(transfer => {
    const walletAddr = transfer.watchedAddress.toLowerCase();
    if (!groupedByWallet[walletAddr]) {
      groupedByWallet[walletAddr] = [];
    }
    groupedByWallet[walletAddr].push(transfer);
  });

  // Send message for each wallet
  for (const [walletAddr, walletTransfers] of Object.entries(groupedByWallet)) {
    const firstTransfer = walletTransfers[0];
    const walletName = getWalletName(walletAddr);
    const timestamp = getCurrentTimestamp();
    const walletLink = `https://basescan.org/address/${walletAddr}`;
    const txLink = `https://basescan.org/tx/${txHash}`;

    // Create wallet name with clickable address
    const walletDisplayName = walletName === "Unknown Wallet" ? `[${walletAddr}](${walletLink})` : `[${walletName}](${walletLink})`;
    let msg = `${walletDisplayName} · ETH\n`;

    // Add all transfers for this wallet
    walletTransfers.forEach((transfer, index) => {
      const tokenLink = `https://basescan.org/token/${transfer.tokenAddress}`;
      const otherAddressLink = `https://basescan.org/address/${transfer.otherAddress}`;
      
      if (transfer.usdPrice > 0) {
        msg += `${transfer.transactionType}: ${transfer.formattedAmount} [${transfer.symbol}](${tokenLink}) (~$${transfer.usdPrice.toFixed(4)}) `;
      } else {
        msg += `${transfer.transactionType}: ${transfer.formattedAmount} [${transfer.symbol}](${tokenLink}) `;
      }
      
      msg += `${transfer.toWatched ? 'From' : 'To'}: [${formatAddress(transfer.otherAddress)}](${otherAddressLink})`;
      
      if (index < walletTransfers.length - 1) {
        msg += '\n';
      }
    });

    msg += `\n[Tx hash](${txLink})`;

    // Add Maestro links for the first token (if not native)
    const firstTokenAddr = walletTransfers[0].tokenAddress;
    if (firstTokenAddr.toLowerCase() !== WBNB.toLowerCase()) {
      const maestroLink = `https://t.me/maestro?start=${firstTokenAddr}-maestroinvite`;
      const maestroProLink = `https://t.me/maestropro?start=${firstTokenAddr}-maestroinvite`;
      msg += ` · [Buy with Maestro](${maestroLink}) ([Pro](${maestroProLink}))`;
    }

    // --- Console output ---
    console.log(`\n${'='.repeat(80)}`);
    console.log(`🕐 ${timestamp}`);
    console.log(`👤 ${walletName}`);
    console.log(`📍 Address: ${walletAddr}`);
    console.log(`🔗 BaseScan: ${walletLink}`);
    
    walletTransfers.forEach(transfer => {
      console.log(`📊 ${transfer.transactionType}: ${transfer.formattedAmount} ${transfer.symbol}`);
      if (transfer.usdPrice > 0) {
        console.log(`💰 USD Value: ~$${transfer.usdPrice.toFixed(4)}`);
      }
      console.log(`🔗 ${transfer.toWatched ? 'From' : 'To'}: ${transfer.otherAddress}`);
    });
    
    console.log(`📝 Tx: ${txLink}`);
    console.log(`${'='.repeat(80)}\n`);

    // --- Send to Telegram ---
    await sendTelegram(msg);
    
    // Update transfer statistics
    updateTransferStats();
    resetErrorStats();
  }

  // Clean up
  pendingTransfers.delete(txHash);
  } catch (error) {
    console.error("❌ Error processing pending transfers:", error.message);
    updateErrorStats();
  }
}

// Memory cleanup function
function cleanupMemory() {
  try {
    const now = Date.now();
    let cleanedCount = 0;
    
    // Clean up old pending transfers
    for (const [hash, transferData] of pendingTransfers.entries()) {
      if (now - transferData.timestamp > 300000) { // Remove transfers older than 5 minutes
        pendingTransfers.delete(hash);
        cleanedCount++;
      }
    }
    
    if (cleanedCount > 0) {
      console.log(`🧹 Memory cleanup: removed ${cleanedCount} old pending transfers`);
    }
    
    // Force garbage collection if available
    if (global.gc) {
      global.gc();
    }
  } catch (error) {
    console.log("⚠️ Memory cleanup error:", error.message);
  }
}

// --- Health Monitoring ---
let lastTransferTime = Date.now();
let transferCount = 0;
let errorCount = 0;
let consecutiveErrors = 0;
let lastRestartTime = Date.now();
const RESTART_COOLDOWN = 5 * 60 * 1000; // 5 minutes

// Health check function
function healthCheck() {
  const now = Date.now();
  const uptime = Math.floor(process.uptime());
  const memoryUsage = process.memoryUsage();
  const memoryUsedMB = Math.round(memoryUsage.heapUsed / 1024 / 1024);
  const memoryTotalMB = Math.round(memoryUsage.heapTotal / 1024 / 1024);
  
  console.log(`\n${'='.repeat(60)}`);
  console.log(`🏥 HEALTH CHECK - ${new Date().toLocaleString()}`);
  console.log(`⏰ Uptime: ${Math.floor(uptime / 3600)}h ${Math.floor((uptime % 3600) / 60)}m ${uptime % 60}s`);
  console.log(`🔗 Connection Status: ${isConnected ? '✅ Connected' : '❌ Disconnected'}`);
  console.log(`📊 Transfers Processed: ${transferCount}`);
  console.log(`❌ Errors: ${errorCount} (Consecutive: ${consecutiveErrors})`);
  console.log(`💾 Memory Usage: ${memoryUsedMB}MB / ${memoryTotalMB}MB`);
  console.log(`📝 Watchlist Size: ${watchList.size}`);
  
  // Enhanced connection statistics
  console.log(`🔄 Connection Stats:`);
  console.log(`   Total Reconnects: ${totalReconnects}`);
  console.log(`   Watchdog Reconnects: ${watchdogReconnectCount}/${WATCHDOG_RECONNECT_THRESHOLD}`);
  console.log(`   WSS Failures: ${wssFailureCount}`);
  console.log(`   HTTPS Fallbacks: ${httpsFallbackCount}`);
  console.log(`   Connection Uptime: ${Math.floor(connectionUptime / 1000)}s`);
  console.log(`   Last Successful: ${lastSuccessfulConnection > 0 ? Math.floor((now - lastSuccessfulConnection) / 1000) + 's ago' : 'Never'}`);
  
  // Current endpoint info
  if (lastChosenEndpoint) {
    const endpointStat = getEndpointStat(lastChosenEndpoint.url);
    console.log(`🔗 Current Endpoint: ${lastChosenEndpoint.url} (${lastChosenEndpoint.type.toUpperCase()})`);
    console.log(`   Health: ${endpointStat.healthy ? '✅' : '❌'}`);
    console.log(`   Latency: ${endpointStat.latencyMs}ms`);
    console.log(`   Failures: ${endpointStat.failureCount}`);
  }
  
  // Memory threshold check
  if (memoryUsedMB > config.MEMORY_THRESHOLD && config.AUTO_RESTART) {
    console.log(`🚨 Memory usage (${memoryUsedMB}MB) exceeds threshold (${config.MEMORY_THRESHOLD}MB)`);
    if (now - lastRestartTime > RESTART_COOLDOWN) {
      console.log("🔄 Auto-restarting due to high memory usage...");
      lastRestartTime = now;
      setTimeout(() => {
        process.exit(1);
      }, 5000);
    }
  }
  
  // Watchdog status check
  if (shouldTriggerWatchdogRestart()) {
    console.log(`🚨 Watchdog restart conditions met!`);
    console.log(`   Reconnects: ${watchdogReconnectCount}/${WATCHDOG_RECONNECT_THRESHOLD}`);
    console.log(`   Time since last success: ${lastSuccessfulConnection > 0 ? Math.floor((now - lastSuccessfulConnection) / 60000) : 'Never'} minutes`);
  }
  
  if (now - lastTransferTime > 300000) { // 5 minutes
    console.log(`⚠️  No transfers detected in last 5 minutes`);
  }
  
  console.log(`${'='.repeat(60)}\n`);
}

// Run health check every 30 minutes
setInterval(healthCheck, 30 * 60 * 1000);

// Run memory cleanup every 10 minutes
setInterval(cleanupMemory, 10 * 60 * 1000);

// Graceful shutdown handling
process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);
process.on('uncaughtException', handleUncaughtException);
process.on('unhandledRejection', handleUnhandledRejection);

function gracefulShutdown() {
  console.log('\n🔄 Graceful shutdown initiated...');
  console.log('📊 Final Statistics:');
  console.log(`   Transfers: ${transferCount}`);
  console.log(`   Errors: ${errorCount}`);
  console.log(`   Uptime: ${Math.floor(process.uptime())} seconds`);
  console.log(`   Total Reconnects: ${totalReconnects}`);
  console.log(`   Watchdog Reconnects: ${watchdogReconnectCount}`);
  console.log(`   WSS Failures: ${wssFailureCount}`);
  console.log(`   HTTPS Fallbacks: ${httpsFallbackCount}`);
  console.log(`   Connection Uptime: ${Math.floor(connectionUptime / 1000)}s`);
  
  if (provider) {
    try {
      provider.destroy();
    } catch (error) {
      console.log("⚠️ Error destroying provider:", error.message);
    }
  }
  
  console.log('✅ Shutdown complete');
  process.exit(0);
}

function handleUncaughtException(error) {
  console.error('🚨 Uncaught Exception:', error);
  updateErrorStats();
  // Do not exit on WebSocket handshake HTTP errors; rotate endpoint instead
  if (error && error.message && error.message.includes('Unexpected server response')) {
    try {
      console.log('⚠️ Handshake error detected, rotating endpoint without exiting...');
      if (lastChosenEndpoint && lastChosenEndpoint.type === 'wss') {
        setEndpointStat(lastChosenEndpoint.url, { healthy: false, supportsSubscriptions: false });
      }
      isConnected = false;
      handleReconnect();
      return;
    } catch {}
  }
  // Ignore benign close-before-open from destroy during reconnection
  if (error && error.message && error.message.includes('WebSocket was closed before the connection was established')) {
    console.log('⚠️ Benign WebSocket close during reconnect; ignoring.');
    return;
  }
  
  if (config.AUTO_RESTART) {
    console.log('🔄 Auto-restarting due to uncaught exception...');
    setTimeout(() => {
      process.exit(1);
    }, 5000);
  } else {
    process.exit(1);
  }
}

function handleUnhandledRejection(reason, promise) {
  // Handle network errors specifically
  if (reason && reason.code === 'NETWORK_ERROR') {
    console.log('⚠️ Network error handled:', reason.message);
    // Don't count network errors as critical errors
    return;
  }
  // DNS/connection reset should not exit; rotate
  if (reason && (reason.code === 'ENOTFOUND' || reason.code === 'ECONNRESET')) {
    console.log('⚠️ Network transient error handled:', reason.message || reason.code);
    if (lastChosenEndpoint && lastChosenEndpoint.type === 'wss') {
      wssFailureCount++;
      if (wssFailureCount >= WSS_FAILURE_THRESHOLD) {
        wssDisableUntil = Date.now() + 10 * 60 * 1000;
        console.log("⏸️ WSS disabled temporarily for 10 minutes due to repeated failures");
        wssFailureCount = 0;
      }
    }
    isConnected = false;
    handleReconnect();
    return;
  }
  
  if (reason && reason.message && reason.message.includes('network is not available')) {
    console.log('⚠️ Network availability error handled:', reason.message);
    // Don't count network availability errors as critical errors
    return;
  }
  
  // Skip nodes that don't support eth_subscribe (common on some public WSS)
  if (reason && reason.message && reason.message.includes('eth_subscribe')) {
    console.log('⚠️ Endpoint does not support subscriptions, rotating...');
    try {
      if (lastChosenEndpoint && lastChosenEndpoint.type === 'wss') {
        setEndpointStat(lastChosenEndpoint.url, { healthy: false, supportsSubscriptions: false });
        wssFailureCount++;
        if (wssFailureCount >= WSS_FAILURE_THRESHOLD) {
          wssDisableUntil = Date.now() + config.WSS_DISABLE_DURATION;
          console.log(`⏸️ WSS disabled temporarily for ${config.WSS_DISABLE_DURATION / 60000} minutes due to repeated failures`);
          wssFailureCount = 0;
        }
      }
      isConnected = false;
      handleReconnect();
    } catch {}
    return;
  }
  
  console.error('🚨 Unhandled Rejection at:', promise, 'reason:', reason);
  updateErrorStats();
}

// Process monitoring
function updateTransferStats() {
  transferCount++;
  lastTransferTime = Date.now();
}

function updateErrorStats() {
  errorCount++;
  consecutiveErrors++;
  
  // Check if we need to restart due to too many consecutive errors
  if (consecutiveErrors >= config.MAX_CONSECUTIVE_ERRORS && config.AUTO_RESTART) {
    const now = Date.now();
    if (now - lastRestartTime > RESTART_COOLDOWN) {
      console.log(`🚨 Too many consecutive errors (${consecutiveErrors}). Auto-restarting...`);
      lastRestartTime = now;
      consecutiveErrors = 0;
      
      // Graceful shutdown and restart
      setTimeout(() => {
        process.exit(1); // Exit with error code to trigger restart
      }, 5000);
    }
  }
}

// Reset consecutive errors on successful operations
function resetErrorStats() {
  consecutiveErrors = 0;
}

// Initialize provider
initializeProvider();

console.log("🚀 DropRaff Monitor Bot Started!");
console.log(`📊 Monitoring ${watchList.size} addresses on Base`);
console.log("🤖 Telegram commands enabled:");
console.log("   /add <address> - Add address to watchlist");
console.log("   /remove <address> - Remove address from watchlist");
console.log("   /list - Show all addresses");
console.log("   /help - Show help message");
console.log("   /status - Show bot status");
console.log("🔍 Initializing Base WebSocket/HTTPS connection...");
console.log("🔄 Auto-reconnect enabled for 24/7 VPS operation");
console.log("🏥 Health monitoring enabled (every 30 minutes)");
