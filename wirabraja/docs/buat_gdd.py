"""Generator Game Design Document (GDD) "Wirabraja: Geger Alun-Alun Keraton".

Cara pakai (dari folder proyek):
    pip install python-docx
    python docs/buat_gdd.py            -> docs/GDD_v1.0.docx

Isi dokumen ditulis di skrip ini agar setiap versi GDD dapat dibuat ulang
secara konsisten dan riwayat perubahannya tercatat di Git.
"""
from __future__ import annotations

import sys
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

FOLDER_DOCS = Path(__file__).resolve().parent
FOLDER_GAMBAR = FOLDER_DOCS / "gambar"

JUDUL = "Wirabraja: Geger Alun-Alun Keraton"
PENULIS = "I Gusti Agung Ayu Putu Wulan Aristina"
NIM = "240030296"
PRODI = "Program Studi Sistem Informasi"
KAMPUS = "Institut Teknologi dan Bisnis STIKOM Bali"
TAHUN = "2026"

RIWAYAT_VERSI = [
    ("1.0", "21 November 2026",
     "Level 1 sederhana: arena Alun-Alun Lor Keraton Surakarta, ksatria Raden Wirabraja "
     "(gerak, lari, lompat, serangan gada, kamera orbit, HP), 1 jenis buta dengan AI "
     "sederhana, 1 bos (Ditya Kalamurka) dengan 1 pola serangan, kondisi menang/kalah "
     "dengan tombol ulang (R), HUD minimal.", PENULIS),
]

MARUN = RGBColor(0x75, 0x14, 0x1C)
SOGAN = RGBColor(0x5A, 0x3A, 0x1E)
FONT = "Times New Roman"


# =================================================================== utilitas dokumen

def atur_gaya(doc: Document) -> None:
    normal = doc.styles["Normal"]
    normal.font.name = FONT
    normal.font.size = Pt(12)
    normal.element.rPr.rFonts.set(qn("w:eastAsia"), FONT)
    normal.paragraph_format.line_spacing = 1.5
    normal.paragraph_format.space_after = Pt(6)
    for nama, ukuran in (("Heading 1", 16), ("Heading 2", 13), ("Heading 3", 12)):
        g = doc.styles[nama]
        g.font.name = FONT
        g.font.size = Pt(ukuran)
        g.font.bold = True
        g.font.color.rgb = MARUN if nama == "Heading 1" else SOGAN
        g.element.rPr.rFonts.set(qn("w:eastAsia"), FONT)
        g.paragraph_format.space_before = Pt(14 if nama == "Heading 1" else 10)
        g.paragraph_format.space_after = Pt(6)
        g.paragraph_format.keep_with_next = True
    for sec in doc.sections:
        sec.page_height, sec.page_width = Cm(29.7), Cm(21.0)
        sec.left_margin = Cm(4)
        sec.top_margin = Cm(3)
        sec.right_margin = Cm(3)
        sec.bottom_margin = Cm(3)


def paragraf(doc: Document, teks: str, rata: str = "justify", miring: bool = False,
             tebal: bool = False, ukuran: int | None = None):
    p = doc.add_paragraph()
    _isi_teks(p, teks, miring=miring, tebal=tebal, ukuran=ukuran)
    p.alignment = {"justify": WD_ALIGN_PARAGRAPH.JUSTIFY, "center": WD_ALIGN_PARAGRAPH.CENTER,
                   "left": WD_ALIGN_PARAGRAPH.LEFT}[rata]
    return p


def _isi_teks(p, teks: str, miring=False, tebal=False, ukuran=None):
    """Mendukung **tebal** dan _miring_ sederhana di dalam teks."""
    import re
    bagian = re.split(r"(\*\*[^*]+\*\*|(?<![A-Za-z0-9/])_[^_]+?_(?![A-Za-z0-9]))", teks)
    for b in bagian:
        if not b:
            continue
        if b.startswith("**") and b.endswith("**"):
            r = p.add_run(b[2:-2])
            r.bold = True
        elif b.startswith("_") and b.endswith("_") and len(b) > 2:
            r = p.add_run(b[1:-1])
            r.italic = True
        else:
            r = p.add_run(b)
        if miring:
            r.italic = True
        if tebal:
            r.bold = True
        if ukuran:
            r.font.size = Pt(ukuran)


def butir(doc: Document, teks: str, bernomor: bool = False):
    p = doc.add_paragraph(style="List Number" if bernomor else "List Bullet")
    _isi_teks(p, teks)
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_after = Pt(2)
    return p


def judul(doc: Document, teks: str, level: int = 1):
    return doc.add_heading(teks, level=level)


def _arsir(sel, warna_hex: str) -> None:
    tcPr = sel._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), warna_hex)
    tcPr.append(shd)


def tabel(doc: Document, kepala: list[str], baris: list[list[str]], lebar_cm: list[float] | None = None,
          ukuran: int = 10, keterangan: str | None = None):
    t = doc.add_table(rows=1, cols=len(kepala))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, k in enumerate(kepala):
        sel = t.rows[0].cells[i]
        sel.text = ""
        r = sel.paragraphs[0].add_run(k)
        r.bold = True
        r.font.size = Pt(ukuran)
        r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        _arsir(sel, "75141C")
    for b in baris:
        sel_baris = t.add_row().cells
        for i, nilai in enumerate(b):
            sel_baris[i].text = ""
            p = sel_baris[i].paragraphs[0]
            p.paragraph_format.line_spacing = 1.0
            _isi_teks(p, str(nilai), ukuran=ukuran)
    # Ulangi baris kepala di setiap halaman.
    trPr = t.rows[0]._tr.get_or_add_trPr()
    el = OxmlElement("w:tblHeader")
    el.set(qn("w:val"), "true")
    trPr.append(el)
    if lebar_cm:
        t.autofit = False
        for i, w in enumerate(lebar_cm):
            t.columns[i].width = Cm(w)
        for row in t.rows:
            for i, w in enumerate(lebar_cm):
                row.cells[i].width = Cm(w)
    if keterangan:
        p = paragraf(doc, keterangan, rata="center", miring=True, ukuran=10)
        p.paragraph_format.space_before = Pt(4)
    else:
        doc.add_paragraph()
    return t


