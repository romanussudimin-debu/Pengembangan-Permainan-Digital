class_name BagiLingko
extends CanvasLayer
## Mini-game MEMBAGI LINGKO DENGAN MOSO: lingko berbentuk lingkaran dibagi menjadi sejumlah
## bagian kecil (ditandai titik di tepi). Garis moso pertama sudah ditancapkan di utara (atas).
## Pemain menancapkan garis moso lain dari lodok (pusat) ke tepi sehingga setiap penerima,
## berurutan searah jarum jam, mendapat bagian sesuai aturan musyawarah (data/lingko.json "ronde").
## "Adil" di sini berarti sesuai kesepakatan adat, bukan sama luas.
## Kontrol: klik/ketuk titik tepi untuk menancapkan/mencabut moso, atau Panah/WASD + E/Spasi;
## tombol Periksa (atau C) untuk memeriksa. Mode Sulit: ukuran bagian tidak ditampilkan dan
## kesempatan salah lebih sedikit.

signal selesai(berhasil: bool)

const PUSAT := Vector2(176, 190)
const JARI: float = 108.0
const KESEMPATAN_NORMAL: int = 3
const KESEMPATAN_SULIT: int = 2
const WARNA_PENERIMA: Array[Color] = [
	Color("e8b430"), Color("b02a2a"), Color("2e7d46"), Color("2c5c96"),
	Color("e07b39"), Color("7a4a8a"), Color("a0703c"), Color("3a9a8a"),
]
const WARNA_MOSO := Color("3b2a1c")

var _ronde: Array = []
var _indeks_ronde: int = 0
var _moso: Array[int] = []  ## posisi titik (0..bagian-1) yang ditancapi moso; 0 selalu ada
var _kursor: int = 1
var _sisa_kesempatan: int = KESEMPATAN_NORMAL
var _salah: Array[int] = []  ## indeks penerima yang bagiannya keliru (ditandai setelah Periksa)
var _terkunci: bool = false
var _selesai: bool = false
var _diakhiri: bool = false  ## mencegah sinyal selesai terpancar dua kali
var _kanvas: Control
var _label_judul_ronde: Label
var _label_aturan: Label
var _label_daftar: RichTextLabel
var _label_info: Label


## `ronde` berisi daftar {"bagian", "penerima", "target", "aturan"} dari lingko.json.
func siapkan(ronde: Array) -> void:
	_ronde = ronde


func _ready() -> void:
	layer = 40
	_bangun_ui()
	_mulai_ronde(0)
	GameState.ubah_state(GameState.State.MINIGAME)


func _data() -> Dictionary:
	return _ronde[_indeks_ronde]


func _jumlah_bagian() -> int:
	return int(_data()["bagian"])


func _mulai_ronde(i: int) -> void:
	_indeks_ronde = i
	_moso = [0]
	_kursor = 1
	_salah.clear()
	_terkunci = false
	_sisa_kesempatan = KESEMPATAN_SULIT if GameState.mode_sulit else KESEMPATAN_NORMAL
	var d: Dictionary = _data()
	_label_judul_ronde.text = "Lingko %d dari %d  ·  %d bagian" % [i + 1, _ronde.size(), _jumlah_bagian()]
	_label_aturan.text = "Aturan musyawarah: " + str(d["aturan"])
	_label_info.text = ""
	_perbarui()


# ------------------------------------------------------------------ tampilan

func _bangun_ui() -> void:
	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	add_child(Gaya.panel_songke(Vector2(40, 30), Vector2(560, 300)))
	var judul := Gaya.label("MEMBAGI LINGKO DENGAN MOSO", 14, Gaya.KUNING)
	judul.position = Vector2(56, 38)
	add_child(judul)
	_label_judul_ronde = Gaya.label("", 10, Gaya.KUNING)
	_label_judul_ronde.position = Vector2(312, 62)
	add_child(_label_judul_ronde)
	_label_aturan = Gaya.label("", 8, Gaya.PUTIH)
	_label_aturan.position = Vector2(312, 78)
	_label_aturan.size = Vector2(272, 44)
	_label_aturan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label_aturan)
	_label_daftar = RichTextLabel.new()
	_label_daftar.bbcode_enabled = true
	_label_daftar.position = Vector2(312, 126)
	_label_daftar.size = Vector2(272, 120)
	_label_daftar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_daftar.add_theme_font_size_override("normal_font_size", 8)
	add_child(_label_daftar)
	_label_info = Gaya.label("", 8, Gaya.PUTIH)
	_label_info.position = Vector2(56, 304)
	_label_info.size = Vector2(530, 24)
	_label_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label_info)
	_kanvas = Control.new()
	_kanvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kanvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	_kanvas.gui_input.connect(_input_mouse)
	var periksa := Gaya.tombol("Periksa [C]")
	periksa.custom_minimum_size = Vector2(120, 24)
	periksa.position = Vector2(312, 254)
	periksa.focus_mode = Control.FOCUS_NONE  # Spasi/E dipakai untuk menancapkan moso
	periksa.pressed.connect(_periksa)
	add_child(periksa)
	var berhenti := Gaya.tombol("Berhenti")
	berhenti.custom_minimum_size = Vector2(110, 24)
	berhenti.position = Vector2(474, 38)
	berhenti.focus_mode = Control.FOCUS_NONE
	berhenti.pressed.connect(_akhiri.bind(false))
	add_child(berhenti)


