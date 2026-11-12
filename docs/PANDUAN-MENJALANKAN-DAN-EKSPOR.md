# Panduan Menjalankan & Mengekspor Game

## A. Menjalankan di Godot (±10 menit pertama kali)
1. Unduh **Godot 4.3** (atau 4.4/4.5) versi **Standard**, *bukan* .NET, dari https://godotengine.org/download. File berupa ZIP, cukup diekstrak tanpa instalasi.
2. Jalankan Godot, klik **Import**, lalu pilih file `src/project.godot` dari folder proyek ini → **Import & Edit**.
3. Tunggu proses impor aset (tekstur dan audio) hingga selesai. Ini hanya terjadi sekali.
4. Tekan **F5** (atau tombol ▶ di kanan atas) untuk memainkan game.

> **Jika muncul error:** buka panel **Output/Debugger** di bawah, salin teks error merahnya, lalu kirimkan ke Claude untuk diperbaiki. Game sudah diuji berjalan di Godot 4.7.2 (macOS).

## B. Pengaturan ekspor sudah disiapkan
File `src/export_presets.cfg` sudah berisi tiga preset: **Windows Desktop**, **Web**, dan **macOS**. Anda tidak perlu mengisi apa pun, cukup:
1. Menu **Editor → Manage Export Templates → Download and Install**. Ukurannya ±1 GB dan hanya perlu sekali.
2. Menu **Project → Export…**, pilih preset di daftar kiri, lalu klik **Export Project**.
3. Hilangkan centang **Export With Debug**, lalu **Save**. Hasilnya masuk ke folder `build/` di akar proyek.

| Preset | Hasil | Keterangan |
|---|---|---|
| Windows Desktop | `build/windows/JejakPenti.exe` | Satu file (PCK sudah disematkan). Bisa diekspor dari Mac. |
| Web | `build/web/index.html` (+ file pendukung) | *Thread Support* mati, jadi langsung jalan di itch.io. |
| macOS | `build/macos/JejakPenti.zip` | Berisi `.app`. Ditandatangani ad-hoc, jadi saat pertama dibuka: klik kanan → **Open**. |

> Jika muncul pesan "folder tidak ada", buat foldernya dulu (`build/windows`, `build/web`, `build/macos`).

## C. Publikasi
- **itch.io:** buat akun → *Upload new project* → jenis *HTML* → unggah ZIP berisi seluruh isi `build/web` → centang *This file will be played in the browser*. Atur *Viewport* ke 1280 × 720.
- **GitHub Releases:** di halaman repo → *Releases → Create a new release* → lampirkan `JejakPenti.exe` dan ZIP macOS.
- **Catatan Web:** suara dialog memakai TTS bawaan browser. Bila tidak ada suara bahasa Indonesia, dialog otomatis tampil sebagai teks.

## D. Merekam video demo (1–2 menit)
- Gunakan **OBS Studio** (gratis), atau **Win + Alt + R** (Xbox Game Bar di Windows).
- Rekam 1080p 30/60 fps, lalu ikuti `docs/laporan/naskah-video-demo.md`.

## E. Membuat ulang aset (opsional)
```bash
pip install pillow numpy
python3 tools/generate_textures.py
python3 tools/generate_audio.py
```
