class_name PlayerInput
extends Node
## Sumber perintah untuk satu karakter pemain. Logika karakter hanya membaca nilai di sini,
## sehingga perintah bisa berasal dari keyboard/mouse, layar sentuh, bot, atau jaringan.

var move_dir: Vector3 = Vector3.ZERO  ## arah gerak di dunia (sudah relatif kamera), panjang 0..1
var aim_point: Vector3 = Vector3.ZERO  ## titik bidik di dunia (bila has_aim_point)
var has_aim_point: bool = false
var auto_aim: bool = false  ## true = bidik otomatis ke musuh terdekat (sentuh/bot)
var shoot_held: bool = false
var jump_pressed: bool = false  ## true hanya pada frame tombol ditekan
var jump_held: bool = false
var interact_pressed: bool = false
var skill_pressed: Array[bool] = [false, false, false, false]  ## Q, E, R, ultimate (frame ditekan)


## Dipanggil karakter sekali per frame fisika sebelum logika gerak. Turunan menimpa fungsi ini.
func update_input(_character: Node3D, _delta: float) -> void:
	pass


func clear() -> void:
	move_dir = Vector3.ZERO
	shoot_held = false
	jump_pressed = false
	jump_held = false
	interact_pressed = false
	for i in skill_pressed.size():
		skill_pressed[i] = false
