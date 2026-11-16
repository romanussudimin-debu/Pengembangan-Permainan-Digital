# Game Design Document (GDD)
# *Jejak Penti di Wae Rebo*

| | |
|---|---|
| **Nama / NIM** | Romanus Sudimin / 240030260 |
| **Program studi** | Sistem Informasi |
| **Mata kuliah** | Pengembangan Permainan Digital — Rencana Tugas 1 |
| **Versi dokumen** | 2.0 (revisi konsep: dari duel caci menjadi jelajah budaya) |
| **Engine** | Godot 4.3+ (renderer Compatibility) |
| **Platform** | Web (HTML5, termasuk browser HP), Windows (.exe), macOS, dan Android (.apk) |

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
| 2.3 | Perbaikan playtest: nyawa, pengecoh, tantangan aksi baru Level 1, dialog ringkas & gelembung, layar antar-level | Masukan "kebanyakan ngobrol, mainnya sedikit" |
| 2.2 | + **Level 3 Songke ke Labuan Bajo** (peta kapal, 6 destinasi TN Komodo, mini-game menjual), ending Penti dipindah ke akhir Level 3 | Menghubungkan budaya (songke) dengan ekonomi kreatif & wisata bertanggung jawab; persiapan Proyek UAS (3 level) |
| 2.1 | + **Level 2 Lingko Lodok** (undangan reke lodok, saluran wae teku, pembagian moso, pandangan dari bukit), Mode Sulit, simpan & lanjutkan | Mengangkat lingko, yang sudah diriset sebagai kandidat mekanik, menjadi level kedua |

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
| Kontrol | Panah/WASD memilih kotak; E/Spasi atau klik/ketuk mengganti warna benang; 1–4 atau ketuk palet memilih warna; tombol Berhenti/Backspace |
| Umpan balik | Jumlah kotak yang belum sama, jumlah langkah, warna terpilih; SFX klik; selesai otomatis saat kain sama persis |

### 4.3 Mekanik 3 — Tabuh Gong-Gendang (ritme)
| Komponen | Rincian |
|---|---|
| Tujuan | Menabuh mengikuti irama untuk mengiringi Penti |
| Kontrol | **J** = gong, **K** = gendang, atau ketuk tombol GONG/GENDANG |
| Aturan | 15 ketukan bergerak dari kanan ke garis tabuh (tempo 76 BPM). Tepat bila ditekan ±0,2 detik dari ketukan. Lulus bila ≥ 60% tepat; bila gagal, coba lagi. |
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
| 9 | Tu'a Golo | Tahun penghargaan UNESCO Wae Rebo → **2012** | Penti | → Level 2: Lingko Lodok (Tu'a Teno menunggu) |

### 4.5 Level 2 — Lingko Lodok (data: `src/data/lingko.json`)
Latar di luar kampung, mewujudkan ungkapan *gendang one, lingko pe'ang*: lingko melingkar dengan **lodok** dan **haju teno** di pusat, tiga pematang melingkar (dalam/tengah/luar) dan pematang menjari. Sebagian pematang **putus** sehingga pemain harus melompat; jatuh ke lumpur = kembali ke titik aman terakhir.

| Tahap | Tujuan pemain | Mekanik | Kartu |
|---|---|---|---|
| 1. Sambut | Temui Tu'a Teno di lodok | Platforming di pematang | Lingko |
| 2. Undang | Undang 5 kepala keluarga berdasarkan **ciri** (daftar di kanan atas); 3 warga pengecoh memberi petunjuk koreksi | Deduksi ciri + jelajah (Ema Gabriel terus berjalan di pematang terluar) | — |
| 3. Reke lodok | Musyawarah duduk melingkar (*lonto leok*) di lodok | Cerita | Reke Lodok & Tu'a Teno |
| 4. Wae teku | Alirkan air mata air ke dua petak | Mini-game **Mengalirkan Air** (putar potongan saluran) | Wae Teku |
| 5. Moso | Bagi 3 lingko (12, 18, 24 bagian) sesuai aturan musyawarah | Mini-game **Membagi Lingko** (tancapkan garis moso dari lodok; urut searah jarum jam dari moso utara) | Moso |
| 6. Bukit batu | Naik bukit batu di barat daya, pandang lingko dari atas | Lompat batu bertingkat + kamera pandang | Lingko Lodok |

