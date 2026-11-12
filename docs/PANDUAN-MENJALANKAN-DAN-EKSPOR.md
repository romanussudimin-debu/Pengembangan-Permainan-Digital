# Panduan Menjalankan & Mengekspor Game

## A. Menjalankan di Godot (±10 menit pertama kali)
1. Unduh **Godot 4.3** (atau 4.4/4.5) versi **Standard**, *bukan* .NET, dari https://godotengine.org/download. File berupa ZIP, cukup diekstrak tanpa instalasi.
2. Jalankan Godot, klik **Import**, lalu pilih file `src/project.godot` dari folder proyek ini → **Import & Edit**.
3. Tunggu proses impor aset (tekstur dan audio) hingga selesai. Ini hanya terjadi sekali.
4. Tekan **F5** (atau tombol ▶ di kanan atas) untuk memainkan game.

> **Jika muncul error:** buka panel **Output/Debugger** di bawah, salin teks error merahnya, lalu kirimkan ke Claude untuk diperbaiki. Kode belum pernah dijalankan di Godot sungguhan; sintaksnya sudah dicek dengan parser GDScript, tetapi bisa saja ada error saat runtime.

## B. Ekspor ke Windows (.exe)
1. Menu **Editor → Manage Export Templates → Download and Install**. Ukurannya ±1 GB dan hanya perlu sekali.
2. Menu **Project → Export… → Add… → Windows Desktop**.
3. Isi **Export Path**, misalnya `build/windows/CaciWaeRebo.exe`.
4. Klik **Export Project**, hilangkan centang **Export With Debug**, lalu **Save**.
5. Hasilnya berupa `CaciWaeRebo.exe` (+ `CaciWaeRebo.pck` bila "Embed PCK" tidak dicentang). Kumpulkan keduanya dalam satu folder atau ZIP.

## C. Ekspor ke Web (HTML5), opsional
1. **Project → Export… → Add… → Web**.
2. Export Path: `build/web/index.html` → **Export Project**.
3. Uji di komputer: **Project → Export → Web → Run in Browser** (ikon ▶ dengan globe di editor), atau unggah seluruh isi folder `build/web` sebagai ZIP ke **itch.io** (jenis proyek *HTML*). Hasilnya berupa tautan yang bisa dibagikan ke dosen.
4. Di Godot 4.3, biarkan *Thread Support* **mati** supaya tidak perlu pengaturan server khusus.

## D. Merekam video demo (1–2 menit)
- Gunakan **OBS Studio** (gratis), atau **Win + Alt + R** (Xbox Game Bar di Windows).
- Rekam 1080p 30/60 fps, lalu ikuti `docs/laporan/naskah-video-demo.md`.

## E. Membuat ulang aset (opsional)
```bash
pip install pillow numpy
python3 tools/generate_textures.py
python3 tools/generate_audio.py
```