def gambar(doc: Document, nama_file: str, keterangan: str, lebar_cm: float = 14.0) -> None:
    path = FOLDER_GAMBAR / nama_file
    if not path.exists():
        paragraf(doc, f"[Gambar {nama_file} tidak ditemukan]", rata="center", miring=True)
        return
    doc.add_picture(str(path), width=Cm(lebar_cm))
    doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
    p = paragraf(doc, keterangan, rata="center", miring=True, ukuran=10)
    p.paragraph_format.space_after = Pt(10)


def blok_kode(doc: Document, teks: str, ukuran: int = 7) -> None:
    t = doc.add_table(rows=1, cols=1)
    t.style = "Table Grid"
    sel = t.rows[0].cells[0]
    _arsir(sel, "F5EFE3")
    sel.text = ""
    p = sel.paragraphs[0]
    p.paragraph_format.line_spacing = 1.0
    for i, baris in enumerate(teks.strip("\n").split("\n")):
        r = p.add_run(baris)
        r.font.name = "Courier New"
        r.element.rPr.rFonts.set(qn("w:eastAsia"), "Courier New")
        r.font.size = Pt(ukuran)
        if i < len(teks.strip("\n").split("\n")) - 1:
            r.add_break()
    doc.add_paragraph()


def daftar_isi(doc: Document) -> None:
    p = doc.add_paragraph()
    r = p.add_run()
    for tag, isi in (("begin", None), (None, 'TOC \\o "1-2" \\h \\z \\u'), ("separate", None), ("end", None)):
        if tag:
            fc = OxmlElement("w:fldChar")
            fc.set(qn("w:fldCharType"), tag)
            r._r.append(fc)
            if tag == "separate":
                t = OxmlElement("w:t")
                t.text = "Klik kanan di sini lalu pilih \"Update Field\" untuk menampilkan daftar isi."
                r._r.append(t)
        else:
            it = OxmlElement("w:instrText")
            it.set(qn("xml:space"), "preserve")
            it.text = isi
            r._r.append(it)


def nomor_halaman(section) -> None:
    p = section.footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run()
    for tag, isi in (("begin", None), (None, "PAGE"), ("end", None)):
        if tag:
            fc = OxmlElement("w:fldChar")
            fc.set(qn("w:fldCharType"), tag)
            r._r.append(fc)
        else:
            it = OxmlElement("w:instrText")
            it.set(qn("xml:space"), "preserve")
            it.text = isi
            r._r.append(it)
    r.font.size = Pt(10)


def pindah_halaman(doc: Document) -> None:
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)


# =================================================================== isi dokumen

def sampul(doc: Document, versi: str) -> None:
    doc.add_paragraph()
    paragraf(doc, "GAME DESIGN DOCUMENT", rata="center", tebal=True, ukuran=18)
    p = paragraf(doc, JUDUL, rata="center", tebal=True, ukuran=24)
    p.runs[0].font.color.rgb = MARUN
    paragraf(doc, "Game Aksi 3D Orang Ketiga Bertema Budaya Jawa Surakarta dan Pewayangan",
             rata="center", miring=True, ukuran=13)
    paragraf(doc, f"Versi {versi}", rata="center", tebal=True, ukuran=13)
    gambar(doc, "ss_awal.png", "", lebar_cm=9.5)
    t = doc.add_table(rows=0, cols=3)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for label, nilai in (("Mata Kuliah", ""), ("Dosen Pengampu", ""), ("Disusun oleh", PENULIS),
                         ("NIM", NIM)):
        c = t.add_row().cells
        c[0].text, c[1].text, c[2].text = label, ":", nilai
        c[0].width, c[1].width, c[2].width = Cm(4.0), Cm(0.5), Cm(8.5)
        for sel in c:
            sel.paragraphs[0].paragraph_format.line_spacing = 1.15
    doc.add_paragraph()
    for baris in (PRODI.upper(), KAMPUS.upper(), TAHUN):
        paragraf(doc, baris, rata="center", tebal=True, ukuran=13).paragraph_format.space_after = Pt(0)


def riwayat_versi(doc: Document) -> None:
    paragraf(doc, "RIWAYAT VERSI", rata="center", tebal=True, ukuran=14)
    tabel(doc, ["Versi", "Tanggal", "Perubahan", "Penulis"],
          [list(r) for r in RIWAYAT_VERSI], lebar_cm=[1.4, 2.8, 7.8, 3.0])
    paragraf(doc, "DAFTAR ISI", rata="center", tebal=True, ukuran=14)
    daftar_isi(doc)


