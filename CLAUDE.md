# Proyek: Prototipe Game Berbasis Budaya Lokal — Tema Budaya Manggarai

Konteks tugas: **Rencana Tugas 1 — Prototipe Game Berbasis Budaya Lokal** (mata kuliah Pengembangan Permainan Digital).
Dikerjakan individu, durasi 4 minggu, engine **Godot 4.3+**, game **3D** low-poly prosedural. Deadline pengumpulan sudah dekat; prioritaskan stabilitas daripada fitur baru.

## Bahasa
Semua dokumen, komentar kode penting, dan komunikasi ditulis dalam **Bahasa Indonesia**.

## Tahapan & bobot (dari dokumen tugas)
| Tahap | Bobot | Agent utama | Output |
|---|---|---|---|
| 1. Penelitian Budaya | 10% | `peneliti-budaya-manggarai` | `docs/riset/` → Laporan penelitian budaya (3–5 hlm) |
| 2. Adaptasi Konsep | 20% | `game-designer`, `penulis-narasi`, `art-audio-director` | `docs/gdd/GDD.md`, daftar aset, naskah |
| 3. Implementasi Teknis | 50% | `godot-developer` | `src/` (project Godot), build |
| 4. Testing & Polish | 10% | `qa-playtester` | `docs/playtest/` |
| 5. Dokumentasi | 10% | `dokumentator` | `docs/laporan/`, naskah video demo, slide |
| Lintas tahap | — | `manajer-proyek` | Koordinasi, timeline, cek rubrik |

## Timeline 4 minggu
- **Minggu 1:** Riset budaya Manggarai + penyusunan GDD
- **Minggu 2:** Implementasi teknis dasar (input, movement, collision, state management)
- **Minggu 3:** Implementasi mekanik (min. 2) + integrasi aset visual & audio + animasi
- **Minggu 4:** Playtesting, iterasi, polish, dokumentasi, video demo (1–2 menit), presentasi

## Rubrik penilaian (acuan semua agent)
- **Kualitas Implementasi Teknis 40%** — kelengkapan fitur (input, movement, collision), kualitas kode & struktur proyek, state management tepat, stabilitas & performa
- **Integrasi Unsur Budaya 30%** — kedalaman riset, kreativitas adaptasi, konsistensi budaya di semua aspek game
- **Kualitas Aset & Visual 15%** — keserasian visual dengan tema budaya, prinsip animasi, kualitas integrasi audio
- **Dokumentasi & Presentasi 15%** — kelengkapan dokumen, kualitas video demo, kejelasan presentasi
- Skala: A >85, AB >80, B >70, BC >65, C >55, D >40, E ≤40

## Luaran wajib
a) File executable (`.exe` / `.apk` / web build) · b) Source code · c) GDD + asset references · d) Laporan penelitian budaya (3–5 hlm) · e) Video demo gameplay (1–2 menit)

## Konsep yang sudah ditetapkan (lihat `docs/prompt-proyek.md` & `docs/gdd/GDD.md`)
**Judul:** *Caci: Jejak Anak Wae Rebo* — game 3D orang ketiga (kamera tetap).
- Jelajah kampung 3D bergaya Wae Rebo (7 Mbaru Niang melingkari compang), NPC Tu'a Golo & Ine Wela, 9 kartu budaya.
- Inti budaya **Caci**: mekanik 1 **TA'ANG** (menangkis tepat waktu + stamina + tipuan), mekanik 2 **PAKI** (bilah timing). Peran bergantian, 3 ronde, 3 lawan (Hingha, Fransi, Ema Agus).
- Bingkai cerita **Penti**; ending warga menari di natas.
- Bahasa Indonesia + istilah Manggarai terverifikasi (`docs/riset/glosarium.md`). Compang tidak dijadikan arena bermain (sakral).
- Semua aset dibuat sendiri (`tools/generate_textures.py`, `tools/generate_audio.py`).

## Struktur folder
```
.claude/agents/   definisi agent
docs/riset/       catatan & laporan penelitian budaya
docs/gdd/         Game Design Document + asset references
docs/playtest/    rencana & hasil playtest
docs/laporan/     laporan proses development, naskah video, slide presentasi
tools/            generator tekstur & audio (Python)
src/              project Godot (scenes/, scripts/, data/, assets/textures, assets/audio)
```

## Aturan umum
- Hormati budaya: hindari stereotip, jangan memalsukan ritual sakral; tandai hal yang belum terverifikasi dengan `[PERLU VERIFIKASI]`.
- Setiap aset pihak ketiga dicatat di `docs/gdd/asset-references.md` (sumber, pembuat, lisensi).
- Lacak progres di `docs/laporan/log-pengembangan.md` (bahan laporan proses development).
