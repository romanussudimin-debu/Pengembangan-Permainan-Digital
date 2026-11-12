# Game Design Document (GDD)
# *Jejak Penti di Wae Rebo*

| | |
|---|---|
| **Nama / NIM** | [NAMA] / [NIM] |
| **Mata kuliah** | Pengembangan Permainan Digital — Rencana Tugas 1 |
| **Versi dokumen** | 2.0 (revisi konsep: dari duel caci menjadi jelajah budaya) |
| **Engine** | Godot 4.3+ (renderer Compatibility) |
| **Platform** | Windows (.exe), macOS, dan Web (HTML5) |

---

## 1. Ringkasan

| Aspek | Keterangan |
|---|---|
| Judul | Jejak Penti di Wae Rebo |
| Genre | Petualangan jelajah budaya 3D orang ketiga dengan rantai teka-teki dan mini-game |
| Target pemain | Remaja–dewasa (13+), pemain kasual, pelajar/mahasiswa yang ingin mengenal budaya Nusantara |
| Durasi main | ±10–15 menit |
| Pitch satu kalimat | Menjelang Penti, Nggohak menelusuri kampung adat Wae Rebo, menemui delapan warga secara berurutan, lalu menjawab teka-teki, menenun songke, dan menabuh gong-gendang untuk mengumpulkan sembilan kartu pengetahuan budaya. |
| Unsur budaya | Mbaru Niang & Wae Rebo, compang, Penti, kain songke, gong-gendang & nyanyian adat (sanda, mbata, danding), caci (pertunjukan) |

