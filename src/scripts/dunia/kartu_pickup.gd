class_name KartuPickup
extends Area3D
## Kartu pengetahuan budaya yang berputar dan melayang; diambil saat disentuh pemain.

@export var id_kartu: String = ""

var _visual: Node3D
var _waktu: float = 0.0
var _diambil: bool = false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	var bentuk := SphereShape3D.new()
	bentuk.radius = 0.8
	var c := CollisionShape3D.new()
	c.shape = bentuk
	add_child(c)
	_visual = Node3D.new()
	add_child(_visual)
	var kartu := BoxMesh.new()
	kartu.size = Vector3(0.5, 0.65, 0.04)
	var m := StandardMaterial3D.new()
	m.albedo_texture = preload("res://assets/textures/kartu.png")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.emission_enabled = true
	m.emission = Color("e8b430")
	m.emission_energy_multiplier = 0.25
	var mi := MeshInstance3D.new()
	mi.mesh = kartu
	mi.material_override = m
	_visual.add_child(mi)
	var cahaya := OmniLight3D.new()
	cahaya.light_color = Color("ffd76a")
	cahaya.light_energy = 0.8
	cahaya.omni_range = 2.5
	add_child(cahaya)


func _process(delta: float) -> void:
	_waktu += delta
	_visual.rotation.y += delta * 2.0
	_visual.position.y = sin(_waktu * 2.5) * 0.15


## Polling tumpang-tindih (bukan sinyal) agar kartu tetap bisa diambil
## jika pemain sudah berdiri di atasnya saat dialog berakhir.
func _physics_process(_delta: float) -> void:
	if _diambil or not GameState.sedang(GameState.State.BERMAIN):
		return
	for body in get_overlapping_bodies():
		if body is Pemain:
			_ambil()
			return


func _ambil() -> void:
	_diambil = true
	GameState.kumpulkan_kartu(id_kartu)
	DialogManager.tampilkan_kartu(id_kartu)
	# Efek diambil: membesar lalu menghilang (ease out)
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE * 1.8, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_property(_visual, "scale", Vector3.ZERO, 0.2).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
