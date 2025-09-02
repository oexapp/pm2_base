# Panduan Singkat VPS (Ubuntu 22.04 LTS) — 24/7 Nonstop

Di bawah ini langkah-langkah paling sederhana dari nol (install Node.js) sampai bot aktif 24 jam memakai PM2.

## 1) Persiapan VPS
```bash
# Login ke VPS via SSH dari komputer Anda
ssh ubuntu@IP_VPS_ANDA

# Update paket
sudo apt update && sudo apt -y upgrade

# (Opsional) Instal alat dasar
sudo apt -y install curl git build-essential
```

## 2) Install Node.js LTS (Node 20)
Opsi termudah: NodeSource
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt -y install nodejs

# Cek versi
node -v
npm -v
```

## 3) Clone Project
```bash
cd ~
# Jika repo sudah ada di komputer Anda, bisa push ke Git lalu clone di VPS
# Contoh (ganti URL sesuai repositori Anda):
 git clone https://github.com/username/etherdrops-monitor.git
cd etherdrops-monitor
```

Jika tidak pakai Git, bisa upload file lewat SFTP lalu `cd` ke folder proyek.

## 4) Konfigurasi Bot
```bash
# Salin template config
cp config.example.js config.js

# Edit config.js dan isi token/URL sesuai kebutuhan
nano config.js
```
Simpan (Ctrl+O), Enter, dan keluar (Ctrl+X).

Tambahkan/cek `address.txt` (opsional):
```bash
[ -f address.txt ] || touch address.txt
```

## 5) Install Dependencies & Tes Jalan
```bash
npm install

# Tes jalan manual (lihat log di terminal)
node index.js
```
Jika sudah muncul log bot berjalan, hentikan dengan Ctrl+C (kita lanjut set 24/7 pakai PM2).

## 6) Jalankan 24/7 dengan PM2
```bash
# Instal PM2 (global)
sudo npm install -g pm2

# Start pakai file PM2 yang sudah disediakan
pm2 start ecosystem.config.js --env production

# Simpan proses agar otomatis start saat reboot
pm2 save

# Setup PM2 sebagai service systemd (ikuti instruksi yang keluar)
sudo pm2 startup systemd -u $USER --hp $HOME
```
Catatan: Setelah menjalankan perintah `pm2 startup`, PM2 biasanya menampilkan satu perintah tambahan. Copy‑paste perintah itu ke terminal, lalu jalankan `pm2 save` lagi jika diminta.

## 7) Cek Log & Status
```bash
# Lihat status proses
pm2 status

# Lihat log realtime (keluar dengan Ctrl+C)
pm2 logs etherdrops-monitor --lines 100

# Monitor CPU/RAM
pm2 monit
```

## 8) Perintah Berguna
```bash
# Restart bot
pm2 restart etherdrops-monitor

# Stop bot
pm2 stop etherdrops-monitor

# Hapus dari PM2
pm2 delete etherdrops-monitor

# Setelah update kode
git pull && npm install && pm2 restart etherdrops-monitor
```

## 9) Firewall (Opsional, Rekomendasi)
```bash
sudo apt -y install ufw
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status
```

## 10) Tips Penting
- Pastikan `config.js` sudah benar (token Telegram, RPC WSS, dsb.)
- Gunakan `pm2 logs` untuk melihat error jika ada masalah
- Bot sudah dilengkapi auto‑reconnect, health check, dan auto‑restart (melalui PM2)
- Simpan cadangan `config.js` dan `address.txt`

Selesai! Bot Anda sekarang berjalan 24/7 di VPS Ubuntu 22.04 LTS. 🎉
