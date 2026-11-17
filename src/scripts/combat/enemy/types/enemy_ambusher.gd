class_name EnemyAmbusher
extends EnemyBase
## Penyergap (ular hijau di semak, ular sawah di air): tersembunyi dan tak bisa dibidik sampai
## pemain mendekat sejauh data.ambush_range, lalu muncul tiba-tiba dan menyerang.
## Tanda adil: semak bergoyang / riak air di tempat persembunyian.

var hidden: bool = true
var _cover: Node3D
var _t: float = 0.0


func _setup() -> void:
	if data.ambush_range <= 0.0:
		hidden = false
		return
	targetable = false
	model.visible = false
	hp_bar.visible = false
	hurtbox.monitorable = false
	_build_cover()
	set_physics_process(false)


func _build_cover() -> void:
	_cover = Node3D.new()
	add_child(_cover)
	var m := StandardMaterial3D.new()
	if data.hide_in == "water":
		m.albedo_color = Color(0.35, 0.55, 0.65, 0.75)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var c := CylinderMesh.new()
		c.top_radius = 0.9
		c.bottom_radius = 0.9
		c.height = 0.03
		c.radial_segments = 16
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = m
		mi.position.y = 0.04
		_cover.add_child(mi)
	else:
		m.albedo_color = Color("4f7a2e")
		for i in 3:
			var b := SphereMesh.new()
			b.radius = 0.55
			b.height = 0.8
			b.radial_segments = 8
			b.rings = 4
			var mi := MeshInstance3D.new()
			mi.mesh = b
			mi.material_override = m
			mi.position = Vector3(cos(i * 2.1) * 0.35, 0.35, sin(i * 2.1) * 0.35)
			_cover.add_child(mi)


func _process(delta: float) -> void:
	if not hidden or not CombatManager.is_authority():
		return
	_t += delta
	if _cover:  # semak bergoyang / riak air: tanda ada sesuatu
		_cover.rotation.z = sin(_t * 9.0) * 0.06 * (1.0 + sin(_t * 1.3))
		_cover.scale = Vector3.ONE * (1.0 + sin(_t * 5.0) * 0.03)
	if not GameState.sedang(GameState.State.BERMAIN):
		return
	var p: Node3D = CombatManager.nearest_player(global_position, data.ambush_range)
	if p:
		_reveal(p)


func _reveal(p: Node3D) -> void:
	hidden = false
	targetable = true
	model.visible = true
	hurtbox.monitorable = true
	target = p
	model.position.y = -0.8
	var tw := create_tween()
	tw.tween_property(model, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if data.hide_in == "water":
		Efek.percikan(get_parent(), global_position + Vector3(0, 0.3, 0))
	else:
		Efek.debu(get_parent(), global_position + Vector3(0, 0.4, 0))
	Efek.teks(get_parent(), global_position + Vector3(0, 1.8, 0), "!", Color("ff6a4a"))
	set_physics_process(true)
	_cooldown = 0.0
	_change_state(State.CHASE)  # langsung menerjang mendekat, lalu menggigit (tetap ada ancang-ancang)
