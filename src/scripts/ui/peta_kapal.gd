extends Node
## Level 3: PETA PERJALANAN KAPAL (tampak atas, ilustrasi tidak berskala).
## Destinasi Taman Nasional Komodo terbuka berurutan (kesulitan naik). Kapal bergerak ke destinasi
## terpilih lalu scene pulau dimuat. Setelah ketiga destinasi tuntas: pulang ke Wae Rebo (ending Penti).

const WARNA_LAUT_ATAS := Color("2a6f97")
const WARNA_LAUT_BAWAH := Color("1d4a6c")
const WARNA_DARAT := Color("8fae5a")
const WARNA_PANTAI := Color("e8d8a8")

## Bentuk pulau-pulau (titik pusat, jari-jari, kelonjongan) untuk latar peta.
const PULAU_LATAR: Array = [
	[Vector2(190, 196), 74.0, Vector2(1.0, 1.25)],  # Pulau Komodo
	[Vector2(462, 236), 48.0, Vector2(1.0, 1.4)],  # Pulau Rinca
	[Vector2(392, 258), 15.0, Vector2(1.3, 0.8)],  # Pulau Padar
	[Vector2(306, 120), 5.0, Vector2(2.0, 0.6)],  # Taka Makassar
]

var _kanvas: Control
var _ui: CanvasLayer
var _tombol: Array[Button] = []
var _tombol_pulang: Button
var _label_status: Label
var _posisi_kapal: Vector2
var _sibuk: bool = false
var _waktu: float = 0.0


func _ready() -> void:
	get_tree().paused = false
	GameState.level = 3
	GameState.ubah_state(GameState.State.BERMAIN)
	AudioManager.putar_musik("kampung")
	_siapkan_uji_langsung()
	var selesai: int = GameState.pulau_selesai
	_posisi_kapal = _titik_pulau(clampi(selesai - 1, 0, DataLabuanBajo.jumlah_pulau() - 1))
	if selesai == 0:
		_posisi_kapal += Vector2(30, 40)  # kapal masih di perairan dekat Labuan Bajo
	_bangun_ui()
	if not GameState.pembuka_l3_dilihat:
		get_tree().create_timer(0.8, false).timeout.connect(_pembuka)
	elif selesai >= DataLabuanBajo.jumlah_pulau():
		get_tree().create_timer(0.6, false).timeout.connect(
				func() -> void: DialogManager.mulai_baris("pulang", DataLabuanBajo.dialog()["pulang"]))


## Bila scene ini dibuka langsung (F6) tanpa memainkan Level 1-2, kartu Level 1-2 dianggap sudah
## terkumpul supaya foto budaya tersedia untuk dijual dan Level 3 bisa diuji sendiri.
func _siapkan_uji_langsung() -> void:
	if GameState.jumlah_terkumpul_level(1) > 0 or GameState.jumlah_terkumpul_level(2) > 0:
		return
	for k: Dictionary in GameState.semua_kartu():
		if int(k.get("level", 1)) < 3:
			GameState.kumpulkan_kartu(str(k["id"]))
	GameState.langkah_rantai = GameState.rantai().size()
	GameState.kartu_awal_level.assign(GameState.kartu_terkumpul)


func _titik_pulau(i: int) -> Vector2:
	var p: Array = DataLabuanBajo.pulau(i)["peta"]
	return Vector2(p[0], p[1])


func _pembuka() -> void:
	DialogManager.mulai_baris("pembuka_l3", DataLabuanBajo.dialog()["pembuka_peta"], func() -> void:
		GameState.kumpulkan_kartu("songke_ekonomi")
		DialogManager.tampilkan_kartu("songke_ekonomi", func() -> void:
			GameState.pembuka_l3_dilihat = true
			GameState.kartu_awal_level.assign(GameState.kartu_terkumpul)
			GameState.simpan()
			_fokus_tombol()))


func _bangun_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	_kanvas = Control.new()
	_kanvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kanvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	var judul := Gaya.label("PETA PERJALANAN KAPAL", 16, Gaya.KUNING)
	judul.position = Vector2(14, 8)
	_ui.add_child(judul)
	var sub := Gaya.label("Level 3 · Songke ke Labuan Bajo (Taman Nasional Komodo) · peta ilustrasi, tidak berskala", 8, Gaya.PUTIH)
	sub.position = Vector2(16, 32)
	_ui.add_child(sub)
	var panel := Gaya.panel_songke(Vector2(10, 292), Vector2(390, 60))
	_ui.add_child(panel)
	_label_status = Gaya.label("", 9, Gaya.PUTIH)
	_label_status.position = Vector2(12, 8)
	_label_status.size = Vector2(366, 46)
	_label_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_label_status)
	var selesai: int = GameState.pulau_selesai
	for i in DataLabuanBajo.jumlah_pulau():
		var data: Dictionary = DataLabuanBajo.pulau(i)
		var awalan: String = "[x] " if i < selesai else ("" if i == selesai else "(terkunci) ")
		var b := Gaya.tombol("%d. %s%s" % [i + 1, awalan, data["nama"]])
		b.custom_minimum_size = Vector2(0, 18)
		b.add_theme_font_size_override("font_size", 8)
		b.disabled = i > selesai
		b.position = _titik_pulau(i) + Vector2(-46, 10)
		b.pressed.connect(_pilih.bind(i))
		_ui.add_child(b)
		_tombol.append(b)
	_tombol_pulang = Gaya.tombol("Pulang ke Wae Rebo")
	_tombol_pulang.position = Vector2(470, 316)
	_tombol_pulang.visible = selesai >= DataLabuanBajo.jumlah_pulau()
	_tombol_pulang.pressed.connect(_pulang)
	_ui.add_child(_tombol_pulang)
	_label_status.text = "Destinasi tuntas: %d/%d  ·  Terjual: %d kain/foto\n%s" % [
		selesai, DataLabuanBajo.jumlah_pulau(), GameState.terjual_total,
		"Semua destinasi tuntas! Bawa pulang hasil penjualan ke Wae Rebo." if _tombol_pulang.visible else DataLabuanBajo.teks("peta_petunjuk")]
	if GameState.pembuka_l3_dilihat:
		_fokus_tombol()


