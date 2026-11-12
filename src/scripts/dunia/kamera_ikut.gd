class_name KameraIkut
extends Camera3D
## Kamera orang ketiga dengan arah tetap yang mengikuti target secara halus.
## Mendukung guncangan layar (screen shake) untuk umpan balik.

@export var offset_kamera: Vector3 = Vector3(0, 5.5, 9.0)
@export var titik_lihat: Vector3 = Vector3(0, 1.2, 0)
@export var kehalusan: float = 6.0

var target: Node3D
var _guncang: float = 0.0


func _ready() -> void:
	fov = 60.0
	if target:
		global_position = target.global_position + offset_kamera


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var tujuan: Vector3 = target.global_position + offset_kamera
	global_position = global_position.lerp(tujuan, clampf(kehalusan * delta, 0.0, 1.0))
	look_at(target.global_position + titik_lihat, Vector3.UP)
	if _guncang > 0.0:
		_guncang = maxf(_guncang - delta * 2.5, 0.0)
		h_offset = randf_range(-1.0, 1.0) * _guncang * 0.3
		v_offset = randf_range(-1.0, 1.0) * _guncang * 0.3
	else:
		h_offset = 0.0
		v_offset = 0.0


func guncang(kekuatan: float = 0.6) -> void:
	_guncang = maxf(_guncang, kekuatan)
