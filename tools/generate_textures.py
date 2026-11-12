"""Generator tekstur untuk versi 3D "Lingko: Jejak Anak Wae Rebo".
Semua tekstur dibuat sendiri secara prosedural (tanpa aset pihak ketiga).
Jalankan: python3 tools/generate_textures.py  (output ke src/assets/textures)
"""
import os, random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "assets", "textures")
os.makedirs(OUT, exist_ok=True)
random.seed(11)

HITAM = (27, 24, 24)
MERAH = (176, 42, 42)
KUNING = (232, 180, 48)
HIJAU = (46, 125, 70)
BIRU = (44, 92, 150)
PUTIH = (232, 226, 210)
ORANYE = (214, 110, 40)


def songke(nama, motif):
    """Kain songke: dasar hitam, pita motif belah ketupat berwarna (tileable 64x64)."""
    s = 64
    img = Image.new("RGB", (s, s), HITAM)
    d = ImageDraw.Draw(img)
    for band, y0 in enumerate((6, 26, 46)):
        c = motif[band % len(motif)]
        d.line([0, y0, s, y0], fill=c)
        d.line([0, y0 + 11, s, y0 + 11], fill=c)
        for x in range(0, s, 8):  # belah ketupat
            c2 = motif[(band + 1) % len(motif)]
            d.polygon([(x + 4, y0 + 2), (x + 7, y0 + 5), (x + 4, y0 + 9), (x + 1, y0 + 5)], outline=c2)
            d.point((x + 4, y0 + 5), fill=motif[(band + 2) % len(motif)])
    img.save(os.path.join(OUT, f"{nama}.png"))


songke("songke_merah", [MERAH, KUNING, HIJAU])
songke("songke_biru", [BIRU, KUNING, MERAH])
songke("songke_kuning", [KUNING, MERAH, HIJAU])
songke("songke_hijau", [HIJAU, KUNING, ORANYE])


def noise_tex(nama, base, var, s=64, garis=None):
    img = Image.new("RGB", (s, s), base)
    px = img.load()
    for y in range(s):
        for x in range(s):
            v = random.randint(-var, var)
            px[x, y] = tuple(max(0, min(255, c + v)) for c in base)
    if garis:
        d = ImageDraw.Draw(img)
        garis(d, s)
    img.save(os.path.join(OUT, f"{nama}.png"))


def ijuk_garis(d, s):  # serat ijuk vertikal pada atap mbaru niang
    for _ in range(140):
        x = random.randint(0, s - 1); y = random.randint(0, s - 1)
        d.line([x, y, x, y + random.randint(4, 12)], fill=(38, 30, 26))


def kayu_garis(d, s):
    for y in range(0, s, 6):
        d.line([0, y, s, y + random.randint(-1, 1)], fill=(86, 56, 34))


def batu_garis(d, s):
    for _ in range(18):
        x = random.randint(0, s - 1); y = random.randint(0, s - 1); r = random.randint(4, 9)
        d.ellipse([x - r, y - r, x + r, y + r], outline=(92, 88, 82))


noise_tex("ijuk", (64, 52, 44), 10, garis=ijuk_garis)
noise_tex("rumput", (78, 140, 62), 14)
noise_tex("tanah", (120, 84, 56), 12)
noise_tex("batu", (128, 124, 116), 14, garis=batu_garis)
noise_tex("kayu", (122, 82, 50), 8, garis=kayu_garis)
noise_tex("kulit_kerbau", (158, 116, 66), 10)
noise_tex("sawah", (88, 158, 70), 12)


def bingkai():
    """Bingkai UI bermotif songke (NinePatchRect, margin 8)."""
    s = 48
    img = Image.new("RGBA", (s, s), (20, 18, 18, 235))
    d = ImageDraw.Draw(img)
    motif = [MERAH, KUNING, HIJAU, BIRU]
    for i in range(s):
        c = motif[(i // 4) % 4]
        for b in (1, 2, s - 3, s - 2):
            d.point((i, b), fill=c)
            d.point((b, i), fill=c)
    for i in range(4, s - 4, 6):
        for b in (5, s - 6):
            d.point((i, b), fill=KUNING)
            d.point((b, i), fill=KUNING)
    d.rectangle([0, 0, s - 1, s - 1], outline=HITAM)
    img.save(os.path.join(OUT, "bingkai_songke.png"))


bingkai()
print("tekstur selesai ->", os.path.abspath(OUT))