func _fokus_tombol() -> void:
	if _tombol_pulang.visible:
		_tombol_pulang.grab_focus()
	else:
		_tombol[mini(GameState.pulau_selesai, _tombol.size() - 1)].grab_focus()


func _process(delta: float) -> void:
	_waktu += delta
	_kanvas.queue_redraw()


func _gambar() -> void:
	var c: Control = _kanvas
	# Laut bergradasi dan riak
	for y in 18:
		var t: float = y / 17.0
		c.draw_rect(Rect2(0, y * 20.0, 640, 20.0), WARNA_LAUT_ATAS.lerp(WARNA_LAUT_BAWAH, t))
	for i in 24:
		var x: float = fposmod(i * 53.0 + _waktu * 8.0, 660.0) - 10.0
		var y: float = 60.0 + fmod(i * 97.0, 280.0)
		c.draw_line(Vector2(x, y), Vector2(x + 10, y), Color(1, 1, 1, 0.18), 1.0)
	# Daratan Flores (timur) dan pulau-pulau
	var flores := PackedVector2Array([Vector2(640, 40), Vector2(590, 60), Vector2(566, 120), Vector2(552, 180), Vector2(560, 240),
		Vector2(548, 300), Vector2(570, 360), Vector2(640, 360)])
	c.draw_colored_polygon(flores, WARNA_DARAT)
	c.draw_polyline(flores, WARNA_PANTAI, 3.0)
	c.draw_string(ThemeDB.fallback_font, Vector2(574, 300), "FLORES", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("2a3a1a"))
	for data: Array in PULAU_LATAR:
		var titik := PackedVector2Array()
		var pusat: Vector2 = data[0]
		var jari: float = data[1]
		var lonjong: Vector2 = data[2]
		for k in 18:
			var a: float = TAU * k / 18.0
			var r: float = jari * (1.0 + 0.12 * sin(a * 3.0 + pusat.x))
			titik.append(pusat + Vector2(cos(a) * r * lonjong.x, sin(a) * r * lonjong.y))
		c.draw_colored_polygon(titik, WARNA_PANTAI if jari < 8.0 else WARNA_DARAT)
		titik.append(titik[0])
		c.draw_polyline(titik, WARNA_PANTAI, 2.0)
	c.draw_string(ThemeDB.fallback_font, Vector2(150, 290), "P. Komodo", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("2a3a1a"))
	c.draw_string(ThemeDB.fallback_font, Vector2(440, 300), "P. Rinca", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("2a3a1a"))
	# Rute kapal (garis putus-putus) dan penanda destinasi
	var selesai: int = GameState.pulau_selesai
	for i in DataLabuanBajo.jumlah_pulau() - 1:
		var a: Vector2 = _titik_pulau(i)
		var b: Vector2 = _titik_pulau(i + 1)
		var n: int = int(a.distance_to(b) / 8.0)
		for k in n:
			if k % 2 == 0:
				c.draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), Color(1, 1, 1, 0.6 if i < selesai else 0.25), 1.5)
	for i in DataLabuanBajo.jumlah_pulau():
		var p: Vector2 = _titik_pulau(i)
		var warna: Color = Gaya.HIJAU if i < selesai else (Gaya.KUNING if i == selesai else Gaya.ABU)
		c.draw_circle(p, 6.0, Gaya.HITAM)
		c.draw_circle(p, 4.5, warna)
	_gambar_kapal(c, _posisi_kapal)


## Kapal kecil di peta (lambung, layar) yang naik-turun pelan.
func _gambar_kapal(c: Control, p: Vector2) -> void:
	var o: Vector2 = p + Vector2(0, sin(_waktu * 2.0) * 1.5 - 14)
	var lambung := PackedVector2Array([o + Vector2(-11, 0), o + Vector2(11, 0), o + Vector2(7, 5), o + Vector2(-7, 5)])
	c.draw_colored_polygon(lambung, Color("6a4428"))
	c.draw_line(o, o + Vector2(0, -14), Color("3b2a1c"), 1.5)
	c.draw_colored_polygon(PackedVector2Array([o + Vector2(1, -13), o + Vector2(10, -2), o + Vector2(1, -2)]), Color("f4ecd8"))


func _pilih(i: int) -> void:
	if _sibuk or not GameState.sedang(GameState.State.BERMAIN) or i > GameState.pulau_selesai:
		return
	_sibuk = true
	for b: Button in _tombol:
		b.disabled = true
	AudioManager.putar_sfx("gong")
	var tw := create_tween()
	tw.tween_property(self, "_posisi_kapal", _titik_pulau(i), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(GameState.kunjungi_pulau.bind(i))


func _pulang() -> void:
	if _sibuk:
		return
	_sibuk = true
	AudioManager.putar_sfx("gong")
	GameState.selesaikan_level(3)
