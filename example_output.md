# Contoh Output Bot

## Format Terminal (Console)
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

## Format Telegram
```
HELLO MOTTHERFCKER · BNB
Received: 7,717,357 BRISE (~$0.3928) From: 0x4c..0f1c
Tx hash · Buy with Maestro (Pro)
```

**Catatan:** 
- Nama wallet (HELLO MOTTHERFCKER) adalah link ke BSCScan address
- Jika wallet tidak dikenal, akan menampilkan alamat lengkap sebagai link
- Semua teks yang terlihat sebagai link (BRISE, 0x4c..0f1c, Tx hash, Buy with Maestro, Pro) adalah link yang dapat diklik

## Multiple Transfers dalam Satu Transaksi
```
HELLO MOTTHERFCKER · BNB
Terkirim: 6,791,274 BRISE (~$0.3457) To: 0x4c..0f1c
Terkirim: 926,083 BRISE (~$0.0471) To: 0x8f..8e83
Tx hash · Buy with Maestro (Pro)
```

## Transaksi BNB (tanpa link Maestro)
```
HELLO MOTTHERFCKER · BNB
Terkirim: 0.000353622164562006 BNB (~$0.3057) To: 0x4c..0f1c
Tx hash
```

## Wallet Tidak Dikenal (Unknown Wallet)
```
0x4C26F7Fdc32e91f469bFc54e1711E71CE3ea0f1C · BNB
Received: 1,000,000 TOKEN (~$50.0000) From: 0x8f..8e83
Tx hash · Buy with Maestro (Pro)
```

**Catatan:** Untuk wallet yang tidak ada di mapping, alamat lengkap akan ditampilkan sebagai link

## Catatan
- Semua link dapat diklik langsung dari pesan Telegram
- Link Maestro hanya muncul untuk token (bukan BNB)
- Multiple transfers dalam satu transaksi akan dikelompokkan
- Harga USD dihitung secara real-time menggunakan PancakeSwap
- Format pesan bersih dan mudah dibaca seperti di gambar
