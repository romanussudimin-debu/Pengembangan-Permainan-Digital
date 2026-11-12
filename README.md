# Caci: Jejak Anak Wae Rebo

Prototipe **game 3D berbasis budaya Manggarai** (Flores, NTT) untuk tugas *Pengembangan Permainan Digital: Rencana Tugas 1*. Engine: **Godot 4.3+**.

Pemain berperan sebagai Nggohak yang pulang ke kampung adat bergaya Wae Rebo menjelang **Penti**. Nggohak menjelajahi Mbaru Niang dan compang, mengumpulkan 9 kartu budaya, lalu berlatih **caci** melawan 3 pemain kampung:
- **Ta'ang (menangkis):** baca ancang-ancang lawan, lalu tangkis tepat waktu dengan nggiling (memakai stamina).
- **Paki (mencambuk):** tekan cambuk saat penanda berada di zona kuning bilah timing.

## Mulai cepat
1. Unduh Godot 4.3 Standard: https://godotengine.org/download
2. Import `src/project.godot`, lalu tekan **F5**.
3. Panduan lengkap (ekspor .exe/web, merekam video): [`docs/PANDUAN-MENJALANKAN-DAN-EKSPOR.md`](docs/PANDUAN-MENJALANKAN-DAN-EKSPOR.md)

**Kontrol:** WASD/panah jalan · Spasi lompat · E interaksi · J/Z cambuk · K/X tangkis · Esc jeda

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