func _sudut_titik(k: int) -> float:
	return -PI / 2.0 + TAU * k / _jumlah_bagian()


func _titik(k: int, jari: float = JARI) -> Vector2:
	var a: float = _sudut_titik(k)
	return PUSAT + Vector2(cos(a), sin(a)) * jari


## Ukuran bagian tiap penerima menurut moso yang tertancap (searah jarum jam dari utara).
func _ukuran_bagian() -> Array[int]:
	var urut: Array[int] = _moso.duplicate()
	urut.sort()
	var hasil: Array[int] = []
	for i in urut.size():
		var akhir: int = urut[i + 1] if i + 1 < urut.size() else _jumlah_bagian()
		hasil.append(akhir - urut[i])
	return hasil


func _gambar() -> void:
	var n: int = _jumlah_bagian()
	# Juring tiap penerima diwarnai sesuai urutan (searah jarum jam dari moso pertama)
	var urut: Array[int] = _moso.duplicate()
	urut.sort()
	var penerima: Array = _data()["penerima"]
	for i in urut.size():
		var awal: int = urut[i]
		var akhir: int = urut[i + 1] if i + 1 < urut.size() else n
		var titik := PackedVector2Array([PUSAT])
		var langkah: int = maxi((akhir - awal) * 4, 2)
		for s in langkah + 1:
			var a: float = lerpf(_sudut_titik(awal), _sudut_titik(akhir), float(s) / langkah)
			titik.append(PUSAT + Vector2(cos(a), sin(a)) * JARI)
		var warna: Color = WARNA_PENERIMA[i % WARNA_PENERIMA.size()] if i < penerima.size() else Color("4a3e34")
		warna.a = 0.75
		_kanvas.draw_colored_polygon(titik, warna)
		if _salah.has(i):
			_kanvas.draw_polyline(titik, Color("ff4a4a"), 2.0)
	_kanvas.draw_arc(PUSAT, JARI, 0.0, TAU, 64, Gaya.KUNING, 2.0)
	# Garis moso dari lodok ke tepi
	for k: int in _moso:
		_kanvas.draw_line(PUSAT, _titik(k), Gaya.KUNING if k == 0 else WARNA_MOSO, 4.0 if k == 0 else 3.0)
	# Titik-titik bagian di tepi lingko
	for k in n:
		_kanvas.draw_circle(_titik(k), 3.0, Gaya.PUTIH if _moso.has(k) else Color("c9c2b0"))
	# Lodok dan haju teno di pusat
	_kanvas.draw_circle(PUSAT, 7.0, Color("6a4428"))
	_kanvas.draw_circle(PUSAT, 3.0, Color("2f6b3a"))
	# Kursor
	if not _terkunci:
		_kanvas.draw_line(PUSAT, _titik(_kursor), Color(1, 1, 1, 0.35), 1.0)
		_kanvas.draw_arc(_titik(_kursor), 7.0, 0.0, TAU, 16, Gaya.PUTIH, 2.0)
	_kanvas.draw_string(ThemeDB.fallback_font, _titik(0, JARI + 14) + Vector2(-12, 4), "Utara", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Gaya.KUNING)


func _perbarui() -> void:
	var d: Dictionary = _data()
	var penerima: Array = d["penerima"]
	var target: Array = d["target"]
	var ukuran: Array[int] = _ukuran_bagian()
	var teks: String = ""
	for i in penerima.size():
		var warna: String = WARNA_PENERIMA[i % WARNA_PENERIMA.size()].to_html(false)
		var punya: String = str(ukuran[i]) if i < ukuran.size() else "-"
		var sasaran: String = "" if GameState.mode_sulit else " / %d" % int(target[i])
		var tanda: String = "  [color=#ff6a6a](belum sesuai)[/color]" if _salah.has(i) else ""
		teks += "[color=#%s]■[/color] %d. %s: %s%s bagian%s\n" % [warna, i + 1, penerima[i], punya, sasaran, tanda]
	_label_daftar.text = teks
	if not _terkunci and _label_info.text == "":
		_label_info.text = _teks_bantuan()
	_kanvas.queue_redraw()