def bab_ringkasan(doc: Document) -> None:
    judul(doc, "1. Ringkasan Game")
    judul(doc, "1.1 Identitas Game", 2)
    tabel(doc, ["Aspek", "Keterangan"], [
        ["Judul", JUDUL],
        ["Genre", "Aksi (_action_) 3D, pertarungan jarak dekat (_hack and slash_ ringan)"],
        ["Platform", "PC (Windows 10/11); kontrol papan ketik dan tetikus"],
        ["Kamera", "Orang ketiga (_third-person_), di belakang tokoh, dapat diputar dengan tetikus"],
        ["Mesin & bahasa", "Godot Engine 4.5 (versi stabil), GDScript dengan _static typing_"],
        ["Target pemain", "Remaja dan dewasa (13 tahun ke atas), pelajar/mahasiswa, dan pemain "
                          "kasual yang tertarik pada budaya Jawa; kekerasan bersifat fantasi tanpa darah"],
        ["Mode", "Pemain tunggal, satu level (Level 1) berdurasi sekitar 5–8 menit"],
        ["Nilai budaya", "Keraton Kasunanan Surakarta, tokoh ksatria dan buta dalam wayang purwa, "
                         "palet warna batik sogan, nilai kepahlawanan ksatria"],
    ], lebar_cm=[3.5, 11.5], keterangan="Tabel 1.1 Identitas game")
    judul(doc, "1.2 Konsep Singkat", 2)
    paragraf(doc, f"**{JUDUL}** adalah game aksi 3D orang ketiga. Pemain mengendalikan "
                  "**Raden Wirabraja**, ksatria pewayangan rekaan yang menjaga Keraton Kasunanan "
                  "Surakarta. Bala buta (raksasa jahat dalam pewayangan) menyerbu Alun-Alun Lor. "
                  "Pemain harus mengalahkan seluruh buta dengan gada, lalu menghadapi raksasa besar "
                  "**Ditya Kalamurka** yang bangkit dari bumi di depan pendopo keraton.")
    judul(doc, "1.3 Nilai Budaya yang Diangkat", 2)
    for b in (
        "**Ruang keraton.** Arena meniru tata ruang sumbu utara–selatan Alun-Alun Lor: sepasang "
        "beringin berpagar di tengah alun-alun, pendopo di sisi utara, dan gerbang keraton di belakangnya.",
        "**Wayang purwa gaya Surakarta.** Pertarungan ksatria melawan buta merujuk pada adegan perang "
        "dalam pertunjukan wayang kulit, khususnya _perang kembang_, yaitu perang antara ksatria halus "
        "dan raksasa yang lazim dalam pakeliran (Brandon, 1970; Keeler, 1987).",
        "**Simbolisme.** Ksatria melambangkan budi luhur dan tanggung jawab, sedangkan buta melambangkan "
        "_angkara murka_ (nafsu angkara) yang harus ditaklukkan (Anderson, 1965).",
        "**Estetika visual.** Placeholder memakai warna khas Jawa: cokelat sogan, emas, merah marun, dan "
        "hijau, serta bentuk atap joglo pada pendopo.",
    ):
        butir(doc, b)
    judul(doc, "1.4 Pilar Desain", 2)
    for b in (
        "**Responsif:** kontrol langsung terasa, serangan memiliki jendela kena yang jelas.",
        "**Terbaca:** setiap serangan musuh diawali ancang-ancang (_telegraph_) yang terlihat.",
        "**Berakar budaya:** latar, tokoh, dan istilah bersumber dari budaya Jawa Surakarta.",
        "**Mudah dikembangkan:** semua nilai keseimbangan dapat disetel (@export) dan model placeholder "
        "mudah diganti dengan model asli.",
    ):
        butir(doc, b)


def bab_cerita(doc: Document) -> None:
    judul(doc, "2. Cerita dan Latar")
    judul(doc, "2.1 Sinopsis Level 1", 2)
    paragraf(doc, "Senja turun di Surakarta. Dari arah hutan Gandamayit, bala buta suruhan raksasa "
                  "Ditya Kalamurka menyerbu Alun-Alun Lor dan mengancam ketenteraman keraton. Raden "
                  "Wirabraja, ksatria penjaga gerbang, maju seorang diri. Setelah seluruh prajurit buta "
                  "tumbang, bumi bergetar dan Ditya Kalamurka bangkit di depan pendopo. Bila sang "
                  "raksasa dikalahkan, alun-alun kembali tenteram dan Level 1 selesai.")
    judul(doc, "2.2 Latar: Keraton Kasunanan Surakarta", 2)
    paragraf(doc, "Keraton Kasunanan Surakarta Hadiningrat didirikan oleh Susuhunan Pakubuwana II pada "
                  "pertengahan abad ke-18 (1745) setelah istana Mataram di Kartasura rusak akibat "
                  "pemberontakan (Ricklefs, 2008). Kompleks keraton tersusun pada sumbu utara–selatan: "
                  "di bagian depan terdapat Alun-Alun Lor dengan sepasang pohon beringin berpagar di "
                  "tengahnya, diikuti bangunan Pagelaran (pendopo besar untuk menghadap raja), "
                  "Sitihinggil, dan gerbang-gerbang (kori) menuju bagian dalam keraton.")
    paragraf(doc, "Dalam game, latar tersebut **distilisasi** menjadi arena berukuran 64 × 64 meter: "
                  "pendopo bergaya joglo mewakili Pagelaran, gapura beratap mewakili gerbang keraton, dan "
                  "dua beringin berpagar (_ringin kurung_) berdiri di tengah. Arena bukan replika "
                  "arsitektural yang akurat; proporsi dan jumlah bangunan disederhanakan demi keterbacaan "
                  "permainan.")
    judul(doc, "2.3 Konteks Pewayangan", 2)
    paragraf(doc, "Wayang kulit purwa diakui UNESCO sebagai Warisan Budaya Takbenda Kemanusiaan "
                  "(UNESCO, 2008). Dalam lakon-lakon wayang purwa, tokoh dibedakan antara golongan "
                  "ksatria yang berwatak halus dan golongan raksasa (_buta_ atau _ditya_) yang berwatak "
                  "kasar. Adegan _perang kembang_ menampilkan ksatria muda yang dengan tenang "
                  "mengalahkan beberapa raksasa sekaligus (Brandon, 1970; Keeler, 1987). Struktur Level 1 "
                  "(gelombang buta lalu satu raksasa besar) mengadaptasi pola dramatik tersebut ke dalam "
                  "bentuk permainan aksi.")
    paragraf(doc, "Tokoh pemain terinspirasi oleh Gatotkaca, putra Bima dan Arimbi, ksatria Pringgandani "
                  "yang dikenal dengan julukan _otot kawat balung wesi_ (berotot kawat, bertulang besi). "
                  "Namun Raden Wirabraja adalah tokoh **orisinal** dengan nama, silsilah, dan desain "
                  "sendiri, sehingga tidak mengubah atau mengklaim kisah tokoh wayang yang sudah ada.")
    judul(doc, "2.4 Catatan Kepekaan Budaya", 2)
    for b in (
        "Keraton Surakarta adalah lembaga adat yang masih hidup. Game tidak menampilkan raja, kerabat "
        "keraton, pusaka, maupun upacara adat; keraton hanya menjadi latar arsitektural.",
        "Tokoh pemain, musuh, dan bos adalah rekaan sehingga tidak mengubah lakon atau watak tokoh wayang "
        "yang telah dikenal masyarakat.",
        "Istilah Jawa dipakai sesuai makna umumnya (buta, ditya, ksatria, pendopo, gapura, alun-alun).",
    ):
        butir(doc, b)


