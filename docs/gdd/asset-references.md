# Asset References

Semua aset dalam prototipe **dibuat sendiri** secara prosedural oleh pembuat proyek. **Tidak ada aset pihak ketiga.** Aset dapat dibuat ulang dengan skrip di folder `tools/`.

## Model 3D
| Aset | Jenis | Dibuat dengan | Lokasi kode | Lisensi |
|---|---|---|---|---|
| Karakter (Nara, NPC, pemain caci, penonton) | Model low-poly dari mesh primitif + animasi prosedural | Godot (CapsuleMesh, BoxMesh, SphereMesh, CylinderMesh, TorusMesh) | `src/scripts/karakter/karakter_model.gd` | Milik pembuat |
| Mbaru Niang, compang, gong & gendang, pohon, bukit, batu, arena, papan | Model low-poly | Godot (mesh primitif) | `src/scripts/dunia/dunia.gd` | Milik pembuat |

## Tekstur (`src/assets/textures/`, 64×64 px kecuali disebut lain)
| File | Isi | Dibuat dengan | Dipakai di |
|---|---|---|---|
| songke_merah/biru/hijau/kuning.png | Motif songke (dasar hitam, garis + belah ketupat) | `tools/generate_textures.py` (Pillow) | Sarung karakter, panggal |
| ijuk.png | Serat atap ijuk | idem | Atap Mbaru Niang |
| rumput.png, tanah.png, batu.png, kayu.png | Material lingkungan | idem | Tanah, arena, compang, tiang |
| kulit_kerbau.png | Kulit perisai | idem | Nggiling, kulit gendang |
| bingkai_songke.png (48×48) | Bingkai UI 9-patch | idem | Panel, dialog |

## Audio (`src/assets/audio/`, WAV 22.050 Hz mono)
| File | Isi | Dibuat dengan |
|---|---|---|
| musik_kampung.wav | Pola gong-gendang tenang + lonceng pentatonik (loop) | `tools/generate_audio.py` (numpy, sintesis aditif) |
| musik_caci.wav | Pola gong-gendang cepat untuk arena (loop) | idem |
| gong.wav, cambuk.wav, perisai.wav, terkena.wav, lompat.wav, langkah.wav, ambil.wav, berhasil.wav, gagal.wav, klik.wav | Efek suara | idem |

> Catatan etis: musik **bukan rekaman** gong-gendang atau nyanyian Manggarai asli. Musik disintesis sebagai penghormatan, sehingga tidak ada rekaman budaya yang dipakai tanpa izin.

## Font
Font bawaan Godot (tanpa font eksternal).

## Referensi budaya (bukan aset)
Deskripsi visual (bentuk Mbaru Niang, warna songke, kostum caci) diambil dari `docs/riset/referensi-visual.md`. Daftar pustaka lengkap ada di `docs/riset/catatan-riset.md`.
