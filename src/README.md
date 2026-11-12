# Source Code (Godot 4.3+)

- Buka `project.godot` di Godot 4.3 atau lebih baru (versi Standard, bukan .NET).
- Scene utama: `scenes/main_menu.tscn`.
- Arsitektur dan state management: lihat `../docs/gdd/GDD.md` bagian 6 dan 13.
- Urutan warga, teka-teki, jawaban, dan petunjuk: `data/rantai_teka_teki.json`.
- Isi kartu & dialog umum: `data/kartu_budaya.json`, `data/dialog.json`.
- Tuning mini-game: konstanta di `scripts/minigame/tenun_songke.gd` dan `scripts/minigame/tabuh_gong.gd`.
- Lint gaya kode (opsional): `pip install "gdtoolkit==4.*"` lalu `gdlint scripts` (konfigurasi di `gdlintrc`).
- Ekspor: lihat `../docs/PANDUAN-MENJALANKAN-DAN-EKSPOR.md`.
