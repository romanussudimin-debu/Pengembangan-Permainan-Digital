class_name KameraOrbit
extends Node3D
## Kamera orbit orang ketiga. Node ini (yaw) berputar mendatar mengikuti mouse,
## anak SpringArm3D (pitch) berputar naik-turun. SpringArm3D mencegah kamera
## menembus dinding/pagar.

@export var sensitivitas_mouse: float = 0.0025
@export_range(-89.0, 0.0) var batas_bawah_derajat: float = -65.0
@export_range(-30.0, 60.0) var batas_atas_derajat: float = 25.0
@export var jarak_kamera: float = 5.5
@export var pitch_awal_derajat: float = -18.0

@onready var _lengan: SpringArm3D = $SpringArm3D
@onready var _kamera: Camera3D = $SpringArm3D/Camera3D

var _yaw: float = 0.0
var _pitch: float = 0.0
var _sisa_guncang: float = 0.0
var _kekuatan_guncang: float = 0.0


func _ready() -> void:
	_lengan.spring_length = jarak_kamera
	_pitch = deg_to_rad(pitch_awal_derajat)
	# Arah awal kamera mengikuti arah hadap pemain di level.
	_yaw = get_parent_node_3d().global_rotation.y if get_parent_node_3d() else 0.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var gerak := event as InputEventMouseMotion
		_yaw -= gerak.relative.x * sensitivitas_mouse
		_pitch -= gerak.relative.y * sensitivitas_mouse
		_pitch = clampf(_pitch, deg_to_rad(batas_bawah_derajat), deg_to_rad(batas_atas_derajat))
	elif event.is_action_pressed("lepas_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.is_pressed() \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Klik pertama hanya mengunci mouse kembali, bukan menyerang.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	# Rig memakai rotasi global agar tidak ikut berputar bila induknya berputar.
	global_rotation = Vector3(0.0, _yaw, 0.0)
	_lengan.rotation.x = _pitch
	# Guncangan kamera (saat bos menghantam tanah).
	if _sisa_guncang > 0.0:
		_sisa_guncang -= delta
		_kamera.h_offset = randf_range(-1.0, 1.0) * _kekuatan_guncang
		_kamera.v_offset = randf_range(-1.0, 1.0) * _kekuatan_guncang
	else:
		_kamera.h_offset = 0.0
		_kamera.v_offset = 0.0


## Sudut yaw kamera (radian), dipakai pemain agar gerak relatif terhadap kamera.
func ambil_yaw() -> float:
	return _yaw


func guncang(kekuatan: float, durasi: float) -> void:
	_kekuatan_guncang = kekuatan
	_sisa_guncang = durasi
