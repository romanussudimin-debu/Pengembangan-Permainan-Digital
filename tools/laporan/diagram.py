# Membuat diagram laporan (SVG, hitam-putih) -> HTML untuk dirender Playwright.
import math, os, sys, html

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
FONT = "font-family:'Liberation Serif','Times New Roman',serif"
G = {"hitam": "#111", "abu": "#777", "muda": "#e9e9e9", "sedang": "#cfcfcf"}


def svg(w, h, isi):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" style="background:#fff;{FONT}">' \
           '<defs><marker id="p" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">' \
           '<path d="M0,0 L10,5 L0,10 z" fill="#111"/></marker></defs>' + isi + '</svg>'


def kotak(x, y, w, h, teks, isi=G["muda"], tebal=False, uk=15, rx=8):
    baris = teks.split("\n")
    t = "".join(f'<tspan x="{x + w / 2}" dy="{0 if i == 0 else uk * 1.25}">{html.escape(b)}</tspan>' for i, b in enumerate(baris))
    y0 = y + h / 2 - (len(baris) - 1) * uk * 1.25 / 2 + uk * 0.35
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{isi}" stroke="#111" stroke-width="1.5"/>'
            f'<text x="{x + w / 2}" y="{y0}" font-size="{uk}" text-anchor="middle" font-weight="{"bold" if tebal else "normal"}">{t}</text>')


def panah(x1, y1, x2, y2, label=None, dx=0, dy=-6, putus=False):
    s = f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#111" stroke-width="1.6" marker-end="url(#p)"{" stroke-dasharray=\"6 4\"" if putus else ""}/>'
    if label:
        s += f'<text x="{(x1 + x2) / 2 + dx}" y="{(y1 + y2) / 2 + dy}" font-size="13" text-anchor="middle" font-style="italic">{html.escape(label)}</text>'
    return s


def teks(x, y, t, uk=14, anchor="middle", tebal=False, miring=False):
    return f'<text x="{x}" y="{y}" font-size="{uk}" text-anchor="{anchor}" font-weight="{"bold" if tebal else "normal"}" font-style="{"italic" if miring else "normal"}">{html.escape(t)}</text>'


def simpan(nama, s):
    open(os.path.join(OUT, nama + ".html"), "w").write(f"<!doctype html><html><body style='margin:0;background:#fff'>{s}</body></html>")


# 1. Lima tingkat Mbaru Niang
w, h = 760, 430
s = ""
cx, top, base = 250, 30, 390
tingkat = [("Hekang kode", "tempat sesajian leluhur (paling sakral)"), ("Lempa rae", "cadangan pangan saat paceklik"),
           ("Lentar", "penyimpanan benih"), ("Lobo", "bahan makanan dan barang"), ("Lutur", "ruang tinggal keluarga besar")]
batas = [top, 105, 170, 235, 305, base]
for i in range(5):
    y1, y2 = batas[i], batas[i + 1]
    def lebar(y): return (y - top) / (base - top) * 190
    isi = ["#d6d6d6", "#e4e4e4", "#d6d6d6", "#e4e4e4", "#d6d6d6"][i]
    s += f'<polygon points="{cx - lebar(y1)},{y1} {cx + lebar(y1)},{y1} {cx + lebar(y2)},{y2} {cx - lebar(y2)},{y2}" fill="{isi}" stroke="#111" stroke-width="1.5"/>'
    ym = (y1 + y2) / 2
    s += f'<line x1="{cx + lebar(ym) + 6}" y1="{ym}" x2="455" y2="{ym}" stroke="#777" stroke-dasharray="4 3"/>'
    s += teks(465, ym - 2, f"{5 - i}. {tingkat[i][0]}", 16, "start", True) + teks(465, ym + 17, tingkat[i][1], 14, "start")
s += f'<rect x="{cx - 22}" y="{base - 42}" width="44" height="42" fill="#fff" stroke="#111"/>' + teks(cx, base + 26, "pintu", 13, miring=True)
simpan("g_mbaru_niang", svg(w, h, s))

