"""Generator GDD versi 1.1 "Wirabraja: Geger Alun-Alun Keraton" (Fase 2).

Cara pakai (dari folder proyek):
    pip install python-docx
    python docs/buat_gdd_v11.py        -> docs/GDD_v1.1.docx

GDD v1.0 tetap disimpan (docs/GDD_v1.0.docx, dibuat oleh docs/buat_gdd.py).
Skrip ini memakai ulang fungsi bantu dari buat_gdd.py. Bagian yang berubah
diberi tanda [Diperbarui v1.1] dan bagian baru diberi tanda [Baru v1.1].
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import buat_gdd as g  # noqa: E402
from docx import Document  # noqa: E402
from docx.enum.section import WD_SECTION  # noqa: E402
from docx.enum.table import WD_TABLE_ALIGNMENT  # noqa: E402
from docx.shared import Cm, Pt, RGBColor  # noqa: E402

VERSI = "1.1"
TANGGAL_V11 = "21 November 2026"
RIWAYAT = g.RIWAYAT_VERSI + [
    ("1.1", TANGGAL_V11,
     "Tambah 3 jenis buta (Kilat, Gempal, Pelempar) dan buta cilik panggilan bos; level dibagi "
     "3 gelombang (12 buta); 3 pola serangan bos (Hantaman Bumi, Serbuan Lurus, Panggil Bala) dan "
     "fase murka saat HP < 50%; AudioManager dengan musik gamelan dan efek suara; narasi pembuka "
     "gaya dalang dengan kayon; uji otomatis menjadi 51 pemeriksaan.", g.PENULIS),
]

WARNA_BARU = RGBColor(0x1E, 0x6B, 0x2E)
WARNA_UBAH = RGBColor(0xB0, 0x5A, 0x00)


def judul(doc: Document, teks: str, level: int = 1, tanda: str | None = None):
    """Heading bernomor dengan penanda perubahan: tanda = 'baru' | 'ubah' | None."""
    h = doc.add_heading(teks, level=level)
    if tanda:
        r = h.add_run("  [Baru v1.1]" if tanda == "baru" else "  [Diperbarui v1.1]")
        r.font.size = Pt(10)
        r.italic = True
        r.font.color.rgb = WARNA_BARU if tanda == "baru" else WARNA_UBAH
    return h


p, butir, tabel, gambar, blok_kode = g.paragraf, g.butir, g.tabel, g.gambar, g.blok_kode


def berurut(doc: Document, daftar: list[str]) -> None:
    """Daftar bernomor manual (agar penomoran selalu mulai dari 1 di setiap daftar)."""
    for i, teks in enumerate(daftar, start=1):
        par = p(doc, f"{i}. {teks}")
        par.paragraph_format.left_indent = Cm(0.9)
        par.paragraph_format.first_line_indent = Cm(-0.6)
        par.paragraph_format.space_after = Pt(2)


# =================================================================== halaman depan

def sampul(doc: Document) -> None:
    doc.add_paragraph()
    p(doc, "GAME DESIGN DOCUMENT", rata="center", tebal=True, ukuran=18)
    par = p(doc, g.JUDUL, rata="center", tebal=True, ukuran=24)
    par.runs[0].font.color.rgb = g.MARUN
    p(doc, "Game Aksi 3D Orang Ketiga Bertema Budaya Jawa Surakarta dan Pewayangan",
      rata="center", miring=True, ukuran=13)
    p(doc, f"Versi {VERSI}", rata="center", tebal=True, ukuran=13)
    gambar(doc, "ss_narasi_kayon.png", "", lebar_cm=9.5)
    t = doc.add_table(rows=0, cols=3)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for label, nilai in (("Mata Kuliah", ""), ("Dosen Pengampu", ""), ("Disusun oleh", g.PENULIS),
                         ("NIM", g.NIM)):
        c = t.add_row().cells
        c[0].text, c[1].text, c[2].text = label, ":", nilai
        c[0].width, c[1].width, c[2].width = Cm(4.0), Cm(0.5), Cm(8.5)
        for sel in c:
            sel.paragraphs[0].paragraph_format.line_spacing = 1.15
    doc.add_paragraph()
    for baris in (g.PRODI.upper(), g.KAMPUS.upper(), g.TAHUN):
        p(doc, baris, rata="center", tebal=True, ukuran=13).paragraph_format.space_after = Pt(0)


def riwayat(doc: Document) -> None:
    p(doc, "RIWAYAT VERSI", rata="center", tebal=True, ukuran=14)
    tabel(doc, ["Versi", "Tanggal", "Perubahan", "Penulis"], [list(r) for r in RIWAYAT],
          lebar_cm=[1.4, 2.8, 7.8, 3.0])
    p(doc, "PANDUAN PENANDA PERUBAHAN", rata="center", tebal=True, ukuran=12)
    par = p(doc, "Judul bagian yang diberi tanda ", rata="justify")
    r = par.add_run("[Baru v1.1]")
    r.italic, r.font.color.rgb = True, WARNA_BARU
    par.add_run(" merupakan bagian baru pada versi ini, sedangkan tanda ")
    r = par.add_run("[Diperbarui v1.1]")
    r.italic, r.font.color.rgb = True, WARNA_UBAH
    par.add_run(" menandai bagian v1.0 yang isinya diubah. Bagian tanpa tanda tidak berubah dari v1.0.")
    tabel(doc, ["Bagian", "Status", "Ringkasan perubahan"], [
        ["1. Ringkasan Game", "Diperbarui", "Identitas, konsep, dan nilai budaya (gamelan, pakeliran)"],
        ["2.1, 2.5 Cerita", "Diperbarui/Baru", "Sinopsis dengan gelombang buta; narasi pembuka gaya dalang"],
        ["3.3–3.7 Tokoh", "Baru", "Buta Kilat, Buta Gempal, Buta Pelempar, Buta Cilik, perbandingan"],
        ["3.8 Ditya Kalamurka", "Diperbarui", "Wujud fase murka"],
        ["4. Gameplay & Kontrol", "Diperbarui", "Alur inti, tombol M, kontrol narasi"],
        ["5. Desain Level", "Diperbarui", "Denah 3 gelombang, alur dan tempo"],
        ["6. Mekanik", "Diperbarui/Baru", "Perilaku varian, 3 pola bos, fase 2, gelombang, parameter, HUD"],
        ["7. Aset & Teknologi", "Diperbarui/Baru", "AudioManager, daftar file audio, aset baru"],
        ["8. Pengujian", "Diperbarui", "51 pemeriksaan otomatis"],
        ["9–10", "Diperbarui", "Rencana berikutnya, pustaka gamelan"],
    ], lebar_cm=[4.0, 3.0, 8.0], keterangan="Tabel 0.1 Ringkasan perubahan v1.0 → v1.1")
    p(doc, "DAFTAR ISI", rata="center", tebal=True, ukuran=14)
    g.daftar_isi(doc)


# =================================================================== bab 1–2

def bab_ringkasan(doc: Document) -> None:
    judul(doc, "1. Ringkasan Game", tanda="ubah")
    judul(doc, "1.1 Identitas Game", 2, tanda="ubah")
    tabel(doc, ["Aspek", "Keterangan"], [
        ["Judul", g.JUDUL],
        ["Genre", "Aksi (_action_) 3D, pertarungan jarak dekat (_hack and slash_ ringan)"],
        ["Platform", "PC (Windows 10/11); kontrol papan ketik dan tetikus"],
        ["Kamera", "Orang ketiga (_third-person_), di belakang tokoh, dapat diputar dengan tetikus"],
        ["Mesin & bahasa", "Godot Engine 4.5 (versi stabil), GDScript dengan _static typing_"],
        ["Target pemain", "Remaja dan dewasa (13 tahun ke atas), pelajar/mahasiswa, dan pemain kasual "
                          "yang tertarik pada budaya Jawa; kekerasan bersifat fantasi tanpa darah"],
        ["Mode", "**[v1.1]** Pemain tunggal; narasi pembuka + Level 1 (3 gelombang buta + bos 2 fase), "
                 "durasi sekitar 8–12 menit"],
        ["Audio", "**[v1.1]** Musik latar bernuansa gamelan (narasi, pertempuran, bos) dan 17 efek suara"],
        ["Nilai budaya", "Keraton Kasunanan Surakarta, ksatria dan buta dalam wayang purwa, janturan "
                         "dalang dan kayon, gamelan Jawa, palet warna batik sogan"],
    ], lebar_cm=[3.5, 11.5], keterangan="Tabel 1.1 Identitas game")
    judul(doc, "1.2 Konsep Singkat", 2, tanda="ubah")
    p(doc, f"**{g.JUDUL}** adalah game aksi 3D orang ketiga. Permainan dibuka dengan narasi bergaya "
           "dalang yang memperkenalkan lakon. Pemain kemudian mengendalikan **Raden Wirabraja**, ksatria "
           "rekaan penjaga Keraton Kasunanan Surakarta, untuk menghalau tiga gelombang bala buta yang "
           "terdiri atas empat jenis dengan perilaku berbeda. Setelah itu pemain menghadapi raksasa "
           "**Ditya Kalamurka**, yang memiliki tiga pola serangan dan menjadi murka ketika nyawanya "
           "tinggal separuh.")
    judul(doc, "1.3 Nilai Budaya yang Diangkat", 2, tanda="ubah")
    for b in (
        "**Ruang keraton.** Arena meniru tata ruang sumbu utara–selatan Alun-Alun Lor: sepasang beringin "
        "berpagar di tengah, pendopo di sisi utara, dan gerbang keraton di belakangnya.",
        "**Wayang purwa gaya Surakarta.** Pertarungan ksatria melawan buta merujuk pada adegan perang dalam "
        "pakeliran, khususnya _perang kembang_ (Brandon, 1970; Keeler, 1987).",
        "**[Baru v1.1] Pakeliran sebagai bingkai cerita.** Narasi pembuka meniru _janturan_ dalang, lengkap "
        "dengan kayon (gunungan) yang membuka dan menutup adegan serta bunyi keprak di setiap baris.",
        "**[Baru v1.1] Gamelan.** Musik memakai bunyi instrumen gamelan (saron, bonang, kenong, kempul, "
        "gong, kendang) dalam laras slendro, dengan struktur bernuansa lancaran untuk pertempuran dan "
        "sampak untuk adegan perang yang memuncak (Lindsay, 1992; Sumarsam, 1995).",
        "**Simbolisme.** Ksatria melambangkan budi luhur, sedangkan buta melambangkan _angkara murka_ "
        "(Anderson, 1965). Fase murka bos memvisualkan watak itu secara langsung.",
        "**Estetika visual.** Warna khas Jawa (sogan, emas, marun, hijau) dan atap joglo.",
    ):
        butir(doc, b)
    judul(doc, "1.4 Pilar Desain", 2)
    for b in (
        "**Responsif:** kontrol langsung terasa, serangan memiliki jendela kena yang jelas.",
        "**Terbaca:** setiap serangan musuh diawali ancang-ancang (_telegraph_) yang terlihat dan terdengar.",
        "**Berakar budaya:** latar, tokoh, narasi, musik, dan istilah bersumber dari budaya Jawa Surakarta.",
        "**Mudah dikembangkan:** semua nilai keseimbangan berupa @export; model dan audio placeholder "
        "mudah diganti.",
    ):
        butir(doc, b)


def bab_cerita(doc: Document) -> None:
    judul(doc, "2. Cerita dan Latar", tanda="ubah")
    judul(doc, "2.1 Sinopsis Level 1", 2, tanda="ubah")
    p(doc, "Senja turun di Surakarta. Dari arah hutan Gandamayit, bala buta suruhan Ditya Kalamurka "
           "menyerbu Alun-Alun Lor dalam tiga gelombang: buta prajurit dan buta kilat, disusul buta "
           "pelempar batu, lalu buta gempal yang sebesar gajah. Raden Wirabraja, ksatria penjaga gerbang, "
           "maju seorang diri. Setelah semua buta tumbang, bumi bergetar dan Ditya Kalamurka bangkit di "
           "depan pendopo. Ketika terdesak, sang raksasa murka: kulitnya memerah dan amukannya makin "
           "ganas. Bila ia dikalahkan, alun-alun kembali tenteram.")
    judul(doc, "2.2 Latar: Keraton Kasunanan Surakarta", 2)
    p(doc, "Keraton Kasunanan Surakarta Hadiningrat didirikan oleh Susuhunan Pakubuwana II pada pertengahan "
           "abad ke-18 (1745) setelah istana Mataram di Kartasura rusak akibat pemberontakan (Ricklefs, "
           "2008). Kompleks keraton tersusun pada sumbu utara–selatan: Alun-Alun Lor dengan sepasang "
           "beringin berpagar di tengahnya, Pagelaran, Sitihinggil, dan gerbang-gerbang (kori) menuju "
           "bagian dalam. Dalam game, latar ini distilisasi menjadi arena 64 × 64 meter dan bukan replika "
           "arsitektural yang akurat.")
    judul(doc, "2.3 Konteks Pewayangan", 2)
    p(doc, "Wayang kulit purwa diakui UNESCO sebagai Warisan Budaya Takbenda Kemanusiaan (UNESCO, 2008). "
           "Tokoh dibedakan antara golongan ksatria yang halus dan golongan raksasa (_buta_ atau _ditya_) "
           "yang kasar. Adegan _perang kembang_ menampilkan ksatria muda yang mengalahkan beberapa raksasa "
           "(Brandon, 1970; Keeler, 1987). Struktur Level 1, yaitu gelombang buta yang diakhiri satu raksasa "
           "besar, mengadaptasi pola dramatik itu. Raden Wirabraja terinspirasi Gatotkaca, ksatria _otot "
           "kawat balung wesi_ putra Bima dan Arimbi, tetapi merupakan tokoh orisinal.")
    judul(doc, "2.4 Catatan Kepekaan Budaya", 2)
    for b in (
        "Game tidak menampilkan raja, kerabat keraton, pusaka, maupun upacara adat; keraton hanya menjadi "
        "latar arsitektural.",
        "Seluruh tokoh adalah rekaan sehingga tidak mengubah lakon atau watak tokoh wayang yang telah dikenal.",
        "Narasi pembuka hanya meniru gaya penuturan dalang; teksnya bukan kutipan suluk atau janturan baku.",
        "Pola musik adalah ciptaan sendiri yang bernuansa gamelan, bukan transkripsi gending tradisional.",
    ):
        butir(doc, b)
    judul(doc, "2.5 Narasi Pembuka Gaya Dalang", 2, tanda="baru")
    p(doc, "Sebelum Level 1 dimulai, layar menampilkan _kelir_ (layar wayang) yang diterangi cahaya "
           "_blencong_. Urutannya:")
    berurut(doc, [
        "Kayon berdiri di tengah kelir diiringi bunyi gong, lalu judul lakon muncul: _Lakon: Geger "
        "Alun-Alun Keraton_.",
        "Kayon disingkirkan ke sisi kiri, seperti dalang yang mencabut kayon untuk memulai adegan.",
        "Tujuh baris narasi muncul satu per satu dengan efek ketik. Setiap baris diawali bunyi keprak.",
        "Kayon kembali ditancapkan di tengah, layar menggelap, lalu Level 1 dimulai.",
        "Kontrol: Spasi/Enter/klik untuk melanjutkan (atau menampilkan teks utuh), Esc/Tab untuk melewati.",
    ])
    gambar(doc, "ss_narasi.png", "Gambar 2.1 Narasi pembuka: kayon di sisi kelir dan teks Ki Dalang", 13)
    tabel(doc, ["No", "Teks narasi"], [
        ["1", "Hong wilaheng..."],
        ["2", "Kacarita, ing Keraton Surakarta Hadiningrat, langit mendadak gelap. Angin dari arah hutan "
              "Gandamayit berembus membawa hawa angkara."],
        ["3", "Bala buta datang menyerbu alun-alun: buta prajurit bergada kayu, buta kilat yang lincah bagai "
              "sambaran petir, buta gempal sebesar gajah, dan buta pelempar batu."],
        ["4", "Di belakang mereka menunggu Ditya Kalamurka, raksasa yang dikuasai angkara murka, yang hendak "
              "merebut ketenteraman negeri."],
        ["5", "Hanya satu ksatria yang berdiri menjaga gerbang: Raden Wirabraja, ksatria berbudi luhur yang "
              "bersenjatakan gada."],
        ["6", "Sang ksatria tidak gentar. Ia memegang pitutur para leluhur: becik ketitik, ala ketara. Yang "
              "baik akan tampak, yang jahat akan terungkap."],
        ["7", "Mangkana... perang pun dimulai!"],
    ], lebar_cm=[1.0, 14.0], keterangan="Tabel 2.1 Naskah narasi pembuka")
    tabel(doc, ["Istilah", "Makna dalam narasi"], [
        ["_Hong wilaheng_", "Ungkapan pembuka bernuansa doa yang lazim mengawali penuturan dalang"],
        ["_Kacarita_", "\"Dikisahkan\"; penanda awal penuturan"],
        ["_Mangkana_", "\"Demikianlah\"; penanda peralihan ke adegan berikutnya"],
        ["_Janturan_", "Narasi dalang yang melukiskan suasana adegan"],
        ["_Kayon_ / _gunungan_", "Wayang berbentuk gunungan untuk membuka/menutup pertunjukan dan menandai pergantian adegan"],
        ["_Kelir_, _blencong_", "Layar putih pertunjukan wayang dan lampu penerangnya"],
        ["_Keprak_", "Lempeng logam di kotak wayang yang dibunyikan dalang untuk memberi aba-aba"],
        ["_Becik ketitik, ala ketara_", "Peribahasa: yang baik akan tampak, yang buruk akan terungkap"],
        ["_Angkara murka_", "Nafsu angkara; watak yang dilambangkan oleh para buta"],
    ], lebar_cm=[4.2, 10.8], keterangan="Tabel 2.2 Glosarium istilah Jawa dalam narasi")


# =================================================================== bab 3

def bab_tokoh(doc: Document) -> None:
    judul(doc, "3. Tokoh dan Musuh", tanda="ubah")
    judul(doc, "3.1 Raden Wirabraja (Tokoh Pemain)", 2)
    p(doc, "Nama _Wirabraja_ dibentuk dari kata _wira_ (pahlawan) dan _braja_ (senjata sakti). Ia memakai "
           "gelung dan jamang emas, garuda mungkur, kotang sogan berlis emas, praba di punggung, kain dodot "
           "marun, sampur hijau, dan bersenjata gada. Desainnya tidak berubah dari v1.0.")
    judul(doc, "3.2 Buta Prajurit", 2)
    p(doc, "Raksasa prajurit berkulit merah, bertaring, bermata melotot, berambut gimbal, membawa gada kayu. "
           "Ia mendekat lurus, mengangkat kedua lengan sebagai ancang-ancang, lalu memukul.")
    gambar(doc, "ss_varian.png", "Gambar 3.1 Empat jenis buta (kiri ke kanan): Prajurit, Kilat, Gempal, Pelempar", 13)
    judul(doc, "3.3 Buta Kilat", 2, tanda="baru")
    p(doc, "Raksasa ramping berkulit hijau dan berkain marun, tanpa senjata. Namanya merujuk pada geraknya "
           "yang secepat kilat. Ia mendekat secara zig-zag lalu **menerjang**: merunduk sesaat, kemudian "
           "melesat lurus sejauh beberapa meter. Setelah menerjang ia terhenti sejenak, dan saat itulah pemain "
           "dapat membalas.")
    judul(doc, "3.4 Buta Gempal", 2, tanda="baru")
    p(doc, "Raksasa sangat besar (sekitar 1,5 kali Buta Prajurit) berkulit sogan tua dan bergada kayu. "
           "Langkahnya lambat, tetapi ia **tidak terhuyung** ketika dipukul (_super armor_) dan hampir tidak "
           "terdorong. Serangannya, **Injak Bumi**, didahului ancang-ancang panjang lalu menghantam tanah dan "
           "melukai pemain di sekelilingnya (360°).")
    judul(doc, "3.5 Buta Pelempar", 2, tanda="baru")
    p(doc, "Raksasa berkulit kuning kunyit dan berkain hijau yang menggenggam batu. Ia **menjaga jarak**: "
           "mundur bila pemain mendekat, mendekat bila pemain terlalu jauh, dan bergeser menyamping bila "
           "jaraknya sudah pas. Setelah mengangkat batu tinggi-tinggi, ia melemparkannya dengan lintasan "
           "melengkung ke perkiraan posisi pemain.")
    judul(doc, "3.6 Buta Cilik (Panggilan Bos)", 2, tanda="baru")
    p(doc, "Buta prajurit berukuran kecil (0,6 kali) yang dipanggil Ditya Kalamurka melalui pola Panggil Bala. "
           "Nyawanya sedikit dan ia tidak dihitung dalam jumlah buta misi. Semua buta cilik ikut lenyap saat "
           "bos kalah.")
    judul(doc, "3.7 Perbandingan Jenis Buta", 2, tanda="baru")
    tabel(doc, ["Jenis", "HP", "Kecepatan", "Damage", "Ciri utama", "Cara menghadapi"], [
        ["Prajurit", "75", "3,2 m/s", "10", "Pukulan jarak dekat", "Mundur saat lengannya terangkat, lalu pukul"],
        ["Kilat", "45", "5,8 m/s", "8", "Zig-zag + terjangan", "Menyamping saat ia merunduk, pukul saat ia terhenti"],
        ["Gempal", "220", "1,9 m/s", "24", "Super armor, Injak Bumi 3,6 m", "Keluar dari jangkauan saat ancang-ancang"],
        ["Pelempar", "50", "2,8 m/s", "12", "Menjaga jarak, lempar batu", "Terus bergerak; kejar dan pojokkan"],
        ["Cilik", "30", "4,3 m/s", "6", "Dipanggil bos, kecil", "Habisi cepat agar tidak mengepung"],
    ], lebar_cm=[2.0, 1.2, 2.0, 1.6, 4.0, 4.2], ukuran=9, keterangan="Tabel 3.1 Perbandingan jenis buta")
    p(doc, "Warna kulit dan ukuran yang berbeda membuat setiap jenis langsung dapat dikenali dari jauh, sebuah "
           "prinsip keterbacaan siluet dalam desain musuh (Schell, 2019).")
    judul(doc, "3.8 Ditya Kalamurka (Bos)", 2, tanda="ubah")
    p(doc, "Raksasa berkulit hijau gelap setinggi sekitar 6 meter, bermata merah menyala, bermahkota emas tinggi, "
           "dan berpraba lingkaran emas. **[v1.1]** Ketika HP-nya tinggal kurang dari separuh, ia memasuki "
           "**fase murka**: meraung, tubuhnya sedikit membesar, kulitnya berubah merah, dan matanya menyala "
           "lebih terang.")
    gambar(doc, "ss_murka.png", "Gambar 3.2 Ditya Kalamurka dalam fase murka bersama buta cilik panggilannya", 13)


# =================================================================== bab 4–5

def bab_gameplay(doc: Document) -> None:
    judul(doc, "4. Gameplay dan Kontrol", tanda="ubah")
    judul(doc, "4.1 Alur Inti (Core Loop)", 2, tanda="ubah")
    berurut(doc, [
        "Mendengarkan narasi pembuka (atau melewatinya).",
        "Membaca jenis buta dari warna dan ukurannya, lalu memilih cara menghadapinya.",
        "Menyerang dengan gada, atau menghindar dengan lari/lompat ketika melihat ancang-ancang.",
        "Menghabisi gelombang buta; gelombang berikutnya turun dari langit diiringi bunyi gong.",
        "Melawan bos: membaca lingkaran merah (Hantaman Bumi), jalur merah (Serbuan Lurus), dan raungan "
        "pemanggil bala, lalu memukul saat bos pulih atau terhuyung setelah menabrak.",
    ])
    judul(doc, "4.2 Kontrol", 2, tanda="ubah")
    tabel(doc, ["Tombol", "Aksi"], [
        ["W / A / S / D (atau panah)", "Bergerak relatif terhadap arah kamera"],
        ["Shift kiri (tahan)", "Berlari"],
        ["Spasi", "Melompat (juga: lanjut narasi)"],
        ["Klik kiri tetikus", "Serangan gada (juga: lanjut narasi)"],
        ["Gerakan tetikus", "Memutar kamera orbit"],
        ["Enter", "**[v1.1]** Lanjut narasi"],
        ["Esc", "Melepas kursor tetikus; **[v1.1]** melewati narasi"],
        ["Tab", "**[v1.1]** Melewati narasi"],
        ["M", "**[v1.1]** Menghidupkan/mematikan musik"],
        ["R", "Mengulang level setelah menang atau kalah"],
    ], lebar_cm=[5.5, 9.5], keterangan="Tabel 4.1 Pemetaan kontrol")
    judul(doc, "4.3 Kamera", 2)
    p(doc, "Kamera orbit (yaw + SpringArm3D, pitch −65° sampai +25°, jarak 5,5 m) tidak berubah dari v1.0. "
           "Guncangan kamera kini juga dipicu oleh Injak Bumi, tabrakan Serbuan Lurus, dan perubahan fase bos.")


def denah_v11() -> str:
    """Membuat denah teks dari koordinat arena dan posisi awal musuh tiap gelombang."""
    lebar, tinggi = 53, 33
    grid = [[" "] * lebar for _ in range(tinggi)]

    def sel(x: float, z: float) -> tuple[int, int]:
        return int(round((x + 32) / 64 * (lebar - 1))), int(round((z + 32) / 64 * (tinggi - 1)))

    def tulis(x: float, z: float, teks: str) -> None:
        c, r = sel(x, z)
        for i, ch in enumerate(teks):
            if 0 <= c + i < lebar:
                grid[r][c + i] = ch

    for c in range(lebar):
        grid[0][c] = grid[-1][c] = "="
    for r in range(tinggi):
        grid[r][0] = grid[r][-1] = "|"
    tulis(-5, -32, "[GERBANG]")
    for z in range(-26, -15):
        for x in (-9, 9):
            tulis(x, z, ":")
    tulis(-9, -26.5, "+" + "-" * 14 + "+")
    tulis(-9, -15.5, "+" + "-" * 14 + "+")
    tulis(-5, -21, "PENDOPO")
    for z in range(-14, 32, 2):
        c, r = sel(0, z)
        if grid[r][c] == " ":
            grid[r][c] = "."
    tulis(-7.5, -2, "[##]")
    tulis(5.5, -2, "[##]")
    tulis(0, -11, "X")
    tulis(0, 24, "P")
    musuh = [
        ("1p", -4, 10), ("1p", 4, 10), ("1p", -8, -4), ("1k", 8, -4),
        ("2k", -10, 4), ("2k", 10, 4), ("2l", -14, -12), ("2l", 14, -12),
        ("3g", -5, -9), ("3g", 5, -9), ("3p", -12, 6), ("3l", 0, -13),
    ]
    for kode, x, z in musuh:
        tulis(x, z, kode)
    return "\n".join("".join(baris) for baris in grid)


def bab_level(doc: Document) -> None:
    judul(doc, "5. Desain Level 1: Alun-Alun Lor", tanda="ubah")
    judul(doc, "5.1 Denah", 2, tanda="ubah")
    p(doc, "Denah berikut dibuat otomatis dari koordinat di scene (utara di atas; satu kolom ≈ 1,2 m, satu "
           "baris = 2 m). Kode musuh: angka = gelombang, p = prajurit, k = kilat, l = pelempar, g = gempal.")
    blok_kode(doc, denah_v11() + "\n P = pemain mulai    X = titik munculnya bos\n"
                                 " [##] = ringin kurung    . = jalan sumbu", ukuran=7)
    gambar(doc, "ss_arena.png", "Gambar 5.1 Tampilan arena dari udara", 12)
    judul(doc, "5.2 Elemen Arena", 2)
    tabel(doc, ["Elemen", "Posisi (x, z) m", "Fungsi dalam permainan"], [
        ["Pagar tembok keliling", "±32", "Batas arena; dinding tak terlihat 5 m; tempat bos menabrak saat menyeruduk"],
        ["Gerbang keraton (paduraksa)", "(0, −32)", "Penanda arah utara"],
        ["Pendopo joglo", "(0, −21)", "Tiang menjadi penghalang dan tempat berlindung dari batu"],
        ["Dua ringin kurung", "(±6,5, −2)", "Rintangan tengah; memecah kepungan; dapat dipakai memancing bos menabrak"],
        ["Delapan pohon tepi", "tepi arena", "Dekorasi dan rintangan kecil"],
        ["Titik munculnya bos", "(0, −11)", "Ruang terbuka di depan pendopo"],
    ], lebar_cm=[4.3, 2.9, 7.8], keterangan="Tabel 5.1 Elemen arena Level 1")
    judul(doc, "5.3 Alur dan Tempo Level", 2, tanda="ubah")
    tabel(doc, ["Tahap", "Isi", "Tujuan desain"], [
        ["Narasi", "Janturan dalang, kayon, musik narasi", "Membangun suasana dan konteks budaya"],
        ["Gelombang 1", "3 Buta Prajurit + 1 Buta Kilat", "Mengenalkan pola dasar serangan dan terjangan"],
        ["Gelombang 2", "2 Buta Kilat + 2 Buta Pelempar", "Melatih bergerak terus dan mengejar musuh jarak jauh"],
        ["Gelombang 3", "2 Buta Gempal + 1 Prajurit + 1 Pelempar", "Ujian gabungan: musuh tangguh + tekanan jarak jauh"],
        ["Bos fase 1", "Hantaman Bumi, Serbuan Lurus, Panggil Bala", "Mempelajari tiga tanda bahaya bos"],
        ["Bos fase 2", "Pola sama, lebih cepat, hantaman ganda, bala lebih banyak", "Puncak ketegangan"],
        ["Penutup", "Teks MENANG/KALAH, sfx gamelan, tombol R", "Umpan balik akhir dan pengulangan cepat"],
    ], lebar_cm=[2.6, 6.2, 6.2], keterangan="Tabel 5.2 Alur dan tempo Level 1 (v1.1)")
    p(doc, "Gelombang berikutnya turun dua detik setelah gelombang sebelumnya habis. Buta yang turun langsung "
           "memburu pemain dari mana pun ia berada, sehingga tempo tetap terjaga.")


# =================================================================== bab 6

def bab_mekanik(doc: Document) -> None:
    judul(doc, "6. Mekanik", tanda="ubah")
    judul(doc, "6.1 Nyawa (HP) dan Kekebalan Sesaat", 2)
    p(doc, "Semua karakter memakai **KomponenHP** (sinyal hp_berubah, terkena, habis). Setelah terkena, pemain "
           "kebal 0,7 detik, terdorong, dan terhuyung 0,25 detik; model berkilat dan terdengar efek suara.")
    judul(doc, "6.2 Serangan Pemain", 2)
    p(doc, "Ayunan gada 0,42 detik dengan hitbox aktif pada detik 0,10–0,26; damage 25; setiap musuh terkena "
           "sekali per ayunan. Tidak berubah dari v1.0.")
    judul(doc, "6.3 Kecerdasan Buatan Buta (State Machine Dasar)", 2)
    tabel(doc, ["State", "Perilaku", "Transisi"], [
        ["DIAM", "Berdiri dan bernapas pelan", "Pemain ≤ jarak deteksi → MENGEJAR"],
        ["MENGEJAR", "Mendekati pemain (cara mendekat bisa ditimpa varian)", "Dalam jangkauan → ANCANG"],
        ["ANCANG", "Ancang-ancang (telegraph), menghadap pemain", "Waktu habis → serangan → PULIH"],
        ["PULIH", "Celah setelah menyerang", "Waktu habis → MENGEJAR"],
        ["TERKENA", "Terdorong dan terhuyung (tidak berlaku bagi Buta Gempal)", "Waktu habis → MENGEJAR"],
        ["MATI", "Rebah, mengecil, dihapus; lapor ke GameManager bila dihitung misi", "—"],
    ], lebar_cm=[2.4, 7.0, 5.6], keterangan="Tabel 6.1 State machine dasar kelas Buta")
    judul(doc, "6.4 Perilaku Varian Buta (Pewarisan Kelas)", 2, tanda="baru")
    p(doc, "Setiap varian adalah kelas turunan **Buta** yang hanya menimpa fungsi tertentu. Pola ini menghindari "
           "duplikasi kode dan memudahkan penambahan jenis buta baru (Nystrom, 2014).")
    tabel(doc, ["Kelas", "Fungsi yang ditimpa", "Perilaku"], [
        ["ButaKilat", "_proses_mengejar, _mulai_ancang, _lakukan_serangan, _proses_pulih",
         "Gerak zig-zag (sinus menyamping); merunduk 0,4 s; terjangan 13 m/s; kena bila jarak ≤ 1,7 m selama masih cepat"],
        ["ButaGempal", "_ready, _lakukan_serangan",
         "tahan_terhuyung = true; Injak Bumi radius 3,6 m (360°), lolos bila melompat; guncangan kamera"],
        ["ButaPelempar", "_proses_mengejar, _mulai_ancang, _lakukan_serangan",
         "Menjaga jarak 8–14 m; jeda lempar 2,2 s; batu balistik dengan perkiraan gerak pemain"],
        ["BatuLempar (Area3D)", "—",
         "Kecepatan awal v = Δ/t dengan komponen y = (Δy + ½·g·t²)/t; pecah saat menyentuh tanah/bangunan"],
    ], lebar_cm=[3.0, 5.0, 7.0], ukuran=9, keterangan="Tabel 6.2 Implementasi varian buta")
    judul(doc, "6.5 Bos: Tiga Pola Serangan dan Fase Murka", 2, tanda="ubah")
    gambar(doc, "ss_serbu.png", "Gambar 6.1 Ancang-ancang Serbuan Lurus: jalur merah menunjukkan arah serudukan", 12.5)
    tabel(doc, ["Pola", "Pemicu", "Tanda (telegraph)", "Efek", "Celah bagi pemain"], [
        ["1. Hantaman Bumi", "Pemain ≤ 5,5 m", "Lengan terangkat, lingkaran merah membesar (1,2 s)",
         "30 damage dalam radius 6,5 m", "Keluar lingkaran atau melompat; pulih 1,5 s"],
        ["2. Serbuan Lurus", "Pemain ≥ 9 m, jeda 7 s", "Raungan, badan condong, jalur merah 20 m (1,0 s)",
         "Menyeruduk 15 m/s, 25 damage", "Menyamping; bila bos menabrak tembok/pohon ia terhuyung 2,2 s"],
        ["3. Panggil Bala", "Jeda 15 s (awal 6 s), maks 4 hidup", "Raungan + lengan terangkat (1,1 s), gong",
         "2 buta cilik jatuh dari langit", "Pukul bos saat memanggil; habisi buta cilik"],
    ], lebar_cm=[2.6, 2.6, 3.6, 3.0, 3.2], ukuran=9, keterangan="Tabel 6.3 Pola serangan Ditya Kalamurka")
    p(doc, "**Pemilihan pola.** Saat mengejar dan jeda antarserangan (0,8 s) habis, bos memeriksa secara "
           "berurutan: (1) pemain dekat → Hantaman Bumi; (2) jeda panggil habis dan bala hidup < 4 → Panggil "
           "Bala; (3) jeda serbu habis dan pemain jauh → Serbuan Lurus; selain itu bos berjalan mendekat.")
    p(doc, "**Fase 2 (murka).** Saat HP turun di bawah 50%, bos berubah fase satu kali: kebal selama 1,8 detik, "
           "meraung, dan berubah warna. Pada fase 2 kecepatan dikali 1,35, semua ancang-ancang dibagi 1,35, "
           "radius Hantaman Bumi menjadi 125% dan hantaman dilakukan dua kali berturut-turut, jeda serbu "
           "dan panggil dipersingkat, dan jumlah panggilan naik menjadi 3. Bahan kulit diduplikasi saat bos "
           "muncul sehingga warna murka tidak terbawa ke permainan berikutnya.")
    blok_kode(doc, """
 MUNCUL (kebal) --> MENGEJAR
 MENGEJAR --pemain dekat------> ANCANG_HANTAM --> HANTAM --(fase 2: ulang 1x)--> PULIH
 MENGEJAR --jeda panggil habis-> MEMANGGIL -------------------------------------> PULIH
 MENGEJAR --pemain jauh-------> ANCANG_SERBU --> SERBU --tidak menabrak---------> PULIH
                                                   +----menabrak--> TERHUYUNG --> MENGEJAR
 PULIH --waktu habis--> MENGEJAR
 (kapan saja) HP < 50%, sekali --> BERUBAH_FASE (kebal) --> MENGEJAR
 HP habis --> MATI (buta cilik ikut lenyap) --> GameManager: MENANG
