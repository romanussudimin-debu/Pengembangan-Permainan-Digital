"""Generator audio prosedural (gong, gendang, SFX) untuk "Lingko: Jejak Anak Wae Rebo".
Semua suara disintesis sendiri (tanpa rekaman pihak ketiga).
Jalankan: python3 tools/generate_audio.py  (output ke src/assets/audio)
"""
import os, wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "src", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(3)


def simpan(nama, x, gain=0.9):
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) or 1.0
    x = np.clip(x / peak * gain, -1, 1)
    with wave.open(os.path.join(OUT, nama), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def t(d):
    return np.arange(int(SR * d)) / SR


def gong(f=110.0, d=2.5):
    tt = t(d)
    partials = [(1.0, 1.0), (2.01, .45), (2.76, .3), (4.1, .15), (5.4, .08)]
    x = sum(a * np.sin(2 * np.pi * f * r * tt) * np.exp(-tt * (1.2 + r * .6)) for r, a in partials)
    x *= 1 + .15 * np.sin(2 * np.pi * 3 * tt)  # dengung khas gong
    return x * np.minimum(1, tt * 200)


def gendang(f=90.0, d=.35, tajam=False):
    tt = t(d)
    pitch = f * (1 + .8 * np.exp(-tt * 30))
    body = np.sin(2 * np.pi * np.cumsum(pitch) / SR) * np.exp(-tt * (14 if not tajam else 22))
    slap = rng.standard_normal(len(tt)) * np.exp(-tt * (60 if tajam else 90)) * (.7 if tajam else .3)
    return body + slap


def lonceng(f, d=.6):
    tt = t(d)
    return (np.sin(2 * np.pi * f * tt) + .3 * np.sin(2 * np.pi * f * 2 * tt)) * np.exp(-tt * 6)


# --- SFX ---
tt = t(.25)
cambuk = rng.standard_normal(len(tt)) * np.exp(-((tt - .08) ** 2) / .0004)
cambuk += .5 * np.sin(2 * np.pi * 1800 * tt) * np.exp(-((tt - .08) ** 2) / .0002)
simpan("cambuk.wav", cambuk)
simpan("perisai.wav", gendang(70, .4, tajam=True) + .4 * gong(220, .4))
simpan("terkena.wav", gendang(60, .3, tajam=True))
tt = t(.18)
simpan("lompat.wav", np.sin(2 * np.pi * np.cumsum(300 + 900 * tt) / SR) * np.exp(-tt * 12), .6)
tt = t(.08)
simpan("langkah.wav", rng.standard_normal(len(tt)) * np.exp(-tt * 70), .35)
simpan("ambil.wav", np.concatenate([lonceng(660, .12), lonceng(880, .12), lonceng(1320, .35)]), .7)
simpan("berhasil.wav", np.concatenate([lonceng(523, .15), lonceng(659, .15), lonceng(784, .15)]) .tolist() + list(gong(131, 1.5) * .6), .8)
simpan("gagal.wav", np.concatenate([lonceng(330, .2), lonceng(262, .5)]), .6)
simpan("klik.wav", lonceng(1000, .07), .4)
simpan("gong.wav", gong(98, 3.0))

# --- Musik: pola gong-gendang berulang (loop) ---
def musik(bpm, pola_gendang, pola_gong, nada, bar=8, ketuk=8):
    step = 60 / bpm / 2
    total = int(SR * step * ketuk * bar)
    x = np.zeros(total + SR * 3)
    for b in range(bar):
        for k in range(ketuk):
            pos = int(((b * ketuk) + k) * step * SR)
            g = pola_gendang[k % len(pola_gendang)]
            if g:
                s = gendang(85 if g == 1 else 120, .3, tajam=(g == 2)) * (.6 if g == 1 else .4)
                x[pos:pos + len(s)] += s
            if pola_gong[k % len(pola_gong)]:
                s = gong(nada[b % len(nada)], 2.0) * .55
                x[pos:pos + len(s)] += s
            if k % 2 == 0:
                f = nada[(b + k // 2) % len(nada)] * 4
                s = lonceng(f, .25) * .12
                x[pos:pos + len(s)] += s
    # lipat ekor ke awal supaya loop mulus
    ekor = x[total:]
    x = x[:total]
    x[:len(ekor)] += ekor
    return x

# skala pentatonik
simpan("musik_kampung.wav", musik(84, [1, 0, 2, 0, 1, 1, 2, 0], [1, 0, 0, 0, 0, 0, 0, 0], [98, 110, 131, 147, 165, 131, 110, 98]), .7)
simpan("musik_caci.wav", musik(120, [1, 2, 1, 2, 1, 1, 2, 2], [1, 0, 0, 0, 1, 0, 0, 0], [98, 98, 110, 131]), .8)
print("audio selesai ->", os.path.abspath(OUT))
