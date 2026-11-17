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
var kind: String = "arrow"  ## "arrow" | "stone" | "fire" | "wind"
var pierce: bool = false  ## menembus musuh (Panah Angin)
var skill: SkillData  ## bila diisi: efek status skill diterapkan pada setiap kena
var on_impact: Callable  ## dipanggil (posisi, target) saat berhenti (mis. ledakan Panah Api)
var _travelled: float = 0.0
var _done: bool = false
var _pierced: Array[Hurtbox] = []


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
	if src is EnemyBase and CombatManager.networked():
		CombatManager.net_event.emit("shot", {"from": from, "dir": direction, "speed": speed, "range": range_m,
				"kind": projectile_kind})
	return p


func _build_mesh() -> void:
	var m := StandardMaterial3D.new()
	if kind == "fire" or kind == "wind":
		_build_glow()
	if kind == "net" or kind == "venom" or kind == "torch":
		_build_enemy_shot()
		return
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


## Panah skill bercahaya: inti terang + cahaya titik kecil (api oranye / angin hijau pucat).
func _build_glow() -> void:
	var warna: Color = Color("ff8a30") if kind == "fire" else Color("c8f0d8")
	var inti := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.16
	bola.height = 0.32
	bola.radial_segments = 8
	bola.rings = 4
	inti.mesh = bola
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(warna, 0.85)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inti.material_override = m
	inti.position = Vector3(0, 0, -0.42)
	inti.scale = Vector3(1, 1, 2.2)
	add_child(inti)
	var cahaya := OmniLight3D.new()
	cahaya.light_color = warna
	cahaya.light_energy = 2.0
	cahaya.omni_range = 3.0
	add_child(cahaya)
	if kind == "wind":
		for i in 2:
			var cincin := MeshInstance3D.new()
			var t := TorusMesh.new()
			t.inner_radius = 0.16
			t.outer_radius = 0.2
			t.rings = 10
			t.ring_segments = 4
			cincin.mesh = t
			cincin.material_override = m
			cincin.rotation.x = PI / 2.0
			cincin.position.z = 0.1 + i * 0.3
			add_child(cincin)


## Proyektil musuh khusus: jaring (putih, melebar), bisa (hijau), obor (kayu + nyala + cahaya).
func _build_enemy_shot() -> void:
	match kind:
		"net":
			for i in 3:
				var t := TorusMesh.new()
				t.inner_radius = 0.18 + i * 0.1
				t.outer_radius = 0.21 + i * 0.1
				t.rings = 12
				t.ring_segments = 3
				var mi := MeshInstance3D.new()
				mi.mesh = t
				var m := StandardMaterial3D.new()
				m.albedo_color = Color("e8e2d2")
				mi.material_override = m
				mi.rotation.x = PI / 2.0
				add_child(mi)
			var spin := create_tween().set_loops()
			spin.tween_property(self, "rotation:z", TAU, 0.6).as_relative()
		"venom":
			var b := SphereMesh.new()
			b.radius = 0.12
			b.height = 0.24
			var mv := MeshInstance3D.new()
			mv.mesh = b
			var m2 := StandardMaterial3D.new()
			m2.albedo_color = Color(0.45, 0.9, 0.3)
			m2.emission_enabled = true
			m2.emission = Color(0.3, 0.7, 0.2)
			mv.material_override = m2
			mv.scale = Vector3(1, 1, 1.6)
			add_child(mv)
		"torch":
			var c := CylinderMesh.new()
			c.top_radius = 0.035
			c.bottom_radius = 0.035
			c.height = 0.6
			var mt := MeshInstance3D.new()
			mt.mesh = c
			var m3 := StandardMaterial3D.new()
			m3.albedo_color = Color("6a4428")
			mt.material_override = m3
			mt.rotation.x = PI / 2.0
			add_child(mt)
			_build_glow()  # nyala oranye di ujung (kind != wind => api)
			var roll := create_tween().set_loops()
			roll.tween_property(self, "rotation:x", TAU, 0.5).as_relative()


func _face_velocity() -> void:
	if velocity.length() > 0.01:
		look_at(global_position + velocity, Vector3.UP if absf(velocity.normalized().y) < 0.99 else Vector3.FORWARD)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if not is_instance_valid(source):
		source = null  # penembak sudah kalah; proyektil tetap melaju tanpa sumber
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
			if target.team == team or target.health == null or target.health.dead or _pierced.has(target):
				exclude.append(target.get_rid())  # kawan sendiri / sudah kalah / sudah ditembus: lewat
				continue
			if skill:
				CombatUtil.apply_skill_hit(target, skill, source, from, damage)
			else:
				var dmg: float = damage
				if target.entity in CombatManager.players and source in CombatManager.players:
					dmg *= CombatConst.PVP_ARROW_MULT  # penyeimbang damage antar-pemain (PvP)
				target.receive_hit(dmg, source, hit["position"])
			if pierce:
				_pierced.append(target)
				exclude.append(target.get_rid())
				Efek.percikan_kena(get_parent(), hit["position"])
				continue
			_impact(hit["position"], target)
			return
		_impact(hit["position"], null)  # dunia: panah menancap sebentar lalu hilang
		return
	global_position = to
	_travelled += step.length()
	if _travelled >= max_distance:
		if on_impact.is_valid() and not _done:
			_done = true
			on_impact.call(global_position, null)  # Panah Api tetap meledak di ujung jangkauan
		queue_free()


func _impact(pos: Vector3, target: Hurtbox) -> void:
	_done = true
	global_position = pos
	impacted.emit(pos, target)
	if on_impact.is_valid():
		on_impact.call(pos, target)
	if target == null:
		Efek.debu(get_parent(), pos)
		var tw := create_tween()
		tw.tween_interval(0.6)
		tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.2)
		tw.tween_callback(queue_free)
	else:
		queue_free()
