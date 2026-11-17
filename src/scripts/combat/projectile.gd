class_name Projectile
extends Node3D
## Proyektil lurus (panah pemain, batu ketapel musuh). Tabrakan dicek dengan raycast per frame
## (dunia + Hurtbox) agar tidak menembus musuh walau cepat. Damage diterapkan oleh otoritas.

signal impacted(hit_position: Vector3, target: Hurtbox)

var velocity: Vector3 = Vector3.ZERO
var damage: float = 10.0
var team: int = CombatConst.TEAM_PLAYERS
var source: Node
var max_distance: float = 18.0
var kind: String = "arrow"  ## "arrow" | "stone"
var _travelled: float = 0.0
var _done: bool = false


static func spawn(parent: Node, from: Vector3, direction: Vector3, speed: float, dmg: float, team_id: int,
		src: Node, range_m: float, projectile_kind: String = "arrow") -> Projectile:
	var p := Projectile.new()
	p.velocity = direction.normalized() * speed
	p.damage = dmg
	p.team = team_id
	p.source = src
	p.max_distance = range_m
	p.kind = projectile_kind
	parent.add_child(p)
	p.global_position = from
	p._build_mesh()
	p._face_velocity()
	return p


func _build_mesh() -> void:
	var m := StandardMaterial3D.new()
	if kind == "stone":
		var bola := SphereMesh.new()
		bola.radius = 0.1
		bola.height = 0.2
		bola.radial_segments = 6
		bola.rings = 3
		m.albedo_color = Color("6a625a")
		bola.material = m
		var mi := MeshInstance3D.new()
		mi.mesh = bola
		add_child(mi)
		return
	# Panah: batang kayu, mata panah, bulu (menghadap -Z)
	m.albedo_color = Color("8a5a32")
	var batang := CylinderMesh.new()
	batang.top_radius = 0.018
	batang.bottom_radius = 0.018
	batang.height = 0.8
	batang.radial_segments = 5
	batang.material = m
	var mb := MeshInstance3D.new()
	mb.mesh = batang
	mb.rotation.x = PI / 2.0
	add_child(mb)
	var m_mata := StandardMaterial3D.new()
	m_mata.albedo_color = Color("d8d2c4")
	m_mata.emission_enabled = true
	m_mata.emission = Color("e8b430") * 0.4
	var mata := CylinderMesh.new()
	mata.top_radius = 0.0
	mata.bottom_radius = 0.05
	mata.height = 0.14
	mata.radial_segments = 4
	mata.material = m_mata
	var mm := MeshInstance3D.new()
	mm.mesh = mata
	mm.rotation.x = -PI / 2.0
	mm.position = Vector3(0, 0, -0.46)
	add_child(mm)
	var m_bulu := StandardMaterial3D.new()
	m_bulu.albedo_color = Color("b02a2a")
	var bulu := BoxMesh.new()
	bulu.size = Vector3(0.1, 0.01, 0.14)
	bulu.material = m_bulu
	for i in 2:
		var mf := MeshInstance3D.new()
		mf.mesh = bulu
		mf.position = Vector3(0, 0, 0.36)
		mf.rotation.z = i * PI / 2.0
		add_child(mf)


func _face_velocity() -> void:
	if velocity.length() > 0.01:
		look_at(global_position + velocity, Vector3.UP if absf(velocity.normalized().y) < 0.99 else Vector3.FORWARD)


func _physics_process(delta: float) -> void:
	if _done:
		return
	var step: Vector3 = velocity * delta
	var from: Vector3 = global_position
	var to: Vector3 = from + step
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, CombatConst.LAYER_WORLD | CombatConst.LAYER_HURTBOX)
	query.collide_with_areas = true
	var exclude: Array[RID] = []
	for attempt in 4:
		query.exclude = exclude
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			break
		var collider: Object = hit["collider"]
		if collider is Hurtbox:
			var target: Hurtbox = collider
			if target.team == team or target.health == null or target.health.dead:
				exclude.append(target.get_rid())  # kawan sendiri / sudah kalah: tembus
				continue
			target.receive_hit(damage, source, hit["position"])
			_impact(hit["position"], target)
			return
		_impact(hit["position"], null)  # dunia: panah menancap sebentar lalu hilang
		return
	global_position = to
	_travelled += step.length()
	if _travelled >= max_distance:
		queue_free()


func _impact(pos: Vector3, target: Hurtbox) -> void:
	_done = true
	global_position = pos
	impacted.emit(pos, target)
	if target == null:
		Efek.debu(get_parent(), pos)
		var tw := create_tween()
		tw.tween_interval(0.6)
		tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.2)
		tw.tween_callback(queue_free)
	else:
		queue_free()