""", ukuran=7)
    judul(doc, "6.6 State Permainan, Gelombang, dan Kondisi Menang/Kalah", 2, tanda="ubah")
    p(doc, "GameManager tetap mengelola state BERTARUNG → BOS → MENANG/KALAH. Pada v1.1, skrip level membagi "
           "anak-anak node _Musuh_ menjadi gelombang. Semua buta misi (12) dihitung di awal, sedangkan "
           "gelombang ke-2 dan ke-3 dilepas dari pohon scene dan baru ditambahkan ketika buta aktif habis. "
           "Buta cilik panggilan bos memiliki dihitung_misi = false sehingga tidak memengaruhi hitungan.")
    blok_kode(doc, """
 NARASI --selesai/Esc--> mulai_level(12) --> [ BERTARUNG ]
 [ BERTARUNG ]: gel.1 habis -> gel.2 turun -> gel.2 habis -> gel.3 turun -> gel.3 habis
 gel.3 habis ----------------> [ BOS ] (fase 1 -> fase 2)
 [ BOS ] --bos kalah---------> [ MENANG ]
 HP pemain habis (kapan saja) -> [ KALAH ]
 MENANG / KALAH: tekan R -> level dimuat ulang
""", ukuran=7)
    judul(doc, "6.7 Parameter Keseimbangan", 2, tanda="ubah")
    tabel(doc, ["Objek", "Parameter", "Nilai v1.0", "Nilai v1.1"], [
        ["Pemain", "hp_maks / damage / kecepatan", "100 / 25 / 5,0", "tetap"],
        ["Buta Prajurit", "hp_maks / damage / kecepatan", "75 / 10 / 3,2", "tetap"],
        ["Buta Kilat", "hp_maks / kecepatan / kecepatan_terjang", "—", "45 / 5,8 / 13"],
        ["Buta Gempal", "hp_maks / damage / radius_injak", "—", "220 / 24 / 3,6"],
        ["Buta Pelempar", "hp_maks / damage / jarak_ideal", "—", "50 / 12 / 8–14 m"],
        ["Buta Cilik", "hp_maks / damage / kecepatan", "—", "30 / 6 / 4,3"],
        ["Ditya Kalamurka", "hp_maks", "500", "650"],
        ["Ditya Kalamurka", "damage hantaman / serbu", "30 / —", "30 / 25"],
        ["Ditya Kalamurka", "ambang_fase_2 / pengali_fase_2", "—", "50% / 1,35"],
        ["Level", "jumlah buta / gelombang", "6 / 1", "12 / 3"],
    ], lebar_cm=[3.2, 5.6, 2.8, 3.4], keterangan="Tabel 6.4 Parameter keseimbangan v1.0 dan v1.1")
    judul(doc, "6.8 Antarmuka (HUD)", 2, tanda="ubah")
    p(doc, "Selain unsur v1.0, HUD kini menampilkan nomor gelombang (\"Gelombang 2/3 · Buta tersisa: 8\"), "
           "pengumuman setiap gelombang dan pola bos, serta penanda fase murka: nama bos menjadi "
           "\"Ditya Kalamurka — MURKA!\" dan bar HP-nya berubah merah. Petunjuk kontrol menyertakan tombol M.")


# =================================================================== bab 7–10

def bab_aset(doc: Document) -> None:
    judul(doc, "7. Aset dan Teknologi", tanda="ubah")
    judul(doc, "7.1 Teknologi", 2, tanda="ubah")
    tabel(doc, ["Komponen", "Pilihan"], [
        ["Mesin game", "Godot Engine 4.5 (stabil), renderer Forward+"],
        ["Bahasa", "GDScript dengan static typing; pewarisan kelas untuk varian buta"],
        ["Autoload", "GameManager (state permainan), **[v1.1]** AudioManager (musik & efek suara)"],
        ["Fisika", "CharacterBody3D, Area3D (hitbox & batu), StaticBody3D (arena)"],
        ["Audio", "**[v1.1]** Ogg Vorbis (musik, berulang) dan WAV (efek); bus Musik & SFX"],
        ["Alat bantu", "Python: python-docx (GDD), numpy + ffmpeg (audio sintetis)"],
        ["Pengujian", "tests/uji_alur.tscn (51 pemeriksaan, headless)"],
    ], lebar_cm=[4.0, 11.0], keterangan="Tabel 7.1 Teknologi yang digunakan")
    judul(doc, "7.2 Struktur Proyek", 2, tanda="ubah")
    blok_kode(doc, """