def bab_tokoh(doc: Document) -> None:
    judul(doc, "3. Tokoh dan Musuh")
    judul(doc, "3.1 Raden Wirabraja (Tokoh Pemain)", 2)
    paragraf(doc, "Nama _Wirabraja_ dibentuk dari kata _wira_ (pahlawan, berani) dan _braja_ (senjata "
                  "petir/senjata sakti). Ia adalah ksatria penjaga gerbang keraton yang bersenjatakan gada.")
    gambar(doc, "ss_awal.png", "Gambar 3.1 Raden Wirabraja (tengah) menghadap bala buta di Alun-Alun Lor", 13)
    tabel(doc, ["Unsur visual", "Bentuk placeholder", "Makna/inspirasi"], [
        ["Kulit", "Kapsul cokelat sogan", "Ksatria gagah, warna sogan khas Surakarta"],
        ["Gelung & jamang", "Silinder emas di kepala", "Mahkota ksatria wayang"],
        ["Garuda mungkur", "Lempeng emas di belakang gelung", "Hiasan kepala ksatria wayang"],
        ["Kotang", "Silinder sogan tua berlis emas", "Rompi ksatria (terinspirasi kotang Gatotkaca)"],
        ["Praba", "Dua lempeng emas di punggung", "Tanda kesaktian ksatria"],
        ["Kain dodot", "Silinder marun + sabuk emas", "Busana bawah ksatria"],
        ["Sampur", "Kotak tipis hijau", "Selendang"],
        ["Gada", "Silinder sogan + kepala emas", "Senjata utama"],
    ], lebar_cm=[3.2, 5.3, 6.5], keterangan="Tabel 3.1 Desain visual Raden Wirabraja")
    judul(doc, "3.2 Buta Prajurit (Musuh Biasa)", 2)
    paragraf(doc, "Raksasa prajurit berkulit merah, bertubuh gempal, bermata melotot, bertaring, berambut "
                  "gimbal hitam, dan membawa gada kayu. Tingginya sekitar 3,2 meter (lebih tinggi dari "
                  "pemain). Ada enam buta di Level 1.")
    gambar(doc, "ss_buta.png", "Gambar 3.2 Dua Buta Prajurit mengepung Raden Wirabraja", 13)
    judul(doc, "3.3 Ditya Kalamurka (Bos)", 2)
    paragraf(doc, "Nama _Ditya Kalamurka_ berasal dari _ditya_ (raksasa), _kala_ (waktu/bencana), dan "
                  "_murka_ (amarah). Raksasa berkulit hijau gelap setinggi kurang lebih 6 meter, bermata "
                  "merah menyala, bermahkota emas tinggi, dan berpraba lingkaran emas di punggung. Ia "
                  "bangkit dari dalam bumi setelah semua buta dikalahkan.")
    gambar(doc, "ss_hantam.png", "Gambar 3.3 Ditya Kalamurka bersiap melakukan Hantaman Bumi "
                                 "(lingkaran merah = area bahaya)", 13)


