# Laporan Proses Pengembangan
## Prototipe Game 3D Berbasis Budaya Lokal: *Caci: Jejak Anak Wae Rebo*

**Nama:** [NAMA] · **NIM:** [NIM] · **Mata kuliah:** Pengembangan Permainan Digital

---

## 1. Pendahuluan
Tugas ini bertujuan menerapkan teknik pengembangan game digital sambil mengintegrasikan unsur budaya lokal. Budaya yang diangkat adalah budaya **Manggarai** (Flores, NTT), dengan **caci**, tarian-tarung cambuk antara *paki* (pencambuk) dan *ta'ang* (penangkis), sebagai inti mekanik. Hasilnya adalah prototipe game 3D yang dapat dimainkan dari menu sampai ending dalam waktu ±10 menit.

## 2. Ringkasan Penelitian Budaya
Studi literatur (lihat `docs/riset/laporan-penelitian-budaya.md`) menghasilkan fakta kunci berikut:
- **Caci** dimainkan oleh paki dengan *larik* (cambuk kulit kerbau) melawan ta'ang dengan *nggiling* (perisai) dan *agang/tereng*. Perannya bergantian dan sasaran sah hanya tubuh di atas pinggang. Nilai utamanya sportivitas dan persaudaraan.
- **Wae Rebo** memiliki 7 Mbaru Niang (1 mbaru gendang + 6 mbaru gena) dengan 5 tingkat dan meraih penghargaan UNESCO Asia-Pacific 2012.
- **Compang** adalah altar batu di natas; **Penti** adalah tahun baru adat dan syukur; **songke** adalah kain tenun berdasar hitam dengan motif bermakna.
Fakta tersebut diterjemahkan ke mekanik, visual, audio, narasi, dan 9 kartu pengetahuan.

## 3. Konsep & Desain
Konsep dan desain lengkap ada di `docs/gdd/GDD.md`. Core loop: jelajah kampung → bicara/kumpulkan kartu → duel caci (ta'ang ⇄ paki) → lawan berikutnya → Penti.

**Perubahan konsep.** Konsep awal berupa game 2D dengan dua mekanik (teka-teki lingko + duel caci). Setelah ditinjau, konsep diubah menjadi **3D dengan caci sebagai inti** agar pengalaman lebih imersif dan fokus. Lingko tetap dibahas dalam riset sebagai konteks dan kandidat pengembangan lanjutan.

## 4. Proses Implementasi
| Tahap | Hasil |
|---|---|
| Setup | Project Godot 4, renderer Compatibility (ringan, mendukung web), resolusi dasar 640×360 diskalakan ke 1280×720 |
| Aset | Pipeline prosedural: tekstur dengan Pillow, audio dengan numpy (sintesis gong/gendang) |
| Fondasi | Input Map lewat kode; GameState FSM; StateMachine generik berbasis node |
| Kontrol pemain | CharacterBody3D, akselerasi/gesekan, coyote time, jump buffer, lompat variabel, collision dengan tanah/rumah/batu/pohon/dinding |
| Karakter | KarakterModel dari mesh primitif dengan sendi pivot dan animasi prosedural (Tween + sinus) |
| Dunia | Builder `Dunia`: Mbaru Niang, compang, gong-gendang, arena, pohon, bukit, langit |
| Interaksi | Area3D `Interaktif` (memilih objek terdekat), NPC, kartu budaya di dalam Mbaru Niang, dialog berbasis JSON |
| Duel | Dua mekanik, FSM lawan 5 state, 3 tingkat kesulitan, tutorial, kondisi menang/kalah |
| UI | Menu utama 3D, HUD, menu jeda, transisi fade, ending Penti |

Detail kronologis ada di `docs/laporan/log-pengembangan.md`.

`[SCREENSHOT: menu utama]` `[SCREENSHOT: kampung & Mbaru Niang]` `[SCREENSHOT: duel — fase TA'ANG dengan tanda "!"]` `[SCREENSHOT: duel — bilah timing PAKI]` `[SCREENSHOT: ending Penti]`

## 5. Arsitektur Teknis
- **State management tiga lapis:** (1) `GameState` dengan transisi tervalidasi; (2) FSM pemain (Idle, Jalan, Lompat, Jatuh, Interaksi); (3) FSM lawan (Siaga, Ancang, Serang, Tangkis, Terkena) ditambah fase duel.
- **Pemisahan data dan kode:** dialog dan kartu disimpan di `data/*.json`; parameter kesulitan dikumpulkan di `KONFIG_LAWAN`.
- **Komunikasi lewat sinyal** sehingga antarskrip tidak saling bergantung langsung.
- **Kode yang dapat dipakai ulang:** `StateMachine`, `KarakterModel`, `Dunia`, dan `Gaya` dipakai di banyak scene.

## 6. Pengujian & Iterasi
- **Validasi statis:** seluruh skrip lolos parser GDScript (gdtoolkit 4.3). Path resource, nama state, id dialog, dan id kartu diperiksa otomatis dengan skrip.
- **Uji fungsional:** mengikuti `docs/playtest/rencana-uji.md`. _[isi hasil]_
- **Playtest:** _[isi ringkasan dari `docs/playtest/hasil-playtest.md`: jumlah penguji, temuan utama, iterasi yang dilakukan]_

## 7. Hasil Akhir & Keterbatasan
**Hasil:** game 3D yang dapat dimainkan dari awal sampai akhir, dengan 2 mekanik caci, 3 lawan, 9 kartu budaya, musik dan SFX bernuansa gong-gendang, serta animasi yang menerapkan prinsip animasi dasar.

**Keterbatasan:**
- Model low-poly sederhana tanpa rig.
- Kamera tidak bisa diputar.
- Belum ada fitur simpan permainan.
- Musik sintetis, bukan rekaman asli.
- Sebagian sumber riset baru diverifikasi dari abstrak.

## 8. Kesimpulan & Pengembangan Lanjutan
Struktur caci (peran bergantian, isyarat ancang-ancang, nilai sportivitas) terbukti dapat diterjemahkan langsung menjadi mekanik timing yang menantang sekaligus mengedukasi. Pengembangan lanjutan:
- Mekanik teka-teki **lingko lodok**.
- Rekaman gong-gendang asli dengan izin komunitas.
- Model 3D yang lebih detail.
- Kamera bebas dan dukungan gamepad.
- Konsultasi dengan budayawan Manggarai.

## Lampiran
- Asset references: `docs/gdd/asset-references.md`
- Daftar pustaka: `docs/riset/catatan-riset.md`
