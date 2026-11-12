# Laporan Penelitian Budaya
## Budaya Manggarai sebagai Fondasi Game 3D *Jejak Penti di Wae Rebo*

**Nama:** Romanus Sudimin  
**NIM:** 240030260  
**Program studi:** Sistem Informasi  
**Mata kuliah:** Pengembangan Permainan Digital — Rencana Tugas 1: Prototipe Game Berbasis Budaya Lokal  
**Tanggal:** 12 November 2026

---

## 1. Pendahuluan

Game berbasis budaya lokal menuntut lebih dari sekadar tempelan ornamen; unsur budaya perlu dipahami makna dan praktiknya agar dapat diterjemahkan menjadi visual, audio, narasi, dan terutama mekanik permainan. Laporan ini menyajikan hasil studi literatur tentang budaya Manggarai di Pulau Flores, Nusa Tenggara Timur, sebagai fondasi pengembangan game 3D jelajah budaya *Jejak Penti di Wae Rebo* (engine Godot 4).

Dalam game, pemain berperan sebagai **Nggohak**, anak muda Manggarai yang pulang ke kampung adat menjelang upacara **Penti**. Pemain menjelajahi kampung 3D yang terinspirasi Wae Rebo, dengan tujuh **Mbaru Niang** yang melingkari **Compang**. Delapan warga masing-masing menyimpan satu kartu pengetahuan budaya, dan kartu-kartu itu harus dikumpulkan **berurutan**. Setiap warga memberi tantangan berupa teka-teki tentang budaya, **menenun motif songke**, atau **menabuh gong-gendang**. Setelah berhasil, warga memberi kartu beserta petunjuk menuju warga berikutnya. Pada puncak Penti, **caci** ditampilkan sebagai pertunjukan.

Tujuan penelitian: (a) memilih unsur budaya fokus dan pendukung; (b) menghimpun fakta bersumber tentang sejarah, makna, dan praktiknya; (c) menganalisis potensi adaptasinya ke game; dan (d) merumuskan pertimbangan etis. Metode yang digunakan adalah studi literatur daring terhadap jurnal ilmiah Indonesia, situs pemerintah (Kementerian Pariwisata/Indonesia.travel, Jadesta, Badan Bahasa), dokumentasi penghargaan UNESCO, dan media kredibel, diakses 12 November 2026. Keterbatasan: sebagian sumber hanya dapat dibaca pada tingkat abstrak/cuplikan, sehingga data bibliografis yang belum lengkap ditandai **[PERLU VERIFIKASI]**. Catatan lengkap terdapat pada `catatan-riset.md`.

## 2. Profil Masyarakat Manggarai

Masyarakat Manggarai mendiami ujung barat Pulau Flores yang kini terbagi atas tiga kabupaten: Manggarai (ibu kota Ruteng), Manggarai Barat (Labuan Bajo), dan Manggarai Timur (Borong). Mereka bertutur dalam bahasa Manggarai dengan variasi dialek yang cukup nyata; misalnya kata untuk "ayah" dapat berbentuk *ema*, *ame*, atau *ameh* tergantung wilayah. Sebagian besar masyarakat bermata pencaharian petani, sementara menenun kain songke terutama dikerjakan perempuan dan menjadi sumber penghasilan keluarga.

Kehidupan adat Manggarai dirangkum dalam ungkapan **"gendang one, lingko pe'ang"**: rumah gendang (*mbaru gendang*) di dalam kampung adalah pusat kehidupan, sedangkan lahan komunal (*lingko*) di luar kampung adalah sumber kehidupan. Kampung dan tanah dipandang sebagai satu kesatuan yang tak terpisahkan. Dalam tata ruang kampung terdapat *natas* (halaman bersama), *compang* (altar batu), dan *wae teku* (sumber air). Kepemimpinan adat dipegang antara lain oleh *tu'a golo* (tua kampung) dan *tu'a teno* (tetua yang berwenang membagi tanah).

