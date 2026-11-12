# Game Design Document (GDD)
# *Caci: Jejak Anak Wae Rebo*

| | |
|---|---|
| **Nama / NIM** | [NAMA] / [NIM] |
| **Mata kuliah** | Pengembangan Permainan Digital — Rencana Tugas 1 |
| **Versi dokumen** | 1.0 (prototipe) |
| **Engine** | Godot 4.3+ (renderer Compatibility) |
| **Platform** | Windows (.exe) dan Web (HTML5) |

---

## 1. Ringkasan

| Aspek | Keterangan |
|---|---|
| Judul | Caci: Jejak Anak Wae Rebo |
| Genre | Petualangan 3D orang ketiga + duel ritme/timing |
| Target pemain | Remaja–dewasa (13+), pemain kasual, pelajar/mahasiswa yang ingin mengenal budaya Nusantara |
| Durasi main | ±10 menit |
| Pitch satu kalimat | Pulang ke kampung adat Wae Rebo menjelang Penti, jelajahi Mbaru Niang, lalu buktikan sportivitasmu dalam **caci**, menangkis sebagai *ta'ang* dan mencambuk sebagai *paki*. |
| Unsur budaya inti | **Caci** (paki & ta'ang, larik, nggiling, panggal) |
| Unsur pendukung | Mbaru Niang & Kampung Wae Rebo, Compang, Penti, kain Songke, gong-gendang & nyanyian adat |

## 2. Latar & Cerita (ringkas)
Nara, pemuda Manggarai, pulang ke kampung adat yang terinspirasi Wae Rebo menjelang **Penti** (tahun baru adat dan syukur pergantian musim). **Tu'a Golo** (tetua kampung) memintanya berlatih caci dengan tiga pemain kampung, yaitu **Rangga**, **Fransi**, dan **Ema Agus** (juara kampung), sambil mengingatkan bahwa *caci bukan untuk melukai, melainkan tentang sportivitas dan persaudaraan*. **Ine Wela**, seorang penenun, mengenalkan songke. Setelah ketiga lawan mengakui Nara, Penti dimulai dan warga menari mengelilingi natas.

Struktur 3 babak:
1. **Pulang:** tiba di kampung, bertemu Tu'a Golo, menjelajah, dan mengumpulkan kartu budaya.
2. **Berlatih:** tiga duel caci dengan kesulitan bertahap.
3. **Penti:** kembali ke Tu'a Golo, lalu ending perayaan.

## 3. Core Loop
```
 ┌─► Jelajahi kampung 3D (jalan, lompat, temukan kartu) ─┐
 │                                                        ▼
 │   Bicara dengan NPC / baca kartu budaya ◄──── Dapat pengetahuan
 │                                                        │
 │                                                        ▼
 │   Duel caci: TA'ANG (tangkis) ⇄ PAKI (cambuk), 3 ronde
 │                                                        │
 └──── Menang: kartu hadiah + lawan berikutnya terbuka ◄──┘
                     (Kalah: ulangi duel / kembali ke kampung)
```

## 4. Mekanik Gameplay

### 4.1 Mekanik 1 — TA'ANG (menangkis)
| Komponen | Rincian |
|---|---|
| Tujuan | Menangkis pukulan larik lawan dengan nggiling |
| Kontrol | **K** atau **X** |
| Aturan | Lawan masuk state **Ancang** (menarik larik ke belakang; muncul tanda "!" kuning lalu merah). Tangkisan **berhasil** bila ditekan paling lama *jendela* detik sebelum pukulan mendarat. |
| Stamina | Maks 100; tiap tangkisan −30; pulih +22/detik; jeda antartangkisan 0,35 detik. Menangkis sembarangan menghabiskan stamina. |
| Tipuan | Lawan 2 dan 3 kadang ancang-ancang tanpa memukul (tipuan) untuk menghukum pemain yang asal menekan tombol. |
| Skor | Tertangkis: pemain +1 · Terkena: lawan +2 |
| Umpan balik | SFX perisai/cambuk, animasi tangkis/terkena, *screen shake*, teks "Tertangkis! +1" / "Terkena!" |

### 4.2 Mekanik 2 — PAKI (mencambuk)
| Komponen | Rincian |
|---|---|
| Tujuan | Mencambuk lawan dengan tepat |
| Kontrol | **J** atau **Z** |
| Aturan | Penanda bergerak bolak-balik pada bilah timing. Zona **kuning** = tepat, **oranye** = hampir, sisanya = meleset. Batas waktu 3 detik per cambukan. |
| Skor | Tepat: pemain +2 (lawan terkena) · Hampir: ditangkis lawan (0) · Meleset/terlambat: 0 |
| Kesulitan | Zona menyempit dan bilah makin cepat untuk lawan berikutnya; bilah juga sedikit lebih cepat setiap ronde. |

### 4.3 Struktur duel
- 3 ronde. Setiap ronde terdiri atas fase **TA'ANG** (2 serangan lawan) lalu fase **PAKI** (2 cambukan). Peran bergantian seperti caci sesungguhnya.
- Menang jika poin pemain > poin lawan. Hadiah: kartu budaya dan lawan berikutnya terbuka.
- Kalah: dialog penyemangat, lalu pilih **Ulangi Duel** atau **Kembali ke Kampung**.
- Tutorial interaktif (dialog Tu'a Golo) muncul sebelum duel pertama.

### 4.4 Parameter lawan
| Lawan | Ancang-ancang (dtk) | Jendela tangkis (dtk) | Lebar zona | Laju bilah | Peluang tipuan | Kartu hadiah |
|---|---|---|---|---|---|---|
| Rangga (latihan) | 1,0–1,4 | 0,38 | 0,26 | 0,8 | 0% | Caci: Paki & Ta'ang |
| Fransi (menengah) | 0,65–1,15 | 0,30 | 0,19 | 1,15 | 20% | Perlengkapan Caci |
| Ema Agus (juara) | 0,45–1,0 | 0,24 | 0,14 | 1,5 | 33% | Nilai Sportivitas Caci |

### 4.5 Mekanik pendukung: eksplorasi & platforming
- Berjalan bebas di kampung 3D, mengunjungi Mbaru Niang yang pintunya bercahaya untuk menemukan kartu, dan melompat ke **batu pijakan** bertingkat (tinggi 1–3 m).
- Lompatan memakai *coyote time* (0,12 dtk), *jump buffer* (0,12 dtk), dan tinggi lompat variabel (lepas tombol lebih awal = lompatan lebih rendah).

## 5. Kontrol
| Aksi | Keyboard |
|---|---|
| Bergerak | W A S D / tombol panah |
| Lompat | Spasi |
| Interaksi / lanjut dialog | E / Enter (dialog juga bisa dilanjutkan dengan Spasi atau klik) |
| Cambuk (paki) | J / Z |
| Tangkis (ta'ang) | K / X |
| Jeda | Esc / P |
| Navigasi menu | Mouse atau panah + Enter |

Input Map didaftarkan lewat kode di `scripts/autoload/kontrol.gd`.

## 6. State Management

### 6.1 State game (`GameState`, autoload)
`MENU → BERMAIN ⇄ DIALOG`, `BERMAIN ⇄ JEDA`, `BERMAIN → MINIGAME ⇄ DIALOG`, `MINIGAME ⇄ JEDA`, `BERMAIN → SELESAI → MENU`.
Transisi yang tidak terdaftar di `TRANSISI_SAH` **ditolak** dan diberi peringatan, sehingga state game selalu konsisten. Contohnya, jeda tidak bisa dibuka saat dialog berlangsung.

### 6.2 FSM Pemain (`scenes/pemain.tscn`)
| State | Masuk ke state ini ketika | Perilaku |
|---|---|---|
| Idle | tidak ada input & di tanah | animasi napas |
| Jalan | ada input arah | ayunan kaki/lengan, SFX langkah |
| Lompat | tombol lompat (dengan buffer & coyote) | stretch, tinggi variabel |
| Jatuh | kecepatan vertikal ≤ 0 / lepas dari tepi | squash saat mendarat |
| Interaksi | GameState menjadi DIALOG | diam, tidak menerima input gerak |

### 6.3 FSM Lawan Caci (`scenes/lawan_caci.tscn`)
| State | Perilaku | Transisi |
|---|---|---|
| Siaga | kuda-kuda caci | ← perintah duel |
| Ancang | menarik larik (*anticipation*), tanda "!" | → Serang, atau → Siaga bila tipuan |
| Serang | pukulan cepat + *follow-through*, memancarkan `pukulan_mendarat` | → Siaga |
| Tangkis | mengangkat nggiling | → Siaga (0,55 dtk) |
| Terkena | terdorong ke belakang + squash | → Siaga (0,6 dtk) |

### 6.4 Fase duel (`duel_caci.gd`)
`PERSIAPAN → (TA'ANG → PAKI) × 3 ronde → HASIL`

## 7. Integrasi Budaya per Aspek
| Aspek | Wujud dalam game |
|---|---|
| **Mekanik** | Peran paki dan ta'ang bergantian; ancang-ancang lawan menjadi isyarat menangkis; menang lewat poin, bukan menghabisi lawan; sasaran di tubuh atas |
| **Visual: karakter** | Pemain caci bertelanjang dada dengan **panggal** bertanduk, **larik**, **nggiling** kulit kerbau, dan sarung **songke**; tetua berbaju hitam; penenun berbaju merah |
| **Visual: lingkungan** | 7 **Mbaru Niang** (1 mbaru gendang lebih besar + 6 mbaru gena) melingkari **compang** di natas, atap ijuk dengan penanda 5 tingkat, gong dan gendang, lembah hijau berlangit cerah |
| **Visual: UI** | Bingkai panel dan dialog bermotif **songke** (dasar hitam, garis merah-kuning-hijau-biru) |
| **Audio** | Musik pola **gong-gendang** sintetis (kampung lebih tenang, arena caci lebih cepat), SFX cambuk, perisai, dan gong pembuka ronde |
| **Narasi** | Bingkai **Penti**; pesan sportivitas dan persaudaraan; sapaan hormat *ité*; *Mori Kraeng* dan *empo* dalam doa syukur |
| **Edukasi** | 9 kartu budaya yang dapat dibaca ulang di menu jeda |
| **Kepekaan** | Compang hanya *dilihat*, tidak dijadikan arena atau platform; ritus Penti tidak diperagakan detail; stamina dan tipuan ditandai sebagai unsur desain |

## 8. Desain Level

### 8.1 Kampung (hub)
```
                    UTARA
          [Mbaru Gendang]✦ (kartu Mbaru Niang)
 ✦[Gena] (kartu Gong-Gendang)       [Gena]
            gong  ┌─────┐
 [Gena]           │  ◎  │ compang (dilihat)   ──── papan "Arena Caci"
   Ine Wela       └─────┘  Tu'a Golo              ( ARENA )  Rangga · Fransi · Ema Agus
 [Gena]                         ✦[Gena] (kartu Penti)
     ✦[Gena] (kartu Wae Rebo)
  batu▲▲▲          ▼ papan "Kampung Wae Rebo"
                 ★ titik muncul (selatan)
 ✦ = pintu Mbaru Niang bercahaya, berisi kartu budaya ("[E] Masuk Mbaru Niang")
```
- Area bermain 80×80 m dengan dinding batas tak terlihat (tanah 220×220 m agar cakrawala bersih tanpa kabut); pohon di radius 22–36 m; bukit di kejauhan.
- Kartu: 4 ditemukan **di dalam Mbaru Niang** (pintu bercahaya hangat sampai kartunya diambil), 1 dari compang, 1 dari Ine Wela, 3 hadiah duel. Total **9**.
- Tiga batu pijakan bertingkat (1–3 m) di barat daya untuk latihan melompat dan memandang kampung dari atas.

### 8.2 Arena caci
Lingkaran tanah dikelilingi batu, 7 penonton setengah lingkaran (sebagian menari), gong-gendang, tiga Mbaru Niang di latar. Kamera samping tetap.

### 8.3 Ending
Natas dengan 10 penari melingkar (*danding*), kamera mengorbit, ringkasan kartu & kemenangan.

## 9. UI / HUD
- **Menu utama:** diorama 3D Wae Rebo dengan kamera mengorbit; tombol Mulai, Cara Bermain, Tentang Game, Keluar.
- **HUD kampung:** tujuan saat ini, jumlah kartu x/9, jumlah lawan x/3, petunjuk kontrol.
- **Petunjuk 3D:** label nama mengambang di atas NPC dan "[E] Bicara" pada objek interaksi terdekat.
- **Dialog:** kotak bermotif songke, efek mesin ketik.
- **HUD duel:** nama lawan, peran saat ini, skor kedua pihak, bar stamina, bilah timing, teks umpan balik yang "meletup".
- **Menu jeda:** lanjutkan, slider volume musik/SFX, koleksi kartu budaya, kembali ke menu.

## 10. Gaya Visual & Audio
- Low-poly prosedural: semua model dibangun dari mesh primitif Godot (kapsul, silinder, kerucut, torus, bola).
- Tekstur pixel 64×64 buatan sendiri: songke (4 varian), ijuk, rumput, tanah, batu, kayu, kulit kerbau.
- Palet: hitam songke `#1B1818`, merah `#B02A2A`, kuning `#E8B430`, hijau `#2E7D46`, biru `#2C5C96`, krem `#E8E2D2`.
- Audio disintesis dengan Python (numpy): gong (parsial inharmonik + dengung), gendang (pitch-drop + noise), lonceng pentatonik.

## 11. Prinsip Animasi yang Diterapkan
| Prinsip | Penerapan |
|---|---|
| Anticipation | Lawan menarik larik jauh ke belakang sebelum memukul; ini juga menjadi isyarat gameplay |
| Timing | Ancang-ancang lambat (0,45–1,4 dtk) vs pukulan sangat cepat (0,09 dtk) |
| Follow-through | Lengan dan larik terus bergerak melewati target, lalu kembali dengan easing elastis |
| Squash & stretch | Stretch saat melompat, squash saat mendarat (sebanding kecepatan jatuh), squash saat terkena, teks umpan balik "meletup" |
| Ease in/out | Tween transisi layar, ayunan lengan, perisai turun perlahan |
| Secondary action | Napas saat idle, ayunan lengan saat berjalan, penonton menari |
| Arcs | Ayunan lengan berbasis rotasi pada sendi bahu dan pinggul |

## 12. Ruang Lingkup
| Prioritas | Fitur | Status |
|---|---|---|
| Must | Gerak, lompat, collision 3D; FSM pemain & lawan; GameState; 2 mekanik caci; 3 lawan; dialog; kartu; audio | ✅ diimplementasikan |
| Should | Menu jeda + volume + koleksi kartu, tutorial, ending Penti, screen shake | ✅ diimplementasikan |
| Nice | Kamera bisa diputar, simpan permainan, teka-teki lingko, model 3D detail, suara rekaman asli (dengan izin) | ⏳ pengembangan lanjutan |

## 13. Arsitektur Teknis (ringkas)
```
src/
├─ project.godot              (autoload, display 640×360 → 1280×720, renderer Compatibility)
├─ scenes/                    main_menu, kampung, duel_caci, ending, pemain, lawan_caci
├─ scripts/
│  ├─ autoload/               Kontrol, GameState, AudioManager, Transisi, DialogManager, MenuJeda
│  ├─ state_machine/          StateMachine + StateDasar (dipakai ulang)
│  ├─ karakter/               KarakterModel (model prosedural + animasi)
│  ├─ pemain/ (+states)       Pemain (CharacterBody3D) + Idle/Jalan/Lompat/Jatuh/Interaksi
│  ├─ lawan/ (+states)        LawanCaci + Siaga/Ancang/Serang/Tangkis/Terkena
│  ├─ dunia/                  Dunia (builder), kampung, Interaktif, NpcKampung, KameraIkut
│  ├─ minigame/               duel_caci, BilahTiming
│  ├─ ui/                     hud, main_menu, ending
│  └─ util/                   Gaya (palet & komponen UI)
├─ data/                      dialog.json, kartu_budaya.json (konten terpisah dari kode)
└─ assets/                    textures/ (PNG), audio/ (WAV)
```
Komunikasi antarbagian memakai **sinyal** (`state_berubah`, `progres_berubah`, `dialog_selesai`, `pukulan_mendarat`, `serangan_selesai`, `momen_pukul`, `keputusan_cambuk`).
