class_name DataLabuanBajo
extends RefCounted
## Akses data Level 3 (data/labuan_bajo.json): destinasi, barang dagangan, dan teks dialog.

const DATA: JSON = preload("res://data/labuan_bajo.json")


static func semua_pulau() -> Array:
	return DATA.data["pulau"]


static func pulau(i: int) -> Dictionary:
	var daftar: Array = semua_pulau()
	return daftar[clampi(i, 0, daftar.size() - 1)]


## Mode Singkat: hanya destinasi pertama (Pelabuhan Labuan Bajo).
static func jumlah_pulau() -> int:
	return 1 if GameState.mode_singkat else semua_pulau().size()


static func dialog() -> Dictionary:
	return DATA.data["dialog"]


static func teks(id: String) -> String:
	return str(dialog().get(id, ""))


## Barang yang dibawa Nggohak: semua kain songke titipan penenun, ditambah foto budaya
## yang terbuka dari kartu Level 1-2 yang sudah dikumpulkan.
static func barang_dibawa() -> Array:
	var hasil: Array = []
	for b: Dictionary in DATA.data["barang"]:
		if b["jenis"] == "kain" or GameState.kartu_terkumpul.has(str(b.get("kartu", ""))):
			hasil.append(b)
	return hasil
