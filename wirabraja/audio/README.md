# Folder audio (v1.1)

Semua audio diputar lewat **AudioManager** (`scripts/autoload/audio_manager.gd`).
File di folder ini adalah **placeholder sintetis** buatan sendiri
(`tools/buat_audio.py`: gamelan disintesis dengan numpy, laras slendro, pola
balungan ciptaan sendiri). Tidak ada sampel pihak ketiga.

**Cara mengganti:** timpa file dengan rekaman asli **bernama sama**
(format boleh tetap .ogg/.wav). Bila nama atau format berubah, sesuaikan tabel
`MUSIK` / `SFX` di `audio_manager.gd`. Bila sebuah file dihapus, game tetap
berjalan tanpa suara itu (hanya muncul peringatan sekali di konsol).

## Musik latar (`audio/musik/`, berulang otomatis)
| File | Dipakai saat | Karakter |
|---|---|---|
| `musik_narasi.ogg` | Narasi pembuka dalang | Lambat dan lembut (gaya gender), gong tiap 16 ketukan |
| `musik_pertempuran.ogg` | Gelombang buta | Bernuansa lancaran ±132 ketukan/menit: saron, peking, bonang, kenong, kempul, kendang, gong |
| `musik_bos.ogg` | Pertarungan Ditya Kalamurka | Bernuansa sampak ±168 ketukan/menit, kenong tiap ketukan, kendang rapat |

## Efek suara (`audio/sfx/`)
| File | Nama di kode | Peristiwa |
|---|---|---|
| `ayun_gada.wav` | `ayun` | Pemain mengayunkan gada |
| `pukulan.wav` | `pukul` | Serangan mengenai buta/bos |
| `kena_serang.wav` | `kena` | Pemain terkena serangan |
| `langkah.wav` | `langkah` | Langkah kaki pemain |
| `lompat.wav` | `lompat` | Pemain melompat |
| `kemenangan.wav` | `menang` | Bos kalah (saron naik + gong) |
| `kekalahan.wav` | `kalah` | HP pemain habis (saron turun + gong) |
| `buta_ayun.wav` | `buta_ayun` | Buta Prajurit memukul |
| `buta_mati.wav` | `buta_mati` | Buta kalah |
| `terjang.wav` | `terjang` | Buta Kilat menerjang |
| `injak_bumi.wav` | `injak` | Buta Gempal menginjak bumi |
| `lempar_batu.wav` | `lempar` | Buta Pelempar melempar batu |
| `batu_jatuh.wav` | `batu_jatuh` | Batu mengenai sasaran/tanah |
| `bos_hantam.wav` | `bos_hantam` | Hantaman Bumi / bos menabrak tembok |
| `bos_raung.wav` | `bos_raung` | Bos muncul, menyeruduk, memanggil bala, murka |
| `gong.wav` | `gong` | Gelombang baru, bos memanggil bala, buka/tutup narasi |
| `keprak.wav` | `keprak` | Setiap baris narasi dalang |

Buat ulang placeholder: `pip install numpy` lalu `python tools/buat_audio.py` (butuh ffmpeg untuk .ogg).
Tombol **M** di dalam game menghidupkan/mematikan musik.
