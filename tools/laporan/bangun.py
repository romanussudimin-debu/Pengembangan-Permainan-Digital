# Membangun Laporan Proyek (.docx) dari laporan.md: gaya kampus, cover, nomor halaman, daftar otomatis.
import subprocess, sys, os, re, copy
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING, WD_BREAK
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

DIR = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
TNR, HITAM = "Times New Roman", RGBColor(0, 0, 0)


def fonts(rpr, font):
    rf = rpr.find(qn('w:rFonts'))
    if rf is None:
        rf = OxmlElement('w:rFonts'); rpr.insert(0, rf)
    for a in list(rf.attrib):
        if a.endswith('Theme'):
            del rf.attrib[a]
    for a in ('w:ascii', 'w:hAnsi', 'w:cs', 'w:eastAsia'):
        rf.set(qn(a), font)


def gaya_dasar(s, ukuran=12, font=TNR, tebal=None, miring=False):
    fonts(s.element.get_or_add_rPr(), font)
    s.font.size = Pt(ukuran); s.font.color.rgb = HITAM; s.font.italic = miring
    if tebal is not None:
        s.font.bold = tebal


def paragraf(s, align=WD_ALIGN_PARAGRAPH.JUSTIFY, spasi=1.5, before=0, after=0, indent_awal=None, kiri=None, gantung=None,
             page_break=False, keep_next=False):
    pf = s.paragraph_format
    pf.alignment = align; pf.line_spacing = spasi
    pf.space_before = Pt(before); pf.space_after = Pt(after)
    pf.first_line_indent = indent_awal
    if kiri is not None:
        pf.left_indent = kiri
    if gantung is not None:
        pf.left_indent = gantung; pf.first_line_indent = -gantung
    pf.page_break_before = page_break; pf.keep_with_next = keep_next


def cari(styles, nama):
    for s in styles:
        if s.name == nama:
            return s
    return None


def tambah(styles, nama, dasar="Normal"):
    s = cari(styles, nama)
    if s is None:
        s = styles.add_style(nama, WD_STYLE_TYPE.PARAGRAPH)
        s.base_style = cari(styles, dasar)
    return s


def border_box(s):
    pPr = s.element.get_or_add_pPr()
    b = OxmlElement('w:pBdr')
    for sisi in ('top', 'left', 'bottom', 'right'):
        e = OxmlElement(f'w:{sisi}'); e.set(qn('w:val'), 'single'); e.set(qn('w:sz'), '4'); e.set(qn('w:space'), '4'); e.set(qn('w:color'), '000000'); b.append(e)
    pPr.append(b)


# ------------------------------------------------------------------ reference.docx
ref = Document(os.path.join(DIR, "ref.docx"))
st = ref.styles
dd = st.element.find(qn('w:docDefaults'))
fonts(dd.find(qn('w:rPrDefault')).find(qn('w:rPr')), TNR)
for s in st:
    if s.type in (WD_STYLE_TYPE.PARAGRAPH, WD_STYLE_TYPE.CHARACTER):
        gaya_dasar(s, 12, "Courier New" if s.name in ("Source Code", "Verbatim Char") else TNR)
for n in ("Normal", "Body Text", "First Paragraph"):
    paragraf(cari(st, n), indent_awal=Cm(1.25) if n != "Normal" else None, after=0)
paragraf(cari(st, "Compact"), after=0)
h1 = cari(st, "Heading 1"); gaya_dasar(h1, 14, tebal=True)
paragraf(h1, WD_ALIGN_PARAGRAPH.CENTER, 1.5, 0, 24, page_break=True, keep_next=True)
for n in ("Heading 2", "Heading 3"):
    h = cari(st, n); gaya_dasar(h, 12, tebal=True)
    paragraf(h, WD_ALIGN_PARAGRAPH.LEFT, 1.5, 12, 6, keep_next=True)
for n in ("Image Caption", "Table Caption"):
    c = cari(st, n); gaya_dasar(c, 12, tebal=False)
    paragraf(c, WD_ALIGN_PARAGRAPH.CENTER, 1.0, 6 if n == "Table Caption" else 4, 6 if n == "Table Caption" else 12,
             keep_next=(n == "Table Caption"))
for n in ("Captioned Figure", "Figure"):
    s = cari(st, n)
    if s is not None:
        paragraf(s, WD_ALIGN_PARAGRAPH.CENTER, 1.0, 6, 0, keep_next=True)
