# Jejak Penti di Wae Rebo

## Cara bermain

| Perangkat | Cara | Link |
|---|---|---|
| **HP / tablet (Android)** | Unduh aplikasi (APK) | [JejakPenti.apk](https://github.com/romanussudimin-debu/Pengembangan-Permainan-Digital/releases/download/apk-terbaru/JejakPenti.apk) |
| **HP / tablet (Android & iPhone)** | Main langsung di browser (putar HP mendatar) | [Main di web](https://romanussudimin-debu.github.io/Pengembangan-Permainan-Digital/) |
| **Windows 10/11** | Unduh aplikasi (.exe) | [JejakPenti-Windows.zip](https://github.com/romanussudimin-debu/Pengembangan-Permainan-Digital/releases/download/desktop-terbaru/JejakPenti-Windows.zip) |
| **macOS (Intel & Apple Silicon)** | Unduh aplikasi (.app) | [JejakPenti-macOS.zip](https://github.com/romanussudimin-debu/Pengembangan-Permainan-Digital/releases/download/desktop-terbaru/JejakPenti-macOS.zip) |
| **Laptop / PC (semua)** | Main langsung di browser | [Main di web](https://romanussudimin-debu.github.io/Pengembangan-Permainan-Digital/) |

- **Android (APK):** buka file yang diunduh → izinkan "Instal aplikasi tidak dikenal" bila diminta → **Instal**. Agar dialog bersuara, pasang suara **Bahasa Indonesia** di Setelan → Aksesibilitas → Output text-to-speech (mesin Google).
- **Main di web dari HP:** ketuk layar sekali agar layar penuh. Bisa juga dipasang sebagai aplikasi: Chrome **⋮ → Instal aplikasi** (Android) atau Safari **Bagikan → Tambahkan ke Layar Utama** (iPhone).
- **Windows:** ekstrak ZIP → klik dua kali `JejakPenti.exe` → bila muncul "Windows protected your PC", klik **More info → Run anyway**.
- **macOS:** ekstrak ZIP → pertama kali, **klik kanan** aplikasi → **Open** → **Open**.

Semua versi dibangun otomatis oleh GitHub Actions (`web.yml`, `android.yml`, `desktop.yml`) setiap ada perubahan di `src/`. Semua rilis ada di [halaman Releases](https://github.com/romanussudimin-debu/Pengembangan-Permainan-Digital/releases).

Game **3D jelajah budaya Manggarai** (Flores, NTT) untuk mata kuliah *Pengembangan Permainan Digital*. Engine: **Godot 4.3+**. Tiga level: **Kampung Wae Rebo** (rantai teka-teki, menenun songke, tabuh gong-gendang), **Lingko Lodok** (undangan reke lodok, saluran wae teku, pembagian moso), dan **Songke ke Labuan Bajo** (menjual songke & foto budaya di 6 destinasi Taman Nasional Komodo), ditutup perayaan Penti dan caci.

Game 3D **jelajah budaya**. Menjelang **Penti**, Nggohak pulang ke kampung adat bergaya Wae Rebo. Delapan warga masing-masing menyimpan kartu budaya yang harus dikumpulkan **berurutan**. Setiap warga memberi tantangan dan petunjuk ke warga berikutnya. Tantangannya:
- **Teka-teki budaya** (pilihan ganda bersuara, jawabannya ada di kartu sebelumnya)
- **Menenun songke**: samakan kain dengan contoh motif
- **Tabuh gong-gendang**: ikuti irama (J = gong, K = gendang)

Setelah 9 kartu terkumpul, Penti dimulai: warga menari dan caci ditampilkan sebagai pertunjukan. Dialog diucapkan dengan suara bahasa Indonesia (Text-to-Speech).

## Mulai cepat
1. Unduh Godot 4.3 Standard: https://godotengine.org/download
2. Import `src/project.godot`, lalu tekan **F5**.
3. Panduan lengkap (ekspor .exe/web, merekam video): [`docs/PANDUAN-MENJALANKAN-DAN-EKSPOR.md`](docs/PANDUAN-MENJALANKAN-DAN-EKSPOR.md)

**Kontrol:** WASD/panah jalan · Spasi lompat · E bicara/lanjut · 1/2/3 jawab teka-teki · J gong · K gendang · Esc jeda & koleksi kartu

## Isi repositori
| Folder | Isi |
|---|---|
| `src/` | Project Godot (scene, script, data JSON, tekstur & audio) |
| `tools/` | Skrip Python pembuat tekstur & audio (semua aset dibuat sendiri) |
| `docs/riset/` | Riset budaya: laporan 3–5 halaman, glosarium, tabel adaptasi, referensi visual, pustaka |
| `docs/gdd/` | Game Design Document + asset references |
| `docs/playtest/` | Rencana uji, kuesioner, template hasil playtest |
| `docs/laporan/` | Laporan proses, log, naskah video demo, kerangka slide, checklist pengumpulan |
| `docs/prompt-proyek.md` | Prompt proyek (Peran–Konteks–Tugas–Format–Contoh) |
| `.claude/agents/` | 8 agent Claude Code untuk tiap tahap pengerjaan |

## Agent (`.claude/agents/`)
| Agent | Tahap |
|---|---|
| `manajer-proyek` | Koordinasi & audit rubrik |
| `peneliti-budaya-manggarai` | 1. Penelitian budaya |
| `game-designer`, `penulis-narasi`, `art-audio-director` | 2. Adaptasi konsep |
| `godot-developer` | 3. Implementasi teknis |
| `qa-playtester` | 4. Testing & polish |
| `dokumentator` | 5. Dokumentasi |
