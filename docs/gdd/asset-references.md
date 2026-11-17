# Asset References

Semua aset dalam prototipe **dibuat sendiri** secara prosedural oleh pembuat proyek. **Tidak ada aset pihak ketiga.** Aset dapat dibuat ulang dengan skrip di folder `tools/`.

## Model 3D
| Aset | Jenis | Dibuat dengan | Lokasi kode | Lisensi |
|---|---|---|---|---|
| Karakter (Nggohak, warga, penampil caci, penari) | Model bergaya anime 3D dari mesh primitif (kepala besar, mata berkilau, rambut bergelombang) + animasi prosedural | Godot (CapsuleMesh, BoxMesh, SphereMesh, CylinderMesh, TorusMesh) | `src/scripts/karakter/karakter_model.gd` | Milik pembuat |
| Mbaru Niang, compang, gong & gendang, pohon, bukit, batu, arena, papan | Model low-poly | Godot (mesh primitif) | `src/scripts/dunia/dunia.gd` | Milik pembuat |
| Anjing, ayam | Model low-poly + animasi prosedural | Godot (mesh primitif) | `src/scripts/dunia/hewan.gd` | Milik pembuat |
| Panorama opening & menu (kampung, lingko, pantai, komodo, laut, kapal, pulau) | Komposisi model low-poly yang ada + kamera sinematik | Godot | `src/scripts/dunia/panorama.gd`, `src/scripts/ui/opening.gd` | Milik pembuat |
| Pulau TN Komodo (laut, daratan pasir/sabana, dermaga, kapal wisata gaya pinisi, lontar, karang, gedung pelabuhan, sampah) | Model low-poly | Godot (mesh primitif) | `src/scripts/dunia/dunia_pulau.gd` | Milik pembuat |
| Penambah nyawa (cangkir kopi, kendi, kelapa muda), benang emas, tamu, jalur pendakian (ngarai, batu retak, titian, gerbang) | Model low-poly | Godot (mesh primitif) | `src/scripts/dunia/penambah_nyawa.gd`, `src/scripts/dunia/pendakian.gd`, `src/scripts/dunia/kampung.gd` | Milik pembuat |
| Ikon hati (nyawa), orb level, tombol bergaya songke, mini-game sangrai & tangkis | Gambar 2D prosedural (`_draw`) | Godot | `src/scripts/util/gambar_hati.gd`, `src/scripts/ui/level_selesai.gd`, `src/scripts/util/gaya.gd`, `src/scripts/minigame/` | Milik pembuat |
| Komodo | Model low-poly + animasi prosedural (ekor meliuk, kaki melangkah, lidah) | Godot (mesh primitif) | `src/scripts/dunia/komodo.gd` | Milik pembuat |
| Wisatawan & ranger (kaos, celana pendek, topi) | Variasi KarakterModel | Godot (mesh primitif) | `src/scripts/karakter/karakter_model.gd` | Milik pembuat |
| Peta perjalanan kapal & piktogram foto budaya | Gambar 2D prosedural (`_draw`) | Godot | `src/scripts/ui/peta_kapal.gd`, `src/scripts/minigame/jual_songke.gd` | Milik pembuat |
| Lingko (pematang, lodok, haju teno, juring sawah, pondok, wae teku, saluran) | Model low-poly + mesh juring (SurfaceTool) | Godot (mesh primitif, SurfaceTool) | `src/scripts/dunia/dunia_lingko.gd` | Milik pembuat |

## Tekstur (`src/assets/textures/`, 64×64 px kecuali disebut lain)
| File | Isi | Dibuat dengan | Dipakai di |
|---|---|---|---|
| songke_merah/biru/hijau/kuning.png | Motif songke (dasar hitam, garis + belah ketupat) | `tools/generate_textures.py` (Pillow) | Sarung karakter, panggal |
| ijuk.png | Serat atap ijuk | idem | Atap Mbaru Niang |
| rumput.png, tanah.png, batu.png, kayu.png | Material lingkungan | idem | Tanah, arena, compang, tiang |
| kulit_kerbau.png | Kulit perisai | idem | Nggiling, kulit gendang |
| ikon/ikon_144/180/192/512.png | Ikon aplikasi: Mbaru Niang di atas pita songke | `tools/generate_ikon.py` (Pillow) | Ikon PWA/web, jendela desktop |
| bingkai_songke.png (48×48) | Bingkai UI 9-patch | idem | Panel, dialog |
| ui/logo_manggarai.png | Logo "Jelajah Budaya Manggarai" (layar awal & menu) | Ilustrasi diberikan pengembang (dibuat dengan AI generatif) sebagai identitas visual; latar putih dibuat transparan [PERLU VERIFIKASI: catat alat/lisensi pembuatan ilustrasi] | Opening, menu utama |
| songke_nggohak.png | Motif songke Nggohak (dasar biru tua, belah ketupat besar merah-kuning-biru) | Dibuat pengembang; kode pembuatnya belum ada di `tools/generate_textures.py` [PERLU VERIFIKASI: tambahkan kode generator] | Sarung & ikat kepala Nggohak |

## Audio (`src/assets/audio/`, WAV 22.050 Hz mono)
| File | Isi | Dibuat dengan |
|---|---|---|
| musik_kampung.wav | Pola gong-gendang tenang + lonceng pentatonik (loop) | `tools/generate_audio.py` (numpy, sintesis aditif) |
| musik_caci.wav | Pola gong-gendang cepat untuk arena (loop) | idem |
| gendang.wav, anjing.wav (gonggong), ayam.wav (kotek), gong.wav, cambuk.wav, perisai.wav, terkena.wav, lompat.wav, langkah.wav, ambil.wav, berhasil.wav, gagal.wav, klik.wav | Efek suara | idem |
| benar.wav, salah.wav, kombo.wav, percik.wav | Umpan balik: jawaban benar, kesalahan (-1 nyawa), kombo beruntun, percikan air/lumpur (tahap 8) | idem |
| busur.wav, kena.wav, ledakan.wav, raung.wav | Tempur: dentingan busur, hentakan kena (teredam, tidak sadis), ledakan Panah Api, raungan bos | idem |
| Model musuh & bos (perampok, kera, ular, lebah, babi hutan, tikus, kalong, kepiting, ubur-ubur, kerbau, komodo) | Low-poly prosedural (`CreatureModel`, `KarakterModel`, `Komodo`, `Burung`) | Dibuat sendiri di kode |

> Catatan etis: musik **bukan rekaman** gong-gendang atau nyanyian Manggarai asli. Musik disintesis sebagai penghormatan, sehingga tidak ada rekaman budaya yang dipakai tanpa izin.

## Suara dialog (Text-to-Speech)
Dialog diucapkan memakai **mesin Text-to-Speech bawaan sistem operasi** (macOS: suara bahasa Indonesia "Damayanti"; Windows: suara bahasa Indonesia bila terpasang) lewat API Godot `DisplayServer.tts_speak`. Tidak ada file rekaman suara yang disertakan dalam proyek.

## Font
Font bawaan Godot (tanpa font eksternal).

## Referensi budaya (bukan aset)
Deskripsi visual (bentuk Mbaru Niang, warna songke, kostum caci) diambil dari `docs/riset/referensi-visual.md`. Daftar pustaka lengkap ada di `docs/riset/catatan-riset.md`.
