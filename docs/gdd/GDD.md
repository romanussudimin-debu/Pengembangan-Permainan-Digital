# Game Design Document (GDD)
# *Jejak Penti di Wae Rebo*

| | |
|---|---|
| **Nama / NIM** | Romanus Sudimin / 240030260 |
| **Program studi** | Sistem Informasi |
| **Mata kuliah** | Pengembangan Permainan Digital — Rencana Tugas 1 |
| **Versi dokumen** | 4.0 (penyederhanaan: tantangan dipangkas, tanpa tempur & mode LAN) |
| **Engine** | Godot 4.3+ (renderer Compatibility) |
| **Platform** | Web (HTML5, termasuk browser HP), Windows (.exe), macOS, dan Android (.apk) |

---

## 1. Ringkasan

| Aspek | Keterangan |
|---|---|
| Judul | Jejak Penti di Wae Rebo |
| Genre | Petualangan jelajah budaya 3D orang ketiga dengan teka-teki dan mini-game |
| Target pemain | Remaja–dewasa (13+), pemain kasual, pelajar/mahasiswa yang ingin mengenal budaya Nusantara |
| Durasi main | ±12–18 menit (3 level + ending) |
| Pitch satu kalimat | Menjelang Penti, Nggohak mendaki ke kampung adat Wae Rebo, menjawab teka-teki Tu'a Golo, menenun songke, mengalirkan air ke lingko, lalu menjual songke penenun kampung kepada wisatawan di Labuan Bajo. |
| Unsur budaya | Wae Rebo & Mbaru Niang, compang, Penti, kain songke, lingko lodok & wae teku, Labuan Bajo/Taman Nasional Komodo, caci (pertunjukan di ending) |

### Riwayat revisi konsep
| Versi | Konsep | Alasan perubahan |
|---|---|---|
| 0.x | 2D: teka-teki lingko + duel caci | — |
| 1.x | 3D: jelajah kampung + duel caci | Lebih imersif |
| 2.0 | 3D: jelajah budaya dengan rantai teka-teki, menenun songke, tabuh gong-gendang; caci sebagai pertunjukan Penti | Duel caci terlalu sulit untuk pemain umum |
| 2.1–2.3 | + Level 2 Lingko Lodok, Level 3 Labuan Bajo, nyawa, pengecoh, tantangan aksi, bintang & pencapaian, analitik lokal | Masukan playtest dan persiapan 3 level |
| 3.0–3.1 | + Pertarungan busur panah (musuh, bos, skill, toko) dan Main Bersama LAN (co-op/PvP) | Masukan penguji yang menyukai genre bertarung |
| **4.0** | **Penyederhanaan**: tiap level hanya berisi tantangan inti; pertarungan, mode LAN/PvP, Mode Singkat, kesulitan Mudah, dan layar Isi Nama dihapus | Game terlalu panjang untuk prototipe tugas kuliah; fokus pada integrasi budaya, stabilitas, dan kejelasan alur |

## 2. Latar & Cerita
Nggohak, pemuda Manggarai, pulang ke kampung adat bergaya Wae Rebo menjelang **Penti** (tahun baru adat, syukur atas panen dan musim kerja baru). Ia mendaki jalan hutan ke kampung, lalu **Tu'a Golo** (tetua kampung) mengujinya dan menunjukkan jalan ke **Ine Wela**, penenun songke. Selanjutnya ia membantu **Tu'a Teno** mengairi **lingko**, lalu membawa songke titipan para penenun ke **Labuan Bajo** untuk dijual kepada wisatawan. Hasil penjualan dibawa pulang untuk perayaan Penti, yang ditutup dengan tarian warga dan pertunjukan **caci**.

## 3. Core Loop
```
 Jelajah 3D (jalan, lompat, hindari pengecoh) ──► Temui tokoh ──► Tantangan (teka-teki / mini-game / menjual)
            ▲                                                         │ berhasil
            │                                                         ▼
            └──────────── Petunjuk / tujuan berikutnya ◄── Kartu budaya (dibacakan, bisa dibaca ulang)
                         (salah/gagal → −1 nyawa; nyawa habis → ulangi tantangan itu saja)
```
Isi kartu budaya menjadi bekal untuk menjawab teka-teki dan pertanyaan wisatawan, sehingga loop bermain sekaligus menjadi **loop belajar**.

## 4. Mekanik Gameplay

