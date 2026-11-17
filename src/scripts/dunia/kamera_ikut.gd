class_name KameraIkut
extends Camera3D
## Kamera orang ketiga yang mengikuti target secara halus.
## - Bisa diputar (tahan klik kanan + geser mouse; di HP: geser satu jari di area kosong)
##   dan di-zoom (roda mouse; di HP: cubit dua jari). Gerak pemain mengikuti arah kamera.
## - Mode tempur: sudut lebih tegak (mendekati top-down) agar medan & musuh terlihat luas.
## - Guncangan layar (screen shake) untuk umpan balik.

const ZOOM_MIN: float = 0.55
const ZOOM_MAX: float = 1.7
const COMBAT_OFFSET := Vector3(0, 11.0, 7.0)  ## sudut ±57 derajat saat bertempur
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
	add_to_group("kamera_ikut")  # Nyawa/tempur menggetarkan kamera
	fov = 60.0
	_offset_aktif = offset_kamera
	if target:
		global_position = target.global_position + offset_kamera


func _offset_tujuan() -> Vector3:
	var dasar: Vector3 = COMBAT_OFFSET if CombatManager.active else offset_kamera
	return (dasar * zoom).rotated(Vector3.UP, yaw)


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
	if not current or not GameState.sedang(GameState.State.BERMAIN):
		return
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_memutar = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			atur_zoom(zoom * 0.9)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			atur_zoom(zoom * 1.1)
	elif event is InputEventMouseMotion and _memutar and event.device != InputEvent.DEVICE_ID_EMULATION:
		yaw -= (event as InputEventMouseMotion).relative.x * ROTATE_SPEED
	elif event is InputEventScreenTouch:
		# Sentuhan yang sampai ke sini tidak dipakai joystick/tombol (KontrolSentuh)
		var st: InputEventScreenTouch = event
		if st.pressed:
			_sentuhan[st.index] = st.position
		else:
			_sentuhan.erase(st.index)
		_jarak_cubit = _hitung_jarak_cubit()
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		if not _sentuhan.has(sd.index):
			return
		_sentuhan[sd.index] = sd.position
		if _sentuhan.size() == 1:
			yaw -= sd.relative.x * ROTATE_SPEED * 1.2  # geser satu jari = putar kamera
		elif _sentuhan.size() == 2:
			var jarak: float = _hitung_jarak_cubit()
			if _jarak_cubit > 0.0 and jarak > 0.0:
				atur_zoom(zoom * _jarak_cubit / jarak)  # cubit = zoom
			_jarak_cubit = jarak


func _hitung_jarak_cubit() -> float:
	if _sentuhan.size() != 2:
		return 0.0
	var titik: Array = _sentuhan.values()
	return (titik[0] as Vector2).distance_to(titik[1] as Vector2)


func atur_zoom(nilai: float) -> void:
	zoom = clampf(nilai, ZOOM_MIN, ZOOM_MAX)


func guncang(kekuatan: float = 0.6) -> void:
	_guncang = maxf(_guncang, kekuatan)
