class_name Checkpoint
extends Area3D
## Titik respawn tempur. Pemain yang menyentuhnya akan hidup lagi di sini setelah kalah.
## Tampil sebagai tiang bambu berbendera songke yang menyala saat aktif.

var _flag_mat: StandardMaterial3D
var _active: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = CombatConst.LAYER_PLAYER
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.0
	cyl.height = 3.0
	shape.shape = cyl
	shape.position.y = 1.5
	add_child(shape)
	var pole := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.05
	c.bottom_radius = 0.06
	c.height = 2.4
	pole.mesh = c
	pole.position.y = 1.2
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("c8a050")
	pole.material_override = m
	add_child(pole)
	var flag := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.6, 0.4, 0.02)
	flag.mesh = b
	flag.position = Vector3(0.32, 2.15, 0)
	_flag_mat = StandardMaterial3D.new()
	_flag_mat.albedo_color = Color("6a5a50")
	flag.material_override = _flag_mat
	add_child(flag)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body in CombatManager.players:
		return
	CombatManager.set_respawn_point(body, global_position)
	if not _active:
		_active = true
		_flag_mat.albedo_color = Color("b02a2a")
		_flag_mat.emission_enabled = true
		_flag_mat.emission = Color("e8b430") * 0.5
		Efek.kilau(get_parent(), global_position + Vector3(0, 2.0, 0))
		Efek.teks(get_parent(), global_position + Vector3(0, 2.8, 0), "Checkpoint")
		AudioManager.putar_sfx("ambil")