func _teks_bantuan() -> String:
	return "Tancapkan %d garis moso lagi (sekarang %d). Ketuk titik tepi, atau Panah + E. Kesempatan salah: %d." % [
		(_data()["penerima"] as Array).size() - 1, _moso.size() - 1, _sisa_kesempatan]


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if _selesai or _terkunci or not GameState.sedang(GameState.State.MINIGAME):
		return
	if event.is_action_pressed("kanan") or event.is_action_pressed("mundur"):
		_gerak(1)
	elif event.is_action_pressed("kiri") or event.is_action_pressed("maju"):
		_gerak(-1)
	elif event.is_action_pressed("interaksi") or event.is_action_pressed("lompat"):
		_tancap(_kursor)
	elif event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_C:
		_periksa()
	else:
		return
	get_viewport().set_input_as_handled()


func _input_mouse(event: InputEvent) -> void:
	if _selesai or _terkunci or not GameState.sedang(GameState.State.MINIGAME):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var v: Vector2 = event.position - PUSAT
		if v.length() < 24.0 or v.length() > JARI + 22.0:
			return
		var a: float = fposmod(v.angle() + PI / 2.0, TAU)
		var k: int = int(round(a / TAU * _jumlah_bagian())) % _jumlah_bagian()
		_kursor = k
		_tancap(k)


func _gerak(arah: int) -> void:
	_kursor = posmod(_kursor + arah, _jumlah_bagian())
	_kanvas.queue_redraw()


func _tancap(k: int) -> void:
	if k == 0:
		_label_info.text = "Moso pertama di utara sudah ditancapkan Tu'a Teno."
		_kanvas.queue_redraw()
		return
	if _moso.has(k):
		_moso.erase(k)
	else:
		_moso.append(k)
	_salah.clear()
	AudioManager.putar_sfx("klik", 0.2)
	_label_info.text = ""
	_perbarui()


func _periksa() -> void:
	if _selesai or _terkunci:
		return
	var d: Dictionary = _data()
	var target: Array = d["target"]
	var perlu: int = target.size()
	if _moso.size() != perlu:
		AudioManager.putar_sfx("gagal")
		_label_info.text = "Lingko ini dibagi untuk %d penerima, jadi harus ada %d garis moso (sekarang %d)." % [perlu, perlu, _moso.size()]
		return
	var ukuran: Array[int] = _ukuran_bagian()
	_salah.clear()
	for i in perlu:
		if ukuran[i] != int(target[i]):
			_salah.append(i)
	if _salah.is_empty():
		_ronde_berhasil()
		return
	_sisa_kesempatan -= 1
	AudioManager.putar_sfx("gagal")
	if GameState.mode_sulit:
		_salah.clear()  # Mode Sulit: bagian yang keliru tidak ditunjukkan
		_label_info.text = "Belum sesuai musyawarah. Hitung lagi perbandingannya. Sisa kesempatan: %d." % _sisa_kesempatan
	else:
		_label_info.text = "Ada %d bagian yang belum sesuai (bertanda merah). Sisa kesempatan: %d." % [_salah.size(), _sisa_kesempatan]
	_perbarui()
	if _sisa_kesempatan <= 0:
		_terkunci = true
		_label_info.text = "Kesempatan habis. Musyawarah perlu diulang."
		get_tree().create_timer(1.6, false).timeout.connect(_akhiri.bind(false))


func _ronde_berhasil() -> void:
	_terkunci = true
	AudioManager.putar_sfx("berhasil")
	_perbarui()
	if _indeks_ronde + 1 < _ronde.size():
		_label_info.text = "Lingko %d terbagi sesuai musyawarah!" % (_indeks_ronde + 1)
		get_tree().create_timer(1.4, false).timeout.connect(_ronde_berikutnya)
	else:
		_selesai = true
		_label_info.text = "Ketiga lingko terbagi adil sesuai musyawarah!"
		AudioManager.putar_sfx("gong")
		get_tree().create_timer(1.6, false).timeout.connect(_akhiri.bind(true))


func _ronde_berikutnya() -> void:
	if is_inside_tree():
		_mulai_ronde(_indeks_ronde + 1)


func _akhiri(berhasil: bool) -> void:
	if _diakhiri or not is_inside_tree():
		return
	_diakhiri = true
	_selesai = true
	GameState.ubah_state(GameState.State.BERMAIN)
	selesai.emit(berhasil)
	queue_free()