### 4.1 Mekanik inti
| Mekanik | Di mana | Rincian |
|---|---|---|
| **Jelajah & platforming 3D** | Semua level | Berjalan, melompat (coyote time, jump buffer, tinggi lompatan bervariasi), collision 3D; jatuh ke sungai/jurang/lumpur/laut = −1 nyawa lalu kembali ke titik aman |
| **Teka-teki budaya** | L1 | Pilihan ganda 4 opsi, dibacakan dengan suara; jawab dengan klik, panah + Enter, atau 1–4 |
| **Menenun Songke** (mini-game 1) | L1 | Samakan kain 5×5 dengan contoh motif (dasar hitam, motif warna cerah); panah/WASD memilih kotak, E/klik mengganti warna benang; benang palsu/warna mirip = −1 nyawa |
| **Mengalirkan Air** (mini-game 2) | L2 | Putar potongan saluran agar air wae teku sampai ke kedua petak sawah; pipa retak membocorkan air |
| **Menjual Songke** (mini-game 3) | L3 | Pilih kain/foto yang cocok dengan keinginan wisatawan, lalu ceritakan maknanya (jawabannya ada di kartu budaya) |

### 4.2 Nyawa, pengecoh, dan umpan balik
- **Nyawa:** 5 (Normal) / 3 (Sulit), diisi penuh saat level atau destinasi Level 3 dimulai. −1 saat salah jawab, salah memilih pengecoh, jatuh, atau gagal tantangan (suara gagal, layar berkedip merah, kamera bergetar). Nyawa habis = **hanya tantangan yang sedang dimainkan yang diulang**. Penambah nyawa bertema budaya: kopi (L1), kelapa muda (L3).
- **Pengecoh yang adil:** batu retak dan jalan buntu (pendakian), pematang rapuh & batu goyah (lingko), bukan pembeli, kerang/bintang laut, dan batu goyah (Labuan Bajo). Semuanya bisa dibedakan bila pemain teliti.
- **Game feel:** percikan air/lumpur, debu mendarat, kilau emas, teks melayang ("−1", "+1", "Terjual!").
- **Bintang & pencapaian:** tiap tantangan ★1–3 dari nyawa yang hilang; 3 pencapaian: *Mata Elang* (tamat satu level tanpa kehilangan nyawa), *Sahabat Laut* (sampah Pink Beach tanpa mengganggu biota), *Penjual Andal* (satu destinasi tanpa salah barang/cerita).

### 4.3 Level 1 — Kampung Wae Rebo (data: `src/data/rantai_teka_teki.json`)
| # | Bagian | Tantangan | Kartu |
|---|---|---|---|
| 1 | Mendaki ke Wae Rebo | Platformer ngarai: **satu sungai** dengan batu pijakan, titian di atas jurang, tanjakan ke dataran tinggi, 3 titik cek. Pengecoh: **batu retak** (lebih gelap, bergaris) dan **cabang jalan buntu** (jalur utama bertiang bambu berkain merah) | — |
| 2 | Tu'a Golo (dekat compang) | Teka-teki: jumlah Mbaru Niang yang melingkari kampung → **Tujuh** (diamati) | Compang + Mbaru Niang |
| 3 | Ine Wela (alat tenun, sisi barat) | **Menenun songke**; petunjuk menuju Ine Wela: *"Jari-jarinya menyusun warna di atas dasar hitam. Carilah ia di sisi matahari terbenam."* | Kain Songke + Penti |

Warga lain (Ema Agus, Ende Lono, Fransi, Hingha, Marngem, Ema Yakobus) tetap hadir sebagai suasana kampung dan hanya menyapa. Compang hanya dilihat (sakral).

### 4.4 Level 2 — Lingko Lodok (data: `src/data/lingko.json`)
Latar di luar kampung, mewujudkan ungkapan *gendang one, lingko pe'ang*: lingko melingkar dengan **lodok** di pusat, pematang melingkar dan menjari. Sebagian pematang putus/rapuh sehingga pemain harus melompat.

| Tahap | Tujuan pemain | Mekanik | Kartu |
|---|---|---|---|
| 1. Sambut | Temui Tu'a Teno di lodok | Platforming di pematang | Lingko |
| 2. Wae teku | Alirkan air mata air ke dua petak | Mini-game **Mengalirkan Air** | Wae Teku |
| 3. Bukit batu | Naik bukit batu di barat daya, pandang lingko dari atas | Lompat batu bertingkat (ada batu goyah) + kamera pandang | Lingko Lodok |

