class_name CombatPickup
extends Node3D
## Koin (emas) dan bola XP (biru) yang dijatuhkan musuh. Tertarik ke pemain terdekat (magnet),
## lalu dihitung ke pemain itu oleh otoritas.

const MAGNET_RANGE: float = 4.0
const COLLECT_RANGE: float = 0.7

var coins: int = 0
var xp: int = 0
var _speed: float = 0.0
var _age: float = 0.0
var _bob_base: float = 0.0
var _mesh: MeshInstance3D


static func drop(parent: Node, pos: Vector3, coin_amount: int, xp_amount: int) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	for i in coin_amount:
		_spawn(parent, pos, 1, 0)
	if xp_amount > 0:
		_spawn(parent, pos, 0, xp_amount)


static func _spawn(parent: Node, pos: Vector3, c: int, x: int) -> void:
	var p := CombatPickup.new()
	p.coins = c
	p.xp = x
	parent.add_child(p)
	var spread := Vector3(randf_range(-0.9, 0.9), 0.0, randf_range(-0.9, 0.9))
	p.global_position = pos + Vector3(0, 0.4, 0)
	p._bob_base = pos.y + 0.4
	var tw := p.create_tween()
	tw.tween_property(p, "global_position", pos + spread + Vector3(0, 0.4, 0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var m := StandardMaterial3D.new()
	if coins > 0:
		var koin := CylinderMesh.new()
		koin.top_radius = 0.16
		koin.bottom_radius = 0.16
		koin.height = 0.04
		koin.radial_segments = 12
		_mesh.mesh = koin
		_mesh.rotation.x = PI / 2.0
		m.albedo_color = Color("e8b430")
		m.metallic = 0.6
		m.emission_enabled = true
		m.emission = Color("e8b430") * 0.3
	else:
		var bola := SphereMesh.new()
		bola.radius = 0.14
		bola.height = 0.28
		_mesh.mesh = bola
		m.albedo_color = Color("5fb8e8")
		m.emission_enabled = true
		m.emission = Color("5fb8e8") * 0.8
	_mesh.material_override = m
	add_child(_mesh)


func _process(delta: float) -> void:
	_age += delta
	_mesh.rotation.y += delta * 4.0
	if not CombatManager.is_authority() or _age < 0.35:
		return
	var p: Node3D = CombatManager.nearest_player(global_position, MAGNET_RANGE)
	if p == null:
		return
	var to: Vector3 = p.global_position + Vector3(0, 1.0, 0) - global_position
	if to.length() < COLLECT_RANGE:
		CombatManager.add_reward(p, coins, xp)
		AudioManager.putar_sfx("ambil", 0.25)
		queue_free()
		return
	_speed = minf(_speed + delta * 18.0, 14.0)
	global_position += to.normalized() * minf(_speed * delta, to.length())
