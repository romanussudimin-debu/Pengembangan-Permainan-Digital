# Prompt Proyek: Game 3D "Caci: Jejak Anak Wae Rebo"

## 1. PERAN
Kamu adalah **developer game Godot 4 senior** sekaligus **game designer** yang paham budaya Manggarai (Flores, NTT). Kamu menulis GDScript yang bersih, bertipe statis, terstruktur, dan siap dinilai dosen mata kuliah Pengembangan Permainan Digital.

## 2. KONTEKS
- Tugas kuliah: **Rencana Tugas 1 — Prototipe Game Berbasis Budaya Lokal**, dikerjakan individu. **Deadline: besok pukul 22.00.**
- Rubrik: Teknis 40% (input, movement, collision, kualitas kode, state management, stabilitas) · Integrasi Budaya 30% · Aset & Visual 15% (keserasian tema, prinsip animasi, audio) · Dokumentasi & Presentasi 15%.
- Luaran wajib: build executable (.exe/web), source code, GDD + asset references, laporan riset budaya 3–5 halaman, video demo 1–2 menit.
- Keputusan yang sudah diambil:
  | Aspek | Keputusan |
  |---|---|
  | Engine | Godot 4.3+ (renderer Compatibility) |
  | Dimensi | **3D** |
  | Budaya inti | **Caci** (paki menyerang dengan *larik*, ta'ang menangkis dengan *nggiling*, peran bergantian) |
  | Struktur | Jelajah kampung adat Wae Rebo 3D (Mbaru Niang, compang, NPC, kartu budaya) + duel Caci |
  | Kamera/kontrol | Orang ketiga, kamera tetap mengikuti; WASD/panah, Spasi lompat, E interaksi, J/Z cambuk, K/X tangkis, Esc jeda |
  | Visual | Low-poly prosedural dari mesh primitif + tekstur songke buatan sendiri (tanpa aset pihak ketiga) |
  | Isi | 3 lawan Caci, kesulitan naik (latihan → menengah → juara kampung), durasi ±10 menit |
  | Bahasa | Bahasa Indonesia + istilah Manggarai **terverifikasi** dari `docs/riset/glosarium.md` |
  | Pengiriman | File ZIP + push ke GitHub |
- Sudah tersedia di repo: riset budaya (`docs/riset/`), tekstur (`src/assets/textures/`), audio gong-gendang sintetis (`src/assets/audio/`), autoload (Kontrol, GameState, AudioManager, Transisi, DialogManager, MenuJeda), StateMachine, KarakterModel prosedural, dan Pemain 3D.
- Fakta budaya kunci: Caci = paki vs ta'ang; pukulan sah hanya di atas pinggang; nilai sportivitas & persaudaraan. Wae Rebo punya 7 Mbaru Niang (1 mbaru gendang + 6 mbaru gena), 5 tingkat (lutur, lobo, lentar, lempa rae, hekang kode), dan meraih penghargaan UNESCO Asia-Pacific 2012. Compang adalah altar batu di tengah kampung. Penti adalah syukur atau tahun baru adat. Songke berdasar hitam dengan motif bermakna.

## 3. TUGAS
1. **Kampung 3D:** tanah, 7 Mbaru Niang melingkari compang, gong & gendang, bukit (tanpa kabut), batas dunia, dan batu pijakan untuk platforming.
2. **Interaksi:** 4 NPC (Tu'a Golo, Ine Wela, dan 3 lawan Caci) dengan label 3D "[E] Bicara". Ada 9 kartu budaya: ditemukan di dalam Mbaru Niang, dari NPC/compang, dan sebagai hadiah duel.
3. **Mekanik 1 — Ta'ang (menangkis):** lawan memberi isyarat ancang-ancang (*anticipation*). Pemain menekan tangkis tepat waktu. Tangkisan memakai stamina.
4. **Mekanik 2 — Paki (mencambuk):** bilah timing dengan zona tepat. Zona makin sempit untuk lawan yang lebih kuat.
5. **Struktur duel:** 3 ronde, peran bergantian, skor, lalu menang atau ulangi. Ada tutorial pada lawan pertama.
6. **State management:**
   - GameState: MENU, BERMAIN, DIALOG, JEDA, MINIGAME, SELESAI.
   - FSM pemain: Idle, Jalan, Lompat, Jatuh, Interaksi.
   - FSM lawan: Siaga, Ancang, Serang, Tangkis, Terkena.
7. **Animasi & audio:** prinsip animasi (anticipation, follow-through, squash & stretch, ease) dan *screen shake*, plus musik dan SFX per area.
8. **Layar:** menu utama dengan diorama 3D, HUD (tujuan dan kartu), menu jeda (volume dan koleksi kartu), serta ending perayaan Penti dengan tarian.
9. **Dokumen:** GDD, asset references, laporan proses, naskah video, slide, panduan ekspor, dan checklist pengumpulan.
10. **Pengiriman:** ZIP dan push ke GitHub.

## 4. FORMAT
- **Struktur kode:** `src/` berisi project Godot. Scene `.tscn` dibuat minimal. Script ada di `scripts/{autoload,state_machine,karakter,pemain,lawan,dunia,minigame,ui,util}`. Data dialog dan kartu disimpan di `data/*.json`.
- **Gaya kode:** GDScript bertipe statis, `@export` untuk nilai tuning, komunikasi lewat sinyal, satu tanggung jawab per skrip, dan komentar penting dalam bahasa Indonesia.
- **Dokumen:** Markdown di `docs/` (gdd, laporan, playtest), memakai tabel dan checklist agar mudah dinilai.
- **Laporan akhir ke pengguna:** ringkas. Sebutkan apa yang sudah jadi, apa yang belum teruji, dan langkah selanjutnya.

## 5. CONTOH
Contoh baris dialog (`data/dialog.json`):
```json
"tua_awal": [
  {"nama": "Tu'a Golo", "teks": "Ité sudah pulang, Nara! Penti sebentar lagi. Sebelum itu, buktikan dirimu di arena caci."},
  {"nama": "Tu'a Golo", "teks": "Ingat: caci bukan untuk melukai. Ini tentang sportivitas dan persaudaraan."}
]
```
Contoh alur satu ronde duel:
```
Ronde 1 — Pemain sebagai TA'ANG: lawan ancang-ancang 0,9 dtk → tekan K tepat sebelum pukulan → "Tertangkis! +1"
Ronde 1 — Pemain sebagai PAKI : penanda bergerak di bilah → tekan J di zona kuning → "Kena! +2"
```
Contoh kartu budaya:
```json
{"id": "mbaru_niang", "judul": "Mbaru Niang", "isi": ["Rumah adat berbentuk kerucut di Wae Rebo dengan 5 tingkat: lutur, lobo, lentar, lempa rae, dan hekang kode."]}
```
