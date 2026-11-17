class_name EnemyCharger
extends EnemyBase
## Penyeruduk (babi hutan, kerbau): ancang-ancang dengan jalur seruduk terlihat di tanah,
## lalu lari lurus cepat. Bisa dihindari dengan menyingkir ke samping atau melompat.
## Setelah menyeruduk (apalagi menabrak dinding) ia terhuyung sebentar: saat terbaik membalas.

var _dashing: bool = false
var _dash_dir: Vector3 = Vector3.FORWARD
var _dash_t: float = 0.0
var _stun: float = 0.0


func _dash_time() -> float:
	return data.charge_distance / maxf(data.charge_speed, 0.1)


func _process_chase(delta: float) -> void:
	if _stun > 0.0:
		_stun -= delta
		_move(Vector3.ZERO, delta)
		return
	super._process_chase(delta)


func _process_attack(delta: float) -> void:
	if not _dashing:
		_move(Vector3.ZERO, delta)
		if target:
			_face(target.global_position, delta * 2.0)
		var t: float = clampf(_state_time / data.attack_windup, 0.0, 1.0)
		# Isyarat: elips panjang ke arah seruduk
		_telegraph_mat.albedo_color.a = 0.15 + t * 0.4
		_telegraph.scale = Vector3(0.7 * data.scale, 1, data.charge_distance * 0.5)
		_telegraph.rotation.y = model.rotation.y
		_telegraph.position = forward() * data.charge_distance * 0.5 + Vector3(0, 0.03, 0)
		if _state_time >= data.attack_windup:
			_dashing = true
			_dash_t = 0.0
			_dash_dir = forward()
			_telegraph.visible = false
			hitbox.damage = damage
			hitbox.activate(_dash_time())
			_anim_strike()
			AudioManager.putar_sfx("gendang", 0.2)
		return
	_dash_t += delta
	hitbox.position = Vector3(0, 0.8, 0) + _dash_dir * 0.9 * data.scale
	velocity.x = _dash_dir.x * data.charge_speed
	velocity.z = _dash_dir.z * data.charge_speed
	if _dash_t > 0.2 and int(_dash_t * 10) % 2 == 0:
		Efek.debu(get_parent(), global_position)
	if _dash_t >= _dash_time() or (is_on_wall() and _dash_t > 0.15):
		_dashing = false
		_cooldown = data.attack_cooldown
		_stun = 1.6 if is_on_wall() else 0.9  # menabrak = terhuyung lebih lama
		if is_on_wall():
			get_tree().call_group("kamera_ikut", "guncang", 0.3)
			Efek.teks(get_parent(), global_position + Vector3(0, 2.0, 0), "Terhuyung!", Color("c9c2b0"))
		velocity.x = 0.0
		velocity.z = 0.0
		_change_state(State.CHASE if target else State.IDLE)


func _change_state(s: State) -> void:
	super._change_state(s)
	if s == State.ATTACK:
		_telegraph.rotation.y = model.rotation.y
	elif _telegraph:
		_telegraph.rotation.y = 0.0