**Pesan budaya utama:** adil dalam lingko **tidak selalu berarti sama luas**. Tu'a teno dan tu'a golo mendapat bagian lebih besar, dan keluarga bertanggungan banyak bisa mendapat lebih, sesuai kesepakatan musyawarah (catatan riset §4). Jawaban "sama rata" sengaja ditolak.

**Mode Sulit** (dipilih di menu utama): batas waktu "sebelum senja" (7 menit, matahari makin rendah dan langit makin jingga), jatuh −10 detik, salah orang −15 detik (sekali per pengecoh), pengecoh hanya memberi petunjuk umum, ukuran bagian lingko tidak ditampilkan, kesempatan salah membagi 2 (Normal 3), dan putaran saluran air dibatasi. Waktu habis → level diulang.

### 4.5b Perbaikan playtest v2.3: nyawa, pengecoh, ritme bermain
Masukan playtest: *"mainnya sedikit, kebanyakan ngobrol"*. Target ritme: ±70% bermain, 30% cerita; obrolan tidak lebih dari 30–60 detik sebelum ada aksi lagi.

**Nyawa (semua level):** 5 (Normal) / 3 (Sulit), diisi penuh saat level atau destinasi Level 3 dimulai. −1 saat salah jawab, memilih pengecoh, jatuh, atau gagal tantangan (suara gagal, layar berkedip merah, kamera bergetar, ikon hati pecah). Nyawa habis = **hanya tantangan yang sedang dimainkan yang diulang** (bagian jelajah: dari titik cek terakhir), bukan level. Penambah nyawa bertema budaya: cangkir kopi (L1), kendi air (L2), kelapa muda (L3).

**Dialog ringkas:** maks. 2 baris pendek per tokoh per kesempatan; obrolan ringan tampil sebagai gelembung teks di atas kepala tokoh (pemain tetap bergerak); kartu budaya tampil sebagai popup judul + 1 kalimat, isi lengkap di Koleksi. Tombol Lewati, tahan tombol = cepat, opsi Teks cepat.

**Level 1 baru (pola: platformer → teka-teki → pola → aksi → antar → ritme → teka-teki → refleks → teka-teki):**

| # | Bagian | Tantangan | Pengecoh (adil, bisa dibedakan bila teliti) | Fakta / adaptasi |
|---|---|---|---|---|
| Pembuka | Mendaki ke Wae Rebo | Platformer ngarai: batu pijakan di sungai, akar, titian di atas jurang, tanjakan; 3 titik cek | Batu **retak** (lebih gelap, bergaris retak) tenggelam bila diinjak; **cabang jalan buntu** (jalur utama bertiang bambu berkain merah) | Wae Rebo memang dicapai lewat jalan setapak hutan; detail jalur = adaptasi |
| 1 | Tu'a Golo | Teka-teki | Jawaban salah = −1 nyawa | Fakta |
| 2 | Ine Wela | Menenun songke | (tahap berikut: warna mirip merah/merah bata) | Fakta |
| 3 | Ema Agus | **Menyangrai Kopi**: memilah biji lalu menjaga panas di zona hijau | Kerikil (abu-abu, bulat) & biji busuk (gelap, berbintik) di antara biji bagus | Kopi komoditas utama Wae Rebo [S48, S49]; cara menyangrai = **adaptasi kreatif** |
| 4 | Ende Lono | **Mengantar Kopi** (3D): nampan miring, kopi tumpah bila berbelok tajam/melompat/menabrak ayam atau anak berlari | Tamu mirip: hanya "berbaju hijau, duduk dekat compang" yang benar | Penyuguhan kopi kepada tamu `[PERLU VERIFIKASI]` |
| 5 | Fransi | Tabuh gong-gendang | (tahap berikut: ketukan tipuan) | Fakta |
| 6 | Hingha | Teka-teki | — | Fakta |
| 7 | Marngem | **Latihan Tangkis Nggiling**: tangkis bola rotan ke kiri/tengah/kanan, makin cepat | Lemparan **tipuan** (ancang-ancang lalu batal); tanda: tangan kosong tanpa bola | Tipuan memang bagian caci; latihan dengan bola rotan = adaptasi, ditampilkan sebagai latihan sportivitas |
| 8–9 | Ema Yakobus, Tu'a Golo | Teka-teki | — | Fakta |
| Bonus | Benang Emas | 5 gulungan benang emas tersembunyi (pencapaian "Penjelajah") | Benang kuning biasa tanpa kilau | Adaptasi |

