# Wirabraja: Geger Alun-Alun Keraton

Game aksi 3D orang ketiga bertema budaya Jawa Surakarta dan pewayangan.
Raden Wirabraja, ksatria penjaga gerbang keraton, harus mengalahkan bala buta
yang menyerbu Alun-Alun Lor Keraton Kasunanan Surakarta, lalu menghadapi
raksasa **Ditya Kalamurka**.

- **Penyusun:** I Gusti Agung Ayu Putu Wulan Aristina (NIM 240030296)
- **Prodi/Kampus:** Sistem Informasi, Institut Teknologi dan Bisnis STIKOM Bali
- **Versi:** 1.0 (Fase 1, Level 1 sederhana)
- **Engine:** Godot 4.5 atau lebih baru (GDScript), platform PC Windows

## Cara membuka dan menjalankan
1. Unduh **Godot 4.5 (Standard)** atau versi yang lebih baru: https://godotengine.org/download
2. Jalankan Godot → **Import** → pilih file `project.godot` di folder ini → **Import & Edit**.
   (Saat pertama dibuka Godot mengimpor aset beberapa detik.)
3. Tekan **F5** (atau tombol ▶ di kanan atas) untuk bermain.
   Scene utama: `scenes/level/level_1.tscn`.

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
| R | Mengulang level setelah menang/kalah |

## Cara bermain
- Kalahkan **6 Buta Prajurit**. Saat buta mengangkat kedua lengannya, ia akan memukul: menjauh atau pukul duluan.
- Setelah semua buta kalah, **Ditya Kalamurka** bangkit di depan pendopo.
  Ketika muncul **lingkaran merah** di tanah, keluar dari lingkaran atau **melompat** tepat sebelum
  hantaman, lalu pukul bos saat ia terengah.
- **Menang:** bos kalah. **Kalah:** HP habis. Tekan **R** untuk mengulang.

## Struktur folder
```
project.godot        konfigurasi, input map, autoload GameManager
scenes/player/       player.tscn (Raden Wirabraja + kamera orbit)
scenes/enemies/      buta.tscn (Buta Prajurit)
scenes/boss/         bos_raksasa.tscn (Ditya Kalamurka)
scenes/level/        level_1.tscn + pendopo, gerbang, pagar_keliling, beringin
scenes/ui/           hud.tscn
scripts/             skrip GDScript (autoload, common, player, enemies, boss, level, ui)
audio/               disiapkan untuk Fase 2
docs/                GDD_v1.0.docx, buat_gdd.py (generator GDD), gambar/
tests/               uji_alur.tscn (uji otomatis), tangkap_layar.tscn
tools/               buat_scene_karakter.py (generator model placeholder)
```

Semua model memakai bentuk bawaan Godot sebagai placeholder. Setiap karakter
punya node `Model` terpisah, sehingga mudah diganti model asli (.glb) nanti.
Nilai penting (HP, damage, kecepatan) adalah variabel `@export` dan bisa disetel di Inspector.

## Pengujian
Uji otomatis alur permainan (gerak, lompat, serangan, AI buta, bos, menang, kalah):
```bash
godot --headless --path . res://tests/uji_alur.tscn
```
Hasil v1.0: **19 pemeriksaan lulus**.

## Membuat ulang GDD
```bash
pip install python-docx
python docs/buat_gdd.py
```
