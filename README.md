# Jejak Penti di Wae Rebo

**▶ Main langsung di browser (HP/laptop):** https://romanussudimin-debu.github.io/Pengembangan-Permainan-Digital/ — putar HP mendatar. Versi web dibangun otomatis oleh GitHub Actions (`.github/workflows/web.yml`) setiap ada perubahan di `src/`.

Prototipe **game 3D jelajah budaya Manggarai** (Flores, NTT) untuk tugas *Pengembangan Permainan Digital: Rencana Tugas 1*. Engine: **Godot 4.3+**.

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
