class_name BossBase
extends EnemyBase
## Dasar bos: pola serangan bergiliran dan fase MARAH saat HP < 50% (lebih cepat, pola baru).
## Bar HP bos tampil besar di HUD (CombatManager.boss). Turunan mengisi _choose_attack() dan
## _run_attack(kind, t, delta) -> true bila serangan selesai.

const ENRAGE_RATIO: float = 0.5

var enraged: bool = false
var _attack_kind: String = ""
var _attack_done: bool = false
var _minion_cd: float = 0.0
var _rage_light: OmniLight3D


func _setup() -> void:
	hp_bar.visible = false
	hp_bar.always_visible = false
	hp_bar.set_process(false)
	health.changed.connect(_check_rage)


func _check_rage(hp: float, max_hp: float) -> void:
	if enraged or hp <= 0.0 or hp > max_hp * ENRAGE_RATIO:
		return
	enraged = true
	speed_mult = 1.4
	CombatManager.announce.emit("%s marah!" % data.display_name, "Pola serangannya berubah. Hati-hati!")
	get_tree().call_group("kamera_ikut", "guncang", 0.6)
	AudioManager.putar_sfx("raung")
	Efek.cincin(get_parent(), global_position, 4.0, Color(0.9, 0.1, 0.05, 0.9), 0.6)
	_rage_light = OmniLight3D.new()
	_rage_light.light_color = Color(1.0, 0.2, 0.1)
	_rage_light.omni_range = 4.0 * data.scale
	_rage_light.position.y = 1.5 * data.scale
	add_child(_rage_light)
	_on_enrage()


func _on_enrage() -> void:
	pass


func _after_physics(delta: float) -> void:
	_minion_cd = maxf(_minion_cd - delta, 0.0)
	if enraged and _rage_light:
		# Cahaya merah berdenyut sebagai tanda fase marah
		_rage_light.light_energy = 1.5 + 1.0 * sin(Time.get_ticks_msec() / 150.0)


func _change_state(s: State) -> void:
	super._change_state(s)
	if s == State.ATTACK:
		_telegraph.visible = false
		_attack_kind = _choose_attack()
		_attack_done = false


func _process_attack(delta: float) -> void:
	if target == null:
		_change_state(State.IDLE)
		return
	if _run_attack(_attack_kind, _state_time, delta):
		_cooldown = data.attack_cooldown * (0.65 if enraged else 1.0)
		_change_state(State.CHASE)


func _choose_attack() -> String:
	return "melee"


func _run_attack(_kind: String, _t: float, _delta: float) -> bool:
	return true


## Memanggil antek (dihitung musuh gelombang agar dibersihkan saat bos kalah).
func summon(minion: EnemyData, count: int) -> void:
	var world: Node3D = get_parent() as Node3D
	for i in count:
		var a: float = TAU * i / maxf(count, 1) + randf()
		var pos: Vector3 = global_position + Vector3(cos(a) * 2.5, 0.2, sin(a) * 2.5)
		var e: EnemyBase = EnemyBase.spawn(world, minion, pos)
		e.detect_override = 60.0
		e.from_wave = true
		Efek.debu(world, pos)
	AudioManager.putar_sfx("gendang")


## Damage area di sekitar titik (dengan dorongan), memakai efek serangan bos.
func area_hit(center: Vector3, radius: float, dmg: float, knock: float) -> void:
	var fx: SkillData = hit_effect.duplicate()
	fx.radius = radius
	fx.damage = dmg
	fx.knockback = knock
	CombatUtil.area_skill(get_parent() as Node3D, center + Vector3(0, 0.8, 0), fx, CombatConst.TEAM_ENEMIES, self, dmg)
	get_tree().call_group("kamera_ikut", "guncang", 0.35)


func face_target(delta: float) -> void:
	if target:
		_face(target.global_position, delta * 3.0)
