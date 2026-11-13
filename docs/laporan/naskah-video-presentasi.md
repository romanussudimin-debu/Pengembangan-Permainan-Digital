# Naskah Video Presentasi: Jejak Penti di Wae Rebo

**Nama:** Romanus Sudimin  
**NIM:** 240030260  
**Program Studi:** Sistem Informasi  
**Mata Kuliah:** Pengembangan Permainan Digital  
**Dosen Pengampu:** I Gede Suardika, S.Kom., M.Kom.  
**Durasi target:** ±8 menit (10 slide dan 1 demo singkat)

## Persiapan Rekaman

1. Buka berkas `06_Slide_Presentasi.pptx` (PowerPoint atau Keynote) dalam mode tayang (*slideshow*).
2. Buka juga game di browser: romanussudimin-debu.github.io/Pengembangan-Permainan-Digital. Tunggu sampai menu utama tampil, lalu biarkan tab ini terbuka untuk bagian demo.
3. Alat rekam:
   - Mac: tekan **Cmd + Shift + 5**, pilih "Rekam Seluruh Layar", lalu di Opsi pilih mikrofon.
   - Windows: OBS Studio, atau Xbox Game Bar (**Win + Alt + R**).
   - Kamera wajah boleh ditambahkan di pojok layar (opsional).
4. Gunakan ruangan yang tenang. Bicara pelan dan jelas, kira-kira 2 kalimat per 10 detik.
5. Teks di kolom **Narasi** boleh dibaca langsung. Kalimat dalam [kurung siku] adalah petunjuk tindakan dan tidak dibacakan.

## Ringkasan Alur

| No | Bagian | Waktu | Durasi |
|---|---|---|---|
| 1 | Slide 1: Pembukaan | 0:00–0:35 | 35 detik |
| 2 | Slide 2: Latar Budaya Manggarai | 0:35–1:25 | 50 detik |
| 3 | Slide 3: Metode Riset | 1:25–2:05 | 40 detik |
| 4 | Slide 4: Revisi Konsep | 2:05–2:50 | 45 detik |
| 5 | Slide 5: Core Loop dan Rantai Teka-teki | 2:50–3:30 | 40 detik |
| 6 | Slide 6: Dua Mekanik Utama | 3:30–4:15 | 45 detik |
| 7 | Slide 7: Integrasi Budaya | 4:15–5:00 | 45 detik |
| 8 | Slide 8: Arsitektur Teknis | 5:00–5:50 | 50 detik |
| 9 | Demo singkat di browser | 5:50–6:50 | 60 detik |
| 10 | Slide 9: Uji Coba dan Iterasi | 6:50–7:30 | 40 detik |
| 11 | Slide 10: Kesimpulan dan Penutup | 7:30–8:15 | 45 detik |

## Naskah Lengkap

### Bagian 1: Slide 1, Pembukaan (0:00–0:35)

**Tampilan:** slide judul "Jejak Penti di Wae Rebo" dengan gambar menu utama.

**Narasi:**

Selamat pagi, Bapak I Gede Suardika, dan teman-teman sekalian. Perkenalkan, nama saya Romanus Sudimin, NIM 240030260, dari Program Studi Sistem Informasi.

Pada kesempatan ini saya akan mempresentasikan hasil Rencana Tugas 1 mata kuliah Pengembangan Permainan Digital, yaitu prototipe game berbasis budaya lokal yang berjudul *Jejak Penti di Wae Rebo*. Game ini adalah game 3D jelajah budaya yang mengangkat budaya Manggarai, Flores, Nusa Tenggara Timur, dan dibuat menggunakan Godot 4.

[Pindah ke slide 2]

### Bagian 2: Slide 2, Latar Budaya Manggarai (0:35–1:25)

**Tampilan:** lima unsur budaya beserta keterangan jumlah sumber (36).

**Narasi:**

Saya memilih budaya Manggarai karena kekayaannya sangat beragam, tetapi masih jarang diangkat ke dalam game. Ada lima unsur yang saya angkat.

Pertama, Mbaru Niang, rumah adat berbentuk kerucut dengan lima tingkat. Kampung Wae Rebo yang memiliki rumah-rumah ini meraih penghargaan UNESCO Asia-Pacific pada tahun 2012.

Kedua, Penti, yaitu upacara syukur dan tahun baru adat setelah panen. Penti saya jadikan bingkai cerita game.

Ketiga, songke, kain tenun khas Manggarai berdasar hitam dengan motif berwarna yang memiliki makna.

Keempat, gong dan gendang, alat musik yang mengiringi ritual dan nyanyian adat.

Kelima, caci, tarian-tarung antara pemain yang menyerang, disebut paki, dan pemain yang menangkis, disebut ta'ang. Caci mengandung nilai sportivitas dan persaudaraan.

Semua informasi ini saya ambil dari 36 sumber, antara lain jurnal, situs Kemenparekraf, Badan Bahasa, dan arsip UNESCO.

[Pindah ke slide 3]

### Bagian 3: Slide 3, Metode Riset (1:25–2:05)