# 2. Core loop
w, h = 800, 360
s = kotak(270, 20, 220, 60, "Temui warga yang\nditunjuk petunjuk", tebal=True)
s += kotak(520, 140, 220, 70, "Tantangan:\nteka-teki / tenun / tabuh", tebal=True)
s += kotak(270, 270, 220, 60, "Kartu budaya\n(dibacakan)", G["sedang"], True)
s += kotak(20, 140, 220, 70, "Petunjuk teka-teki\nke warga berikutnya", tebal=True)
s += panah(490, 60, 600, 138, "mulai tantangan", 50, -4)
s += panah(600, 212, 492, 290, "berhasil", 52, 14)
s += panah(268, 300, 150, 212, "", 0)
s += panah(150, 138, 268, 52, "jelajahi kampung", -55, -4)
s += f'<path d="M742,160 C800,140 800,215 742,195" fill="none" stroke="#111" stroke-width="1.4" stroke-dasharray="6 4" marker-end="url(#p)"/>'
s += teks(700, 240, "salah/gagal:", 13, miring=True) + teks(700, 256, "baca kartu, ulangi", 13, miring=True)
s += teks(380, 190, "9 langkah, 8 warga", 15, tebal=True) + teks(380, 210, "→ setelah kartu ke-9: Penti", 14, miring=True)
simpan("g_core_loop", svg(w, h, s))

# 3. Peta kampung
w, h = 800, 640
sk = 11.5
ox, oy = 350, 300
def P(x, z): return ox + x * sk, oy + z * sk
s = f'<circle cx="{ox}" cy="{oy}" r="{15 * sk}" fill="none" stroke="#999" stroke-dasharray="5 5"/>'
sudut = [-90, -130, -170, 150, 110, -50, 40]
ket = {0: "Mbaru gendang\n(Ema Agus #3, di dalam)", 5: "jemuran songke\n(Ende Lono #4, di dalam)", 3: "kayu bakar\n(Ema Yakobus #8, di dalam)"}
for i, a in enumerate(sudut):
    x, y = P(math.cos(math.radians(a)) * 15, math.sin(math.radians(a)) * 15)
    r = 30 if i == 0 else 24
    s += f'<circle cx="{x}" cy="{y}" r="{r}" fill="{"#bdbdbd" if i in ket else "#e2e2e2"}" stroke="#111" stroke-width="1.5"/>'
    s += teks(x, y + 5, "MN" if i else "MG", 13, tebal=True)
    if i in ket:
        lx, ly = (x, y - r - 26) if i == 0 else ((x + 40, y - 8) if i == 5 else (x - 40, y + 2))
        anchor = "middle" if i == 0 else ("start" if i == 5 else "end")
        for j, b in enumerate(ket[i].split("\n")):
            s += teks(lx, ly + j * 15, b, 13, anchor, j == 0)
cx_, cy_ = P(0, 0)
s += f'<rect x="{cx_ - 20}" y="{cy_ - 20}" width="40" height="40" fill="#fff" stroke="#111" stroke-width="2"/>' + teks(cx_, cy_ + 5, "C", 15, tebal=True)
s += teks(cx_, cy_ + 38, "compang (hanya dilihat)", 12, miring=True)
def titik(x, z, label, anchor="start", dx=10, isi="#111"):
    px, py = P(x, z)
    return f'<circle cx="{px}" cy="{py}" r="6" fill="{isi}"/>' + teks(px + dx, py + 5, label, 13, anchor)
s += titik(0, 5.8, "Tu'a Golo #1, #9")
s += titik(-8, 0.5, "Ine Wela #2 + alat tenun", "end", -10)
s += titik(-5, -4, "gong-gendang", "start", 10, "#777")
fx = [(-7.2, -4.6), (-3.5, -10), (-1, -6.5)]
s += f'<polyline points="{" ".join(f"{P(*p)[0]},{P(*p)[1]}" for p in fx + [fx[0]])}" fill="none" stroke="#111" stroke-dasharray="3 3"/>'
s += teks(P(-1, -6.5)[0] + 10, P(-1, -6.5)[1] + 4, "Fransi #5 (berkeliling)", 13, "start")
ax, ay = P(26, 0)
s += f'<circle cx="{ax}" cy="{ay}" r="{5 * sk}" fill="#f2f2f2" stroke="#111" stroke-width="1.5"/>' + teks(ax, ay + 5, "ARENA", 14, tebal=True)
s += f'<line x1="{P(23, -4)[0]}" y1="{P(23, -4)[1]}" x2="{P(22, 5)[0]}" y2="{P(22, 5)[1]}" stroke="#111" stroke-width="1.5" marker-start="url(#p)" marker-end="url(#p)"/>'
s += teks(ax, ay + 5 * sk + 22, "Hingha #6 ⇄ Marngem #7", 13, tebal=True) + teks(ax, ay + 5 * sk + 38, "(bertukar tempat)", 13, miring=True)
sx, sy = P(0, 22)
s += f'<polygon points="{sx},{sy - 9} {sx + 9},{sy + 7} {sx - 9},{sy + 7}" fill="#111"/>' + teks(sx, sy + 26, "titik muncul pemain", 13)
for k, (x, z) in enumerate([(-9, 19), (-11.8, 17.2), (-14.2, 15)]):
    px, py = P(x, z)
    s += f'<rect x="{px - 8}" y="{py - 8}" width="16" height="16" fill="#999" stroke="#111"/>'
