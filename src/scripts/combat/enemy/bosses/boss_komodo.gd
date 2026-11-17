class_name BossKomodo
extends BossBase
## BOS Level 3: Komodo Raksasa.
##  - Sapuan ekor: lingkaran besar di sekitarnya (menjauh!)
##  - Semburan racun: 3 gumpal bisa menyebar yang meninggalkan genangan racun
## Fase marah: + MENGGALI - menghilang ke dalam tanah, lingkaran muncul di bawah pemain,
##   lalu menyembul tiba-tiba di sana.

var _burrow_target: Vector3


func _choose_attack() -> String:
	if enraged and randf() < 0.4:
		return "burrow"
	if target and _flat_distance(target.global_position) < 4.5:
		return "tail"
	return "spit"


func _run_attack(kind: String, t: float, delta: float) -> bool:
	_move(Vector3.ZERO, delta)
	match kind:
		"tail":
			if t < 0.05:
				Telegraph.circle(get_parent(), global_position, 4.2, 0.9)
				_anim_windup(0.9)
			if t >= 0.9 and not _attack_done:
				_attack_done = true
				model.rotation.y += PI  # ekor menyapu berputar
				var tw := create_tween()
				tw.tween_property(model, "rotation:y", model.rotation.y + PI, 0.35)
				area_hit(global_position, 4.2, damage, 8.0)
				Efek.cincin(get_parent(), global_position, 4.2, Color(0.6, 0.5, 0.3, 0.9))
			return t >= 1.4
		"burrow":
			return _run_burrow(t)
		_:
			face_target(delta)
			if t < 0.05:
				_anim_windup(0.8)
			if t >= 0.8 and not _attack_done:
				_attack_done = true
				var from: Vector3 = global_position + Vector3(0, 1.0 * data.scale * 0.6, 0) + forward() * 2.0
				var to: Vector3 = target.global_position + Vector3(0, CombatConst.COMBAT_HEIGHT, 0)
				var world: Node = get_parent()
				for a: float in [-0.32, 0.0, 0.32]:
					var p := Projectile.spawn(world, from, (to - from).rotated(Vector3.UP, a), 11.0, damage * 0.6,
							CombatConst.TEAM_ENEMIES, self, 16.0, "venom")
					p.skill = hit_effect
					p.on_impact = func(pos: Vector3, _h: Hurtbox) -> void:
						HazardZone.spawn(world, Vector3(pos.x, global_position.y, pos.z), 1.4, 6.0, 4.0,
								CombatConst.TEAM_ENEMIES, self, Color(0.35, 0.8, 0.2, 0.5))
				AudioManager.putar_sfx("percik")
			return t >= 1.2


func _run_burrow(t: float) -> bool:
	if t < 0.05:
		targetable = false
		hurtbox.monitorable = false
		Efek.debu(get_parent(), global_position + Vector3(0, 0.3, 0))
		var tw := create_tween()
		tw.tween_property(model, "position:y", -2.5, 0.5).set_ease(Tween.EASE_IN)
	if t >= 1.0 and t < 1.05 and target:
		_burrow_target = target.global_position
		Telegraph.circle(get_parent(), _burrow_target, 3.0, 1.1)
	if t >= 2.1 and not _attack_done:
		_attack_done = true
		global_position = Vector3(_burrow_target.x, global_position.y, _burrow_target.z)
		model.position.y = 0.0
		model.scale = Vector3.ONE * data.scale * 0.4
		var tw := create_tween()
		tw.tween_property(model, "scale", Vector3.ONE * data.scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		targetable = true
		hurtbox.monitorable = true
		area_hit(global_position, 3.0, damage * 1.2, 9.0)
		Efek.debu(get_parent(), global_position + Vector3(0, 0.5, 0))
		Efek._partikel(get_parent(), global_position + Vector3(0, 0.5, 0), Color("8a7a5a"), 16, 6.0, 0.8, 0.14, -14.0, 2.0)
	return t >= 2.6
