# Wirabraja: Geger Alun-Alun Keraton

Game aksi 3D orang ketiga bertema budaya Jawa Surakarta dan pewayangan.
Setelah narasi pembuka bergaya dalang, Raden Wirabraja, ksatria penjaga gerbang keraton,
harus menghalau tiga gelombang bala buta di Alun-Alun Lor Keraton Kasunanan Surakarta,
lalu menghadapi raksasa **Ditya Kalamurka**.

- **Penyusun:** I Gusti Agung Ayu Putu Wulan Aristina (NIM 240030296)
- **Prodi/Kampus:** Sistem Informasi, Institut Teknologi dan Bisnis STIKOM Bali
- **Versi:** 1.1 (Fase 2: variasi musuh, bos 3 pola + fase 2, audio gamelan, narasi dalang)
- **Engine:** Godot 4.5 atau lebih baru (GDScript), platform PC Windows

## Cara membuka dan menjalankan
1. Unduh **Godot 4.5 (Standard)** atau versi yang lebih baru: https://godotengine.org/download
2. Jalankan Godot → **Import** → pilih file `project.godot` di folder ini → **Import & Edit**.
   (Saat pertama dibuka Godot mengimpor aset beberapa detik.)
3. Tekan **F5** (atau tombol ▶ di kanan atas) untuk bermain.
   Scene utama: `scenes/ui/narasi_pembuka.tscn` (narasi), lalu otomatis masuk `scenes/level/level_1.tscn`.

### Membuat file .exe (opsional)
Menu **Project → Export… → Add… → Windows Desktop**. Bila diminta, unduh *export templates*
lewat **Editor → Manage Export Templates**, lalu klik **Export Project**.

## Kontrol
| Tombol | Aksi |
|---|---|
| W A S D / tombol panah | Bergerak (relatif terhadap kamera) |
| Shift kiri (tahan) | Berlari |
| Spasi | Melompat |
| Klik kiri | Serangan gada |
| Gerakan mouse | Memutar kamera |
| Esc | Melepas kursor mouse (klik untuk mengunci lagi) |
| M | Musik hidup/mati |
| R | Mengulang level setelah menang/kalah |

**Saat narasi pembuka:** Spasi / Enter / klik = lanjut (atau tampilkan teks utuh), Esc / Tab = lewati.

## Cara bermain
Kalahkan **3 gelombang buta (12 ekor)**, lalu bos. Kenali musuh dari warna dan ukurannya:

| Musuh | Ciri | Tips |
|---|---|---|
| Buta Prajurit (merah) | Mengangkat kedua lengan lalu memukul | Mundur saat lengannya terangkat, lalu pukul |
| Buta Kilat (hijau, ramping) | Zig-zag, merunduk lalu menerjang | Menyamping saat ia merunduk, pukul saat ia terhenti |
| Buta Gempal (cokelat, besar) | Tidak terhuyung, Injak Bumi di sekelilingnya | Keluar dari jangkauannya saat ancang-ancang |
| Buta Pelempar (kuning) | Menjaga jarak, melempar batu | Terus bergerak; kejar dan pojokkan |

**Ditya Kalamurka** punya 3 pola serangan:
1. **Hantaman Bumi**: muncul lingkaran merah di tanah; keluar dari lingkaran atau **melompat** tepat sebelum hantaman.
2. **Serbuan Lurus**: muncul jalur merah; menyamping. Bila ia menabrak tembok/pohon, ia terhuyung lama (kesempatan memukul).
3. **Panggil Bala**: meraung dan memanggil buta cilik.

Saat HP-nya di bawah 50%, bos **murka** (kulit memerah): lebih cepat, hantaman dua kali, bala lebih banyak.
**Menang:** bos kalah. **Kalah:** HP habis. Tekan **R** untuk mengulang.

## Struktur folder
```
project.godot        konfigurasi, input map, autoload GameManager
scenes/player/       player.tscn (Raden Wirabraja + kamera orbit)
scenes/enemies/      buta, buta_kilat, buta_gempal, buta_pelempar, buta_cilik, batu_lempar
scenes/boss/         bos_raksasa.tscn (Ditya Kalamurka)
scenes/level/        level_1.tscn + pendopo, gerbang, pagar_keliling, beringin
scenes/ui/           hud.tscn, narasi_pembuka.tscn (scene utama)
scripts/             skrip GDScript (autoload: GameManager & AudioManager, common, player, enemies, boss, level, ui)
audio/               musik/ (3 .ogg) dan sfx/ (17 .wav), lihat audio/README.md
docs/                GDD_v1.0.docx, GDD_v1.1.docx, buat_gdd.py, buat_gdd_v11.py, gambar/
tests/               uji_alur.tscn (uji otomatis), tangkap_layar.tscn
tools/               buat_scene_karakter.py (model placeholder), buat_audio.py (audio gamelan sintetis)
```

Semua model memakai bentuk bawaan Godot sebagai placeholder. Setiap karakter
punya node `Model` terpisah, sehingga mudah diganti model asli (.glb) nanti.
Nilai penting (HP, damage, kecepatan) adalah variabel `@export` dan bisa disetel di Inspector.

## Pengujian
Uji otomatis (narasi, audio, gerak, serangan, 3 varian buta, gelombang, 3 pola bos + fase 2, menang, kalah):
```bash
godot --headless --path . res://tests/uji_alur.tscn
```
Hasil v1.1: **51 pemeriksaan lulus** (v1.0: 19).

## Audio
Musik dan efek suara adalah placeholder bernuansa gamelan yang disintesis sendiri (tanpa sampel pihak ketiga).
Daftar file dan cara menggantinya ada di [`audio/README.md`](audio/README.md). Membuat ulang:
```bash
pip install numpy
python tools/buat_audio.py
```

## Membuat ulang GDD
```bash
pip install python-docx
python docs/buat_gdd.py
python docs/buat_gdd_v11.py
```
`buat_gdd.py` menghasilkan GDD v1.0 dan `buat_gdd_v11.py` menghasilkan GDD v1.1. Bagian yang berubah ditandai
[Diperbarui v1.1] / [Baru v1.1].
