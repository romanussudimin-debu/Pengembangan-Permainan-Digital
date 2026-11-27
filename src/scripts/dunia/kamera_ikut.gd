class_name KameraIkut
extends Camera3D
## Kamera orang ketiga yang mengikuti target secara halus.
## - Bisa diputar (tahan klik kanan + geser mouse; di HP: geser satu jari di separuh KANAN layar)
##   dan di-zoom (roda mouse; di HP: cubit dua jari). Ketuk dua kali = kamera lurus kembali.
##   Gerak pemain mengikuti arah kamera.
## - Guncangan layar (screen shake) untuk umpan balik.

const ZOOM_MIN: float = 0.55
const ZOOM_MAX: float = 1.7
const ROTATE_SPEED: float = 0.006

@export var offset_kamera: Vector3 = Vector3(0, 6.5, 10.5)
@export var titik_lihat: Vector3 = Vector3(0, 1.6, 0)
@export var kehalusan: float = 6.0

var target: Node3D
var yaw: float = 0.0  ## putaran kamera di sekitar target (radian)
var zoom: float = 1.0  ## 1 = jarak normal; < 1 mendekat, > 1 menjauh
var _guncang: float = 0.0
var _offset_aktif: Vector3
var _memutar: bool = false
var _sentuhan: Dictionary = {}  ## indeks jari -> posisi (untuk geser/cubit di HP)
var _jarak_cubit: float = 0.0


func _ready() -> void:
	add_to_group("kamera_ikut")  # Nyawa menggetarkan kamera
	fov = 60.0
	_offset_aktif = offset_kamera
	if target:
		global_position = target.global_position + offset_kamera


func _offset_tujuan() -> Vector3:
	return (offset_kamera * zoom).rotated(Vector3.UP, yaw)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var t: float = clampf(kehalusan * delta, 0.0, 1.0)
	_offset_aktif = _offset_aktif.lerp(_offset_tujuan(), t)
	var tujuan: Vector3 = target.global_position + _offset_aktif
	global_position = global_position.lerp(tujuan, t)
	look_at(target.global_position + titik_lihat, Vector3.UP)
	if _guncang > 0.0:
		_guncang = maxf(_guncang - delta * 2.5, 0.0)
		h_offset = randf_range(-1.0, 1.0) * _guncang * 0.3
		v_offset = randf_range(-1.0, 1.0) * _guncang * 0.3
	else:
		h_offset = 0.0
		v_offset = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not current:
		return
	# Jari diangkat / klik kanan dilepas selalu diproses (walau dialog terbuka), agar tidak ada
	# sentuhan "basi" yang membuat geseran berikutnya ikut memutar kamera.
	if _lepas(event):
		return
	if not GameState.sedang(GameState.State.BERMAIN):
		_sentuhan.clear()
		_memutar = false
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		_input_sentuh(event)
	elif event.device != InputEvent.DEVICE_ID_EMULATION:
		_input_mouse(event)


func _lepas(event: InputEvent) -> bool:
	if event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		_sentuhan.erase((event as InputEventScreenTouch).index)
		_jarak_cubit = _hitung_jarak_cubit()
		return true
	if event is InputEventMouseButton and not (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		_memutar = false
		return true
	return false


## PC: tahan klik kanan + geser = putar; roda = zoom.
func _input_mouse(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_memutar = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			atur_zoom(zoom * 0.9)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			atur_zoom(zoom * 1.1)
	elif event is InputEventMouseMotion and _memutar:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_memutar = false
		else:
			yaw -= (event as InputEventMouseMotion).relative.x * ROTATE_SPEED


## HP: geser satu jari di separuh kanan = putar; cubit dua jari = zoom; ketuk dua kali = lurus kembali.
## Sentuhan yang sampai ke sini tidak dipakai joystick/tombol (KontrolSentuh).
func _input_sentuh(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.double_tap:
			reset_view()
		elif not _sentuhan.is_empty() or st.position.x >= get_viewport().get_visible_rect().size.x * 0.5:
			_sentuhan[st.index] = st.position
			_jarak_cubit = _hitung_jarak_cubit()
		return
	var sd: InputEventScreenDrag = event
	if not _sentuhan.has(sd.index):
		return
	_sentuhan[sd.index] = sd.position
	if _sentuhan.size() == 1:
		yaw -= sd.relative.x * ROTATE_SPEED * 1.2
	elif _sentuhan.size() == 2:
		var jarak: float = _hitung_jarak_cubit()
		if _jarak_cubit > 0.0 and jarak > 0.0:
			atur_zoom(zoom * _jarak_cubit / jarak)
		_jarak_cubit = jarak


func _hitung_jarak_cubit() -> float:
	if _sentuhan.size() != 2:
		return 0.0
	var titik: Array = _sentuhan.values()
	return (titik[0] as Vector2).distance_to(titik[1] as Vector2)


func reset_view() -> void:
	yaw = 0.0
	zoom = 1.0
	_sentuhan.clear()


func atur_zoom(nilai: float) -> void:
	zoom = clampf(nilai, ZOOM_MIN, ZOOM_MAX)


func guncang(kekuatan: float = 0.6) -> void:
	_guncang = maxf(_guncang, kekuatan)
