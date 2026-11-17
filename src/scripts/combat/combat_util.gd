class_name CombatUtil
## Fungsi bantu tempur: mencari Hurtbox dalam radius (kueri bentuk fisika) dan
## menerapkan damage area + efek status. Dipakai skill, bos, dan bahaya lingkungan.


## Semua Hurtbox tim lain di dalam bola `radius` di `center`.
static func hurtboxes_in_radius(world_node: Node3D, center: Vector3, radius: float, attacker_team: int) -> Array[Hurtbox]:
	var hasil: Array[Hurtbox] = []
	if world_node == null or not world_node.is_inside_tree():
		return hasil
	var shape := SphereShape3D.new()
	shape.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis.IDENTITY, center)
	q.collision_mask = CombatConst.LAYER_HURTBOX
	q.collide_with_areas = true
	q.collide_with_bodies = false
	for hit: Dictionary in world_node.get_world_3d().direct_space_state.intersect_shape(q, 32):
		var c: Object = hit["collider"]
		if c is Hurtbox:
			var hb: Hurtbox = c
			if hb.team != attacker_team and hb.health and not hb.health.dead and not hasil.has(hb):
				hasil.append(hb)
	return hasil


## Damage area dari sebuah skill. Mengembalikan jumlah target yang terkena.
static func area_skill(world_node: Node3D, center: Vector3, skill: SkillData, team: int, source: Node,
		damage_override: float = -1.0) -> int:
	var n: int = 0
	for hb: Hurtbox in hurtboxes_in_radius(world_node, center, skill.radius, team):
		if apply_skill_hit(hb, skill, source, center, damage_override):
			n += 1
	return n


## Satu kena skill: damage (dikali pvp_multiplier bila target pemain), terbakar, lambat, dorongan.
static func apply_skill_hit(hb: Hurtbox, skill: SkillData, source: Node, from: Vector3, damage_override: float = -1.0) -> bool:
	var dmg: float = skill.damage if damage_override < 0.0 else damage_override
	if hb.entity in CombatManager.players:
		dmg *= skill.pvp_multiplier
	if not hb.receive_hit(dmg, source, hb.global_position):
		return false
	if hb.status:
		hb.status.apply_burn(skill.burn_dps, skill.burn_duration, source, skill.burn_is_poison)
		hb.status.apply_slow(skill.slow_factor, skill.slow_duration)
	if skill.knockback != 0.0 and hb.entity and hb.entity.has_method("apply_knockback"):  # negatif = menarik
		var push: Vector3 = hb.entity.global_position - from
		push.y = 0.0
		hb.entity.call("apply_knockback", push.normalized() * skill.knockback)
	return true
