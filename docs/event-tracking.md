# Event Tracking: `level_completed`

## Tujuan
Event `level_completed` mencatat setiap kali seorang pemain menamatkan sebuah level. Data ini menjadi bahan
evaluasi playtest dan keseimbangan, antara lain lama penyelesaian level, jumlah kesalahan memilih pengecoh,
jumlah tantangan yang diulang, dan perbandingan antar-kesulitan. Pencatatan sepenuhnya **lokal** (berkas JSON
di perangkat pemain), tanpa koneksi internet, tanpa SDK pihak ketiga, dan **tanpa data pribadi** (tidak ada nama
pemain, alamat IP, atau ID perangkat). Event ini ditangani oleh autoload `Analitik` yang sudah ada
(`src/scripts/autoload/analitik.gd`, fungsi `catat_level_selesai`).

## Kapan event dikirim
Event dikirim satu kali setiap level tamat, melalui `GameState.selesaikan_level` yang memancarkan sinyal
`GameState.level_selesai`:

| Level | Titik tamat |
|---|---|
| 1. Kampung Wae Rebo | Setelah tantangan menenun songke bersama Ine Wela |
| 2. Lingko Lodok | Setelah memandang lingko dari bukit batu |
| 3. Songke ke Labuan Bajo | Saat menekan "Pulang ke Wae Rebo" di peta kapal setelah tiga destinasi tuntas |

Durasi mulai dihitung saat sinyal `GameState.level_dimulai` dipancarkan (`mulai_level`, `pilih_level`, atau
`lanjutkan`). Waktu selama permainan dijeda (Menu Jeda dan panel "Nyawa habis") tidak dihitung. Mengulang
tantangan karena nyawa habis **tidak** mereset durasi. Event lama `level_selesai` di `user://analitik.json`
tetap dicatat seperti sebelumnya.

## Field (skema versi 2)
| Field | Tipe | Contoh | Arti |
|---|---|---|---|
| `event` | String | `"level_completed"` | Nama event |
| `versi_skema` | int | `2` | Versi struktur data (v2: field `mode` dan `koin_didapat` dihapus bersama mode LAN dan pertarungan) |
| `level_id` | int | `1` | Level 1/2/3 |
| `nama_level` | String | `"Kampung Wae Rebo"` | Nama level |
| `kesulitan` | String | `"normal"` | `"normal"` atau `"sulit"` |
| `waktu` | String | `"2026-11-27T14:05:31"` | Waktu lokal ISO 8601 saat tamat |
| `durasi_detik` | float | `245.3` | Lama bermain level tanpa waktu jeda (1 desimal) |
| `nyawa_tersisa` | int | `3` | Sisa nyawa saat tamat |
| `nyawa_maks` | int | `5` | Nyawa maksimum (Normal 5, Sulit 3) |
| `salah_pengecoh` | int | `2` | Salah memilih pengecoh (batu goyah, bukan pembeli) |
| `tantangan_diulang` | int | `1` | Tantangan yang diulang karena nyawa habis |
| `kartu_didapat` | Array | `["compang", "mbaru_niang"]` | ID kartu budaya baru di level ini |
| `pertama_kali` | bool | `true` | `true` bila level ini baru pertama kali ditamatkan |

## Lokasi berkas log
Berkas: `user://analitik/event_log.json`, berupa array event. Hanya 500 event terakhir yang disimpan. Penulisan
dilakukan ke berkas `.tmp` terlebih dahulu, lalu berkas tersebut diganti nama. Berkas yang rusak atau hilang
diperlakukan sebagai array kosong.
- **Windows:** `%APPDATA%\Godot\app_userdata\Jejak Penti di Wae Rebo\analitik\event_log.json`
- **macOS:** `~/Library/Application Support/Godot/app_userdata/Jejak Penti di Wae Rebo/analitik/event_log.json`
- **Linux:** `~/.local/share/godot/app_userdata/Jejak Penti di Wae Rebo/analitik/event_log.json`
- **Android:** penyimpanan internal aplikasi, `/data/data/<nama paket>/files/analitik/event_log.json` (dapat dibaca
  dengan `adb shell run-as <nama paket> cat files/analitik/event_log.json` pada build debug)
- **Web:** IndexedDB peramban (sistem berkas virtual Godot)

Setiap event juga dicetak satu baris di Output/konsol, misalnya
`[Analitik] level_completed level=1 kesulitan=normal durasi=245.3s nyawa=3/5 pengecoh=0 diulang=1 kartu=4 pertama_kali=true`.
Saat game dibuka, `Analitik.ringkasan_level()` (jumlah tamat dan rata-rata durasi per level) dicetak sekali dengan
awalan `[Analitik] ringkasan_level`.

## Langkah uji manual
1. Jalankan proyek dari editor Godot 4.3 dan perhatikan baris `[Analitik] ringkasan_level ...` di panel Output.
2. Pilih kesulitan **Normal**, lalu mainkan Level 1 sampai layar "Level 1 berhasil". Sengaja salah menjawab
   teka-teki Tu'a Golo sekali (nyawa berkurang), dan buka Menu Jeda beberapa detik.
3. Pastikan muncul satu baris `[Analitik] level_completed level=1 kesulitan=normal ...` dengan `nyawa=4/5`, dan
   durasi yang tidak memuat waktu jeda. (`pengecoh` terisi di Level 3, misalnya saat menawarkan kepada bukan pembeli.)
4. Ulangi Level 1 lewat Pilih Level dengan kesulitan **Sulit**, lalu tamatkan. Baris kedua menunjukkan `kesulitan=sulit`
   dan `nyawa=x/3`.
5. Buka `event_log.json` di lokasi di atas. Pastikan berisi dua event dengan nilai yang sesuai.
6. Opsional: isi berkas dengan teks acak, lalu jalankan ulang game. Game tidak boleh crash dan log dimulai kosong.