### 4.5 Level 3 — Songke ke Labuan Bajo (data: `src/data/labuan_bajo.json`)
Warga menitipkan **songke tenunan penenun kampung** dan **foto budaya** (dari kartu yang sudah didapat). Nggohak ikut kapal wisata sebagai pemandu budaya. Peta kapal (tampak atas) → destinasi terbuka berurutan → scene pulau. Target **3 pembeli per destinasi**; ciri calon pembeli tampil di panel kanan; menawarkan kepada yang bukan pembeli = −1 nyawa. Kartu tambahan **Songke sebagai Ekonomi Kreatif** diberikan di awal Level 3.

| # | Destinasi | Mekanik khas | Kartu |
|---|---|---|---|
| 1 | Pelabuhan Labuan Bajo | Tutorial menjual | Labuan Bajo |
| 2 | Pulau Padar | Mendaki 3 pos; **tenaga** berkurang saat berjalan, minum di pos; jalan pintas dengan **batu goyah** | Pulau Padar |
| 3 | Pink Beach | Pantai + air dangkal; jangan injak karang; **wajib pungut 5 sampah**; kerang & bintang laut jangan diambil, penyu jangan disentuh | Pink Beach |

**Pesan wisata bertanggung jawab:** jaga jarak dari satwa, jangan menginjak karang, bawa pulang sampah, hargai karya penenun dengan harga yang adil. Setelah ketiga destinasi tuntas → **Pulang ke Wae Rebo** → ending Penti.

### 4.6 Kesulitan
| | Normal | Sulit |
|---|---|---|
| Nyawa | 5 | 3 |
| Batas waktu | — | "Sebelum senja" (L2) dan per destinasi (L3); jatuh mengurangi waktu |
| Lainnya | — | Salah cerita = wisatawan pergi; tenaga Padar lebih cepat habis |

**Progres:** tersimpan di `user://simpanan.cfg`; menu utama menampilkan **Lanjutkan** dan **Pilih Level** untuk level yang sudah terbuka.

### 4.7 Estimasi durasi (permainan pertama, Normal)
| Bagian | Isi | Perkiraan |
|---|---|---|
| Level 1 | Pendakian + teka-teki Tu'a Golo + menenun songke | 4–6 menit |
| Level 2 | Pematang + saluran air + bukit | 3–4 menit |
| Level 3 | 3 destinasi × 3 penjualan (+ tenaga Padar, sampah Pink Beach) | 5–7 menit |
| **Total** | termasuk ending Penti | **±12–18 menit** |

## 5. Kontrol
| Aksi | Keyboard / mouse | Layar sentuh (HP/tablet) |
|---|---|---|
| Bergerak | W A S D / panah | joystick virtual (separuh kiri layar) |
| Lompat | Spasi | tombol LOMPAT |
| Bicara / lanjut dialog | E / Enter (juga Spasi atau klik) | tombol BICARA; ketuk layar untuk lanjut |
| Jawab teka-teki | klik, panah + Enter, atau 1–4 | ketuk pilihan |
| Menenun / saluran air | panah/WASD, E/Spasi/klik | ketuk kotak |
| Jeda & koleksi kartu | Esc / P | tombol II (kanan atas) |
| Putar / zoom kamera | tahan klik kanan + geser / roda mouse | geser satu jari di separuh kanan / cubit; ketuk dua kali = kamera lurus |

## 6. State Management
- **GameState (autoload):** `MENU → BERMAIN ⇄ DIALOG`, `BERMAIN ⇄ JEDA`, `BERMAIN ⇄ MINIGAME`, `BERMAIN → SELESAI → MENU`. Transisi di luar `TRANSISI_SAH` ditolak. Sinyal `level_dimulai` dan `level_selesai` dipakai Analitik dan Nyawa.
- **FSM Pemain:** Idle, Jalan, Lompat, Jatuh, Interaksi (dikunci saat DIALOG).
- **FSM tahap Level 2:** SAMBUT → AIR → BUKIT → SELESAI.
- **FSM NPC & hewan:** DIAM/JALAN; **FSM Penampil Caci (ending):** Siaga, Ancang, Serang, Tangkis, Terkena.

