@tool
class_name PaletJawa
extends RefCounted
## Palet warna khas Jawa (Surakarta) untuk bahan placeholder.
## Bahan disimpan dalam cache agar mesh yang sewarna berbagi satu bahan (hemat draw call).

const SOGAN := Color(0.45, 0.29, 0.16)        # cokelat sogan (warna batik klasik Solo)
const SOGAN_TUA := Color(0.28, 0.17, 0.09)
const EMAS := Color(0.86, 0.66, 0.22)
const MARUN := Color(0.46, 0.08, 0.11)
const HIJAU := Color(0.17, 0.40, 0.22)
const HIJAU_TUA := Color(0.08, 0.22, 0.12)
const GADING := Color(0.93, 0.89, 0.78)       # putih gading untuk dinding & tembok
const PASIR := Color(0.76, 0.68, 0.50)        # tanah berpasir alun-alun
const RUMPUT := Color(0.36, 0.50, 0.24)
const HITAM := Color(0.08, 0.07, 0.06)
const GENTENG := Color(0.38, 0.16, 0.10)      # atap sirap/genteng

static var _cache: Dictionary = {}


static func bahan(warna: Color, logam: bool = false) -> StandardMaterial3D:
	var kunci := "%s_%s" % [warna.to_html(), logam]
	if _cache.has(kunci):
		return _cache[kunci]
	var b := StandardMaterial3D.new()
	b.albedo_color = warna
	if logam:
		b.metallic = 0.75
		b.roughness = 0.3
	else:
		b.roughness = 0.85
	_cache[kunci] = b
	return b