def bab_gameplay(doc: Document) -> None:
    judul(doc, "4. Gameplay dan Kontrol")
    judul(doc, "4.1 Alur Inti (Core Loop)", 2)
    for b in (
        "Mendekati buta, membaca ancang-ancang serangannya (kedua lengan terangkat).",
        "Menyerang dengan gada (tiga pukulan mengalahkan satu buta) atau menghindar dengan lari/lompat.",
        "Mengulangi sampai semua buta kalah, lalu menghadapi bos.",
        "Membaca lingkaran bahaya bos, keluar dari lingkaran atau melompat tepat waktu, lalu memukul "
        "bos saat ia terengah (fase pulih).",
    ):
        butir(doc, b, bernomor=True)
    judul(doc, "4.2 Kontrol", 2)
    tabel(doc, ["Tombol", "Aksi"], [
        ["W / A / S / D (atau panah)", "Bergerak relatif terhadap arah kamera"],
        ["Shift kiri (tahan)", "Berlari"],
        ["Spasi", "Melompat"],
        ["Klik kiri tetikus", "Serangan gada"],
        ["Gerakan tetikus", "Memutar kamera orbit (mendatar dan naik-turun)"],
        ["Esc", "Melepas kursor tetikus (klik untuk mengunci kembali)"],
        ["R", "Mengulang level setelah menang atau kalah"],
    ], lebar_cm=[5.5, 9.5], keterangan="Tabel 4.1 Pemetaan kontrol")
    judul(doc, "4.3 Kamera", 2)
    paragraf(doc, "Kamera orbit terdiri atas node _yaw_ (berputar mendatar) dan SpringArm3D (_pitch_, "
                  "dibatasi −65° sampai +25°) berjarak 5,5 meter di belakang tokoh. SpringArm3D mencegah "
                  "kamera menembus pagar atau bangunan. Kamera bergetar singkat ketika bos menghantam tanah.")


def bab_level(doc: Document) -> None:
    judul(doc, "5. Desain Level 1: Alun-Alun Lor")
    judul(doc, "5.1 Denah", 2)
    paragraf(doc, "Denah teks berikut memperlihatkan tata letak arena dilihat dari atas (utara di atas). "
                  "Satu karakter mewakili sekitar 2 meter.")
    blok_kode(doc, r"""
                     UTARA (gerbang keraton)
 +=================[ G E R B A N G ]=================+   z = -32
 |                                                   |
 |        +-------------------------------+          |
 |        |   PENDOPO (Pagelaran, joglo)  |          |   z = -21
 |        +-------------------------------+          |
 |   B5                    X                  B6     |   X  = titik bos (z = -11)
 | B3                                            B4  |
 |          [##]  beringin   ||   beringin  [##]     |   z = -2 (ringin kurung)
 |  T                        ||                   T  |   T  = pohon tepi
 |                           ||                      |
 |              B1           ||          B2          |   z = 10
 |                           ||                      |   || = jalan sumbu
 |                           P                       |   P  = pemain mulai (z = 24)
 +===================================================+   z = +32
                         SELATAN
  Bn = posisi awal Buta Prajurit ke-n     Arena 64 m x 64 m, pagar tembok keliling
""", ukuran=7)
    gambar(doc, "ss_arena.png", "Gambar 5.1 Tampilan arena dari udara (tangkapan layar game)", 14)
    judul(doc, "5.2 Elemen Arena", 2)
    tabel(doc, ["Elemen", "Posisi (x, z) m", "Fungsi dalam permainan"], [
        ["Pagar tembok keliling", "±32", "Batas arena; dinding tak terlihat setinggi 5 m mencegah pemain keluar"],
        ["Gerbang keraton (paduraksa)", "(0, −32)", "Penanda arah utara dan tujuan visual"],
        ["Pendopo joglo", "(0, −21)", "Penanda latar; tiang menjadi penghalang dan tempat berlindung"],
        ["Dua ringin kurung", "(±6,5, −2)", "Rintangan di tengah; berguna untuk memecah kepungan buta"],
        ["Delapan pohon tepi", "tepi arena", "Dekorasi dan rintangan kecil"],
        ["Jalan sumbu", "x = 0", "Membimbing pemain dari selatan ke utara"],
        ["Titik munculnya bos", "(0, −11)", "Ruang terbuka di depan pendopo untuk pertarungan bos"],
    ], lebar_cm=[4.3, 2.9, 7.8], keterangan="Tabel 5.1 Elemen arena Level 1")
    judul(doc, "5.3 Alur dan Tempo Level", 2)
    for b in (
        "**Pembuka:** pemain mulai di selatan; dua buta (B1, B2) langsung terdeteksi (jarak deteksi 20 m) "
        "sebagai pemanasan.",
        "**Tengah:** saat pemain maju, empat buta lain (B3–B6) di sekitar beringin dan pendopo ikut mengejar.",
        "**Puncak:** setelah buta terakhir kalah muncul pengumuman, dua detik kemudian Ditya Kalamurka "
        "bangkit dari tanah di depan pendopo.",
        "**Penutup:** bos kalah, tampil teks MENANG dan petunjuk tombol R. Bila HP pemain habis kapan "
        "pun, tampil teks KALAH.",
    ):
        butir(doc, b)


