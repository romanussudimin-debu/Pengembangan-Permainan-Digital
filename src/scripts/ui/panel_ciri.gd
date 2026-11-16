class_name PanelCiri
extends Control
## Panel kanan Level 3: ciri calon pembeli (warna topi & baju) - kotak dicentang saat terjual,
## dicoret bila wisatawan pergi - dan jumlah sampah plastik yang wajib dipungut.

const NAMA_WARNA: Dictionary = {
	"f1ede4": "putih", "e8e2d2": "putih", "e8b430": "kuning", "e07b39": "oranye", "b02a2a": "merah",
	"2e7d46": "hijau", "2c5c96": "biru", "7a4a8a": "ungu", "4a4a4a": "abu-abu", "1b1818": "hitam",
	"c9a45c": "cokelat muda",
}

var pulau: Node  ## skrip pulau.gd (sumber data pembeli & sampah)


func _ready() -> void:
	position = Vector2(456, 80)
	size = Vector2(176, 24 + pulau._pembeli.size() * 14 + (14 if pulau._sampah_wajib > 0 else 0))
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Ciri calon pembeli dibentuk dari warna topi & baju (data wisatawan), atau field "ciri" bila ada.
static func ciri(w: Dictionary) -> String:
	if w.has("ciri"):
		return str(w["ciri"])
	var topi: String = str(NAMA_WARNA.get(str(w.get("topi", "c9a45c")), "?"))
	var baju: String = str(NAMA_WARNA.get(str(w.get("baju", "2c5c96")), "?"))
	return "Topi %s, baju %s" % [topi, baju]


## Panel kanan: daftar ciri calon pembeli; kotak dicentang saat terjual, dicoret bila pergi.
func _draw() -> void:
	var c: Control = self
	var huruf: Font = ThemeDB.fallback_font
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.08, 0.06, 0.06, 0.78))
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Gaya.KUNING, false, 1.0)
	c.draw_string(huruf, Vector2(8, 14), DataLabuanBajo.teks("ciri_judul") + " (pilih 3):", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Gaya.KUNING)
	for i in pulau._pembeli.size():
		var npc: Variant = pulau._pembeli[i]  # bisa sudah dihapus (wisatawan pergi), jadi tidak diberi tipe
		var y: float = 28.0 + i * 14.0
		var st: String = str(pulau._status.get(npc, "pergi"))
		var w: Dictionary = pulau._data_npc.get(npc, {})
		var warna: Color = Gaya.PUTIH
		var kotak := Rect2(8, y - 8, 8, 8)
		c.draw_rect(kotak, Gaya.PUTIH, false, 1.0)
		if st == "terjual":
			warna = Color("6ad07a")
			c.draw_polyline(PackedVector2Array([Vector2(9, y - 4), Vector2(12, y - 1), Vector2(17, y - 10)]), warna, 2.0)
		elif st == "pergi":
			warna = Gaya.ABU
		c.draw_string(huruf, Vector2(22, y), ciri(w), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, warna)
		if st == "pergi":
			c.draw_line(Vector2(22, y - 3), Vector2(168, y - 3), Gaya.ABU, 1.0)
	if pulau._sampah_wajib > 0:
		var y2: float = 28.0 + pulau._pembeli.size() * 14.0
		var warna2: Color = Color("6ad07a") if pulau._sampah_dipungut >= pulau._sampah_wajib else Color("8fd0e8")
		var teks_sampah: String = "Sampah plastik: %d/%d" % [pulau._sampah_dipungut, pulau._sampah_wajib]
		c.draw_string(huruf, Vector2(8, y2), teks_sampah, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, warna2)
