# 📱 Contoh Penggunaan Bot Telegram

## 🚀 Memulai Bot

1. Jalankan bot:
```bash
node index.js
```

2. Bot akan menampilkan:
```
✅ Loaded 2978 addresses to monitor.
🚀 EtherDrops Monitor Bot Started!
📊 Monitoring 2978 addresses on BSC
🤖 Telegram commands enabled:
   /add <address> - Add address to watchlist
   /remove <address> - Remove address from watchlist
   /list - Show all addresses
   /help - Show help message
   /status - Show bot status
🔍 Listening to all token transfers on BSC...
```

## 💬 Interaksi dengan Bot

### 1. Menambahkan Alamat Baru
Kirim pesan ke bot:
```
/add 0x1234567890123456789012345678901234567890
```

Bot akan merespons:
```
✅ Address 0x1234567890123456789012345678901234567890 added successfully!
```

### 2. Melihat Daftar Alamat
Kirim pesan:
```
/list
```

Bot akan merespons:
```
📝 Watchlist (2979 addresses):

1. HELLO MOTTHERFCKER (0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef)
2. 0x4C26F7Fdc32e91f469bFc54e1711E71CE3ea0f1C
3. 0x7427f499b1f18ace43ba6dfaeeeff5cf0496141e
...
2979. 0x1234567890123456789012345678901234567890
```

### 3. Menghapus Alamat
Kirim pesan:
```
/remove 0x1234567890123456789012345678901234567890
```

Bot akan merespons:
```
✅ Address 0x1234567890123456789012345678901234567890 removed successfully!
```

### 4. Cek Status Bot
Kirim pesan:
```
/status
```

Bot akan merespons:
```
🤖 Bot Status:
📊 Monitoring: 2978 addresses
🔗 Network: BSC (Binance Smart Chain)
⏰ Uptime: 3600 seconds
📝 Last update: 27/08/2025 12:30:45
```

### 5. Bantuan
Kirim pesan:
```
/help
```

Bot akan merespons dengan daftar lengkap perintah.

## 🔍 Monitoring Transaksi

Setelah bot berjalan, Anda akan menerima notifikasi transaksi seperti:

### Terminal Output:
```
================================================================================
🕐 27/08/2025 12:28
 HELLO MOTTHERFCKER
📍 Address: 0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef
 BSCScan: https://bscscan.com/address/0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef
📊 Received: 7,717,357 BRISE
 USD Value: ~$0.3928
🔗 From: 0x4c26f7fdc32e91f469bfc54e1711e71ce3ea0f1c
📝 Tx: https://bscscan.com/tx/0x6df7f3f937e13e25b213a57a65098e51ef3665c7a56f17dadfbd197889425a5e
================================================================================
```

### Telegram Message:
```
HELLO MOTTHERFCKER · BNB
Received: 7,717,357 BRISE (~$0.3928) From: 0x4c..0f1c
Tx hash · Buy with Maestro (Pro)
```

## ⚙️ Konfigurasi Lanjutan

### Mengubah Interval Pengecekan Telegram
Edit `config.js`:
```javascript
TELEGRAM_CHECK_INTERVAL: 1000  // 1 detik (default: 2000ms)
```

### Menambahkan Nama Wallet
Edit `config.js`:
```javascript
WALLET_NAMES: {
  "0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef": "HELLO MOTTHERFCKER",
  "0x1234567890123456789012345678901234567890": "My Wallet",
  // Tambahkan lebih banyak...
}
```

## 🚨 Troubleshooting

### Bot Tidak Merespons Commands
1. Pastikan bot token benar di `config.js`
2. Pastikan chat ID benar
3. Restart bot
4. Periksa koneksi internet

### Alamat Tidak Ditambahkan
1. Pastikan format alamat benar (0x + 40 karakter hex)
2. Periksa apakah alamat sudah ada dengan `/list`
3. Pastikan bot memiliki akses tulis ke file `address.txt`

### Notifikasi Tidak Muncul
1. Pastikan alamat ada di watchlist (`/list`)
2. Periksa koneksi ke BSC network
3. Pastikan ada transaksi yang terjadi

## 💡 Tips

1. **Backup**: Selalu backup file `address.txt` secara berkala
2. **Monitoring**: Gunakan `/status` untuk memantau kesehatan bot
3. **Batch Add**: Tambahkan beberapa alamat sekaligus dengan mengirim perintah berurutan
4. **Case Insensitive**: Bot menerima alamat dengan huruf besar/kecil
5. **Real-time**: Perubahan watchlist langsung aktif tanpa restart
