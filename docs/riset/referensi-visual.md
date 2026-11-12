# Referensi Visual — Budaya Manggarai

Untuk `art-audio-director`. Fakta bersumber diberi kode [S#] (lihat `catatan-riset.md`, diakses 12 November 2026). Kode warna hex adalah **saran artistik pengembang** (bukan standar adat), diturunkan dari deskripsi sumber dan pengamatan umum dokumentasi foto.

> Sebelum membuat sprite, kumpulkan foto referensi berlisensi terbuka (mis. Wikimedia Commons, CC BY/CC BY-SA) dan catat di `docs/gdd/asset-references.md`. Jangan menjiplak foto berhak cipta.

## 1. Mbaru Niang (hub kampung)
- **Bentuk:** kerucut tinggi; atap **daun lontar** menutup dari puncak hingga hampir ke tanah, sehingga dinding nyaris tak terlihat [S1]. Rangka kayu & bambu, ikatan rotan/ijuk [S7].
- **Jumlah & tata letak:** 7 rumah — 1 **mbaru gendang** (rumah utama, sedikit lebih menonjol) + 6 **mbaru gena** [S7], mengelilingi **natas** (halaman) dengan **compang** di tengah [S20]. Susunan setengah lingkaran `[PERLU VERIFIKASI terhadap foto udara]`.
- **Lima tingkat (potongan melintang untuk kartu/ilustrasi interior)** [S5]:
  1. Lutur (paling lebar; perapian, tikar, keluarga)
  2. Lobo (rak/para-para bahan makanan)
  3. Lentar (benih)
  4. Lempa rae (cadangan pangan)
  5. Hekang kode (puncak sempit; **sakral — tampilkan hanya sebagai siluet/diagram, tidak dapat dimasuki**)
- **Ukuran sprite saran (2D side view):** rasio tinggi:lebar ≈ 1,3:1 `[PERLU VERIFIKASI dimensi asli]`; pintu kecil di bagian bawah.
- **Lingkungan:** lembah pegunungan berkabut, hutan hijau lebat [S1].

| Elemen | Hex saran |
|---|---|
| Atap lontar kering (terang) | `#B89A6A` |
| Atap lontar (bayangan) | `#7A6243` |
| Kayu/bambu rangka | `#6B4A2B` |
| Ijuk (puncak/ikatan) | `#2B2420` |
| Kabut pagi | `#DDE3E6` |
| Hutan pegunungan | `#2F5D3A`, `#4E7F4F` |

## 2. Compang (pusat kampung)
- Susunan **batu berundak** (melingkar/bertingkat) di tengah natas, tempat meletakkan persembahan [S22, S24]. Visual: batu kali abu-abu, ditumbuhi lumut; di beberapa kampung ada pohon di atasnya `[PERLU VERIFIKASI per kampung]`.
- Hex: batu `#7D7F7A`, batu gelap `#55574F`, lumut `#6E8B3D`.
- Perlakuan: landmark statis, tidak bisa diinjak/dipanjat.

## 3. Lingko (layar teka-teki)
- **Pola:** lingkaran lahan; titik pusat **lodok** dengan kayu **teno**; garis **moso** memancar dari pusat ke tepi seperti jari-jari jaring laba-laba [S17]. Petak-petak berupa **juring** (irisan) yang melebar ke luar; lebar juring tidak harus sama [S17, S18].
- Dari atas bukit (seperti Weol) beberapa lingko tampak berdampingan [S16, S17] → latar layar teka-teki: tampak atas (top-down).
- Pematang = garis tipis; petak padi berbeda tahap tumbuh memberi variasi warna.

| Elemen | Hex saran |
|---|---|
| Padi muda | `#8DBF4E` |
| Padi menguning | `#D6B84A` |
| Air sawah (pantul langit) | `#9EC3C9` |
| Pematang/moso | `#6E5235` |
| Kayu teno (pusat) | `#4A3320` |
| Garis panduan UI (aktif) | `#F2E3B3` |

## 4. Songke (UI, pakaian, kartu)
- **Warna dasar hitam**, motif berwarna ditenun di atasnya [S25, S26].
- **Motif** (gunakan sebagai pola ubin/bingkai) [S25, S26]:
  - *Jok* — motif dasar identitas (bentuk geometris belah ketupat `[PERLU VERIFIKASI bentuk]`)
  - *Ranggong* — laba-laba (cocok untuk bingkai teka-teki lingko — tafsir kreatif)
  - *Su'i* — garis-garis (pembatas/border panel UI)
  - *Mata manuk* — "mata ayam" (gunakan sopan; jangan untuk ikon musuh/bahaya)
  - *Wela kaweng* — bunga (dekorasi kartu pengetahuan)
- Warna benang yang umum terlihat pada foto songke: merah, kuning/oranye, hijau, putih, biru `[PERLU VERIFIKASI — makna warna tidak ditemukan di sumber; jangan beri arti]`.

| Elemen | Hex saran |
|---|---|
| Dasar hitam songke | `#141414` |
| Hitam kebiruan (variasi) | `#1C1F26` |
| Merah benang | `#B3262E` |
| Oranye/kuning benang | `#E0A526` |
| Hijau benang | `#2E8B57` |
| Putih benang | `#F1EDE4` |
| Biru benang | `#2D5DA1` |

## 5. Kostum Caci
- **Paki** memegang **larik** (cambuk kulit kerbau, panjang, ujung tipis); **ta'ang** memegang **nggiling** (perisai bundar kulit kerbau) dan **agang/tereng** (busur rotan/bambu melengkung) [S13, S14].
- **Panggal**: penutup kepala menyerupai tanduk kerbau, dari kulit kerbau dilapisi kain warna-warni [S13, S14].
- **Ndeki**: hiasan menyerupai ekor di pinggang belakang [S14].
- Bawahan kain **songke**; tubuh atas terbuka (sasaran sah hanya di atas pinggang [S10]). Detail lain (gelang, lonceng kaki, selendang) `[PERLU VERIFIKASI dengan foto]`.
- Penonton & penabuh gong-gendang di tepi arena; latar natas kampung.
- **Animasi:** ayunan larik (anticipation–action–follow-through), tangkisan nggiling (squash kecil saat impact), langkah tari ringan saat jeda (caci adalah tarian, bukan hanya tarung).
- **Efek kena:** kilatan putih/garis merah tipis singkat, **tanpa darah/gore**.

| Elemen | Hex saran |
|---|---|
| Kulit kerbau (nggiling/larik) | `#8A5A33` |
| Kulit kerbau tua | `#5C3A1E` |
| Rotan agang/tereng | `#C49A5A` |
| Kain penghias panggal | `#B3262E`, `#E0A526` |
| Warna kulit tokoh (rentang) | `#8D5A3B`, `#6E4429` |
| Tanah arena | `#A07E5A` |

## 6. Gong & gendang (latar audio-visual)
- Gong logam (kuning tembaga) dan gendang kulit; dimainkan pengiring mbata dan caci [S27, S28b]. Hex: gong `#B8863B`, gendang kayu `#7A4E2D`, kulit gendang `#D9C29A`.

## 7. Palet master (ringkas)
`#141414` hitam songke · `#B3262E` merah · `#E0A526` kuning · `#2E8B57` hijau · `#F1EDE4` putih · `#B89A6A` lontar · `#6B4A2B` kayu · `#8DBF4E` padi · `#2F5D3A` hutan · `#DDE3E6` kabut
