"""Generator audio placeholder bernuansa gamelan untuk Wirabraja (Fase 2).

Semua suara DISINTESIS dari nol dengan numpy (tanpa sampel pihak ketiga):
  - Instrumen gamelan disederhanakan: saron, peking, demung, bonang, kenong,
    kempul, gong ageng (dengan efek "ombak", yaitu denyut akibat dua nada yang
    sedikit berbeda), dan kendang.
  - Laras: slendro yang didekati dengan 5 nada berjarak sama (~240 sen).
  - Pola balungan adalah ciptaan sendiri bernuansa lancaran/sampak,
    BUKAN transkripsi gending tradisional tertentu.

Pemakaian (dari folder proyek):
    pip install numpy        (ffmpeg diperlukan untuk menulis .ogg)
    python tools/buat_audio.py

Keluaran: audio/musik/*.ogg dan audio/sfx/*.wav. File-file ini adalah placeholder;
cukup timpa dengan rekaman gamelan asli bernama sama untuk menggantinya.
"""
from __future__ import annotations

import subprocess
import wave
from pathlib import Path

import numpy as np

SR = 44100
AKAR = Path(__file__).resolve().parent.parent
RNG = np.random.default_rng(1745)  # benih tetap agar hasil selalu sama

# ------------------------------------------------------------------ laras slendro

DASAR_SARON = 520.0  # nada 1 (ji) saron barung, Hz (perkiraan)
DERAJAT = {1: 0, 2: 1, 3: 2, 5: 3, 6: 4}


def frek(nada: int, oktaf: int = 0, dasar: float = DASAR_SARON) -> float:
    langkah = DERAJAT[nada] + 5 * oktaf
    return dasar * 2 ** (langkah * 240 / 1200)


# ------------------------------------------------------------------ utilitas sinyal

def t_arr(durasi: float) -> np.ndarray:
    return np.arange(int(durasi * SR)) / SR


def amplop(n: int, serang: float, peluruhan: float) -> np.ndarray:
    t = np.arange(n) / SR
    e = np.exp(-t / max(peluruhan, 1e-4))
    a = int(serang * SR)
    if a > 0:
        e[:a] *= np.linspace(0, 1, a)
    return e


def derau(durasi: float) -> np.ndarray:
    return RNG.uniform(-1, 1, int(durasi * SR))