src = tambah(st, "Source Code"); gaya_dasar(src, 8.5, "Courier New")
paragraf(src, WD_ALIGN_PARAGRAPH.LEFT, 1.0, 0, 12); border_box(src)
hl = cari(st, "Hyperlink"); hl.font.underline = False

# gaya khusus
s = tambah(st, "Cover Judul"); gaya_dasar(s, 14, tebal=True); paragraf(s, WD_ALIGN_PARAGRAPH.CENTER, 1.5, 0, 12)
s = tambah(st, "Cover"); gaya_dasar(s, 12, tebal=False); paragraf(s, WD_ALIGN_PARAGRAPH.CENTER, 1.5, 0, 0)
s = tambah(st, "Cover Tebal"); gaya_dasar(s, 12, tebal=True); paragraf(s, WD_ALIGN_PARAGRAPH.CENTER, 1.5, 0, 12)
s = tambah(st, "Cover Logo"); gaya_dasar(s, 12); paragraf(s, WD_ALIGN_PARAGRAPH.CENTER, 1.0, 24, 24)
s = tambah(st, "Cover Bawah"); gaya_dasar(s, 14, tebal=True); paragraf(s, WD_ALIGN_PARAGRAPH.CENTER, 1.15, 0, 0)
s.paragraph_format.keep_with_next = True
s = tambah(st, "Tanda Tangan"); gaya_dasar(s, 12); paragraf(s, WD_ALIGN_PARAGRAPH.LEFT, 1.15, 0, 0, kiri=Cm(8))
s = tambah(st, "Judul Awal"); gaya_dasar(s, 14, tebal=True); paragraf(s, WD_ALIGN_PARAGRAPH.CENTER, 1.5, 0, 24, page_break=True)
s = tambah(st, "Kode Judul"); gaya_dasar(s, 12); paragraf(s, WD_ALIGN_PARAGRAPH.LEFT, 1.0, 6, 4, keep_next=True)
s = tambah(st, "Pustaka"); gaya_dasar(s, 12); paragraf(s, WD_ALIGN_PARAGRAPH.LEFT, 1.0, 0, 12, gantung=Cm(1.25))
ref.save(os.path.join(DIR, "ref_laporan.docx"))

# ------------------------------------------------------------------ pandoc
mentah = os.path.join(DIR, "laporan_mentah.docx")
subprocess.run(["pandoc", "laporan.md", "-f", "markdown+pipe_tables+raw_attribute+fenced_divs-auto_identifiers",
                "-o", mentah, "--reference-doc=ref_laporan.docx", "--no-highlight"], cwd=DIR, check=True)

# ------------------------------------------------------------------ pascaproses
d = Document(mentah)
ROMAWI = re.compile(r"^(BAB [IVX]+) (.+)$")
for p in d.paragraphs:
    if p.style.name == "Heading 1":
        teks = "".join(r.text for r in p.runs)
        m = ROMAWI.match(teks)
        if m:
            for r in p.runs[1:]:
                r._r.getparent().remove(r._r)
            p.runs[0].text = m.group(1)
            p.runs[0].add_break(WD_BREAK.LINE)
            p.add_run(m.group(2))
    if p.style.name == "Cover Bawah" and not getattr(d, "_bawah_diatur", False):
        p.paragraph_format.space_before = Pt(80); d._bawah_diatur = True
    if p.style.name == "Source Code":
        p.paragraph_format.keep_together = True
        for r in p.runs:
            r.font.size = Pt(9)
    elif p.style.name != "Kode Judul":
        for r in p.runs:
            if r.style is not None and r.style.name == "Verbatim Char":
                r.font.size = Pt(11)
    if p.style.name in ("Cover Logo",):
        p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER

# Tabel: garis hitam, kepala tebal, sel spasi tunggal 11 pt
for t in d.tables:
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    tblPr = t._tbl.tblPr
    for old in tblPr.findall(qn('w:tblBorders')):
        tblPr.remove(old)
    b = OxmlElement('w:tblBorders')
    for sisi in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        e = OxmlElement(f'w:{sisi}'); e.set(qn('w:val'), 'single'); e.set(qn('w:sz'), '4'); e.set(qn('w:color'), '000000'); b.append(e)
    tblPr.append(b)
    for i, row in enumerate(t.rows):
        for c in row.cells:
            tcPr = c._tc.get_or_add_tcPr()
            for sh in tcPr.findall(qn('w:shd')):
                tcPr.remove(sh)
            for p in c.paragraphs:
                pf = p.paragraph_format
                pf.line_spacing = 1.0; pf.space_after = Pt(0); pf.space_before = Pt(0); pf.first_line_indent = Cm(0)
                if p.alignment is None or p.alignment == WD_ALIGN_PARAGRAPH.JUSTIFY:
                    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
                for r in p.runs:
                    r.font.size = Pt(11)
                    if i == 0:
                        r.font.bold = True