## 7. Integrasi Budaya per Aspek
| Aspek | Wujud dalam game |
|---|---|
| **Mekanik** | Menenun motif songke; mengairi lingko dari wae teku; menjual songke dengan menceritakan maknanya; menghormati compang (hanya dilihat) |
| **Visual: lingkungan** | 7 Mbaru Niang melingkari compang, lingko berbentuk jaring laba-laba, Labuan Bajo, Padar, Pink Beach |
| **Visual: karakter** | Gaya anime 3D, kulit cokelat, rambut bergelombang, sarung songke; pemain caci dengan panggal, larik, nggiling (ending) |
| **Audio** | Musik pola gong-gendang sintetis; dialog diucapkan (TTS bahasa Indonesia) |
| **Narasi** | Bingkai Penti; sapaan *ité* dan *Kraeng*; ekonomi kreatif songke; wisata bertanggung jawab |
| **Edukasi** | 11 kartu budaya yang dibacakan dan dapat dibaca ulang di menu jeda |
| **Kepekaan** | Compang tidak dijadikan tempat bermain; caci ditampilkan sebagai pertunjukan, bukan pertarungan |

> **Tafsir kreatif [PERLU VERIFIKASI]:** motif belah ketupat 5×5 sebagai penyederhanaan motif songke; pola irama gong-gendang (bukan pola adat tertentu); detail jalur pendakian dan sistem tenaga Padar adalah adaptasi.

## 8. UI / HUD
- **Menu utama:** panorama 3D, Mulai Permainan, Lanjutkan, Pilih Level, Pencapaian, Mode Normal/Sulit, Cara Bermain, Tentang, Layar Penuh, Keluar.
- **HUD:** tujuan/petunjuk aktif, ikon nyawa (hati), jumlah kartu.
- **Dialog bersuara**, panel teka-teki, overlay mini-game bermotif songke, layar "Level N berhasil", menu jeda (volume, teks dialog, koleksi kartu).

## 9. Gaya Visual & Audio
Low-poly prosedural dari mesh primitif Godot; tekstur pixel 64×64 buatan sendiri (`tools/generate_textures.py`). Palet: hitam `#1B1818`, merah `#B02A2A`, kuning `#E8B430`, hijau `#2E7D46`, biru `#2C5C96`, krem `#E8E2D2`. Audio disintesis (`tools/generate_audio.py`).

## 10. Prinsip Animasi
| Prinsip | Penerapan |
|---|---|
| Anticipation | Penampil caci menarik larik ke belakang sebelum memukul |
| Timing | Ancang-ancang lambat vs pukulan cepat |
| Follow-through | Lengan dan larik melewati target lalu kembali dengan easing |
| Squash & stretch | Stretch saat melompat, squash saat mendarat; teks umpan balik "meletup" |
| Ease in/out | Transisi layar, kamera pandang lingko |
| Secondary action | Napas saat idle, ayunan lengan, penari Penti, ekor anjing bergoyang, ayam mematuk |

## 11. Analitik (event tracking)
Event `level_completed` dicatat lokal ke `user://analitik/event_log.json` (tanpa internet dan tanpa data pribadi). Rincian field ada di `docs/event-tracking.md`.

## 12. Arsitektur Teknis
```
src/
├─ scenes/        opening, main_menu, pendakian, kampung, lingko, peta_kapal, pulau, level_selesai, ending, pemain, penampil_caci
├─ scripts/
│  ├─ autoload/   Kontrol, GameState, AudioManager, Transisi, DialogManager, Nyawa, Prestasi, Analitik, MenuJeda, KontrolSentuh, Layar
│  ├─ state_machine/  StateMachine + StateDasar
│  ├─ karakter/   KarakterModel (model prosedural + animasi)
│  ├─ pemain/     Pemain + states
│  ├─ caci/       PenampilCaci + states
│  ├─ dunia/      builder dunia, pendakian, kampung, lingko, pulau, NPC, hewan, kamera
│  ├─ minigame/   TenunSongke, SaluranAir, JualSongke
│  ├─ ui/         hud, main_menu, peta_kapal, level_selesai, ending
│  └─ util/       Gaya, Efek, DataLabuanBajo
├─ data/          rantai_teka_teki, kartu_budaya, dialog, lingko, labuan_bajo, level, pencapaian (.json)
└─ assets/        textures/, audio/
```
Konten (tantangan, pertanyaan, jawaban, petunjuk, isi kartu, wisatawan) terpisah dari kode sehingga dapat diubah tanpa pemrograman.