def bab_mekanik(doc: Document) -> None:
    judul(doc, "6. Mekanik")
    judul(doc, "6.1 Nyawa (HP) dan Kekebalan Sesaat", 2)
    paragraf(doc, "Pemain, buta, dan bos memakai komponen yang sama, **KomponenHP**, yang memancarkan "
                  "sinyal hp_berubah, terkena, dan habis. Setelah terkena, pemain kebal selama 0,7 "
                  "detik, terdorong ke belakang, dan terhuyung selama 0,25 detik. Model berkilat merah-putih "
                  "sebagai umpan balik visual.")
    judul(doc, "6.2 Serangan Pemain", 2)
    paragraf(doc, "Satu klik memicu ayunan gada selama 0,42 detik: gada diangkat ke atas kepala lalu "
                  "dihantamkan ke depan. Hitbox (Area3D berbentuk silinder di depan tokoh) hanya aktif pada "
                  "detik 0,10–0,26 dan setiap musuh hanya terkena satu kali per ayunan. Pemain melangkah "
                  "maju sedikit saat menyerang, dan musuh yang terkena terdorong mundur.")
    judul(doc, "6.3 Kecerdasan Buatan Buta (State Machine)", 2)
    tabel(doc, ["State", "Perilaku", "Transisi"], [
        ["DIAM", "Berdiri dan bernapas pelan", "Pemain ≤ 20 m → MENGEJAR"],
        ["MENGEJAR", "Berjalan lurus ke arah pemain (3,2 m/s)", "Jarak ≤ 2,2 m → ANCANG; pemain > 35 m → DIAM"],
        ["ANCANG", "Berhenti, mengangkat kedua lengan selama 0,55 detik (telegraph)", "Waktu habis → serangan → PULIH"],
        ["PULIH", "Diam 0,8 detik setelah memukul (celah bagi pemain)", "Waktu habis → MENGEJAR"],
        ["TERKENA", "Terdorong dan terhuyung 0,35 detik", "Waktu habis → MENGEJAR"],
        ["MATI", "Rebah, mengecil, dihapus; lapor ke GameManager", "—"],
    ], lebar_cm=[2.4, 7.0, 5.6], keterangan="Tabel 6.1 State machine Buta Prajurit")
    paragraf(doc, "Serangan buta hanya mengenai bila pemain masih berada dalam jangkauan (2,8 m) dan berada "
                  "di depan buta. Dengan demikian pemain dapat menghindar setelah melihat ancang-ancang.")
    judul(doc, "6.4 Bos: Pola Serangan Hantaman Bumi", 2)
    for b in (
        "**Muncul:** bos bangkit dari tanah selama 1,8 detik dan kebal selama animasi ini.",
        "**Mengejar:** berjalan pelan (2,4 m/s) ke arah pemain.",
        "**Ancang-ancang (1,2 detik):** bila pemain ≤ 5,5 m, bos mengangkat kedua lengan dan lingkaran merah "
        "berdenyut membesar di tanah hingga radius 6,5 m.",
        "**Hantam:** pemain di dalam lingkaran yang tidak sedang melompat (tinggi < 0,5 m) menerima 30 damage "
        "dan terpental. Debu melingkar dan guncangan kamera menandai hantaman.",
        "**Pulih (1,6 detik):** bos diam, waktu terbaik untuk memukul.",
        "Bos memiliki _super armor_ (tidak terhuyung) dan 500 HP, setara 20 pukulan gada.",
    ):
        butir(doc, b)
    judul(doc, "6.5 State Permainan dan Kondisi Menang/Kalah", 2)
    paragraf(doc, "Autoload **GameManager** mengelola state permainan dan memancarkan sinyal ke level dan HUD "
                  "(pola _observer_), sehingga antarnode tidak saling bergantung secara langsung (Nystrom, 2014).")
    blok_kode(doc, """
   mulai_level(6)
        |
        v
  [ BERTARUNG ] --(buta terakhir kalah)--> [ BOS ] --(bos kalah)--> [ MENANG ]
        |                                    |
        +------(HP pemain habis)-------------+-----------------------> [ KALAH ]

  MENANG / KALAH : teks di tengah layar + "Tekan R untuk mengulang" -> muat ulang level
""")
    judul(doc, "6.6 Parameter Keseimbangan", 2)
    paragraf(doc, "Semua nilai berikut merupakan variabel @export sehingga dapat disetel lewat Inspector Godot "
                  "tanpa mengubah kode.")
    tabel(doc, ["Objek", "Parameter", "Nilai v1.0"], [
        ["Pemain", "hp_maks / kecepatan / kecepatan_lari", "100 / 5,0 m/s / 8,5 m/s"],
        ["Pemain", "kekuatan_lompat / waktu_kebal", "6,5 m/s / 0,7 s"],
        ["Pemain", "damage / durasi_serangan", "25 / 0,42 s"],
        ["Buta Prajurit", "hp_maks / kecepatan / damage", "75 / 3,2 m/s / 10"],
        ["Buta Prajurit", "jarak_deteksi / jarak_serang", "20 m / 2,2 m"],
        ["Buta Prajurit", "waktu_ancang / waktu_pulih", "0,55 s / 0,8 s"],
        ["Ditya Kalamurka", "hp_maks / kecepatan", "500 / 2,4 m/s"],
        ["Ditya Kalamurka", "radius_hantaman / damage_hantaman", "6,5 m / 30"],
        ["Ditya Kalamurka", "waktu_ancang / waktu_pulih", "1,2 s / 1,6 s"],
    ], lebar_cm=[3.4, 6.6, 5.0], keterangan="Tabel 6.2 Parameter keseimbangan Level 1")
    judul(doc, "6.7 Antarmuka (HUD)", 2)
    paragraf(doc, "HUD menampilkan nama dan bar HP pemain (kiri atas), jumlah buta tersisa (kanan atas), bar HP "
                  "bos (tengah atas, hanya saat bos muncul), pengumuman singkat (tengah), petunjuk kontrol "
                  "(bawah), serta layar MENANG/KALAH.")
    gambar(doc, "ss_menang.png", "Gambar 6.1 Layar kemenangan setelah Ditya Kalamurka kalah", 13)