LEBAR_TEKS = Cm(14)
CM_PER_KAR = 0.24  # perkiraan lebar rata-rata satu karakter TNR 11 pt


def atur_lebar(t):
    ncol = len(t.columns)
    teks = [[c.text for c in row.cells] for row in t.rows]
    minimal, bobot = [], []
    for j in range(ncol):
        kol = [r[j] for r in teks if j < len(r)]
        kata = min(max((len(w) for x in kol for w in x.split()), default=2), 20)
        minimal.append(max(1.1, kata * CM_PER_KAR + 0.55))
        bobot.append(max(min(max((len(x) for x in kol), default=1), 90), 1))
    total = LEBAR_TEKS.cm
    sisa = total - sum(minimal)
    if sisa < 0:
        lebar = [m * total / sum(minimal) for m in minimal]
    else:
        tambahan = [max(b - m / CM_PER_KAR, 0) for b, m in zip(bobot, minimal)]
        tt = sum(tambahan) or 1
        lebar = [m + sisa * a / tt for m, a in zip(minimal, tambahan)]
    tblPr = t._tbl.tblPr
    for tag in ('w:tblW', 'w:tblLayout'):
        for e in tblPr.findall(qn(tag)):
            tblPr.remove(e)
    w = OxmlElement('w:tblW'); w.set(qn('w:w'), str(int(Cm(sum(lebar)).twips))); w.set(qn('w:type'), 'dxa'); tblPr.append(w)
    lay = OxmlElement('w:tblLayout'); lay.set(qn('w:type'), 'fixed'); tblPr.append(lay)
    grid = t._tbl.tblGrid
    for j, g in enumerate(grid.findall(qn('w:gridCol'))):
        g.set(qn('w:w'), str(int(Cm(lebar[j]).twips)))
    for i, row in enumerate(t.rows):
        trPr = row._tr.get_or_add_trPr()
        cs = OxmlElement('w:cantSplit'); trPr.append(cs)
        if i == 0:
            h = OxmlElement('w:tblHeader'); trPr.append(h)
        for j, c in enumerate(row.cells):
            c.width = Cm(lebar[j])


for t in d.tables:
    atur_lebar(t)
    nxt = t._tbl.getnext()
    if nxt is not None and nxt.tag == qn('w:p'):
        from docx.text.paragraph import Paragraph
        Paragraph(nxt, d._body).paragraph_format.space_before = Pt(12)

# Hapus warna langsung pada run
for rpr in d.element.body.iter(qn('w:rPr')):
    for tag in ('w:color', 'w:shd', 'w:highlight'):
        for e in rpr.findall(qn(tag)):
            rpr.remove(e)


def isi_footer(sec, nomor):
    sec.footer.is_linked_to_previous = False
    ft = sec.footer
    for p in ft.paragraphs:
        for r in list(p.runs):
            r._r.getparent().remove(r._r)
    if not nomor:
        return
    p = ft.paragraphs[0]; p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run()
    for tag, teks in (('begin', None), (None, ' PAGE '), ('end', None)):
        if tag:
            f = OxmlElement('w:fldChar'); f.set(qn('w:fldCharType'), tag); r._r.append(f)
        else:
            it = OxmlElement('w:instrText'); it.set(qn('xml:space'), 'preserve'); it.text = teks; r._r.append(it)


secs = d.sections
print("jumlah section:", len(secs))
for i, sec in enumerate(secs):
    sec.page_height, sec.page_width = Cm(29.7), Cm(21.0)
    sec.left_margin, sec.right_margin, sec.top_margin, sec.bottom_margin = Cm(4), Cm(3), Cm(3), Cm(3)
    sec.footer_distance = Cm(1.5)
    isi_footer(sec, i > 0)
# halaman isi mulai dari 1 (angka arab)
akhir = secs[-1]._sectPr
for old in akhir.findall(qn('w:pgNumType')):
    akhir.remove(old)
pg = OxmlElement('w:pgNumType'); pg.set(qn('w:fmt'), 'decimal'); pg.set(qn('w:start'), '1')
akhir.find(qn('w:pgMar')).addnext(pg)
d.save(OUT)
print("disimpan", OUT)