**Tampilan:** empat langkah riset dan angka 36, ±70, dan 9.

**Narasi:**

Riset budaya saya lakukan dalam empat langkah.

Langkah pertama adalah studi literatur dari jurnal, situs resmi pariwisata, dan arsip rekaman. Langkah kedua, saya menyusun glosarium yang berisi sekitar 70 istilah Manggarai beserta arti dan sumbernya. Langkah ketiga, saya membuat tabel adaptasi, yaitu memetakan setiap fakta budaya ke mekanik, visual, audio, dan narasi game. Langkah keempat adalah verifikasi. Bagian yang merupakan tafsir kreatif saya, dan belum dapat dipastikan dari sumber, saya tandai dengan label "perlu verifikasi".

Hasil riset ini kemudian menjadi 9 kartu pengetahuan budaya yang dikumpulkan pemain di dalam game.

[Pindah ke slide 4]

### Bagian 4: Slide 4, Revisi Konsep (2:05–2:50)

**Tampilan:** perbandingan konsep awal dan konsep akhir.

**Narasi:**

Konsep game ini sempat mengalami revisi. Konsep awalnya adalah duel caci: pemain bergantian menjadi paki dan ta'ang melawan tiga lawan dengan tingkat kesulitan yang terus naik.

Namun ada dua kendala. Pertama, mekaniknya terlalu sulit untuk pemain umum. Kedua, ada risiko caci hanya dipandang sebagai pertarungan, padahal caci adalah bagian dari upacara adat.

Karena itu, konsep saya ubah menjadi jelajah budaya. Pemain memecahkan rantai teka-teki bersama delapan warga kampung, memainkan mini-game menenun songke dan menabuh gong-gendang, lalu caci ditampilkan secara hormat sebagai pertunjukan pada perayaan Penti. Dengan cara ini, pengetahuan budaya menjadi kunci untuk maju di dalam game.

[Pindah ke slide 5]

### Bagian 5: Slide 5, Core Loop dan Rantai Teka-teki (2:50–3:30)

**Tampilan:** diagram siklus empat langkah.

**Narasi:**

Ini adalah *core loop* atau siklus utama permainannya, yang terdiri dari empat langkah.

Pemain menemui seorang warga, lalu menyelesaikan tantangan dari warga tersebut. Setelah berhasil, pemain mendapatkan kartu budaya. Kemudian pemain memecahkan petunjuk berupa teka-teki untuk menemukan warga berikutnya, dan siklus ini terus berulang.

Yang menarik, jawaban setiap teka-teki ada di dalam kartu yang sudah dikumpulkan. Jadi pemain harus benar-benar membaca dan memahami isi budayanya agar dapat melanjutkan permainan. Total ada 9 kartu dari 8 warga yang harus dikumpulkan secara berurutan.

[Pindah ke slide 6]

### Bagian 6: Slide 6, Dua Mekanik Utama (3:30–4:15)

**Tampilan:** gambar mini-game Menenun Songke dan Tabuh Gong-Gendang.

**Narasi:**

Selain eksplorasi dan teka-teki, game ini memiliki dua mekanik utama.

Yang pertama adalah Menenun Songke. Pemain menyamakan kain berukuran lima kali lima dengan contoh motif belah ketupat. Mekanik ini melatih pengamatan pola. Pemain dapat mengeklik atau mengetuk kotak, atau memakai tombol WASD dan E.

Yang kedua adalah Tabuh Gong dan Gendang, yaitu mekanik ritme. Pemain menabuh tepat pada ketukannya dengan toleransi 0,2 detik dan dinyatakan lulus jika minimal 60 persen ketukannya tepat. Kontrolnya menggunakan tombol J dan K, atau tombol GONG dan GENDANG di layar HP.

[Pindah ke slide 7]

### Bagian 7: Slide 7, Integrasi Budaya (4:15–5:00)

**Tampilan:** gambar Nggohak di kampung dan empat aspek integrasi budaya.

**Narasi:**

Budaya Manggarai saya integrasikan ke semua aspek game.

Dari sisi visual, ada tujuh Mbaru Niang yang melingkari compang, seperti tata kampung Wae Rebo. Tokohnya berkulit cokelat, berambut ombak, dan memakai sarung songke.

Dari sisi audio, musik latar memakai pola gong-gendang, dan setiap dialog diucapkan dengan nada suara yang berbeda untuk tiap tokoh.

Dari sisi narasi, cerita dibingkai oleh perayaan Penti dengan sapaan khas seperti "ité" dan "Kraeng".

Saya juga menjaga kepekaan budaya. Compang adalah tempat sakral, sehingga di dalam game compang hanya bisa dilihat dan tidak dapat dipakai bermain. Caci juga tidak dimainkan, melainkan ditampilkan sebagai pertunjukan.

[Pindah ke slide 8]

### Bagian 8: Slide 8, Arsitektur Teknis (5:00–5:50)

**Tampilan:** diagram arsitektur: Autoload, Scene dan FSM, Data JSON, dan Platform.

**Narasi:**

Selanjutnya arsitektur teknisnya. Game ini dibuat dengan Godot 4 dan bahasa GDScript.