s += teks(P(-12, 20.5)[0] - 10, P(-12, 20.5)[1] + 18, "batu pijakan", 13)
s += teks(740, 40, "U", 18, tebal=True) + panah(740, 80, 740, 48)
s += teks(600, 560, "MG = mbaru gendang", 13, "start") + teks(600, 578, "MN = mbaru gena (6 rumah)", 13, "start")
s += teks(600, 596, "#n = urutan kartu", 13, "start") + teks(600, 614, "semua rumah dapat dimasuki", 13, "start")
simpan("g_peta", svg(w, h, s))

# 4. GameState
w, h = 760, 380
pos = {"MENU": (30, 160), "BERMAIN": (290, 160), "DIALOG": (290, 20), "JEDA": (560, 300), "MINIGAME": (560, 20), "SELESAI": (290, 300)}
for n, (x, y) in pos.items():
    s_ = kotak(x, y, 170, 56, n, G["sedang"] if n == "BERMAIN" else G["muda"], True, 16)
    s = s_ if n == "MENU" else s + s_
s += panah(200, 188, 288, 188, "mulai", 0, -8)
s += panah(360, 158, 360, 78) + panah(390, 78, 390, 158)
s += panah(460, 175, 560, 70) + panah(575, 78, 470, 168)
s += panah(460, 205, 560, 310) + panah(570, 300, 470, 214)
s += panah(375, 218, 375, 298)
s += panah(460, 48, 558, 48, "tantangan", 0, -8)
s += panah(645, 78, 645, 298, "jeda", 22, 0)
s += panah(290, 328, 115, 218, "kembali ke menu", -70, 20)
s += teks(380, 368, "Transisi lain ditolak oleh TRANSISI_SAH (mis. jeda saat dialog)", 13, miring=True)
simpan("g_gamestate", svg(w, h, s))

# 5. FSM pemain
w, h = 760, 300
pos = {"Idle": (40, 110), "Jalan": (300, 20), "Lompat": (560, 110), "Jatuh": (300, 200), "Interaksi": (40, 230)}
s = ""
for n, (x, y) in pos.items():
    s += kotak(x, y, 150, 50, n, G["sedang"] if n == "Idle" else G["muda"], True, 16)
s += panah(190, 125, 298, 52, "ada input", -20, -4) + panah(298, 62, 192, 140, "", 0)
s += panah(450, 45, 600, 108, "lompat", 25, -6) + panah(190, 132, 558, 132, "lompat", 120, -6)
s += panah(635, 160, 452, 218, "turun (vy < 0)", 70, 12)
s += panah(298, 230, 192, 148, "mendarat", -40, 18)
s += panah(115, 160, 115, 228, "DIALOG", 34, 0) + panah(95, 228, 95, 162)
s += teks(560, 255, "coyote time 0,12 dtk", 13, "start", miring=True) + teks(560, 273, "jump buffer 0,12 dtk", 13, "start", miring=True)
simpan("g_fsm_pemain", svg(w, h, s))

# 6. Rancangan tampilan mini-game
w, h = 760, 330
s = f'<rect x="10" y="10" width="360" height="310" rx="10" fill="#f4f4f4" stroke="#111"/>' + teks(190, 40, "Menenun Songke", 17, tebal=True)
abu = ["#222", "#bbb", "#777", "#fff"]
for gy in range(5):
    for gx in range(5):
        d = abs(gx - 2) + abs(gy - 2)
        c = 3 if d == 0 else 2 if d == 1 else 1 if d == 2 else 0
        s += f'<rect x="{40 + gx * 30}" y="{80 + gy * 30}" width="28" height="28" fill="{abu[c]}" stroke="#111"/>'
        s += f'<rect x="{215 + gx * 26}" y="{86 + gy * 26}" width="24" height="24" fill="{"#222" if (gx + gy) % 3 else "#bbb"}" stroke="#111"/>'