wirabraja/
  project.godot        input map, autoload GameManager & AudioManager
  scenes/player/       player.tscn
  scenes/enemies/      buta, buta_kilat, buta_gempal, buta_pelempar,
                       buta_cilik, batu_lempar
  scenes/boss/         bos_raksasa.tscn
  scenes/level/        level_1.tscn (Musuh/Gelombang1..3), pendopo,
                       gerbang, pagar_keliling, beringin
  scenes/ui/           hud.tscn, narasi_pembuka.tscn (scene utama)
  scripts/autoload/    game_manager.gd, audio_manager.gd
  scripts/enemies/     buta.gd (kelas dasar), buta_kilat.gd,
                       buta_gempal.gd, buta_pelempar.gd, batu_lempar.gd
  scripts/ui/          hud.gd, narasi_pembuka.gd, kayon.gd
  audio/musik/         3 musik .ogg
  audio/sfx/           17 efek suara .wav
  docs/                GDD_v1.0.docx, GDD_v1.1.docx, buat_gdd.py,
                       buat_gdd_v11.py
  tools/               buat_scene_karakter.py, buat_audio.py
""", ukuran=7)
    judul(doc, "7.3 Daftar Aset Visual", 2, tanda="ubah")
    tabel(doc, ["Aset", "Bentuk dasar", "Status"], [
        ["Raden Wirabraja, Buta Prajurit, Ditya Kalamurka, arena", "Seperti v1.0", "Tetap"],
        ["Buta Kilat", "Model raksasa diskalakan (0,78; 0,9; 0,78), kulit hijau", "Baru"],
        ["Buta Gempal", "Model raksasa diskalakan (1,5; 1,35; 1,5), kulit sogan tua", "Baru"],
        ["Buta Pelempar + batu di tangan", "Model raksasa, kulit kunyit, SphereMesh batu", "Baru"],
        ["Buta Cilik", "Model Buta Prajurit diskalakan 0,6", "Baru"],
        ["Batu lemparan", "SphereMesh pipih + Area3D", "Baru"],
        ["Penanda Serbuan Lurus", "BoxMesh pipih transparan 2,8 × 20 m", "Baru"],
        ["Kayon (gunungan)", "Digambar dengan kode (_draw) pada Control", "Baru"],
        ["Kelir & blencong", "Panel + GradientTexture2D radial", "Baru"],
    ], lebar_cm=[5.0, 7.5, 2.5], keterangan="Tabel 7.2 Aset visual placeholder")
    judul(doc, "7.4 Audio", 2, tanda="baru")
    p(doc, "Semua suara diputar lewat **AudioManager**. Musik berganti dengan _crossfade_, sedangkan efek "
           "dimainkan dari kumpulan 12 pemutar, dengan volume yang dilemahkan menurut jarak dari kamera dan "
           "nada yang sedikit diacak agar tidak monoton. Bila sebuah file tidak ada, permainan tetap berjalan "
           "tanpa suara itu.")
    p(doc, "File audio pada v1.1 adalah **placeholder sintetis buatan sendiri** (tools/buat_audio.py). Bilah "
           "logam disintesis dari parsial tak harmonis, dan setiap nada dibunyikan oleh dua sumber yang "
           "selisih frekuensinya sekitar 2 Hz sehingga muncul denyut (_ombak_) seperti pada gamelan. Gong "
           "ageng diberi modulasi amplitudo sekitar 2,6 Hz. Laras slendro didekati dengan lima nada berjarak "
           "sekitar 240 sen (Lindsay, 1992). Pola balungan adalah ciptaan sendiri.")
    tabel(doc, ["File", "Peristiwa / penggunaan"], [
        ["musik/musik_narasi.ogg", "Narasi pembuka (lembut, gong tiap 16 ketukan)"],
        ["musik/musik_pertempuran.ogg", "Gelombang buta (bernuansa lancaran, ±132 ketukan/menit)"],
        ["musik/musik_bos.ogg", "Pertarungan bos (bernuansa sampak, ±168 ketukan/menit)"],
        ["sfx/ayun_gada, pukulan, kena_serang", "Mengayun gada, serangan mengenai musuh, pemain terkena"],
        ["sfx/langkah, lompat", "Langkah kaki dan lompatan pemain"],
        ["sfx/buta_ayun, buta_mati", "Buta memukul dan buta kalah"],
        ["sfx/terjang, injak_bumi, lempar_batu, batu_jatuh", "Serangan khas Buta Kilat, Gempal, Pelempar"],
        ["sfx/bos_hantam, bos_raung", "Hantaman/tabrakan bos; raungan (muncul, serbu, panggil, murka)"],
        ["sfx/gong, keprak", "Gelombang baru dan buka/tutup narasi; aba-aba dalang tiap baris"],
        ["sfx/kemenangan, kekalahan", "Saron naik + gong (menang); saron turun + gong (kalah)"],
    ], lebar_cm=[6.0, 9.0], ukuran=9, keterangan="Tabel 7.3 Daftar file audio (rincian lengkap di audio/README.md)")
    p(doc, "Untuk mengganti dengan rekaman gamelan asli, timpa file bernama sama atau ubah tabel MUSIK/SFX di "
           "audio_manager.gd. Setiap rekaman pihak ketiga wajib dicatat sumber dan lisensinya.")
    judul(doc, "7.5 Palet Warna dan Strategi Penggantian Model", 2)
    p(doc, "Palet warna Jawa (sogan, sogan tua, emas, marun, hijau, hijau tua, gading) dan strategi penggantian "
           "model (node Model terpisah, animasi prosedural opsional, efek kilat generik) sama seperti v1.0. "
           "Tambahan v1.1: kelas varian hanya mencari node opsional sehingga model asli tiap jenis buta "
           "dapat dipasang tanpa mengubah logika.")


def bab_pengujian(doc: Document) -> None:
    judul(doc, "8. Pengujian", tanda="ubah")
    p(doc, "Uji otomatis dijalankan secara headless: godot --headless --path . res://tests/uji_alur.tscn. "
           "Hasil v1.1: **51 pemeriksaan lulus, 0 gagal**, tanpa galat maupun peringatan.")
    tabel(doc, ["Kelompok uji", "Jumlah", "Contoh pemeriksaan", "Hasil"], [
        ["Narasi pembuka", "4", "Lanjut dengan Spasi/Enter, lewati dengan Esc, musik narasi", "Lulus"],
        ["Audio", "2", "20 file audio tersedia, bus Musik & SFX", "Lulus"],
        ["Buta Kilat", "3", "Zig-zag, terjangan > 10 m/s, terjangan mengenai", "Lulus"],
        ["Buta Gempal", "3", "Super armor, HP besar & lambat, Injak Bumi mengenai", "Lulus"],
        ["Buta Pelempar", "3", "Mundur menjaga jarak, batu dilempar, batu mengenai", "Lulus"],
        ["Pemain & gelombang", "11", "WASD, lompat, serangan, 12 buta, gelombang 2 & 3 turun", "Lulus"],
        ["Bos", "21", "3 pola, panggilan tidak dihitung misi, fase 2, warna tidak menular, MENANG", "Lulus"],
        ["Kondisi kalah", "4", "Reset level, pemain mati, KALAH, teks + petunjuk R", "Lulus"],
    ], lebar_cm=[3.3, 1.6, 8.0, 2.1], keterangan="Tabel 8.1 Ringkasan hasil uji otomatis v1.1")
    p(doc, "Catatan: uji otomatis memeriksa logika dan alur. Rasa bermain (kesulitan, kepekaan kamera, volume "
           "audio) tetap perlu dinilai lewat uji main langsung oleh pemain.")


def bab_rencana(doc: Document) -> None:
    judul(doc, "9. Rencana Pengembangan Berikutnya", tanda="ubah")
    p(doc, "Seluruh rencana Fase 2 pada GDD v1.0 telah diwujudkan di v1.1. Rencana selanjutnya:")
    for b in (
        "**Uji main** dengan 5–10 pemain untuk menyetel kesulitan (HP bos, jeda serangan, jumlah buta).",
        "**Aset asli:** model 3D bergaya wayang dengan animasi rangka; rekaman gamelan asli berlisensi jelas.",
        "**Menu dan pengaturan:** menu utama, jeda, sensitivitas tetikus, dan volume.",
        "**Level lanjutan:** Alun-Alun Kidul dan kawasan Sitihinggil, dengan lakon lanjutan.",
        "**Ekspor:** berkas .exe Windows untuk dibagikan.",
    ):
        butir(doc, b)


def bab_pustaka(doc: Document) -> None:
    judul(doc, "10. Daftar Pustaka", tanda="ubah")
    pustaka = [
        "Anderson, B. R. O'G. (1965). _Mythology and the tolerance of the Javanese_. Modern Indonesia "
        "Project, Cornell University.",
        "Brandon, J. R. (Ed.). (1970). _On thrones of gold: Three Javanese shadow plays_. Harvard University Press.",
        "Godot Engine. (2025). _Godot Engine documentation_ (stable). https://docs.godotengine.org/en/stable/",
        "Keeler, W. (1987). _Javanese shadow plays, Javanese selves_. Princeton University Press.",
        "Lindsay, J. (1992). _Javanese gamelan_ (2nd ed.). Oxford University Press.",
        "Nystrom, R. (2014). _Game programming patterns_. Genever Benning.",
        "Ricklefs, M. C. (2008). _A history of modern Indonesia since c. 1200_ (4th ed.). Palgrave Macmillan.",
        "Schell, J. (2019). _The art of game design: A book of lenses_ (3rd ed.). CRC Press.",
        "Sumarsam. (1995). _Gamelan: Cultural interaction and musical development in Central Java_. "
        "University of Chicago Press.",
        "UNESCO. (2008). _Wayang puppet theatre_. Intangible Cultural Heritage. "
        "https://ich.unesco.org/en/RL/wayang-puppet-theatre-00063",
    ]
    for item in pustaka:
        par = p(doc, item, rata="left")
        par.paragraph_format.left_indent = Cm(1.25)
        par.paragraph_format.first_line_indent = Cm(-1.25)
        par.paragraph_format.line_spacing = 1.15


def buat() -> Path:
    doc = Document()
    g.atur_gaya(doc)
    doc.core_properties.title = f"GDD {g.JUDUL} v{VERSI}"
    doc.core_properties.author = g.PENULIS
    sampul(doc)
    sec = doc.add_section(WD_SECTION.NEW_PAGE)
    sec.footer.is_linked_to_previous = False
    g.nomor_halaman(sec)
    riwayat(doc)
    g.pindah_halaman(doc)
    for bab in (bab_ringkasan, bab_cerita, bab_tokoh, bab_gameplay, bab_level, bab_mekanik, bab_aset,
                bab_pengujian, bab_rencana, bab_pustaka):
        bab(doc)
    keluar = g.FOLDER_DOCS / f"GDD_v{VERSI}.docx"
    doc.save(keluar)
    return keluar


if __name__ == "__main__":
    print("GDD disimpan:", buat())
