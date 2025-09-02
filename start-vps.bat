@echo off
chcp 65001 >nul
title EtherDrops Monitor Bot - VPS Startup

echo 🚀 Starting EtherDrops Monitor Bot on Windows VPS...

REM Check if PM2 is installed
pm2 --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 📦 Installing PM2 globally...
    npm install -g pm2
)

REM Create logs directory
if not exist "logs" mkdir logs

REM Check if config.js exists
if not exist "config.js" (
    echo ❌ config.js not found! Please copy from config.example.js and configure it first.
    pause
    exit /b 1
)

REM Check if address.txt exists
if not exist "address.txt" (
    echo 📝 Creating empty address.txt...
    type nul > address.txt
)

REM Install dependencies
echo 📦 Installing dependencies...
npm install

REM Start with PM2
echo 🔧 Starting bot with PM2...
pm2 start ecosystem.config.js --env production

REM Save PM2 configuration
pm2 save

echo.
echo ✅ Bot started successfully!
echo.
echo 📊 PM2 Commands:
echo    pm2 status                    - Check bot status
echo    pm2 logs etherdrops-monitor  - View logs
echo    pm2 restart etherdrops-monitor - Restart bot
echo    pm2 stop etherdrops-monitor   - Stop bot
echo    pm2 delete etherdrops-monitor - Remove from PM2
echo.
echo 🔍 Monitoring:
echo    pm2 monit                     - Monitor CPU/Memory usage
echo    pm2 dashboard                 - Web dashboard
echo.
echo 📝 Logs location: ./logs/
echo 🔄 Auto-restart enabled for 24/7 operation
echo 🏥 Health monitoring enabled
echo.
echo 🌐 Bot is now running and monitoring BSC transfers!
echo.
pause
