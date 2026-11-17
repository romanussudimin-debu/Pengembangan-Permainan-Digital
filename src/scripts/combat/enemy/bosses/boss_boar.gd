class_name BossBoar
extends BossBase
## BOS Level 2: Babi Hutan Raksasa.
##  - Seruduk beruntun: 3 kali dengan jalur terlihat; setelah itu kelelahan (saat terbaik membalas)
##  - Menabrak dinding/pematang = puing berhamburan & terhuyung
## Fase marah: seruduk lebih cepat dan memanggil 2 Babi Hutan Kecil di awal rentetan.

const MINION: EnemyData = preload("res://data/combat/enemies/l2/babi_hutan_kecil.tres")
const CHAIN: int = 3

var _charges_left: int = 0
var _dashing: bool = false
var _dash_dir: Vector3 = Vector3.FORWARD
var _dash_t: float = 0.0
var _phase_t: float = 0.0
var _tired: float = 0.0


func _choose_attack() -> String:
	_charges_left = CHAIN
	_dashing = false
	_phase_t = 0.0
	if enraged and _minion_cd <= 0.0:
		_minion_cd = 18.0
		summon(MINION, 2)
	return "charge"


func _process_chase(delta: float) -> void:
	if _tired > 0.0:
		_tired -= delta
		_move(Vector3.ZERO, delta)
		return
	super._process_chase(delta)


func _speed() -> float:
	return data.charge_speed * (1.25 if enraged else 1.0)


func _run_attack(_kind: String, _t: float, delta: float) -> bool:
	_phase_t += delta
	var windup: float = data.attack_windup if _charges_left == CHAIN else 0.5
	if not _dashing:
		_move(Vector3.ZERO, delta)
		face_target(delta * 2.0)
		_telegraph.visible = true
		_telegraph_mat.albedo_color.a = 0.2 + 0.4 * clampf(_phase_t / windup, 0.0, 1.0)
		_telegraph.scale = Vector3(1.1 * data.scale, 1, data.charge_distance * 0.5)
		_telegraph.rotation.y = model.rotation.y
		_telegraph.position = forward() * data.charge_distance * 0.5 + Vector3(0, 0.03, 0)
		if _phase_t >= windup:
			_dashing = true
			_dash_t = 0.0
			_dash_dir = forward()
			_telegraph.visible = false
			hitbox.damage = damage
			hitbox.activate(data.charge_distance / _speed())
			_anim_strike()
			AudioManager.putar_sfx("gendang")
		return false
	_dash_t += delta
	hitbox.position = Vector3(0, 1.0, 0) + _dash_dir * 1.4 * data.scale
	velocity.x = _dash_dir.x * _speed()
	velocity.z = _dash_dir.z * _speed()
	if int(_dash_t * 12) % 2 == 0:
		Efek.debu(get_parent(), global_position)
	var hit_wall: bool = is_on_wall() and _dash_t > 0.15
	if _dash_t >= data.charge_distance / _speed() or hit_wall:
		if hit_wall:
			# Menghancurkan pematang/pagar: puing berhamburan
			Efek._partikel(get_parent(), global_position + _dash_dir * 1.5 + Vector3(0, 0.8, 0), Color("6a4a30"), 14, 5.0,
					0.7, 0.12, -14.0, 1.8)
			get_tree().call_group("kamera_ikut", "guncang", 0.5)
		velocity.x = 0.0
		velocity.z = 0.0
		_dashing = false
		_phase_t = 0.0
		_charges_left -= 1
		if _charges_left <= 0:
			_tired = 2.5
			_telegraph.rotation.y = 0.0
			Efek.teks(get_parent(), global_position + Vector3(0, 3.5, 0), "Kelelahan!", Gaya.KUNING)
			return true
	return false
