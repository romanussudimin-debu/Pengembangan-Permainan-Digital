# Naskah Video Demo: Event Tracking `level_completed` (Pertemuan 8)

## Poin penjelasan
1. **Event:** *Level Completed*, dicatat setiap kali pemain menamatkan level.
2. **Alat:** sistem analitik lokal buatan sendiri di Godot (autoload `Analitik`), kategori "yang lainnya". Alasan:
   - game dibuat dengan Godot (Unity Analytics khusus Unity; Firebase/GameAnalytics tidak punya SDK resmi Godot);
   - bisa dimainkan offline (HP, LAN);
   - tidak menyimpan data pribadi;
   - hasil berupa JSON yang mudah diolah (Excel/Python).
3. **Alur:** level tamat → sinyal `GameState.level_selesai` → `Analitik.catat_level_selesai()` → disimpan ke
   `event_log.json` + dicetak `[Analitik] level_completed ...`.
4. **Data:** level, kesulitan, mode, waktu, durasi (tanpa jeda), sisa nyawa, salah pengecoh, tantangan diulang,
   kartu baru, koin, pertama kali tamat. Rincian di `docs/event-tracking.md`.
5. **Manfaat:** mengetahui level yang terlalu sulit dan perbedaan Normal dengan Sulit.

## Naskah (±1,5–2 menit)
| Waktu | Tampilan | Narasi |
|---|---|---|
| 0:00–0:15 | Menu utama | "Saya Romanus Sudimin. Ini game *Jejak Penti di Wae Rebo* buatan Godot. Event yang saya pasang adalah Level Completed, memakai sistem analitik lokal buatan sendiri." |
| 0:15–0:40 | `analitik.gd` (`catat_level_selesai`) dan `game_state.gd` (`level_selesai.emit`) | "Saat level tamat, GameState memancarkan sinyal, lalu Analitik mencatat datanya. Saya tidak memakai Firebase atau GameAnalytics karena game ini Godot, bisa dimainkan offline, dan tidak menyimpan data pribadi." |
| 0:40–1:15 | Level 1 di Mode Singkat sampai layar "Level 1 berhasil" | "Untuk demo saya pakai Mode Singkat. Sekarang saya tamatkan Level 1…" |
| 1:15–1:40 | Panel Output: `[Analitik] level_completed level=1 ...` | "Event langsung tercatat: level, kesulitan, durasi, sisa nyawa, dan jumlah salah pengecoh." |
| 1:40–1:55 | `event_log.json` dibuka di Notepad | "Data juga tersimpan sebagai JSON, siap diolah untuk evaluasi game." |
| 1:55–2:00 | Kembali ke game | "Terima kasih." |

## Tips merekam
- Aktifkan **Mode Singkat** di menu utama: Level 1 cukup 2 tantangan + 1 gelombang (±1 menit), lalu klik **Mulai Permainan**.
- Jalankan dari editor Godot (F5) agar panel Output terlihat.
- Berkas JSON (Windows): Win+R → `%APPDATA%\Godot\app_userdata\Jejak Penti di Wae Rebo\analitik`.
- Perekam: Win+Alt+R (Xbox Game Bar) atau OBS Studio.

## Teks untuk WA Group
> Romanus Sudimin – 240030260
> Absensi Pertemuan 8: Event Tracking
> Game: Jejak Penti di Wae Rebo (Godot 4)
> Event: **Level Completed**, tercatat setiap level tamat (level, kesulitan, mode, durasi, sisa nyawa, salah pengecoh, kartu, koin).
> Tools: sistem analitik lokal buatan sendiri (kategori "lainnya"), disimpan ke file JSON di perangkat, offline, tanpa data pribadi.
> Video demo terlampir.
