# Source Code (Godot 4.3+)

- Buka `project.godot` di Godot 4.3 atau lebih baru (versi Standard, bukan .NET).
- Scene utama: `scenes/main_menu.tscn`.
- Arsitektur dan state management: lihat `../docs/gdd/GDD.md` bagian 6 dan 13.
- Tuning kesulitan duel: `KONFIG_LAWAN` di `scripts/minigame/duel_caci.gd`.
- Konten dialog & kartu: `data/dialog.json`, `data/kartu_budaya.json`.
- Lint gaya kode (opsional): `pip install "gdtoolkit==4.*"` lalu `gdlint scripts` (konfigurasi di `gdlintrc`).
- Ekspor: lihat `../docs/PANDUAN-MENJALANKAN-DAN-EKSPOR.md`.
