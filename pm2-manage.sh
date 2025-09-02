#!/bin/bash

# PM2 management helper for EtherDrops Monitor (Base)
# Actions: start | save | startup | status | logs

set -e

APP_DIR="/root/etherdrops-monitor-base"
PM2_APP_NAME="etherdrops-monitor-base"

usage() {
  echo "Usage: $0 {start|save|startup|status|logs}"
  exit 1
}

ACTION="$1"
if [ -z "$ACTION" ]; then
  usage
fi

case "$ACTION" in
  start)
    echo "🚀 Starting $PM2_APP_NAME via PM2..."
    cd "$APP_DIR"
    if [ ! -f "ecosystem.config.js" ]; then
      echo "❌ Missing ecosystem.config.js in $APP_DIR"; exit 1;
    fi
    pm2 start ecosystem.config.js --env production --only "$PM2_APP_NAME" || pm2 restart "$PM2_APP_NAME"
    echo "✅ Started."
    ;;

  save)
    echo "💾 Saving current PM2 process list..."
    pm2 save
    echo "✅ Saved."
    ;;

  startup)
    echo "🧩 Enabling PM2 startup with systemd for root..."
    pm2 startup systemd -u root --hp /root || true
    # Try to enable generated unit (idempotent)
    systemctl enable pm2-root || true
    echo "💾 Saving current PM2 process list for resurrection..."
    pm2 save
    echo "✅ PM2 will resurrect on reboot."
    ;;

  status)
    pm2 status "$PM2_APP_NAME"
    ;;

  logs)
    pm2 logs "$PM2_APP_NAME" --lines 100
    ;;

  *)
    usage
    ;;
esac


