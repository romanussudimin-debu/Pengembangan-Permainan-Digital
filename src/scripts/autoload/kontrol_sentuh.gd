extends CanvasLayer
## Kontrol layar sentuh untuk ponsel/tablet (APK Android atau browser HP).
## Joystick virtual di kiri (jalan) dan tombol di kanan (lompat, interaksi, jeda).
## Hanya tampil di perangkat sentuh dan hanya saat state BERMAIN; selebihnya
## (dialog, teka-teki, mini-game, menu) cukup diketuk karena sentuhan ditiru sebagai klik mouse.

const PUSAT_JOYSTICK := Vector2(78, 282)
const JARI_JOYSTICK: float = 46.0
const JARI_KENOP: float = 20.0
const ZONA_MATI: float = 0.18
## Tombol aksi: nama aksi Input Map -> {pusat, jari-jari, label}.
const TOMBOL: Dictionary = {
	"lompat": {"pusat": Vector2(586, 300), "jari": 30.0, "label": "LOMPAT"},
	"interaksi": {"pusat": Vector2(520, 254), "jari": 30.0, "label": "BICARA"},
	"jeda": {"pusat": Vector2(612, 24), "jari": 16.0, "label": "II"},
}

var aktif_di_perangkat: bool = false
var _jari_joystick: int = -1  ## indeks sentuhan yang memegang joystick (-1 = tidak ada)
var _kenop := Vector2.ZERO  ## posisi kenop relatif pusat
var _jari_tombol: Dictionary = {}  ## indeks sentuhan -> nama aksi
var _kanvas: Node2D


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	aktif_di_perangkat = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") \
		or OS.has_feature("web_android") or OS.has_feature("web_ios")
	_kanvas = Node2D.new()
	add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	GameState.state_berubah.connect(_saat_state_berubah)
	_atur_tampil()


func _saat_state_berubah(_lama: int, _baru: int) -> void:
	_atur_tampil()


func _atur_tampil() -> void:
	var tampil: bool = aktif_di_perangkat and GameState.sedang(GameState.State.BERMAIN)
	if not tampil:
		_lepas_semua()
	visible = tampil
	_kanvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var sentuh: InputEventScreenTouch = _kanvas.make_input_local(event)
		if sentuh.pressed:
			_mulai_sentuh(sentuh.index, sentuh.position)
		else:
			_akhiri_sentuh(sentuh.index)
	elif event is InputEventScreenDrag:
		var geser: InputEventScreenDrag = _kanvas.make_input_local(event)
		if geser.index == _jari_joystick:
			_gerak_joystick(geser.position)


func _mulai_sentuh(indeks: int, pos: Vector2) -> void:
	for aksi: String in TOMBOL:
		var t: Dictionary = TOMBOL[aksi]
		if pos.distance_to(t["pusat"]) <= float(t["jari"]) + 8.0:
			_jari_tombol[indeks] = aksi
			_kirim_aksi(aksi, true)
			_kanvas.queue_redraw()
			get_viewport().set_input_as_handled()
			return
	# Joystick "mengambang": sentuhan di separuh kiri layar mana pun menggerakkan tokoh.
	if _jari_joystick == -1 and pos.x < 320.0 and pos.y > 90.0:
		_jari_joystick = indeks
		_gerak_joystick(pos)
		get_viewport().set_input_as_handled()


func _akhiri_sentuh(indeks: int) -> void:
	if indeks == _jari_joystick:
		_jari_joystick = -1
		_kenop = Vector2.ZERO
		_terapkan_arah()
	elif _jari_tombol.has(indeks):
		_kirim_aksi(_jari_tombol[indeks], false)
		_jari_tombol.erase(indeks)
	_kanvas.queue_redraw()


func _gerak_joystick(pos: Vector2) -> void:
	_kenop = (pos - PUSAT_JOYSTICK).limit_length(JARI_JOYSTICK)
	_terapkan_arah()
	_kanvas.queue_redraw()


## Kekuatan aksi analog dibaca Input.get_vector() di Pemain.arah_input().
func _terapkan_arah() -> void:
	var v: Vector2 = _kenop / JARI_JOYSTICK
	if v.length() < ZONA_MATI:
		v = Vector2.ZERO
	_atur_sumbu("kiri", -v.x)
	_atur_sumbu("kanan", v.x)
	_atur_sumbu("maju", -v.y)
	_atur_sumbu("mundur", v.y)


func _atur_sumbu(aksi: String, kekuatan: float) -> void:
	if kekuatan > 0.0:
		Input.action_press(aksi, clampf(kekuatan, 0.0, 1.0))
	else:
		Input.action_release(aksi)


## Mengirim InputEventAction supaya _unhandled_input (Pemain, MenuJeda) ikut menerimanya.
func _kirim_aksi(aksi: String, ditekan: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = aksi
	ev.pressed = ditekan
	ev.strength = 1.0 if ditekan else 0.0
	Input.parse_input_event(ev)


func _lepas_semua() -> void:
	for indeks: int in _jari_tombol:
		_kirim_aksi(_jari_tombol[indeks], false)
	_jari_tombol.clear()
	_jari_joystick = -1
	_kenop = Vector2.ZERO
	for aksi: String in ["kiri", "kanan", "maju", "mundur"]:
		Input.action_release(aksi)


func _gambar() -> void:
	if not visible:
		return
	var putih := Color(1, 1, 1, 0.35)
	_kanvas.draw_circle(PUSAT_JOYSTICK, JARI_JOYSTICK, Color(0, 0, 0, 0.3))
	_kanvas.draw_arc(PUSAT_JOYSTICK, JARI_JOYSTICK, 0.0, TAU, 40, putih, 2.0)
	_kanvas.draw_circle(PUSAT_JOYSTICK + _kenop, JARI_KENOP, Color(Gaya.KUNING, 0.6))
	var ditekan: Array = _jari_tombol.values()
	for aksi: String in TOMBOL:
		var t: Dictionary = TOMBOL[aksi]
		var pusat: Vector2 = t["pusat"]
		var jari: float = t["jari"]
		var isi := Color(Gaya.MERAH, 0.75) if ditekan.has(aksi) else Color(0, 0, 0, 0.4)
		_kanvas.draw_circle(pusat, jari, isi)
		_kanvas.draw_arc(pusat, jari, 0.0, TAU, 32, Color(Gaya.KUNING, 0.8), 2.0)
		var ukuran: int = 9 if jari > 20.0 else 10
		var lebar: float = ThemeDB.fallback_font.get_string_size(t["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
		_kanvas.draw_string(ThemeDB.fallback_font, pusat + Vector2(-lebar / 2.0, ukuran * 0.35), t["label"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, Gaya.PUTIH)