def saring(x: np.ndarray, rendah: float | None = None, tinggi: float | None = None) -> np.ndarray:
    """Filter sederhana berbasis FFT. rendah = batas bawah (high-pass), tinggi = batas atas (low-pass)."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    m = np.ones_like(f)
    if rendah:
        m *= 1 / (1 + (rendah / np.maximum(f, 1)) ** 4)
    if tinggi:
        m *= 1 / (1 + (f / tinggi) ** 4)
    return np.fft.irfft(X * m, len(x))


def normal(x: np.ndarray, puncak: float = 0.9) -> np.ndarray:
    m = np.max(np.abs(x))
    return x * (puncak / m) if m > 0 else x


def gema(x: np.ndarray, campur: float = 0.25) -> np.ndarray:
    """Gema ruang sederhana (beberapa pantulan tertunda) seperti di pendopo."""
    y = x.copy()
    for tunda, g in ((0.031, 0.5), (0.047, 0.4), (0.071, 0.33), (0.113, 0.25), (0.167, 0.18), (0.241, 0.12)):
        d = int(tunda * SR)
        y[d:] += x[:-d] * g * campur * 2
    return y


def tambah(kanvas: np.ndarray, suara: np.ndarray, mulai: float, gain: float = 1.0) -> None:
    i = int(mulai * SR)
    if i >= len(kanvas):
        return
    j = min(len(kanvas), i + len(suara))
    kanvas[i:j] += suara[: j - i] * gain


# ------------------------------------------------------------------ instrumen

def bilah(f: float, durasi: float = 1.6, keras: float = 1.0, lembut: bool = False) -> np.ndarray:
    """Bilah logam (saron/demung/peking/gender): parsial tak harmonis + ombak."""
    t = t_arr(durasi)
    y = np.zeros_like(t)
    for rasio, amp, luruh in ((1.0, 1.0, 0.9), (2.76, 0.32, 0.35), (5.4, 0.12, 0.12), (8.9, 0.05, 0.05)):
        for geser in (0.0, 2.2):  # dua bilah sedikit berbeda -> ombak
            y += amp * np.sin(2 * np.pi * (f * rasio + geser) * t) * np.exp(-t / (luruh * durasi))
    serang = 0.012 if lembut else 0.002
    y *= amplop(len(t), serang, durasi * 2)
    if not lembut:  # bunyi pukulan tabuh
        klik = saring(derau(0.015), rendah=2000) * amplop(int(0.015 * SR), 0.0, 0.004)
        y[: len(klik)] += klik * 0.4 * keras
    return y * keras


def pencon(f: float, durasi: float, luruh: float, keras: float = 1.0) -> np.ndarray:
    """Gong berpencu (bonang/kenong/kempul): parsial mendekati harmonis + sedikit naik-turun nada."""
    t = t_arr(durasi)
    goyang = 1 + 0.002 * np.sin(2 * np.pi * 1.5 * t)
    y = (np.sin(2 * np.pi * f * goyang * t)
         + 0.35 * np.sin(2 * np.pi * f * 2.02 * t) * np.exp(-t / (luruh * 0.4))
         + 0.15 * np.sin(2 * np.pi * f * 3.01 * t) * np.exp(-t / (luruh * 0.25)))
    y *= amplop(len(t), 0.006, luruh)
    return y * keras


def gong_ageng(f: float = 52.0, durasi: float = 6.0, keras: float = 1.0) -> np.ndarray:
    t = t_arr(durasi)
    ombak = 1 + 0.35 * np.sin(2 * np.pi * 2.6 * t)  # denyut khas gong ageng
    y = (np.sin(2 * np.pi * f * t) * ombak
         + 0.5 * np.sin(2 * np.pi * (f * 2.0 + 1.3) * t) * np.exp(-t / 2.5)
         + 0.25 * np.sin(2 * np.pi * f * 2.93 * t) * np.exp(-t / 1.2)
         + 0.12 * np.sin(2 * np.pi * f * 4.1 * t) * np.exp(-t / 0.6))
    y *= amplop(len(t), 0.03, durasi * 0.45)
    return y * keras


def kendang(jenis: str, keras: float = 1.0) -> np.ndarray:
    if jenis == "dhe":  # bunyi rendah (dhah/dhe)
        t = t_arr(0.4)
        f = 75 + 70 * np.exp(-t / 0.03)
        y = np.sin(2 * np.pi * np.cumsum(f) / SR) * amplop(len(t), 0.001, 0.12)
        y += saring(derau(0.4), tinggi=600) * amplop(len(t), 0.0, 0.02) * 0.4
    elif jenis == "tak":  # bunyi kering tinggi (tak/ket)
        t = t_arr(0.12)
        y = saring(derau(0.12), rendah=1500, tinggi=5000) * amplop(len(t), 0.0, 0.025)
        y += np.sin(2 * np.pi * 420 * t) * amplop(len(t), 0.0, 0.03) * 0.6
    else:  # "tung" bunyi menggema sedang
        t = t_arr(0.3)
        f = 180 + 40 * np.exp(-t / 0.02)
        y = np.sin(2 * np.pi * np.cumsum(f) / SR) * amplop(len(t), 0.001, 0.09)
    return y * keras


# ------------------------------------------------------------------ komposisi musik

def bunyikan_gending(balungan: list[list[int]], bpm: float, gaya: str) -> np.ndarray:
    """balungan: daftar gongan, tiap gongan berisi nada per ketukan.
    Nada negatif = oktaf atas (mis. -1 = 1 tinggi). 0 = kosong (pin)."""
    ketukan = 60.0 / bpm
    nada_rata = [n for g in balungan for n in g]
    panjang = len(nada_rata) * ketukan
    ekor = 6.0
    kanvas = np.zeros(int((panjang + ekor) * SR))
    per_gongan = len(balungan[0])

    def f_dari(n: int, okt: int = 0) -> float:
        return frek(abs(n), okt + (1 if n < 0 else 0))

    for i, n in enumerate(nada_rata):
        t0 = i * ketukan
        pos = i % per_gongan + 1  # 1..16
        if gaya == "narasi":
            if n:
                tambah(kanvas, bilah(f_dari(n, -1), 3.5, 0.5, lembut=True), t0, 0.5)
                tambah(kanvas, bilah(f_dari(n, 0), 3.0, 0.3, lembut=True), t0 + ketukan * 0.5, 0.35)
            if pos % 4 == 0:
                tambah(kanvas, pencon(frek(abs(n) or 5, -1, 260), 3.0, 1.6), t0, 0.35)
            if pos == per_gongan:
                tambah(kanvas, gong_ageng(50, 7.0), t0, 0.9)
            continue

        # Saron (balungan) dan demung oktaf bawah.
        if n:
            tambah(kanvas, bilah(f_dari(n), 1.4), t0, 0.5)
            tambah(kanvas, bilah(f_dari(n, -1), 1.8), t0, 0.35)
            # Peking: memukul nada dua kali lebih rapat.
            tambah(kanvas, bilah(f_dari(n, 1), 0.7, 0.6), t0, 0.18)
            tambah(kanvas, bilah(f_dari(n, 1), 0.7, 0.5), t0 + ketukan * 0.5, 0.15)
        # Bonang: mengisi di antara ketukan dengan nada berikutnya.
        n_berikut = nada_rata[(i + 1) % len(nada_rata)] or n
        if n_berikut:
            tambah(kanvas, pencon(f_dari(n_berikut, -1) * 1.0, 0.9, 0.35), t0 + ketukan * 0.5, 0.22)

        if gaya == "lancaran":
            if pos % 2 == 1:
                tambah(kanvas, pencon(330, 0.4, 0.08), t0 + ketukan * 0.5, 0.15)    # ketuk
            if pos % 4 == 0 and pos != per_gongan:
                tambah(kanvas, pencon(f_dari(n or 2, -1), 2.5, 1.2), t0, 0.35)       # kenong
            if pos in (6, 10, 14):
                tambah(kanvas, pencon(f_dari(n or 5, -2), 2.5, 1.0), t0, 0.4)        # kempul
            # Kendang
            if pos % 4 == 1:
                tambah(kanvas, kendang("dhe"), t0, 0.7)
            tambah(kanvas, kendang("tak"), t0 + ketukan * 0.5, 0.35)
            if pos % 4 == 3:
                tambah(kanvas, kendang("tung"), t0 + ketukan * 0.75, 0.4)
        else:  # sampak: kenong tiap ketukan, kempul tiap dua ketukan, kendang lebih rapat
            tambah(kanvas, pencon(f_dari(n or 2, -1), 1.2, 0.6), t0, 0.28)
            if pos % 2 == 0:
                tambah(kanvas, pencon(f_dari(n or 5, -2), 2.0, 0.8), t0, 0.35)
            tambah(kanvas, kendang("dhe" if pos % 2 == 1 else "tung"), t0, 0.7)
            tambah(kanvas, kendang("tak"), t0 + ketukan * 0.5, 0.4)
            if pos % 4 == 0:
                tambah(kanvas, kendang("tak"), t0 + ketukan * 0.75, 0.35)
        if pos == per_gongan:
            tambah(kanvas, gong_ageng(52, 6.0), t0, 1.0)

    kanvas = gema(kanvas, 0.22)
    # Lipat ekor ke awal agar perulangan (loop) mulus.
    n_panjang = int(panjang * SR)
    hasil = kanvas[:n_panjang].copy()
    sisa = kanvas[n_panjang:]
    hasil[: len(sisa)] += sisa
    return normal(hasil, 0.85)


def musik_pertempuran() -> np.ndarray:
    A = [6, 5, 3, 2, 6, 5, 3, 2, 3, 5, 6, -1, 6, 5, 3, 2]
    B = [5, 3, 5, 2, 5, 3, 5, 2, 3, 2, 1, 6, 1, 2, 3, 5]
    C = [2, 3, 2, 1, 2, 3, 2, 1, 6, 1, 2, 3, 6, 5, 3, 2]
    return bunyikan_gending([A, B, A, C], 132, "lancaran")


def musik_bos() -> np.ndarray:
    A = [2, 2, 2, 2, 1, 1, 1, 1, 6, 6, 6, 6, 1, 1, 2, 2]
    B = [3, 3, 3, 3, 5, 5, 5, 5, 6, 6, 5, 5, 3, 3, 2, 2]
    return bunyikan_gending([A, B, A, B], 168, "sampak")


def musik_narasi() -> np.ndarray:
    A = [0, 2, 0, 1, 0, 2, 0, 6, 0, 3, 0, 2, 0, 1, 0, 6]
    B = [0, 5, 0, 6, 0, 1, 0, 2, 0, 1, 0, 6, 0, 5, 0, 3]
    return bunyikan_gending([A, B], 52, "narasi")


# ------------------------------------------------------------------ efek suara

def wus(durasi: float, f_awal: float, f_akhir: float) -> np.ndarray:
    """Desir udara (ayunan senjata) dengan menyapu pita frekuensi."""
    n = int(durasi * SR)
    x = derau(durasi)
    keluar = np.zeros(n)
    blok = 512
    for i in range(0, n, blok):
        k = i / n
        fc = f_awal + (f_akhir - f_awal) * k
        potong = x[i:i + blok]
        keluar[i:i + blok] = saring(np.pad(potong, (0, blok - len(potong))), rendah=fc * 0.6, tinggi=fc * 1.6)[: len(potong)]
    env = np.sin(np.linspace(0, np.pi, n)) ** 2
    return keluar * env


def dentum(durasi: float, f_awal: float, f_akhir: float, luruh: float) -> np.ndarray:
    t = t_arr(durasi)
    f = f_akhir + (f_awal - f_akhir) * np.exp(-t / (durasi * 0.15))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * amplop(len(t), 0.002, luruh)


def sfx_semua() -> dict[str, np.ndarray]:
    s: dict[str, np.ndarray] = {}
    s["ayun_gada"] = normal(wus(0.28, 600, 2200), 0.7)
    pukul = dentum(0.35, 160, 60, 0.09) + saring(derau(0.35), rendah=800, tinggi=4000) * amplop(int(0.35 * SR), 0, 0.03) * 0.6
    pukul += bilah(780, 0.35, 0.25)[: len(pukul)] * 0.4  # denting gada emas
    s["pukulan"] = normal(pukul, 0.9)
    kena = dentum(0.3, 320, 140, 0.12) * 0.8 + saring(derau(0.3), rendah=300, tinggi=1500) * amplop(int(0.3 * SR), 0, 0.08)
    s["kena_serang"] = normal(np.tanh(kena * 2.5), 0.8)
    s["langkah"] = normal(saring(derau(0.09), rendah=60, tinggi=500) * amplop(int(0.09 * SR), 0.002, 0.025), 0.6)
    s["lompat"] = normal(wus(0.22, 400, 1200), 0.5)
    s["buta_ayun"] = normal(wus(0.4, 250, 900), 0.8)
    mati = dentum(0.9, 220, 55, 0.35) * 0.7 + saring(derau(0.9), rendah=100, tinggi=700) * amplop(int(0.9 * SR), 0.05, 0.3) * 0.5
    tambah(mati, dentum(0.4, 90, 40, 0.12), 0.45, 0.9)
    s["buta_mati"] = normal(np.tanh(mati * 1.5), 0.85)
    s["terjang"] = normal(wus(0.35, 900, 2600), 0.7)
    injak = dentum(0.9, 110, 38, 0.3) + saring(derau(0.9), tinggi=400) * amplop(int(0.9 * SR), 0.0, 0.25) * 0.8
    s["injak_bumi"] = normal(injak, 0.9)
    s["lempar_batu"] = normal(wus(0.3, 300, 800), 0.6)
    batu = dentum(0.4, 140, 70, 0.08) + saring(derau(0.4), rendah=1200, tinggi=6000) * amplop(int(0.4 * SR), 0, 0.06) * 0.7
    s["batu_jatuh"] = normal(batu, 0.8)
    hantam = dentum(1.6, 90, 30, 0.5) + saring(derau(1.6), tinggi=300) * amplop(int(1.6 * SR), 0.0, 0.45) * 1.2
    s["bos_hantam"] = normal(np.tanh(hantam * 1.8), 0.95)
    # Raungan: gergaji rendah bervibrato + derau berformant.
    t = t_arr(1.6)
    f = 62 + 18 * np.sin(2 * np.pi * 5.5 * t) * np.linspace(0.3, 1, len(t))
    gergaji = 2 * ((np.cumsum(f) / SR) % 1) - 1
    raung = saring(gergaji, rendah=80, tinggi=1400) + saring(derau(1.6), rendah=300, tinggi=1100) * 0.5
    raung *= np.sin(np.linspace(0, np.pi, len(t))) ** 0.6
    s["bos_raung"] = normal(np.tanh(raung * 2.0), 0.85)
    s["gong"] = normal(gema(gong_ageng(52, 5.5)), 0.9)
    # Keprak: lempeng logam di kotak wayang yang dipukul dalang (dua ketukan rapat).
    kep = np.zeros(int(0.35 * SR))
    for mulai in (0.0, 0.09):
        tt = t_arr(0.2)
        bunyi = sum(a * np.sin(2 * np.pi * fr * tt) for fr, a in ((2150, 1.0), (3420, 0.7), (5010, 0.4)))
        bunyi = bunyi * amplop(len(tt), 0.0, 0.035) + saring(derau(0.2), rendah=3000) * amplop(len(tt), 0, 0.01) * 0.8
        tambah(kep, bunyi, mulai, 1.0 if mulai == 0 else 0.7)
    s["keprak"] = normal(kep, 0.8)
    # Kemenangan: saron naik 1-2-3-5-6-1' lalu gong ageng.
    menang = np.zeros(int(5.5 * SR))
    for i, (n, o) in enumerate(((1, 0), (2, 0), (3, 0), (5, 0), (6, 0), (1, 1))):
        tambah(menang, bilah(frek(n, o), 1.6), i * 0.16, 0.6)
        tambah(menang, bilah(frek(n, o + 1), 0.8, 0.5), i * 0.16, 0.2)
    tambah(menang, pencon(frek(1, -1), 3.0, 1.5), 0.96, 0.5)
    tambah(menang, gong_ageng(52, 4.5), 1.0, 1.0)
    s["kemenangan"] = normal(gema(menang), 0.9)
    # Kekalahan: saron turun pelan lalu gong rendah.
    kalah = np.zeros(int(5.5 * SR))
    for i, n in enumerate((6, 5, 3, 2, 1)):
        tambah(kalah, bilah(frek(n, -1), 2.0, 0.7, lembut=True), i * 0.42, 0.6)
    tambah(kalah, gong_ageng(46, 4.0), 2.1, 1.0)
    s["kekalahan"] = normal(gema(kalah), 0.85)
    return s


# ------------------------------------------------------------------ penulisan file

def tulis_wav(path: Path, x: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def tulis_ogg(path: Path, x: np.ndarray) -> None:
    sementara = path.with_suffix(".tmp.wav")
    tulis_wav(sementara, x)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(sementara), "-c:a", "libvorbis",
                    "-q:a", "4", str(path)], check=True)
    sementara.unlink()


def main() -> None:
    for nama, x in sfx_semua().items():
        p = AKAR / "audio" / "sfx" / f"{nama}.wav"
        tulis_wav(p, x)
        print(f"sfx   {p.name:22s} {len(x) / SR:5.2f} s")
    for nama, fungsi in (("musik_pertempuran", musik_pertempuran), ("musik_bos", musik_bos),
                         ("musik_narasi", musik_narasi)):
        x = fungsi()
        p = AKAR / "audio" / "musik" / f"{nama}.ogg"
        tulis_ogg(p, x)
        print(f"musik {p.name:22s} {len(x) / SR:5.2f} s")


if __name__ == "__main__":
    main()
