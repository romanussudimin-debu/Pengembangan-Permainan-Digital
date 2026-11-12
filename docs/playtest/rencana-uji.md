# Rencana Uji (Testing)

Centang ☐ → ☑ saat menguji di Godot. Catat bug di tabel paling bawah.

## 1. Fungsional: kontrol & fisika
| # | Uji | Hasil diharapkan | ☐ |
|---|---|---|---|
| F1 | WASD/panah | Nggohak berjalan ke 4 arah, model menghadap arah gerak | ☐ |
| F2 | Spasi | Melompat; tahan = lebih tinggi, ketuk = lebih rendah | ☐ |
| F3 | Lompat dari tepi batu sesaat setelah jatuh | Masih bisa melompat (coyote time) | ☐ |
| F4 | Naik batu pijakan 1 → 2 → 3 (barat daya) | Bisa dicapai; tidak tembus batu | ☐ |
| F4b | Masuk Mbaru Niang yang pintunya bercahaya (E) | Kartu didapat, cahaya pintu padam; masuk lagi → "sudah berkunjung" | ☐ |
| F5 | Menabrak Mbaru Niang, pohon, compang, dinding batas | Tertahan, tidak tembus | ☐ |
| F6 | Mendekati NPC | Muncul "[E] Bicara"; hanya objek terdekat yang menampilkan petunjuk | ☐ |

## 2. State management
| # | Uji | Hasil diharapkan | ☐ |
|---|---|---|---|
| S1 | Bicara ke NPC | Nggohak tidak bisa bergerak selama dialog; HUD tersembunyi | ☐ |
| S2 | Tekan Esc saat dialog | Menu jeda **tidak** terbuka | ☐ |
| S3 | Esc saat berjalan / saat duel | Game berhenti; Lanjutkan mengembalikan ke state semula | ☐ |
| S4 | Bicara ke Fransi sebelum mengalahkan Hingha | Dialog "kalahkan dulu pemain sebelumnya" | ☐ |
| S5 | Bicara ke lawan sebelum bertemu Tu'a Golo | Diarahkan menemui Tu'a Golo | ☐ |
| S6 | Kartu diambil lalu kembali dari arena | Kartu tidak muncul lagi; hitungan tetap | ☐ |

## 3. Mekanik caci
| # | Uji | Hasil diharapkan | ☐ |
|---|---|---|---|
| C1 | Tangkis tepat saat "!" merah | "Tertangkis! +1", SFX perisai | ☐ |
| C2 | Tidak menangkis | "Terkena!", lawan +2, layar bergetar | ☐ |
| C3 | Tekan K berulang-ulang | Stamina habis → "Stamina habis!" | ☐ |
| C4 | Lawan Fransi/Ema Agus | Kadang ada "Tipuan!" tanpa pukulan | ☐ |
| C5 | Tekan J di zona kuning / oranye / luar | Kena +2 / ditangkis / meleset | ☐ |
| C6 | Tidak menekan J selama 3 detik | "Terlambat!" | ☐ |
| C7 | Kalah | Muncul tombol Ulangi Duel / Kembali ke Kampung | ☐ |
| C8 | Menang 3 lawan → Tu'a Golo | Ending Penti tampil, ringkasan benar | ☐ |

## 3b. Jeda kopi & dialog bersuara
| # | Uji | Hasil diharapkan | ☐ |
|---|---|---|---|
| K1 | Selesai ronde 1 dan 2 | Ende Lono & Marngem berjalan membawa nampan kopi ke kedua pemain, lalu kembali; stamina penuh | ☐ |
| K2 | Bicara ke Ende Lono/Marngem di dekat arena | Dialog tentang kopi untuk pemain caci | ☐ |
| V1 | Bicara ke NPC mana pun | Dialog **terdengar** (bahasa Indonesia), hanya nama pembicara yang tampil, lalu lanjut otomatis | ☐ |
| V2 | Tekan E saat suara berbicara | Kalimat dilewati ke baris berikutnya | ☐ |
| V3 | Menu jeda → centang "Tampilkan teks dialog" | Teks dialog ikut tampil | ☐ |
| V4 | Komputer tanpa suara bahasa Indonesia | Teks dialog tampil otomatis (cadangan) | ☐ |

## 4. Audio, visual, stabilitas
| # | Uji | Hasil diharapkan | ☐ |
|---|---|---|---|
| A1 | Musik kampung/arena | Berganti dengan fade, berulang tanpa putus | ☐ |
| A2 | Slider volume di menu jeda | Volume musik/SFX berubah | ☐ |
| P1 | Main dari awal sampai ending | Tidak crash, tidak ada error merah di Output | ☐ |
| P2 | FPS (Debugger → Monitors) | Stabil ±60 fps di laptop biasa | ☐ |
| P3 | Build .exe dijalankan di luar Godot | Berjalan normal | ☐ |

## Daftar bug
| ID | Deskripsi | Langkah reproduksi | Keparahan | Status |
|---|---|---|---|---|
| | | | | |