def bab_aset(doc: Document) -> None:
    judul(doc, "7. Aset dan Teknologi")
    judul(doc, "7.1 Teknologi", 2)
    tabel(doc, ["Komponen", "Pilihan"], [
        ["Mesin game", "Godot Engine 4.5 (stabil), renderer Forward+"],
        ["Bahasa", "GDScript dengan static typing"],
        ["Fisika", "CharacterBody3D + move_and_slide, Area3D (hitbox), StaticBody3D (arena)"],
        ["Lapisan tabrakan", "1 = dunia, 2 = pemain, 3 = musuh"],
        ["Dokumen", "Python 3 + python-docx (skrip docs/buat_gdd.py)"],
        ["Pengujian", "Scene uji otomatis tests/uji_alur.tscn dijalankan secara headless"],
    ], lebar_cm=[4.0, 11.0], keterangan="Tabel 7.1 Teknologi yang digunakan")
    judul(doc, "7.2 Struktur Proyek", 2)
    blok_kode(doc, """
wirabraja/
  project.godot           konfigurasi, input map, autoload GameManager
  scenes/player/          player.tscn (Raden Wirabraja + kamera orbit)
  scenes/enemies/         buta.tscn
  scenes/boss/            bos_raksasa.tscn (Ditya Kalamurka)
  scenes/level/           level_1.tscn, pendopo, gerbang, pagar_keliling, beringin
  scenes/ui/              hud.tscn
  scripts/autoload/       game_manager.gd (state permainan)
  scripts/common/         komponen_hp.gd, efek_visual.gd, palet_jawa.gd
  scripts/player|enemies|boss|level|ui/   skrip per objek
  audio/                  (disiapkan untuk Fase 2)
  docs/                   GDD_v1.0.docx, buat_gdd.py, gambar/
  tests/                  uji_alur (uji otomatis), tangkap_layar
  tools/                  buat_scene_karakter.py (generator model placeholder)
""")
    judul(doc, "7.3 Daftar Aset Placeholder", 2)
    paragraf(doc, "Seluruh aset 3D Fase 1 dibuat dari bentuk bawaan Godot (CapsuleMesh, SphereMesh, "
                  "CylinderMesh, BoxMesh, TorusMesh). Tidak ada aset pihak ketiga.")
    tabel(doc, ["Aset", "Bentuk dasar", "Lokasi"], [
        ["Raden Wirabraja", "Kapsul, bola, silinder, kotak, torus (±30 mesh)", "scenes/player/player.tscn"],
        ["Buta Prajurit", "Kapsul, bola, silinder, kotak, torus", "scenes/enemies/buta.tscn"],
        ["Ditya Kalamurka", "Model raksasa diskalakan 1,95× + praba torus", "scenes/boss/bos_raksasa.tscn"],
        ["Pendopo joglo", "Silinder (tiang), kotak, limas dari CylinderMesh 4 sisi", "scenes/level/pendopo.tscn"],
        ["Gerbang paduraksa", "Kotak, limas, bola", "scenes/level/gerbang.tscn"],
        ["Pagar keliling", "Kotak", "scenes/level/pagar_keliling.tscn"],
        ["Beringin / ringin kurung", "Silinder, bola, kotak", "scenes/level/beringin.tscn"],
        ["Penanda Hantaman Bumi", "Silinder pipih transparan", "scenes/boss/bos_raksasa.tscn"],
        ["Efek debu", "Torus yang membesar dan memudar", "scripts/common/efek_visual.gd"],
    ], lebar_cm=[3.6, 6.0, 5.4], keterangan="Tabel 7.2 Aset placeholder")
    judul(doc, "7.4 Palet Warna Jawa", 2)
    palet = [
        ("Cokelat sogan", "734A29", "734A29", "Kulit ksatria, kayu, batik sogan"),
        ("Sogan tua", "472B17", "472B17", "Kotang, batang beringin, balok"),
        ("Emas", "DBA838", "DBA838", "Mahkota, perhiasan, lis bangunan"),
        ("Merah marun", "75141C", "75141C", "Kain dodot, tiang pendopo, pintu gerbang"),
        ("Hijau", "2B6638", "2B6638", "Sampur, tajuk pohon"),
        ("Hijau tua", "14381F", "14381F", "Kain buta, tajuk pohon"),
        ("Putih gading", "EDE3C7", "EDE3C7", "Tembok pagar dan gerbang"),
    ]
    t = tabel(doc, ["Warna", "Kode heksa", "Contoh", "Penggunaan"],
              [[n, f"#{h}", "", u] for n, _, h, u in palet], lebar_cm=[3.2, 2.6, 1.8, 7.4],
              keterangan="Tabel 7.3 Palet warna placeholder")
    for i, (_, _, h, _) in enumerate(palet, start=1):
        _arsir(t.rows[i].cells[2], h)
    judul(doc, "7.5 Strategi Penggantian ke Model Asli", 2)
    for b in (
        "Setiap karakter memiliki node **Model** yang terpisah dari node fisika (CollisionShape3D) dan "
        "logika. Model asli (.glb/.gltf) cukup diletakkan sebagai pengganti isi node Model.",
        "Animasi prosedural mencari node opsional LenganKanan, LenganKiri, KakiKanan, dan KakiKiri. Bila "
        "model asli memakai AnimationPlayer, node tersebut boleh dihapus tanpa menimbulkan galat.",
        "Efek kilat terkena bekerja pada semua MeshInstance3D turunan sehingga tetap berfungsi pada model baru.",
        "Bangunan arena adalah scene terpisah (pendopo, gerbang, pagar, beringin); skrip pembangunnya cukup "
        "dilepas lalu model asli ditambahkan sebagai anak node yang sama.",
    ):
        butir(doc, b)


