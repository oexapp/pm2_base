# EtherDrops Monitor Bot

Bot monitoring untuk transaksi token BSC yang mengirim notifikasi ke Telegram dengan format yang mirip dengan Drops Bot.

## Fitur

- ✅ Monitor semua transfer token ERC-20 di BSC
- ✅ Format pesan Telegram yang mirip dengan Drops Bot
- ✅ Output terminal yang informatif
- ✅ Support multiple transfers dalam satu transaksi
- ✅ Link ke BSCScan untuk token, wallet, dan transaksi
- ✅ Link Maestro untuk trading
- ✅ Perhitungan harga USD real-time
- ✅ Mapping nama wallet yang dapat dikustomisasi
- ✅ Format pesan yang bersih dengan link yang dapat diklik
- ✅ Bot Telegram commands untuk mengelola watchlist
- ✅ **VPS Ready** - Auto-reconnect, health monitoring, dan auto-restart untuk 24/7 operation

## Instalasi

1. Clone repository ini
2. Install dependencies:
```bash
npm install
```

3. Buat file konfigurasi:
   ```bash
   cp config.example.js config.js
   ```
   
4. Edit file `config.js` dan sesuaikan konfigurasi:
   - `TELEGRAM_BOT_TOKEN`: Token bot Telegram Anda
   - `TELEGRAM_CHAT_ID`: ID chat Telegram untuk mengirim notifikasi
   - `WALLET_NAMES`: Mapping nama wallet (opsional)

5. Edit file `address.txt` dan tambahkan alamat wallet yang ingin dimonitor (satu alamat per baris)

## Konfigurasi

### Telegram Bot
1. Buat bot baru dengan [@BotFather](https://t.me/botfather)
2. Dapatkan token bot
3. Dapatkan chat ID dengan mengirim pesan ke bot dan mengunjungi:
   `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`

### Wallet Names
Edit bagian `WALLET_NAMES` di `config.js` untuk menambahkan nama wallet:
```javascript
WALLET_NAMES: {
  "0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef": "HELLO MOTTHERFCKER",
  "0x4C26F7Fdc32e91f469bFc54e1711E71CE3ea0f1C": "Another Wallet",
  // Tambahkan lebih banyak sesuai kebutuhan
}
```

## Menjalankan Bot

### **Development/Local:**
```bash
node index.js
```

### **Production/VPS (Recommended):**
```bash
# Linux/Mac
chmod +x start-vps.sh
./start-vps.sh

# Windows
start-vps.bat

# Manual PM2
pm2 start ecosystem.config.js --env production
```

## Format Output

### Terminal Output
```
================================================================================
🕐 27/08/2025 12:28
👤 HELLO MOTTHERFCKER
📍 Address: 0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef
🔗 BSCScan: https://bscscan.com/address/0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef
📊 Received: 7,717,357 BRISE
💰 USD Value: ~$0.3928
🔗 From: 0x4c26f7fdc32e91f469bfc54e1711e71ce3ea0f1c
📝 Tx: https://bscscan.com/tx/0x6df7f3f937e13e25b213a57a65098e51ef3665c7a56f17dadfbd197889425a5e
================================================================================
```

### Telegram Message
```
HELLO MOTTHERFCKER · BNB
Received: 7,717,357 BRISE (~$0.3928) From: 0x4c..0f1c
Tx hash · Buy with Maestro (Pro)
```

**Catatan:** 
- Nama wallet (HELLO MOTTHERFCKER) adalah link ke BSCScan address
- Jika wallet tidak dikenal, akan menampilkan alamat lengkap sebagai link
- Semua teks yang terlihat sebagai link (BRISE, 0x4c..0f1c, Tx hash, Buy with Maestro, Pro) adalah link yang dapat diklik

## Bot Telegram Commands

Bot dapat menerima perintah langsung dari Telegram untuk mengelola watchlist:

### 📝 **Address Management:**
- `/add <address>` - Tambahkan alamat ke watchlist
- `/remove <address>` - Hapus alamat dari watchlist
- `/list` - Tampilkan semua alamat dalam watchlist

### 📊 **Info:**
- `/help` - Tampilkan bantuan
- `/status` - Tampilkan status bot

### 💡 **Contoh Penggunaan:**
```
/add 0x1234567890123456789012345678901234567890
/remove 0x1234567890123456789012345678901234567890
/list
/status
```

## Struktur File

- `index.js` - File utama bot
- `config.js` - File konfigurasi (buat dari config.example.js)
- `config.example.js` - Template konfigurasi
- `address.txt` - Daftar alamat wallet yang dimonitor
- `package.json` - Dependencies dan konfigurasi npm
- `start.bat` - Script untuk menjalankan bot di Windows
- `start.sh` - Script untuk menjalankan bot di Linux/Mac
- `start-vps.sh` - Script VPS startup untuk Linux/Mac dengan PM2
- `start-vps.bat` - Script VPS startup untuk Windows dengan PM2
- `ecosystem.config.js` - Konfigurasi PM2 untuk production deployment
- `BOT_COMMANDS.md` - Dokumentasi lengkap bot Telegram commands
- `TROUBLESHOOTING.md` - Panduan troubleshooting dan error handling
- `VPS_DEPLOYMENT.md` - Panduan lengkap deployment di VPS untuk 24/7 operation
- `README.md` - Dokumentasi ini

## Dependencies

- `ethers` - Library untuk berinteraksi dengan blockchain
- `axios` - HTTP client untuk mengirim pesan ke Telegram
- `fs` - File system untuk membaca file address.txt

## Catatan

- Bot menggunakan WebSocket untuk monitoring real-time
- Delay 2 detik untuk mengumpulkan multiple transfers dalam satu transaksi
- Harga USD dihitung menggunakan PancakeSwap router
- Link Maestro hanya ditampilkan untuk token (bukan BNB)

## Troubleshooting

1. **Bot tidak mengirim pesan ke Telegram**: Periksa token bot dan chat ID
2. **Tidak ada notifikasi**: Pastikan alamat wallet ada di `address.txt`
3. **Error koneksi**: Periksa koneksi internet dan RPC endpoint
4. **Harga tidak muncul**: Token mungkin tidak memiliki liquidity di PancakeSwap

## Lisensi

ISC