Kartu dari warga yang teka-tekinya diganti tetap didapat setelah tantangan aksinya selesai; kartu bonus baru **Kopi Wae Rebo** (Level 1 kini 10 kartu).

**Level 2 (tahap 5):** pola: jelajah pematang → saluran air → **Usir Burung** → membagi lingko → bukit.

| Bagian | Tantangan | Pengecoh | Fakta / adaptasi |
|---|---|---|---|
| Pematang | Menyusuri pematang ke lodok | **Pematang rapuh** (gelap, bergaris retak) runtuh setelah 0,8 detik; batu goyah di jalan bukit | Adaptasi |
| Wae teku | Saluran air (putar pipa) | **Pipa retak** membocorkan air (-1 nyawa) | Pembagian air sawah = fakta; pipa = adaptasi |
| Usir Burung | 3 gelombang pipit di 4 petak; jaga padi | **Kuntul putih** tidak boleh diusir (pemakan serangga, dilindungi) | Pipit hama padi & kuntul predator hama = fakta [S51–S54]; praktik khas Manggarai `[PERLU VERIFIKASI]` |

**Bintang & pencapaian (v2.3):** setiap tantangan memberi ★1–3 dari nyawa yang hilang (0 salah = ★★★, 1–2 = ★★, 3+ = ★); ringkasan bintang tampil di layar Level Berhasil, bintang terbaik per level di menu **Pilih Level** (hanya level yang sudah terbuka). Tujuh pencapaian tersimpan: *Tanpa Tumpah* (antar kopi tanpa tumpah), *Mata Elang* (tamat satu level tanpa kehilangan nyawa), *Penjelajah* (5 benang emas), *Penangkis Ulung* (tangkis nggiling tanpa salah), *Penjaga Sawah* (tidak mengusir kuntul), *Sahabat Laut* (sampah Pink Beach & Manjarite tanpa mengganggu biota), *Penjual Andal* (satu destinasi tanpa salah barang/cerita).

**Antar-level:** layar "Level N berhasil" (kartu, waktu, nyawa) → tombol "Lanjutkan ke Level N+1" → animasi orb atom "LEVEL N+1" + tagline → tombol Mulai.

