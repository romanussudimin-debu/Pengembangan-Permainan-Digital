"""Generator ikon aplikasi "Jejak Penti" (PWA/web, Android, jendela desktop).
Dibuat sendiri secara prosedural: Mbaru Niang di atas latar songke hitam bermotif belah ketupat.
Jalankan: python3 tools/generate_ikon.py  (output ke src/assets/ikon)
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "assets", "ikon")
os.makedirs(OUT, exist_ok=True)

HITAM = (27, 24, 24)
MERAH = (176, 42, 42)
KUNING = (232, 180, 48)
HIJAU = (46, 125, 70)
BIRU = (44, 92, 150)
IJUK = (92, 70, 48)
IJUK_GELAP = (64, 48, 34)


def ikon(s=512):
    img = Image.new("RGB", (s, s), HITAM)
    d = ImageDraw.Draw(img)
    u = s / 512.0
    # Pita songke atas & bawah (garis + belah ketupat)
    for y0 in (28, 446):
        y0 = int(y0 * u)
        d.rectangle([0, y0, s, y0 + int(6 * u)], fill=MERAH)
        d.rectangle([0, y0 + int(32 * u), s, y0 + int(38 * u)], fill=MERAH)
        for i, x in enumerate(range(0, s, int(32 * u))):
            c = (KUNING, HIJAU, BIRU)[i % 3]
            cx, cy, r = x + 16 * u, y0 + 19 * u, 11 * u
            d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], outline=c, width=max(1, int(3 * u)))
    # Matahari senja di belakang rumah
    d.ellipse([s * 0.56, s * 0.2, s * 0.86, s * 0.5], fill=(214, 110, 40))
    # Mbaru Niang (kerucut ijuk) dengan garis tingkat dan pintu
    puncak, kiri, kanan, dasar = (s * 0.5, s * 0.15), s * 0.18, s * 0.82, s * 0.78
    d.polygon([puncak, (kanan, dasar), (kiri, dasar)], fill=IJUK)
    for k in range(1, 5):
        t = k / 5.0
        y = puncak[1] + (dasar - puncak[1]) * t
        lebar = (kanan - kiri) / 2 * t
        d.line([(s * 0.5 - lebar, y), (s * 0.5 + lebar, y)], fill=IJUK_GELAP, width=max(2, int(7 * u)))
    d.rectangle([s * 0.46, s * 0.66, s * 0.54, s * 0.78], fill=HITAM)
    d.line([(s * 0.5, s * 0.15), (s * 0.5, s * 0.09)], fill=KUNING, width=max(2, int(8 * u)))
    # Tanah/compang
    d.rectangle([0, int(dasar), s, int(s * 0.86)], fill=(60, 110, 60))
    return img


besar = ikon(512)
besar.save(os.path.join(OUT, "ikon_512.png"))
for ukuran in (144, 180, 192):
    besar.resize((ukuran, ukuran), Image.LANCZOS).save(os.path.join(OUT, "ikon_%d.png" % ukuran))
print("ikon dibuat di", OUT)
