# Log Pengembangan

| Tanggal | Kegiatan / fitur | Kendala | Solusi |
|---|---|---|---|
| 12 Nov 2026 | Struktur proyek + 8 agent (manajer proyek, peneliti budaya, game designer, penulis narasi, art & audio director, Godot developer, QA, dokumentator) | — | — |
| 12 Nov 2026 | Riset budaya Manggarai: catatan, glosarium ±70 istilah, tabel adaptasi, referensi visual, laporan 3–5 halaman | Banyak situs jurnal tidak dapat dibuka penuh | Fakta diambil dari abstrak; entri yang belum pasti ditandai [PERLU VERIFIKASI] |
| 12 Nov 2026 | Konsep awal 2D (lingko + caci) diubah menjadi **3D berfokus Caci** sesuai keputusan pengembang | Aset 2D tidak terpakai | Pipeline aset diganti menjadi tekstur prosedural untuk model 3D low-poly |
| 12 Nov 2026 | Aset: 13 tekstur (songke, ijuk, dll.) dan 12 audio sintetis (gong, gendang, SFX, 2 musik loop) | Tidak ada aset 3D berlisensi bebas yang bernuansa Manggarai | Semua aset dibuat sendiri dengan skrip Python, bebas masalah lisensi |
| 12 Nov 2026 | Fondasi teknis: Input Map lewat kode, GameState dengan transisi tervalidasi, FSM berbasis node, Pemain CharacterBody3D (coyote time, jump buffer, lompat variabel) | — | — |
| 12 Nov 2026 | KarakterModel prosedural + animasi (anticipation, follow-through, squash & stretch) | Tidak memakai rig/tulang | Sendi dibuat sebagai pivot Node3D lalu dianimasikan dengan Tween dan fungsi sinus |
| 12 Nov 2026 | Kampung 3D: 7 Mbaru Niang, compang, gong-gendang, batu pijakan, NPC, 9 kartu budaya, HUD, dialog JSON | Batu pijakan bertabrakan dengan rumah | Jarak antarobjek dicek dengan skrip, lalu posisi digeser |
| 12 Nov 2026 | Duel caci: mekanik TA'ANG (stamina, tipuan) & PAKI (bilah timing), 3 lawan, FSM lawan, tutorial, menang/kalah | Await coroutine bisa error jika scene ditutup saat jeda | Menunggu memakai Timer milik scene sehingga ikut terhapus dengan aman |
| 12 Nov 2026 | Menu utama diorama 3D, menu jeda (volume + koleksi kartu), transisi fade, ending Penti | — | — |
| 12 Nov 2026 | Validasi: seluruh 39 skrip lolos parser GDScript (gdtoolkit); path resource, nama state, id dialog/kartu dicek otomatis | Godot tidak bisa dijalankan di lingkungan pengembangan | Uji runtime dilakukan di laptop pengembang (lihat rencana uji) |
| _(isi)_ | Uji coba di Godot & perbaikan error | | |
| _(isi)_ | Playtest dengan 3+ penguji & iterasi | | |
| _(isi)_ | Ekspor .exe / web, rekam video demo | | |