### Riwayat revisi konsep
| Versi | Konsep | Alasan perubahan |
|---|---|---|
| 0.x | 2D: teka-teki lingko + duel caci | — |
| 1.x | 3D: jelajah kampung + duel caci (ta'ang/paki, 3 lawan) | Lebih imersif |
| **2.0** | **3D: jelajah budaya dengan rantai teka-teki, menenun songke, tabuh gong-gendang; caci sebagai pertunjukan Penti** | Duel caci dinilai terlalu sulit untuk pemain umum. Jelajah budaya mengenalkan lebih banyak unsur budaya. Caci tetap tampil dengan hormat sebagai pertunjukan. |

## 2. Latar & Cerita
Nggohak, pemuda Manggarai, pulang ke kampung adat bergaya Wae Rebo menjelang **Penti** (tahun baru adat, syukur pergantian musim kerja). Menurut **Tu'a Golo** (tetua kampung), setiap warga menyimpan satu **kartu pengetahuan budaya**. Kartu harus dikumpulkan **berurutan**. Setiap warga memberi tantangan, dan setelah berhasil, ia menunjukkan siapa yang harus ditemui berikutnya. Setelah semua kartu terkumpul, Penti dimulai: warga menari dan dua pemuda menampilkan **caci**.

## 3. Core Loop
```
 Temui warga yang ditunjuk petunjuk ──► Tantangan (teka-teki / tenun / tabuh)
            ▲                                         │ berhasil
            │                                         ▼
 Jelajahi kampung 3D ◄── Petunjuk ke warga berikutnya ◄── Kartu budaya (dibacakan)
                         (salah/gagal → ingat isi kartu, coba lagi)
```
Pengetahuan dari setiap kartu menjadi bekal untuk menjawab teka-teki berikutnya, sehingga loop ini sekaligus menjadi **loop belajar**.

## 4. Mekanik Gameplay

### 4.1 Mekanik 1 — Rantai Teka-teki & Jelajah
| Komponen | Rincian |
|---|---|
| Tujuan | Menafsirkan petunjuk berupa teka-teki untuk menemukan warga berikutnya, lalu menjawab tantangannya |
| Petunjuk | Diucapkan warga dan tampil di HUD. Petunjuk **tidak menyebut nama atau lokasi secara langsung**, tetapi ciri orang atau rumah, misalnya *"Di depan sebuah rumah, sehelai kain berdasar hitam dijemur… Pemiliknya tidak berada di luar."* |
| Di dalam rumah | Ketujuh Mbaru Niang **dapat dimasuki** lewat pintunya. Atap menghilang saat pemain di dalam (tampilan potong) sehingga lantai, tungku api, dan tikar terlihat. **Tiga pemegang kartu menunggu di dalam rumah** yang urutannya tidak bersebelahan (utara → timur laut → barat daya); rumah lain kosong sebagai pengecoh. Rumah dikenali dari cirinya: paling besar (mbaru gendang), **jemuran kain songke**, atau **tumpukan kayu bakar**. |
| Warga bergerak | Fransi mondar-mandir di antara tiga titik; **Hingha dan Marngem bertukar tempat** bolak-balik di sekitar arena (FSM DIAM/JALAN). Warga berhenti saat diajak bicara. |
| Urutan | Warga yang belum gilirannya menolak dengan sopan; warga yang sudah memberi kartu mengucapkan terima kasih |
| Teka-teki | Pilihan ganda **4 opsi** dengan pengecoh mirip (misalnya *sanda/mbata/danding*, *lobo/lentar/lempa rae*), dibacakan dengan suara; jawab dengan klik, panah + Enter, atau 1–4. Jawabannya ada di isi kartu, termasuk kartu yang didapat jauh sebelumnya. Teka-teki pertama menuntut pengamatan (menghitung Mbaru Niang). |
| Salah | Warga menyarankan membuka koleksi kartu (Esc) lalu kembali lagi |
| Gerak | Berjalan, melompat (coyote time, jump buffer, tinggi variabel), batu pijakan bertingkat 1–3 m |

### 4.2 Mekanik 2 — Menenun Songke (teka-teki pola)
| Komponen | Rincian |
|---|---|
| Tujuan | Menyamakan kain 5×5 dengan contoh motif belah ketupat (dasar hitam, cincin kuning, merah, pusat hijau) |
| Kontrol | Panah/WASD memilih kotak; E/Spasi atau klik mengganti warna benang; 1–4 memilih warna langsung; Backspace berhenti |
| Umpan balik | Jumlah kotak yang belum sama, jumlah langkah, warna terpilih; SFX klik; selesai otomatis saat kain sama persis |

### 4.3 Mekanik 3 — Tabuh Gong-Gendang (ritme)
| Komponen | Rincian |
|---|---|
| Tujuan | Menabuh mengikuti irama untuk mengiringi Penti |
| Kontrol | **J** = gong, **K** = gendang |
| Aturan | 18 ketukan bergerak dari kanan ke garis tabuh (tempo 76 BPM). Tepat bila ditekan ±0,2 detik dari ketukan. Lulus bila ≥ 60% tepat; bila gagal, coba lagi. |
| Umpan balik | Suara gong/gendang setiap tabuhan, teks "Tepat!/Luput" yang meletup, skor berjalan; musik latar dijeda selama mini-game |

### 4.4 Urutan rantai (data: `src/data/rantai_teka_teki.json`)
| # | Warga (keberadaan) | Tantangan → jawaban | Kartu | Petunjuk ke berikutnya (ringkas) |
|---|---|---|---|---|
| 1 | Tu'a Golo (luar, dekat compang) | Jumlah Mbaru Niang → **Tujuh** (diamati) | Compang | Penyusun warna di atas hitam, sisi matahari terbenam |
| 2 | Ine Wela (luar, alat tenun di barat) | **Menenun songke** | Kain Songke | Rumah paling besar penyimpan pusaka, penjaga di dekat api |
| 3 | Ema Agus (**di dalam** mbaru gendang, utara) | Motif hewan penenun jaring → **Ranggong** | Mbaru Niang | Kain berdasar hitam dijemur di depan rumah |
| 4 | Ende Lono (**di dalam** rumah berjemuran songke, timur laut) | Tingkat penyimpan benih → **Lentar** | Kampung Wae Rebo | Benda bulat bersuara dalam; penabuhnya tak pernah diam |
| 5 | Fransi (**berpindah-pindah** di sekitar gong) | **Tabuh gong-gendang** | Gong, Gendang & Nyanyian | Pemakai panggal yang masih muda di timur, suka bertukar tempat |
| 6 | Hingha (**bertukar tempat** di arena) | Nyanyian sambil duduk diiringi gong → **Mbata** | Caci: Paki & Ta'ang | "Hitam, pahit, menghangatkan", dibawa di atas nampan |
| 7 | Marngem (**bertukar tempat** dengan Hingha) | Sasaran sah pukulan → **Di atas pinggang** | Perlengkapan Caci | Pemain tertua beristirahat; kayu bakar di depan pintu |
| 8 | Ema Yakobus (**di dalam** rumah berkayu bakar, barat daya) | Hiasan ekor di pinggang → **Ndeki** | Nilai Sportivitas Caci | Dia yang pertama menyambut, di samping batu yang tak boleh dipijak |
| 9 | Tu'a Golo | Tahun penghargaan UNESCO Wae Rebo → **2012** | Penti | → Ending Penti |

## 5. Kontrol
| Aksi | Keyboard / mouse |
|---|---|
| Bergerak | W A S D / panah |
| Lompat | Spasi |
| Bicara / lanjut / lewati dialog | E / Enter (juga Spasi atau klik) |
| Jawab teka-teki | klik, panah + Enter, atau 1–4 |
| Menenun | panah/WASD, E/Spasi/klik, 1–4 |
| Tabuh | J (gong), K (gendang) |
| Jeda & koleksi kartu | Esc / P |

## 6. State Management
- **GameState (autoload):** `MENU → BERMAIN ⇄ DIALOG`, `BERMAIN ⇄ JEDA`, `BERMAIN ⇄ MINIGAME`, `BERMAIN → SELESAI → MENU`. Transisi yang tidak ada di `TRANSISI_SAH` ditolak. Contohnya, jeda tidak bisa dibuka saat dialog atau saat menjawab teka-teki. Progres disimpan di `langkah_rantai` dan `kartu_terkumpul`.
- **FSM Pemain:** Idle, Jalan, Lompat, Jatuh, Interaksi (dikunci saat DIALOG).
- **FSM Penampil Caci (ending):** Siaga, Ancang, Serang, Tangkis, Terkena. Dua penampil bergantian menjadi paki dan ta'ang.
- **State tantangan:** rantai berbasis data, dengan tiga jenis tantangan (`teka_teki`, `tenun`, `gong`) yang dikendalikan `kampung.gd`.

## 7. Integrasi Budaya per Aspek
| Aspek | Wujud dalam game |
|---|---|
| **Mekanik** | Menenun motif songke; menabuh gong-gendang; teka-teki tentang Mbaru Niang, songke, nyanyian adat, dan caci; menghormati compang (hanya dilihat) |
| **Visual: lingkungan** | 7 Mbaru Niang (1 mbaru gendang + 6 mbaru gena) melingkari compang di natas, atap ijuk 5 tingkat, gong & gendang, arena, langit cerah |
| **Visual: karakter** | Gaya **anime 3D**: tubuh lebih besar, kepala besar, mata besar berkilau, **kulit cokelat**, **rambut bergelombang** (pendek untuk laki-laki, panjang terurai untuk perempuan); sarung songke; pemain caci dengan panggal, larik, nggiling |
| **Suasana kampung** | Anjing dan ayam berkeliaran (FSM diam/jalan; ayam mematuk, ekor anjing bergoyang) dan sesekali bersuara saat pemain dekat |
| **Visual: UI** | Panel bermotif songke |
| **Audio** | Musik pola gong-gendang sintetis; SFX gong/gendang interaktif; **dialog diucapkan** (TTS bahasa Indonesia, nada berbeda per tokoh) |
| **Narasi** | Bingkai Penti; sapaan *ité* dan *Kraeng*; pesan sportivitas & persaudaraan; warga saling mengenalkan budaya |
| **Edukasi** | 9 kartu budaya yang dibacakan dan dapat dibaca ulang di menu jeda; teka-teki menguji isi kartu |
| **Kepekaan** | Compang tidak dijadikan tempat bermain; caci ditampilkan sebagai pertunjukan, bukan pertarungan; kopi dan pola motif adalah tafsir kreatif |

> **Tafsir kreatif [PERLU VERIFIKASI]:** perempuan pembawa kopi untuk pemain caci; motif belah ketupat 5×5 sebagai penyederhanaan motif songke; pola irama gong-gendang (bukan pola adat tertentu).

## 8. Desain Level
```
                  UTARA
         [Mbaru Gendang] ← Ema Agus DI DALAM (#3)
  [Gena]                         [Gena] ← jemuran songke, Ende Lono DI DALAM (#4)
     Fransi (#5) ↔ berkeliling di sekitar gong
  [Gena]        ◎ compang      ──── papan "Arena Caci (Penti)"
   Ine Wela (#2) + alat tenun   Tu'a Golo (#1, #9)   ( ARENA )  Hingha (#6) ⇄ Marngem (#7)
  [Gena] ← kayu bakar, Ema Yakobus DI DALAM (#8)
            [Gena]                 [Gena]
  batu▲▲▲              ▼ papan "Kampung Wae Rebo"
                 ★ titik muncul (selatan)
```
- Semua rumah dapat dimasuki; isi rumah: lantai kayu, tungku api (cahaya hangat), tikar.
- Area bermain 80×80 m dengan dinding batas tak terlihat; tanah 220 m; pohon & bukit; anjing dan ayam berkeliaran.

**Ending:** natas dengan 10 penari melingkar dan dua penampil caci yang bergantian menyerang/menangkis; kamera mengorbit.

## 9. UI / HUD
- **Menu utama:** diorama 3D, judul "JEJAK PENTI di Wae Rebo", tombol Mulai, Cara Bermain, Tentang, Keluar.
- **HUD:** "Petunjuk: ..." (petunjuk aktif) dan jumlah kartu x/9.
- **Dialog bersuara:** panel kecil berisi nama pembicara; kalimat diucapkan lewat TTS; lanjut otomatis; E untuk melewati. Teks tampil bila suara tidak tersedia atau dinyalakan di menu jeda.
- **Teka-teki:** panel pertanyaan + 3 tombol jawaban.
- **Mini-game:** overlay bermotif songke (tenun, tabuh).
- **Menu jeda:** volume musik/SFX/suara dialog, tampilkan teks dialog, koleksi kartu, kembali ke menu.

## 10. Gaya Visual & Audio
Low-poly prosedural dari mesh primitif Godot; tekstur pixel 64×64 buatan sendiri (songke 4 varian, ijuk, rumput, tanah, batu, kayu, kulit kerbau). Palet: hitam `#1B1818`, merah `#B02A2A`, kuning `#E8B430`, hijau `#2E7D46`, biru `#2C5C96`, krem `#E8E2D2`. Audio disintesis (gong, gendang, lonceng pentatonik).

## 11. Prinsip Animasi
| Prinsip | Penerapan |
|---|---|
| Anticipation | Penampil caci menarik larik ke belakang sebelum memukul |
| Timing | Ancang-ancang lambat vs pukulan sangat cepat (0,09 dtk) |
| Follow-through | Lengan dan larik melewati target lalu kembali dengan easing elastis |
| Squash & stretch | Stretch saat melompat, squash saat mendarat; teks umpan balik "meletup" |
| Ease in/out | Transisi layar, langkah pembawa kopi, perisai turun |
| Secondary action | Napas saat idle, ayunan lengan, penari Penti, perempuan menahan nampan, ekor anjing bergoyang, ayam mematuk |

## 12. Ruang Lingkup
| Prioritas | Fitur | Status |
|---|---|---|
| Must | Gerak/lompat/collision 3D; FSM pemain; GameState; rantai teka-teki 9 langkah; 2 mini-game; dialog; kartu; audio | ✅ |
| Should | Dialog bersuara, menu jeda + koleksi kartu, ending Penti dengan pertunjukan caci | ✅ |
| Nice | Simpan permainan, kamera bebas, lebih banyak motif tenun, rekaman suara asli (dengan izin) | ⏳ |

## 13. Arsitektur Teknis
```
src/
├─ scenes/        main_menu, kampung, ending, pemain, penampil_caci
├─ scripts/
│  ├─ autoload/   Kontrol, GameState, AudioManager, Transisi, DialogManager (TTS + teka-teki), MenuJeda
│  ├─ state_machine/  StateMachine + StateDasar
│  ├─ karakter/   KarakterModel (model prosedural + animasi; laki-laki/perempuan, nampan kopi)
│  ├─ pemain/     Pemain + states
│  ├─ caci/       PenampilCaci + states (Siaga, Ancang, Serang, Tangkis, Terkena)
│  ├─ dunia/      Dunia (builder), kampung (rantai teka-teki), Interaktif, NpcKampung, Hewan, KameraIkut
│  ├─ minigame/   TenunSongke, TabuhGong
│  ├─ ui/         hud, main_menu, ending
│  └─ util/       Gaya
├─ data/          rantai_teka_teki.json, kartu_budaya.json, dialog.json
└─ assets/        textures/, audio/
```
Konten (urutan warga, pertanyaan, jawaban, petunjuk, isi kartu) terpisah dari kode, sehingga dapat diubah tanpa pemrograman.