def bab_pengujian(doc: Document) -> None:
    judul(doc, "8. Pengujian Fase 1")
    paragraf(doc, "Pengujian otomatis dijalankan secara headless dengan perintah "
                  "godot --headless --path . res://tests/uji_alur.tscn. Hasil pada versi 1.0:")
    tabel(doc, ["No", "Skenario uji", "Hasil"], [
        ["1", "State awal BERTARUNG dan jumlah buta = 6", "Lulus"],
        ["2", "WASD menggerakkan pemain; pemain berdiri di lantai (collision)", "Lulus"],
        ["3", "Spasi membuat pemain melompat", "Lulus"],
        ["4", "Klik kiri: serangan gada mengurangi HP buta (75 → 50)", "Lulus"],
        ["5", "Buta mengejar dan menyerang pemain", "Lulus"],
        ["6", "Semua buta kalah → state BOS → bos muncul", "Lulus"],
        ["7", "Bos kebal selama animasi muncul", "Lulus"],
        ["8", "Bos melakukan ancang-ancang + penanda; Hantaman Bumi mengenai pemain", "Lulus"],
        ["9", "Bos kalah → MENANG, HUD menampilkan teks menang", "Lulus"],
        ["10", "Level baru me-reset state; HP pemain habis → KALAH + teks dan petunjuk R", "Lulus"],
    ], lebar_cm=[1.0, 11.5, 2.5], keterangan="Tabel 8.1 Hasil uji otomatis Fase 1 (19 pemeriksaan lulus)")


def bab_rencana(doc: Document) -> None:
    judul(doc, "9. Rencana Pengembangan Berikutnya")
    paragraf(doc, "Fase 2 (versi 1.1) direncanakan mencakup hal-hal berikut:")
    for b in (
        "**Variasi musuh:** minimal tiga jenis buta baru dengan perilaku berbeda (buta lincah, buta besar "
        "yang lambat tetapi kuat, dan buta pelempar batu jarak jauh) yang mewarisi kelas Buta.",
        "**Bos yang lebih kaya:** minimal tiga pola serangan (hantaman area, serbuan lurus, memanggil buta "
        "kecil) dan fase kedua ketika HP bos di bawah 50%.",
        "**Audio:** musik latar bernuansa gamelan dan efek suara (pukulan, terkena, langkah, kemenangan) "
        "melalui AudioManager.",
        "**Narasi pembuka bergaya dalang:** layar teks berurutan sebelum level dimulai, dapat dilewati.",
        "**Polesan:** penyesuaian keseimbangan dari hasil uji main dan pembaruan GDD ke versi 1.1.",
    ):
        butir(doc, b)
    paragraf(doc, "Untuk jangka lebih panjang: model 3D asli bergaya wayang, animasi rangka (skeletal), menu "
                  "utama, serta level lanjutan di Alun-Alun Kidul dan kawasan Sitihinggil.")


def bab_pustaka(doc: Document) -> None:
    judul(doc, "10. Daftar Pustaka")
    pustaka = [
        "Anderson, B. R. O'G. (1965). _Mythology and the tolerance of the Javanese_. Modern Indonesia "
        "Project, Cornell University.",
        "Brandon, J. R. (Ed.). (1970). _On thrones of gold: Three Javanese shadow plays_. Harvard "
        "University Press.",
        "Godot Engine. (2025). _Godot Engine documentation_ (stable). https://docs.godotengine.org/en/stable/",
        "Keeler, W. (1987). _Javanese shadow plays, Javanese selves_. Princeton University Press.",
        "Nystrom, R. (2014). _Game programming patterns_. Genever Benning.",
        "Ricklefs, M. C. (2008). _A history of modern Indonesia since c. 1200_ (4th ed.). Palgrave Macmillan.",
        "Schell, J. (2019). _The art of game design: A book of lenses_ (3rd ed.). CRC Press.",
        "UNESCO. (2008). _Wayang puppet theatre_. Intangible Cultural Heritage. "
        "https://ich.unesco.org/en/RL/wayang-puppet-theatre-00063",
    ]
    for item in pustaka:
        p = paragraf(doc, item, rata="left")
        p.paragraph_format.left_indent = Cm(1.25)
        p.paragraph_format.first_line_indent = Cm(-1.25)
        p.paragraph_format.line_spacing = 1.15


# =================================================================== utama

def buat(versi: str = "1.0") -> Path:
    doc = Document()
    atur_gaya(doc)
    doc.core_properties.title = f"GDD {JUDUL} v{versi}"
    doc.core_properties.author = PENULIS
    sampul(doc, versi)
    sec = doc.add_section(WD_SECTION.NEW_PAGE)
    sec.footer.is_linked_to_previous = False
    nomor_halaman(sec)
    riwayat_versi(doc)
    pindah_halaman(doc)
    bab_ringkasan(doc)
    bab_cerita(doc)
    bab_tokoh(doc)
    bab_gameplay(doc)
    bab_level(doc)
    bab_mekanik(doc)
    bab_aset(doc)
    bab_pengujian(doc)
    bab_rencana(doc)
    bab_pustaka(doc)
    keluar = FOLDER_DOCS / f"GDD_v{versi}.docx"
    doc.save(keluar)
    return keluar


if __name__ == "__main__":
    v = sys.argv[1] if len(sys.argv) > 1 else "1.0"
    print("GDD disimpan:", buat(v))