Ada beberapa *autoload* atau skrip global. GameState mengatur enam keadaan permainan dengan *finite state machine*. Dialog Manager mengatur dialog dan suara *text-to-speech*. AudioManager mengatur musik dan efek suara. KontrolSentuh menampilkan joystick dan tombol untuk layar HP.

Karakter pemain juga memakai *state machine* dengan keadaan diam, jalan, lompat, jatuh, dan interaksi. Penampil caci di bagian ending memiliki lima keadaan.

Isi cerita, kartu budaya, dan dialog disimpan terpisah dalam file JSON sehingga mudah diubah tanpa menyentuh kode.

Game ini dapat dijalankan di browser dan HP, Windows, macOS, serta Android. Versi web dibangun secara otomatis oleh GitHub Actions setiap kali kode diperbarui.

Sekarang saya akan menunjukkan demo singkat gamenya.

[Pindah ke tab browser yang berisi game]

### Bagian 9: Demo Singkat di Browser (5:50–6:50)

**Tampilan:** rekaman layar game di browser.

| Waktu | Tindakan di layar | Narasi |
|---|---|---|
| 5:50–6:00 | Menu utama tampil, kamera mengorbit kampung. Klik **Mulai**. | "Ini menu utama yang menampilkan diorama kampung Wae Rebo. Saya mulai permainannya." |
| 6:00–6:15 | Gerakkan Nggohak (WASD), lewati Mbaru Niang dan compang, lalu lompat (Spasi). | "Pemain berperan sebagai Nggohak yang pulang ke kampung menjelang Penti. Ia dapat berjalan, melompat, dan menjelajahi kampung." |
| 6:15–6:35 | Dekati Tu'a Golo, tekan **E**, dan dengarkan dialognya. Jawab teka-teki, lalu kartu budaya pertama muncul. | "Saat berbicara dengan warga, dialog dibacakan dengan suara. Jawaban yang benar memberi kartu budaya dan petunjuk menuju warga berikutnya." |
| 6:35–6:50 | Tekan **Esc** untuk membuka menu jeda dan koleksi kartu. | "Semua kartu yang sudah dikumpulkan dapat dibaca ulang di menu jeda. Untuk demo lengkap mini-game dan ending Penti, silakan lihat video demo gameplay yang saya kumpulkan terpisah." |

[Kembali ke slide 9]

> **Catatan:** jika game di browser lambat saat direkam, bagian demo ini dapat diganti dengan potongan video demo gameplay (0:00–0:38) dengan narasi yang sama.

### Bagian 10: Slide 9, Uji Coba dan Iterasi (6:50–7:30)

**Tampilan:** hasil playtest.

**Narasi:**

Tahap berikutnya adalah pengujian. Saya melakukan playtest dengan 3 orang penguji. Setiap penguji bermain sekitar 8 sampai 10 menit, lalu mengisi kuesioner berisi 7 pertanyaan dengan skala 1 sampai 5.

Hasilnya, rata-rata skor kuesioner adalah 4 dari 5. Artinya, secara umum game ini dinilai baik oleh penguji.

Temuan utamanya adalah tampilan di HP masih terasa kecil dan tombol sentuhnya masih kurang. Masukan ini menjadi prioritas perbaikan berikutnya, yaitu memperbesar tampilan dan teks di HP serta menambah dan memperbesar tombol sentuh.

[Pindah ke slide 10]

### Bagian 11: Slide 10, Kesimpulan dan Penutup (7:30–8:15)

**Tampilan:** kesimpulan, rencana pengembangan, dan link game serta kode sumber.

**Narasi:**

Sebagai kesimpulan, melalui *Jejak Penti di Wae Rebo*, budaya Manggarai menjadi inti permainan, bukan sekadar hiasan. Pemain harus memahami budaya untuk dapat menyelesaikan game.

Ke depan, game ini dapat dikembangkan dengan menambah area baru seperti kebun lingko dan sawah lodok, menambah motif songke lain, menggunakan rekaman gong-gendang asli, serta memverifikasi isi budaya bersama penutur budaya Manggarai.

Game ini dapat dimainkan langsung di browser maupun HP melalui link yang tertera di layar, dan kode sumbernya tersedia di GitHub.

Demikian presentasi dari saya. Terima kasih kepada Bapak I Gede Suardika atas bimbingannya, dan terima kasih kepada teman-teman yang sudah menyimak. Selamat pagi.

[Biarkan slide 10 tampil 3 detik, lalu hentikan rekaman]

## Tips Setelah Merekam

1. Tonton ulang rekaman dan potong bagian awal atau akhir yang kosong (iMovie, CapCut, atau Clipchamp).
2. Pastikan suara narasi dan suara game sama-sama terdengar jelas.
3. Simpan dalam format MP4 1080p dengan nama `Video_Presentasi_Romanus_Sudimin_240030260.mp4`.
4. Jika ingin durasinya lebih pendek (±5 menit), bagian demo (Bagian 9) boleh dihapus dan narasi tiap slide dipersingkat menjadi 2–3 kalimat.
