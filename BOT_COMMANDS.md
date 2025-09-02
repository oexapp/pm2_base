# 🤖 EtherDrops Monitor Bot Commands

Bot Telegram ini dapat menerima perintah langsung untuk mengelola watchlist alamat wallet.

## 📝 Address Management Commands

### `/add <address>`
Menambahkan alamat wallet ke watchlist.

**Contoh:**
```
/add 0x1234567890123456789012345678901234567890
/add 0x4C26F7Fdc32e91f469bFc54e1711E71CE3ea0f1C
```

**Response:**
- ✅ `Address 0x1234...7890 added successfully!` - Berhasil ditambahkan
- ⚠️ `Address 0x1234...7890 already exists in watchlist.` - Sudah ada
- ❌ `Invalid address format: 0x1234` - Format alamat salah

### `/remove <address>`
Menghapus alamat wallet dari watchlist.

**Contoh:**
```
/remove 0x1234567890123456789012345678901234567890
/remove 0x4C26F7Fdc32e91f469bFc54e1711E71CE3ea0f1C
```

**Response:**
- ✅ `Address 0x1234...7890 removed successfully!` - Berhasil dihapus
- ⚠️ `Address 0x1234...7890 not found in watchlist.` - Tidak ditemukan

### `/list`
Menampilkan semua alamat dalam watchlist.

**Contoh:**
```
/list
```

**Response:**
```
📝 Watchlist (3 addresses):

1. HELLO MOTTHERFCKER (0x60c3ec77930bc87b1f9c3357dcf1428d51c1d1ef)
2. 0x4C26F7Fdc32e91f469bFc54e1711E71CE3ea0f1C
3. 0x7427f499b1f18ace43ba6dfaeeeff5cf0496141e
```

## 📊 Info Commands

### `/help`
Menampilkan bantuan dan daftar semua perintah yang tersedia.

**Contoh:**
```
/help
```

### `/status`
Menampilkan status bot dan informasi monitoring.

**Contoh:**
```
/status
```

**Response:**
```
🤖 Bot Status:
📊 Monitoring: 5 addresses
🔗 Network: BSC (Binance Smart Chain)
⏰ Uptime: 3600 seconds
📝 Last update: 27/08/2025 12:30:45
```

## 🔧 Technical Details

### Address Validation
- Bot akan memvalidasi format alamat Ethereum/BSC
- Alamat akan disimpan dalam format lowercase
- Duplikasi alamat akan dicegah

### File Management
- Perubahan watchlist akan otomatis disimpan ke `address.txt`
- Bot akan memuat ulang watchlist secara real-time
- Backup otomatis saat menambah/menghapus alamat

### Response Time
- Bot memeriksa pesan Telegram setiap 2 detik (dapat dikonfigurasi)
- Response biasanya dalam 1-3 detik
- Tidak ada delay untuk perintah sederhana

## 🚨 Error Handling

### Common Errors:
- **Invalid address format** - Pastikan alamat dimulai dengan `0x` dan memiliki 40 karakter hex
- **Address already exists** - Alamat sudah ada di watchlist
- **Address not found** - Alamat tidak ditemukan saat menghapus
- **Unknown command** - Perintah tidak dikenali, gunakan `/help`

### Troubleshooting:
1. Pastikan bot token dan chat ID sudah benar di `config.js`
2. Pastikan bot sudah ditambahkan ke grup/chat
3. Periksa koneksi internet
4. Restart bot jika ada masalah

## 💡 Tips Penggunaan

1. **Batch Operations**: Anda dapat menambahkan beberapa alamat sekaligus dengan mengirim perintah `/add` berurutan
2. **Address Format**: Bot menerima alamat dengan atau tanpa `0x` prefix
3. **Case Insensitive**: Alamat akan disimpan dalam lowercase
4. **Real-time Updates**: Perubahan watchlist langsung aktif tanpa restart bot
5. **Backup**: File `address.txt` selalu terupdate otomatis

## 🔒 Security Notes

- Bot hanya merespons perintah yang dimulai dengan `/`
- Semua alamat akan divalidasi sebelum disimpan
- File `address.txt` dapat di-backup secara manual
- Bot tidak menyimpan log perintah untuk keamanan
