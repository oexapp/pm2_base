module.exports = {
  apps: [{
    name: 'etherdrops-monitor',
    script: 'index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '900M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    // Restart on file changes (optional)
    ignore_watch: ['node_modules', 'logs', 'address.txt'],
    // Restart delay
    restart_delay: 5000,
    // Max restart attempts
    max_restarts: 10,
    // Min uptime before considering app stable
    min_uptime: '10s',
    // Max time to wait for app to start
    max_start_time: '60s', // Increased for better startup stability
    // Kill timeout
    kill_timeout: 10000, // Increased for graceful shutdown
    // Listen timeout
    listen_timeout: 30000, // Increased for network stability
    // Graceful shutdown
    shutdown_with_message: true,
    // Auto restart on crash
    autorestart: true,
    // Restart on memory threshold
    max_memory_restart: '900M',
    // Node options for better performance
    node_args: '--max-old-space-size=512',
    // Environment variables
    env_production: {
      NODE_ENV: 'production'
    }
  }]
};