s += teks(115, 70, "contoh motif", 13, miring=True) + teks(280, 78, "kain pemain", 13, miring=True)
s += f'<rect x="{213 + 2 * 26}" y="{84 + 2 * 26}" width="28" height="28" fill="none" stroke="#111" stroke-width="3"/>'
s += teks(190, 260, "Pilih kotak (WASD/klik/ketuk), ganti benang", 13) + teks(190, 278, "(E/Spasi/1–4/palet) sampai kain sama", 13)
s += teks(190, 300, "dengan contoh belah ketupat", 13)
s += f'<rect x="390" y="10" width="360" height="310" rx="10" fill="#f4f4f4" stroke="#111"/>' + teks(570, 40, "Tabuh Gong & Gendang", 17, tebal=True)
for j, (nama, ny, notes) in enumerate([("GONG", 120, [520, 600, 690]), ("GENDANG", 190, [560, 640, 670, 720])]):
    s += teks(405, ny + 5, nama, 12, "start", True) + f'<line x1="470" y1="{ny}" x2="735" y2="{ny}" stroke="#777" stroke-width="2"/>'
    for nx in notes:
        s += f'<circle cx="{nx}" cy="{ny}" r="10" fill="{"#111" if j == 0 else "#888"}"/>'
s += f'<line x1="490" y1="90" x2="490" y2="220" stroke="#111" stroke-width="3"/>' + teks(490, 238, "garis tabuh", 12, miring=True)
s += panah(720, 150, 640, 150, "ketukan bergerak", 0, -6)
s += teks(570, 270, "Tekan J/K atau tombol GONG/GENDANG", 13) + teks(570, 288, "saat ketukan di garis (±0,2 dtk);", 13) + teks(570, 306, "lulus bila ≥ 60% tepat", 13)
simpan("g_minigame", svg(w, h, s))

# 7. Arsitektur
w, h = 760, 420
s = teks(380, 24, "Proyek Godot 4 (src/)", 16, tebal=True)
lapis = [("Autoload (global)", ["Kontrol", "Game\nState", "Dialog\nManager", "Audio\nManager", "Transisi", "Menu\nJeda", "Kontrol\nSentuh"]),
         ("Scene", ["main_menu", "kampung", "ending", "pemain", "penampil_caci"]),
         ("Skrip & FSM", ["StateMachine", "Pemain + 5 state", "NpcKampung", "PenampilCaci + 5 state", "TenunSongke", "TabuhGong"]),
         ("Data & Aset", ["rantai_teka_\nteki.json", "kartu_\nbudaya.json", "dialog.json", "12 tekstur", "15 audio"])]
for i, (judul, isi) in enumerate(lapis):
    y = 45 + i * 92
    s += kotak(10, y, 150, 74, judul, G["sedang"], True, 15)
    lebar = (580 - (len(isi) - 1) * 8) / len(isi)
    for j, b in enumerate(isi):
        s += kotak(170 + j * (lebar + 8), y, lebar, 74, b.replace(" + ", "\n+ ").replace("_", "_​"), G["muda"], False, 12 if len(isi) > 5 else 13)
simpan("g_arsitektur", svg(w, h, s))

# 8. Alur build & publikasi
w, h = 760, 170
langkah = ["Push kode\nke GitHub", "GitHub Actions\n(Godot 4.7.2)", "Impor aset &\nekspor Web", "Cabang\ngh-pages", "Browser\nlaptop / HP"]
s = ""
for i, l in enumerate(langkah):
    x = 10 + i * 152
    s += kotak(x, 50, 128, 70, l, G["sedang"] if i in (0, 4) else G["muda"], True, 14)
    if i < 4:
        s += panah(x + 130, 85, x + 150, 85)
s += teks(380, 155, "Otomatis setiap ada perubahan di folder src/", 13, miring=True)
simpan("g_build", svg(w, h, s))
print("ok")
