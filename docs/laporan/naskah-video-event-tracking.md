# Naskah Video Demo: Event Tracking `daily_login` & `level_completed` (Pertemuan 8)

## Poin penjelasan
1. **Event:**
   - *Daily Login* (`daily_login`): dicatat sekali per hari saat game dibuka, dengan hari berturut-turut (streak)
     dan total hari bermain.
   - *Level Completed* (`level_completed`): dicatat setiap kali pemain menamatkan level.
2. **Alat:** sistem analitik lokal buatan sendiri di Godot (autoload `Analitik`), kategori "yang lainnya". Alasan:
   - game dibuat dengan Godot (Unity Analytics khusus Unity; Firebase/GameAnalytics tidak punya SDK resmi Godot);
   - bisa dimainkan offline (HP, laptop);
   - tidak menyimpan data pribadi;
   - hasil berupa JSON yang mudah diolah (Excel/Python).
3. **Alur:**
   - Game dibuka → `Analitik.catat_login_harian()` → cek tanggal terakhir di `login.cfg` → bila hari baru,
     event `daily_login` disimpan + dicetak `[Analitik] daily_login ...`.
   - Level tamat → sinyal `GameState.level_selesai` → `Analitik.catat_level_selesai()` → disimpan ke
     `event_log.json` + dicetak `[Analitik] level_completed ...`.
4. **Data:**
   - `daily_login`: tanggal, hari berturut-turut, streak terbaik, total hari, jeda hari, login pertama, platform.
   - `level_completed`: level, kesulitan, waktu, durasi (tanpa jeda), sisa nyawa, salah pengecoh,
     tantangan diulang, kartu baru, pertama kali tamat.
   - Rincian di `docs/event-tracking.md`.
5. **Manfaat:**
   - Daily login: mengukur retensi (berapa hari pemain kembali bermain).
   - Level completed: mengetahui level yang terlalu sulit dan perbedaan Normal dengan Sulit.

## Naskah (±1,5–2 menit)
| Waktu | Tampilan | Narasi |
|---|---|---|
| 0:00–0:15 | Editor Godot, tekan ⌘B/F5; panel Output menampilkan `[Analitik] daily_login ...` | "Saya Romanus Sudimin. Ini game *Jejak Penti di Wae Rebo* buatan Godot. Saya memasang dua event dengan sistem analitik lokal buatan sendiri. Begitu game dibuka, event Daily Login langsung tercatat." |
| 0:15–0:35 | `analitik.gd`: fungsi `catat_login_harian` dan `catat_level_selesai` | "Daily Login dicatat sekali per hari, lengkap dengan hari berturut-turut. Saat level tamat, GameState memancarkan sinyal, lalu Analitik mencatat Level Completed. Saya tidak memakai Firebase atau GameAnalytics karena game ini Godot, bisa dimainkan offline, dan tidak menyimpan data pribadi." |
| 0:35–1:10 | Bagian akhir Level 1 (menenun songke bersama Ine Wela) sampai layar "Level 1 berhasil" | "Sekarang saya tamatkan Level 1…" |
| 1:10–1:30 | Panel Output: `[Analitik] level_completed level=1 ...` | "Event Level Completed tercatat: level, kesulitan, durasi, sisa nyawa, dan kartu budaya yang didapat." |
| 1:30–1:50 | `event_log.json` dibuka (Finder: Cmd+Shift+G) | "Kedua event tersimpan di file JSON ini, siap diolah untuk evaluasi game." |
| 1:50–2:00 | Kembali ke game | "Terima kasih." |

## Tips merekam
- Hapus folder `analitik` sebelum merekam agar Output menampilkan `daily_login ... login_pertama=true`.
  Di Mac: Finder → Cmd+Shift+G → `~/Library/Application Support/Godot/app_userdata/Jejak Penti di Wae Rebo/`.
- Level 1 kini singkat (pendakian, teka-teki Tu'a Golo, menenun songke; ±4–6 menit). Percepat bagian pendakian saat mengedit.
- Jalankan dari editor Godot (⌘B di Mac, F5 di Windows) agar panel Output terlihat.
- Berkas JSON (Windows): Win+R → `%APPDATA%\Godot\app_userdata\Jejak Penti di Wae Rebo\analitik`.
- Perekam: Mac Cmd+Shift+5; Windows Win+Alt+R (Xbox Game Bar); atau OBS Studio.

## Teks untuk WA Group
> Romanus Sudimin – 240030260
> Absensi Pertemuan 8: Event Tracking
> Game: Jejak Penti di Wae Rebo (Godot 4)
> Event:
> 1. **Daily Login**: tercatat sekali per hari saat game dibuka (tanggal, hari berturut-turut, total hari bermain).
> 2. **Level Completed**: tercatat setiap level tamat (level, kesulitan, durasi, sisa nyawa, salah pengecoh, kartu budaya).
> Tools: sistem analitik lokal buatan sendiri (kategori "lainnya"), disimpan ke file JSON di perangkat, offline, tanpa data pribadi.
> Video demo terlampir.