### 4.6 Level 3 — Songke ke Labuan Bajo (data: `src/data/labuan_bajo.json`)
Setelah lingko terbagi, warga menitipkan **songke tenunan penenun kampung** kepada Nggohak, ditambah **foto budaya** dari Level 1–2. Ia ikut **kapal wisata resmi sebagai pemandu budaya** ke 6 destinasi Taman Nasional Komodo. Hasil penjualan dibawa pulang untuk Penti dan para penenun → **ending Penti + caci** (dengan adegan penyerahan hasil penjualan kepada Tu'a Golo dan penenun).

**Struktur:** peta perjalanan kapal (UI tampak atas, destinasi terbuka berurutan) → scene pulau yang dibangun dari builder yang sama (`DuniaPulau`). Target **3 pembeli per pulau** (4 pembeli + 2 wisatawan pemberi info per pulau, total 18 penjualan). Progres per pulau tersimpan.

**Menemukan pembeli (v2.3):** panel kanan menampilkan **ciri calon pembeli** (warna topi & baju, unik terhadap wisatawan pengecoh). Semua wisatawan bisa diajak ngobrol; memilih "Tawarkan songke" kepada yang bukan pembeli = −1 nyawa. Pink Beach & Manjarite tuntas bila 3 pembeli **dan** 5 sampah plastik terkumpul.

**Mekanik menjual (mini-game `JualSongke`):** (1) wisatawan menyebut keinginan → (2) pilih kain/foto yang cocok (salah barang hanya ditolak) → (3) ceritakan maknanya: pilihan ganda yang jawabannya ada di kartu budaya. Salah cerita: Normal boleh sekali lagi, Sulit wisatawan langsung pergi. Bila pembeli tersisa tidak cukup → pulau diulang.

| # | Destinasi | Mekanik khas | Kartu | Fakta / adaptasi |
|---|---|---|---|---|
| 1 | Pelabuhan Labuan Bajo | Tutorial menjual | Labuan Bajo | Fakta [S41] |
| 2 | Pulau Padar | Mendaki 3 pos; **tenaga** berkurang saat berjalan (lebih cepat di tanjakan), minum di pos (sekali per pos); tenaga habis = −1 nyawa & kembali ke pos minum terakhir; jalan pintas batu pijakan dengan **batu goyah** (gelap, miring, retak) | Pulau Padar | Fakta (tiga pantai, panas, tanpa penjual) [S42]; sistem tenaga = adaptasi |
| 3 | Pink Beach | Pantai + air dangkal; **injak karang = kembali**; **wajib pungut 5 sampah**; pengecoh kerang & bintang laut (jangan diambil), penyu (jangan disentuh) | Pink Beach | Fakta [S43, S55]; aturan "jangan ambil/sentuh" `[PERLU VERIFIKASI: aturan resmi BTNK]` [S56] |
| 4 | Pulau Komodo | Jalur bersama **ranger**; komodo berpatroli; terlalu dekat = kembali (Sulit: komodo 5, jarak bahaya lebih besar); **semak bergoyang**: angin (pelan, seirama) vs komodo bersembunyi (goyang tak teratur + jejak kaki + ekor) | Komodo | Fakta [S44]; komodo predator penyergap [S57]; jarak bahaya = adaptasi `[PERLU VERIFIKASI]` |
| 5 | Taka Makassar | Pulau pasir sabit **menyempit karena air pasang** (batas waktu alami 4 menit, Sulit ±2,8 menit) | Taka Makassar | *Adaptasi kreatif* (penyusutan dipercepat) [S45] |
| 6 | Teluk Manjarite | **Berenang** antar-kapal berlabuh; **arus** mendorong pemain; karang; **wajib pungut 5 sampah**; penyu & kawanan ikan jangan diganggu; terseret melewati **garis pelampung** = −1 | Teluk Manjarite | `[PERLU VERIFIKASI]` detail teluk [S45] |

Kartu tambahan: **Songke sebagai Ekonomi Kreatif** (diberikan di awal Level 3) [S46, S47]. Kartu destinasi didapat dengan membaca papan informasi atau saat pulau tuntas.

**Pesan wisata bertanggung jawab:** jaga jarak dari satwa, jangan menginjak karang, bawa pulang sampah, hargai karya penenun dengan harga yang adil.

**Mode Sulit Level 3:** batas waktu 5 menit per pulau (habis → ulangi pulau), salah cerita = wisatawan pergi, tenaga Padar lebih cepat habis, komodo lebih banyak dan lebih cepat, denda waktu saat jatuh ke laut/menginjak karang (−10 dtk) atau terlalu dekat komodo (−15 dtk).

### 4.7 Kurva kesulitan
| Level | Kesulitan | Tantangan utama |
|---|---|---|
| 1 Kampung Wae Rebo | Mudah | Jelajah, teka-teki, 2 mini-game tanpa tekanan waktu |
| 2 Lingko Lodok | Sedang | Platforming pematang, deduksi ciri, 2 mini-game logika |
| 3 Labuan Bajo | Sulit, naik per destinasi | Tutorial → stamina → bahaya lingkungan (karang) → bahaya bergerak (komodo) → batas waktu alami (pasang) → arus + berenang |

**Progres:** setelah Level 1 tamat, progres tersimpan (`user://simpanan.cfg`), sehingga tombol **Lanjutkan (Level 2)** muncul di menu utama. Level 2 tamat → ending Penti.

## 5. Kontrol
| Aksi | Keyboard / mouse | Layar sentuh (HP/tablet) |
|---|---|---|
| Bergerak | W A S D / panah | joystick virtual (separuh kiri layar) |
| Lompat | Spasi | tombol LOMPAT |
| Bicara / lanjut / lewati dialog | E / Enter (juga Spasi atau klik) | tombol BICARA; ketuk layar untuk lanjut |
| Jawab teka-teki | klik, panah + Enter, atau 1–4 | ketuk pilihan |
| Menenun | panah/WASD, E/Spasi/klik, 1–4 | ketuk kotak kain & palet benang; tombol Berhenti |
| Tabuh | J (gong), K (gendang) | tombol GONG / GENDANG |
| Jeda & koleksi kartu | Esc / P | tombol II (kanan atas) |

Kontrol sentuh (`KontrolSentuh`) hanya muncul di perangkat layar sentuh dan hanya saat state BERMAIN.

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
- **Teka-teki:** panel pertanyaan + 4 tombol jawaban.
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
│  ├─ autoload/   Kontrol, GameState, AudioManager, Transisi, DialogManager (TTS + teka-teki), MenuJeda, KontrolSentuh
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
