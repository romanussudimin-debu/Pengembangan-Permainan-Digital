# Rencana Uji (Testing)

Centang ☐ → ☑ saat menguji di Godot. Catat bug di tabel paling bawah.

## 1. Kontrol & fisika
| # | Uji | Hasil diharapkan | ☐ |
|---|---|---|---|
| F1 | WASD/panah | Nggohak berjalan ke 4 arah, menghadap arah gerak | ☐ |
| F2 | Spasi (tahan vs ketuk) | Lompat tinggi vs rendah | ☐ |
| F3 | Naik batu pijakan 1 → 2 → 3 (barat daya) | Bisa dicapai; tidak tembus | ☐ |
| F4 | Menabrak rumah, pohon, compang, batas dunia | Tertahan | ☐ |
| F5 | Mendekati warga | "[E] Bicara" hanya pada warga terdekat | ☐ |

## 2. Rantai teka-teki & state
| # | Uji | Hasil diharapkan | ☐ |
|---|---|---|---|
| R1 | Bicara ke warga selain Tu'a Golo di awal | "Kartuku belum bisa kuberikan sekarang" | ☐ |
| R2 | Tu'a Golo → jawab benar | Kartu Compang dibacakan; HUD menampilkan petunjuk ke Ine Wela | ☐ |
| R3 | Jawab salah | Saran membuka koleksi (Esc); bicara lagi → teka-teki diulang | ☐ |
| R4 | Ikuti 9 langkah sampai Tu'a Golo kedua | Ending Penti; kartu 9/9 | ☐ |
| R5 | Bicara ke warga yang sudah memberi kartu | "Terima kasih, Kraeng" | ☐ |
| S1 | Esc saat dialog/teka-teki | Menu jeda tidak terbuka | ☐ |
| S2 | Esc saat jalan / saat mini-game | Game berhenti; Lanjutkan kembali normal | ☐ |

## 3. Mini-game
| # | Uji | Hasil diharapkan | ☐ |
|---|---|---|---|
| T1 | Tenun: panah, E/Spasi, 1–4, klik mouse | Kursor bergerak, warna benang berganti | ☐ |
| T2 | Kain sama persis dengan contoh | "Kain songke selesai", kartu Songke | ☐ |
| T3 | Backspace saat menenun | Keluar; Ine Wela bisa dicoba lagi | ☐ |
| G1 | Tabuh: J/K tepat di garis | "Tepat!", suara gong/gendang | ☐ |
| G2 | Tepat < 60% | "Belum pas" → Fransi mengajak mencoba lagi | ☐ |
| G3 | Musik latar | Berhenti selama tabuh, lanjut setelahnya | ☐ |

## 4. Suara, visual, stabilitas
| # | Uji | Hasil diharapkan | ☐ |
|---|---|---|---|
| V1 | Dialog | Terdengar (bahasa Indonesia), hanya nama pembicara tampil, lanjut otomatis | ☐ |
| V2 | E saat berbicara | Dilewati | ☐ |
| V3 | Menu jeda → "Tampilkan teks dialog" | Teks ikut tampil | ☐ |
| V4 | Teka-teki | Pertanyaan & pilihan dibacakan; tombol 1/2/3 berfungsi | ☐ |
| E1 | Ending | Penari & dua penampil caci bergantian menyerang/menangkis | ☐ |
| P1 | Main dari awal sampai ending | Tidak crash, tidak ada error merah | ☐ |
| P2 | FPS | Stabil ±60 | ☐ |
| P3 | Build .exe/.app dijalankan di luar Godot | Normal | ☐ |

## Daftar bug
| ID | Deskripsi | Langkah reproduksi | Keparahan | Status |
|---|---|---|---|---|
| | | | | |