Nilai musyawarah tampak dalam praktik *lonto leok*, yaitu duduk melingkar untuk memutuskan urusan bersama. Kesantunan berbahasa ditandai kata ganti hormat *ité*, yang menurut kajian Menggo (2024) mengungkapkan rasa hormat, kerendahan hati, dan kedekatan kepada lawan bicara. Dalam ritus adat, Tuhan disebut *Mori Kraeng* dan leluhur disebut *empo*. Perkawinan dipandang sebagai urusan dua keluarga besar dengan *belis* (mas kawin) sebagai unsur penting. Komposisi agama dan rincian sistem klan (*wa'u*) belum terverifikasi dalam riset ini [PERLU VERIFIKASI].

## 3. Unsur Budaya Terpilih

Konsep game berupa jelajah budaya, sehingga beberapa unsur diangkat secara seimbang. **Songke** dan **gong-gendang** menjadi dasar dua mini-game. **Mbaru Niang**, **Compang**, dan **Penti** menjadi latar dan bingkai cerita. **Caci** menjadi materi teka-teki dan pertunjukan puncak Penti. **Lingko** dikaji sebagai konteks penting tata ruang dan kehidupan adat Manggarai (*gendang one, lingko pe'ang*), sekaligus kandidat mekanik untuk pengembangan lanjutan.

### 3.1 Caci

**Sejarah dan konteks.** Caci adalah tari-tarung cambuk yang dimainkan berpasangan oleh pria Manggarai dan diwariskan turun-temurun di seluruh Manggarai Raya. Caci lazim dipentaskan pada perayaan syukur panen dan Penti. Beberapa sumber populer menyebut caci dahulu berkaitan dengan penyelesaian sengketa antarkampung [PERLU VERIFIKASI]. Status caci sebagai Warisan Budaya Takbenda Indonesia tidak ditemukan konfirmasi resminya dalam riset ini [PERLU VERIFIKASI]. Kajian tahun 2025 (jurnal *Pilar*) mencatat minat generasi muda terhadap caci menurun, sehingga upaya pelestarian diperlukan.

**Praktik.** Dua peran utama adalah **paki** (pencambuk) dan **ta'ang** (penangkis), yang hubungannya dikaji dalam *Paradigma: Jurnal Kajian Budaya* (2024). Paki menyerang dengan **larik**, cambuk dari kulit kerbau. Ta'ang bertahan dengan **nggiling**, perisai bundar dari kulit kerbau, dan **agang/tereng**, busur penangkis dari rotan atau bambu. Pemain mengenakan **panggal**, penutup kepala menyerupai tanduk kerbau yang dilapisi kain warna-warni, serta **ndeki**, hiasan menyerupai ekor di pinggang belakang. Aturannya jelas: serangan hanya sah ke tubuh di atas pinggang; pukulan yang tidak tertangkis dapat melukai; dan pemain yang terkena di mata dinyatakan kalah. Pertunjukan diiringi gong, gendang, dan nyanyian, termasuk *dere caci*.

**Makna.** Penelitian menyebut caci melambangkan kejantanan, kemeriahan, dan sportivitas, serta menegaskan nilai kebersamaan, kekeluargaan, persaudaraan, dan gotong royong. Pemain caci dituntut bersikap sportif dan kreatif. Dengan kata lain, caci adalah ketangkasan yang dibingkai persaudaraan, bukan permusuhan.

### 3.2 Lingko

**Sejarah dan konteks.** *Lingko* adalah tanah ulayat komunal yang dibagi kepada keluarga-keluarga anggota kampung. Pola pembagian **lingko lodok** membentuk petak-petak menyerupai **jaring laba-laba**. Contoh paling terkenal ada di Cancar dan Meler (sekitar Ruteng): dari Bukit Weol terlihat sebelas hamparan sawah lodok milik delapan kampung (Udus dkk.; Mongabay, 2017).

**Praktik.** Pembagian diawali rapat **reke lodok** untuk menentukan waktu dan siapa yang berhak. Di titik pusat (**lodok**) ditanam kayu **teno** (*haju teno*). Dari pusat itu ditarik garis-garis batas **moso** ke tepi lahan, membentuk juring-juring yang melebar ke luar. Jumlah moso dihitung "menurut jari tangan", disesuaikan dengan jumlah penerima dan keturunannya. Pembagian dipimpin **tu'a teno**. Satu temuan penting: *tu'a teno* dan *tu'a golo* umumnya memperoleh bagian lebih luas. Artinya, keadilan dalam lingko adalah keadilan menurut kesepakatan adat dan kedudukan sosial, bukan sekadar luas yang sama rata. Kajian di *Jurnal Alternatif* (Undana) secara khusus menelaah apakah prosedur ini menghasilkan rasa keadilan.

**Makna.** Lingko melambangkan kekuatan kolektif masyarakat dalam mengolah tanah bersama, jaringan sosial, dan solidaritas. Pola juring lingkaran juga telah dikaji sebagai sumber etnomatematika (sudut dan juring), sehingga sangat cocok untuk teka-teki.

### 3.3 Mbaru Niang

**Sejarah.** Kampung Wae Rebo (Desa Satar Lenda, Kecamatan Satarmese Barat, Kabupaten Manggarai) terletak terpencil di pegunungan. Kampung ini memiliki tujuh *mbaru niang*: satu *mbaru gendang* sebagai rumah utama yang menyimpan pusaka dan menjadi tempat berkumpul, serta enam *mbaru gena* sebagai rumah pendamping. Pembangunan ulang rumah-rumah ini secara gotong royong, diprakarsai Yayasan Rumah Asuh yang dipimpin arsitek Yori Antar, memperoleh **Award of Excellence** (penghargaan tertinggi) dalam **UNESCO Asia-Pacific Awards for Cultural Heritage Conservation 2012**, diumumkan di Bangkok pada 27 Agustus 2012, dari 43 nominasi asal 11 negara.

**Praktik dan makna.** Mbaru niang berbentuk kerucut tinggi beratap daun lontar yang menutup hingga hampir ke tanah. Rumah ini memiliki lima tingkat: *lutur* (tempat tinggal keluarga besar), *lobo* (bahan makanan dan barang), *lentar* (benih untuk musim tanam berikutnya), *lempa rae* (cadangan pangan saat paceklik), dan *hekang kode* (tempat sesajian untuk leluhur, paling sakral). Susunan ini mencerminkan hubungan manusia, pangan, dan leluhur secara vertikal.

### 3.4 Compang dan Penti

**Compang** adalah susunan batu berundak di tengah kampung, tempat meletakkan persembahan bagi penjaga dan pelindung kampung. **Penti** adalah pesta tahun baru adat Manggarai (Verheijen dalam Janggur, 2010) sekaligus syukur atas pergantian musim kerja dan hasil panen. Penti dirayakan antara September dan Desember, dengan waktu yang bervariasi antarkampung. Di Kampung Pau, Penti meliputi ritus *Barong Lodok*, *Barong Wae Teku*, *Barong Boa*, dan *Barong Compang*, yaitu penghormatan di lingko, mata air, makam, dan compang. Penti memiliki dimensi vertikal (syukur kepada *Mori Kraeng* dan leluhur), horizontal (relasi dengan alam), dan sosial (kebersamaan warga). Penti di Wae Rebo dipromosikan pemerintah sebagai ritual sakral.

### 3.5 Songke

*Towe songke* adalah kain tenun Manggarai dengan **warna dasar hitam** dan motif berwarna di atasnya. Warna hitam dikaitkan dengan iklim pegunungan yang dingin. Motif-motifnya bermakna: *jok* sebagai identitas Manggarai; *wela kaweng* (bunga) sebagai relasi manusia dengan alam; *ranggong* (laba-laba) sebagai kejujuran dan kerja keras; *su'i* (garis) sebagai kehidupan yang tumbuh dan batas hukum adat; dan *mata manuk* (mata ayam) sebagai lambang Tuhan Yang Maha Melihat, yang juga dipakai dalam persembahan pada ritus seperti Penti (kajian Pong Lengor, *Nirwasita* dan *Widyadari*, 2022). Makna warna benang selain hitam tidak ditemukan dalam sumber terverifikasi.

### 3.6 Musik dan nyanyian

Tiga bentuk vokal adat utama adalah *sanda* (berdiri melingkar, tanpa alat musik), *mbata* (duduk, diiringi gong dan gendang yang lembut), dan *danding* (berkelompok, bergerak melingkar). Pukulan gong-gendang mengiringi berbagai ritus, termasuk *congko lokap* (peresmian rumah adat), dan polanya telah ditranskripsi dalam kajian akademik.

## 4. Analisis Potensi Adaptasi ke Game

**Mekanik 1 — Rantai teka-teki (jelajah).** Kartu pengetahuan dipegang oleh delapan warga dan harus dikumpulkan berurutan. Setiap warga menunjukkan warga berikutnya lewat petunjuk deskriptif, misalnya *"perempuan yang menenun kain berdasar hitam di sisi barat kampung"*. Teka-teki pilihan ganda menguji isi kartu yang baru didapat, misalnya warna dasar songke, nama tingkat teratas Mbaru Niang (*hekang kode*), nyanyian *sanda*, peran *ta'ang*, dan perisai *nggiling*. Dengan cara ini pengetahuan budaya menjadi kunci kemajuan permainan, bukan sekadar hiasan. Bentuk ini juga mencerminkan cara pengetahuan adat diwariskan: dari orang ke orang di dalam komunitas.

**Mekanik 2 — Menenun songke.** Pemain menyamakan kain 5×5 dengan contoh motif belah ketupat berdasar hitam. Mekanik ini menyederhanakan proses tenun menjadi teka-teki pola, sehingga pemain mengalami bahwa songke disusun dari pola berulang yang teliti. Motif dalam game adalah **penyederhanaan kreatif**, bukan reproduksi motif adat tertentu.

**Mekanik 3 — Tabuh gong-gendang.** Pemain menabuh gong dan gendang mengikuti irama untuk mengiringi Penti. Musik yang biasanya menjadi latar dijadikan mekanik permainan. Pola iramanya adalah **ciptaan pengembang**, bukan pola adat tertentu [PERLU VERIFIKASI].

**Caci sebagai pertunjukan.** Duel caci tidak dijadikan pertarungan yang dimainkan. Caci ditampilkan pada ending Penti: dua penampil bergantian berperan sebagai paki dan ta'ang, dengan ancang-ancang, pukulan, dan tangkisan nggiling. Pilihan ini menjaga caci tetap tampil dengan hormat dan menekankan nilai sportivitas, sementara pengetahuan tentang caci disampaikan lewat kartu dan teka-teki.

**Unsur pendukung.**
- **Mbaru Niang:** menjadi hub 3D berupa tujuh rumah kerucut (satu mbaru gendang lebih besar) yang mengelilingi natas. Kelima tingkatnya ditandai pada atap dan dijelaskan lewat kartu.
- **Compang:** menjadi landmark di tengah kampung yang dapat *dilihat* dan dijelaskan, tetapi tidak dijadikan tempat bermain karena bersifat sakral.
- **Penti:** menjadi bingkai cerita dan klimaks; pertunjukan caci dan tarian warga menjadi puncak perayaan.
- **Songke:** mewarnai pakaian NPC, panel UI (motif *su'i* sebagai border), dan latar kartu pengetahuan.
- **Musik:** nuansa gong-gendang yang lembut untuk area kampung dan pola yang lebih cepat untuk perayaan Penti.
- **Kartu pengetahuan:** 9 kartu dalam prototipe: Mbaru Niang (lima tingkat), Kampung Wae Rebo (UNESCO 2012), Compang, Songke, Penti, Gong–Gendang & Nyanyian, Caci (paki & ta'ang), Perlengkapan Caci, dan Nilai Sportivitas Caci. Setiap kartu memuat fakta dari riset ini, sehingga game sekaligus menjadi media edukasi.

**Bahasa dalam dialog.** Gunakan istilah yang terverifikasi: *ité* (sapaan hormat), *ema* (ayah), *neka rabo* (maaf), *Mori Kraeng* (Tuhan), dan nama benda/tempat adat. Salam seperti *tabe* atau *di'a* belum terverifikasi sehingga ditunda pemakaiannya.

## 5. Pertimbangan Etis

1. **Ruang sakral tidak dijadikan objek permainan.** *Hekang kode*, compang, dan ritus *barong* Penti hanya ditampilkan atau diceritakan, tidak dapat dipanjat, dijarah, atau "dimainkan". Tidak ada simulasi persembahan atau hewan kurban.
2. **Caci tidak digambarkan sebagai kekerasan atau perang.** Efek kena dibuat abstrak tanpa darah/gore. Narasi menekankan sportivitas dan persaudaraan, dan "serangan ke mata" tidak dijadikan jurus.
3. **Komunitas nyata.** Wae Rebo adalah kampung yang hidup dan memiliki aturan kunjungan sendiri. Tokoh dan keluarga dalam game bersifat fiktif, dan kredit menyebut bahwa kampung dalam game *terinspirasi* Wae Rebo.
4. **Keakuratan dan transparansi.** Fakta bersumber dibedakan dari tafsir kreatif (misalnya kaitan motif ranggong dengan lingko, serta mekanik stamina). Hal yang belum pasti ditandai, dan glosarium memberi status aman/tidak bagi setiap istilah.
5. **Hak cipta dan atribusi.** Rekaman musik arsip (mis. CREM-CNRS) dan foto asli hanya dipakai bila lisensinya jelas. Untuk prototipe, disarankan musik dan sprite orisinal yang *terinspirasi*, dengan seluruh sumber dicatat di `asset-references.md`.
6. **Validasi komunitas.** Idealnya naskah dan istilah ditinjau penutur asli Manggarai sebelum rilis publik.

## 6. Kesimpulan

Budaya Manggarai menyediakan bahan yang sangat kaya untuk game jelajah budaya. Pengetahuan tentang **Mbaru Niang**, **compang**, **Penti**, **songke**, **gong-gendang**, dan **caci** dapat dijalin menjadi rantai teka-teki yang mengajak pemain belajar dari satu warga ke warga lain. **Songke** dan **gong-gendang** dapat diterjemahkan menjadi mekanik pola dan ritme yang mudah dimainkan. **Caci** tampil dengan hormat sebagai pertunjukan puncak Penti yang menonjolkan nilai sportivitas dan persaudaraan. **Lingko** tetap menjadi konteks penting dan kandidat mekanik untuk pengembangan lanjutan. Dengan pembedaan yang jelas antara fakta bersumber dan tafsir kreatif, serta perlakuan hormat terhadap ruang dan ritus sakral, *Jejak Penti di Wae Rebo* berpotensi menjadi game yang menghibur sekaligus edukatif. Langkah lanjutan adalah memverifikasi butir bertanda [PERLU VERIFIKASI], terutama status WBTb caci, salam berbahasa Manggarai, dan data bibliografis jurnal.

## 7. Daftar Pustaka
*(Seluruhnya diakses 12 November 2026; data yang belum lengkap ditandai [PERLU VERIFIKASI].)*

1. Antara Kupang. (2024). *Dirut BPOLBF: Budaya Manggarai jadi basis nilai pengembangan Parapuar*. https://kupang.antaranews.com/berita/126111/dirut-bpolbf--budaya-manggarai-jadi-basis-nilai-pengembangan-parapuar
2. CREM-CNRS. (t.t.). *(Manggarai Timur) chœur mixte Mbata* [rekaman arsip]. https://archives.crem-cnrs.fr/archives/items/CNRSMH_I_2000_008_003_08/
3. Good News From Indonesia. (2015, 30 September). *Rumah tradisional Flores ini mendapat Award of Excellence dari UNESCO*. https://www.goodnewsfromindonesia.id/2015/09/30/rumah-tradisonal-flores-ini-mendapat-award-of-excellence-dari-unesco
4. Good News From Indonesia. (2024, 12 Februari). *Potret kehidupan kolektif masyarakat Manggarai dalam budaya lonto leok*. https://www.goodnewsfromindonesia.id/2024/02/12/potret-kehidupan-kolektif-masyarakat-manggarai-dalam-budaya-lonto-leok
5. Good News From Indonesia. (2024, 27 Maret). *Tenun songke, kearifan lokal khas Manggarai Flores Nusa Tenggara Timur*. https://www.goodnewsfromindonesia.id/2024/03/27/tenun-songke-kearifan-lokal-khas-manggarai-flores-nusa-tenggara-timur
6. Good News From Indonesia. (t.t.). *Uniknya musik tradisional ala Flores*. https://www.goodnewsfromindonesia.id/cerita-dari-kawan/tren/uniknya-musik-tradisional-ala-flores
7. Kementerian Pariwisata dan Ekonomi Kreatif RI. (t.t.). *Flores – Wae Rebo Village*. Indonesia.travel. https://www.indonesia.travel/id/id/destination/bali-nusa-tenggara/east-nusa-tenggara/flores---wae-rebo-village
8. Kementerian Pariwisata dan Ekonomi Kreatif RI. (t.t.). *The sacred rituals of Penti*. Indonesia.travel. https://indonesia.travel/ph/en/destinations/bali-nusa-tenggara/flores/the-sacred-rituals-of-penti
9. Kementerian Pariwisata RI. (t.t.). *Atraksi Tarian Caci*. Jadesta. https://jadesta.kemenpar.go.id/atraksi/tarian_caci_1
10. Menggo, S. (2024). The function of honorific term ité: Cultural perspectives from Manggarai, Indonesia. *Journal of Language and Literature*. https://e-journal.usd.ac.id/index.php/JOLL/article/view/7926
11. Mongabay Indonesia. (2017, 28 Juli). *Sawah berbentuk jaring laba-laba di Manggarai ini, hanya satu-satunya di dunia*. https://mongabay.co.id/2017/07/28/sawah-berbentuk-jaring-laba-laba-di-manggarai-ini-hanya-satu-satunya-di-dunia/
12. Moses, F. (2018). *Mengenal Manggarai di Nusa Tenggara Timur*. Badan Pengembangan dan Pembinaan Bahasa. https://badanbahasa.kemdikbud.go.id/resource/doc/files/Mengenal_Manggarai_di_Nusa_Tenggara_Timur-Desember.pdf
13. [Penulis PERLU VERIFIKASI]. (2019). Nilai kesenian budaya tarian caci pada masyarakat Manggarai Kabupaten Manggarai Timur. *Equilibrium*. https://journal.unismuh.ac.id/index.php/equilibrium/id/article/view/2663
14. [Penulis PERLU VERIFIKASI]. (2021). [Pertunjukan musik Mbata di Kota Komba]. *Jurnal Citra Pendidikan*, 1(2), 204–215. https://jurnal.citrabakti.ac.id/index.php/jcp/article/download/223/141
15. [Penulis PERLU VERIFIKASI]. (2022). [Teknik pukulan gong dan gendang ritual congko lokap]. *Jurnal Citra Pendidikan*, 2(1), 84–92. https://jurnal.citrabakti.ac.id/index.php/jcp/article/download/382/220
16. [Penulis PERLU VERIFIKASI]. (2022). [Motif tenun songke Pong Lengor]. *Nirwasita*, 3(1). https://ojs.mahadewa.ac.id/index.php/nirwasita/article/view/2247 ; *Widyadari*, 23(2). https://ojs.mahadewa.ac.id/index.php/widyadari/article/view/2268
17. [Penulis PERLU VERIFIKASI]. (2022). Personal pronouns ité as politeness marker in Manggarai language and culture, Indonesia. *Edulite*. https://jurnal.unissula.ac.id/index.php/edulite/article/view/21083
18. [Penulis PERLU VERIFIKASI]. (2023). [Makna tarian caci]. *Jurnal Edukasi Citra Olahraga*. https://jurnal.citrabakti.ac.id/index.php/jor/article/download/2098/601/6242
19. [Penulis PERLU VERIFIKASI]. (2023). [Konsep matematis sawah lodok]. *JPMI*. https://journal.ikipsiliwangi.ac.id/index.php/jpmi/article/view/20468/6081
20. [Penulis PERLU VERIFIKASI]. (2024). [Paki dan ta'ang dalam caci]. *Paradigma: Jurnal Kajian Budaya*, 14(2). https://doi.org/10.17510/paradigma.v14i2.1387
21. [Penulis PERLU VERIFIKASI]. (2024). Tari tradisional caci perantau Manggarai di Pontianak. *BALELE*. https://jurnal.untan.ac.id/index.php/BALELE/article/download/80853/pdf
22. [Penulis PERLU VERIFIKASI]. (2025). Estetika ruang rumah adat Mbaru Niang Wae Rebo. *Jurnal Vastukara*, 5(1). https://doi.org/10.59997/vastukara.v5i1.4616
23. [Penulis PERLU VERIFIKASI]. (2025). An evaluation of the relationship between function, form, and architectural meaning of the traditional house Mbaru Niang in Wae Rebo Village. *ARTEKS*, 10(2), 421–434. https://doi.org/10.30822/arteks.v10i2.4635
24. [Penulis PERLU VERIFIKASI]. (2025). Upaya pelestarian tari caci sebagai budaya lokal Kecamatan Manggarai, NTT. *Pilar*. https://e-journal.unmas.ac.id/index.php/pilar/article/view/11258
25. [Penulis & tahun PERLU VERIFIKASI]. [Prosedur pembagian tanah lingko dan rasa keadilan]. *Jurnal Alternatif* (Undana). https://ejurnal.undana.ac.id/index.php/alj/article/view/13336
26. [Penulis & tahun PERLU VERIFIKASI]. Pemanfaatan jenis-jenis tumbuhan bahan bangunan rumah adat Mbaru Niang Kampung Wae Rebo. *Biotropikal Sains* (Undana). https://ejurnal.undana.ac.id/index.php/biotropikal/issue/download/653/7-PEMANFAATAN%20JENIS-JENIS%20TUMBUHAN%20BAHAN%20BANGUNAN%20RUMAH%20ADAT%20MBARU%20NIANG%20KAMPUNG%20WAE%20REBO%20DESA%20SATAR%20LENDA%20KECAMATAN%20SATARMESE%20BARAT%20KABUPATEN%20MANGGARAI
27. [Penulis & tahun PERLU VERIFIKASI]. [Nilai dalam permainan caci]. *Verbavitae* (Unwira). https://www.journal.unwira.ac.id/index.php/VERBAVITAE/en/article/download/461/178/1615
28. [Penulis PERLU VERIFIKASI]. Politeness in tiba meka ritual in Manggaraian language and culture, Eastern Indonesia. *International Journal of Social Sciences* (UFS). https://pubs.ufs.ac.za/index.php/ijss/article/view/847
29. [Penulis PERLU VERIFIKASI]. Manggarai speech community local wisdom in *ireng neka dur ata*. *Journal of a Sustainable Global South*. https://jurnal.harianregional.com/jsgs/id-58904
30. [Penulis PERLU VERIFIKASI]. (t.t.). [Skripsi upacara Penti, mengutip Janggur (2010) & Verheijen]. Repositori Universitas PGRI Adi Buana Surabaya. https://repository.unipasby.ac.id/1652/3/3.%20BAB%20I.pdf
31. [Penulis & tahun PERLU VERIFIKASI]. [Compang]. *Sosioreligius* (UIN Alauddin). https://journal3.uin-alauddin.ac.id/index.php/Sosioreligius/article/view/13368/8293
32. [Penulis & tahun PERLU VERIFIKASI]. [Kajian masyarakat Manggarai]. *Sparkle* (Undana). https://ejurnal.undana.ac.id/index.php/sparkle/article/download/14242/6140
33. The Best in Heritage. (2013). *Mbaru Niang*. https://presentations.thebestinheritage.com/2013/Mbaru%20Niang
34. The Jakarta Post. (2016, 5 Mei). *Clean-up ritual à la Manggarai people*. https://newgelora.thejakartapost.com/multimedia/2016/05/05/clean-up-ritual-a-la-manggarai-people
35. Tourism Cambodia. (2012). *UNESCO Award of Excellence 2012 for Wae Rebo's Mbaru Niang traditional houses on Flores*. https://www.tourismcambodia.com/news/worldnews/6547/
36. Udus, G. I., Wulakada, H. H., & Rahmawati, A. ([tahun PERLU VERIFIKASI]). [Sawah lodok di Meler, Ruteng]. *Jurnal Geografi* (Undana). https://ejurnal.undana.ac.id/index.php/jgeo/article/view/17313
