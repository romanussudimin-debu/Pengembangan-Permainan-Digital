class_name SkillCaster
extends Node
## Tiga skill panah + satu ultimate dengan cooldown dan energi (anak dari CombatPlayer).
## Slot: 0 = Panah Api [Q], 1 = Hujan Panah [E], 2 = Panah Angin Lingko [R], 3 = Semangat Leluhur [F].

signal cast(index: int)
signal cast_failed(index: int, reason: String)
signal energy_changed(energy: float, max_energy: float)

const MAX_ENERGY: float = 100.0
const ENERGY_REGEN: float = 8.0  ## per detik

var skills: Array[SkillData] = [
	preload("res://data/combat/skills/panah_api.tres"),
	preload("res://data/combat/skills/hujan_panah.tres"),
	preload("res://data/combat/skills/panah_angin.tres"),
	preload("res://data/combat/skills/semangat_leluhur.tres"),
]
var cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var energy: float = MAX_ENERGY
var combat: CombatPlayer
var _fail_cooldown: float = 0.0


func _ready() -> void:
	combat = get_parent()


func _physics_process(delta: float) -> void:
	_fail_cooldown = maxf(_fail_cooldown - delta, 0.0)
	if not CombatManager.active or combat.is_dead:
		return
	for i in cooldowns.size():
		cooldowns[i] = maxf(cooldowns[i] - delta, 0.0)
	if energy < MAX_ENERGY:
		energy = minf(energy + ENERGY_REGEN * delta, MAX_ENERGY)
		energy_changed.emit(energy, MAX_ENERGY)


func cooldown_ratio(i: int) -> float:
	return cooldowns[i] / skills[i].cooldown if skills[i].cooldown > 0.0 else 0.0


func can_cast(i: int) -> bool:
	return cooldowns[i] <= 0.0 and energy >= skills[i].energy_cost


func reset() -> void:
	for i in cooldowns.size():
		cooldowns[i] = 0.0
	energy = MAX_ENERGY
	energy_changed.emit(energy, MAX_ENERGY)


func try_cast(i: int) -> bool:
	if i < 0 or i >= skills.size() or combat.is_dead:
		return false
	var s: SkillData = skills[i]
	if cooldowns[i] > 0.0:
		_fail(i, "Belum siap")
		return false
	if energy < s.energy_cost:
		_fail(i, "Energi kurang")
		return false
	cooldowns[i] = s.cooldown
	energy -= s.energy_cost
	energy_changed.emit(energy, MAX_ENERGY)
	match s.kind:
		"fire_arrow":
			_fire_arrow(s)
		"arrow_rain":
			_arrow_rain(s)
		"wind_arrow":
			_wind_arrow(s)
		"ultimate":
			_ultimate(s)
	combat.aiming_time = 0.6
	combat.character.model.lepas_panah()
	get_tree().call_group("kamera_ikut", "guncang", s.shake)
	cast.emit(i)
	return true


func _fail(i: int, reason: String) -> void:
	if _fail_cooldown > 0.0:
		return
	_fail_cooldown = 0.5
	AudioManager.putar_sfx("klik")
	cast_failed.emit(i, reason)
	Efek.teks(_world(), combat.character.global_position + Vector3(0, 2.8, 0), reason, Color("c9c2b0"))


func _world() -> Node3D:
	return combat.character.get_parent() as Node3D


func _origin() -> Vector3:
	return combat.character.global_position + Vector3(0, CombatConst.COMBAT_HEIGHT, 0) + combat.aim_dir * 0.6


# ------------------------------------------------------------------ skill

## Panah Api: panah menyala yang meledak saat kena (atau di ujung jangkauan): damage area + terbakar.
func _fire_arrow(s: SkillData) -> void:
	var p := Projectile.spawn(_world(), _origin(), combat.aim_dir, s.projectile_speed, 0.0, combat.team,
			combat.character, s.cast_range, "fire")
	p.on_impact = func(pos: Vector3, _t: Hurtbox) -> void:
		Efek.ledakan_api(_world(), pos, s.radius)
		CombatUtil.area_skill(_world(), pos, s, combat.team, combat.character)
		get_tree().call_group("kamera_ikut", "guncang", s.shake)
	AudioManager.putar_sfx("cambuk", 0.1)


## Hujan Panah: lingkaran emas di titik bidik, lalu beberapa gelombang panah jatuh.
func _arrow_rain(s: SkillData) -> void:
	var center: Vector3 = _rain_target(s)
	var world: Node3D = _world()
	Efek.cincin(world, center, s.radius, Color(1.0, 0.85, 0.3, 0.9), 0.45 + s.ticks * s.tick_interval)
	AudioManager.putar_sfx("gendang", 0.1)
	var tw := create_tween()
	tw.tween_interval(0.45)
	for k in s.ticks:
		tw.tween_callback(func() -> void:
			if not is_instance_valid(world):
				return
			_falling_arrows(world, center, s.radius)
			CombatUtil.area_skill(world, center, s, combat.team, combat.character)
			AudioManager.putar_sfx("cambuk", 0.25))
		tw.tween_interval(s.tick_interval)


func _rain_target(s: SkillData) -> Vector3:
	var origin: Vector3 = combat.character.global_position
	var point: Vector3 = origin + combat.aim_dir * 6.0
	var input: PlayerInput = combat.character.input
	if input.has_aim_point:
		point = Vector3(input.aim_point.x, origin.y, input.aim_point.z)
	else:
		var e: Node3D = CombatManager.nearest_enemy(origin, s.cast_range)
		if e:
			point = e.global_position
	var offset: Vector3 = point - origin
	offset.y = 0.0
	if offset.length() > s.cast_range:
		point = origin + offset.normalized() * s.cast_range
	point.y = origin.y
	return point


## Panah-panah kecil berjatuhan (visual, tanpa tabrakan) di dalam lingkaran.
func _falling_arrows(world: Node3D, center: Vector3, radius: float) -> void:
	for n in 6:
		var a: float = randf() * TAU
		var r: float = sqrt(randf()) * radius
		var land: Vector3 = center + Vector3(cos(a) * r, 0.05, sin(a) * r)
		var p := Projectile.spawn(world, land + Vector3(0, 6.0, 0), Vector3.DOWN, 30.0, 0.0, combat.team, combat.character, 6.2)
		p.set_physics_process(false)  # hanya visual; damage dihitung area di atas
		var tw := p.create_tween()
		tw.tween_property(p, "global_position", land, 0.2).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void: Efek.debu(world, land))
		tw.tween_interval(0.25)
		tw.tween_callback(p.queue_free)


## Panah Angin Lingko: menembus semua musuh di jalurnya, mendorong mundur dan memperlambat.
func _wind_arrow(s: SkillData) -> void:
	var p := Projectile.spawn(_world(), _origin(), combat.aim_dir, s.projectile_speed, s.damage, combat.team,
			combat.character, s.cast_range, "wind")
	p.pierce = true
	p.skill = s
	AudioManager.putar_sfx("lompat", 0.1)


## Semangat Leluhur: gelombang emas di sekitar Nggohak (damage besar) + kebal sesaat.
func _ultimate(s: SkillData) -> void:
	var world: Node3D = _world()
	var pos: Vector3 = combat.character.global_position
	combat.health.invulnerable_time = maxf(combat.health.invulnerable_time, s.invulnerable_time)
	combat.show_aura(s.invulnerable_time)
	Efek.cincin(world, pos, s.radius, Color(1.0, 0.82, 0.25, 0.95), 0.6)
	Efek.cincin(world, pos, s.radius * 0.6, Color(0.7, 0.15, 0.1, 0.9), 0.45)
	Efek.cahaya(world, pos + Vector3(0, 1.5, 0), Color(1.0, 0.8, 0.35), 6.0, 0.7, 10.0)
	Efek._partikel(world, pos + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.3), 22, 6.0, 0.9, 0.1, -6.0, 3.0)
	Efek.teks(world, pos + Vector3(0, 3.2, 0), s.display_name + "!", Gaya.KUNING)
	AudioManager.putar_sfx("gong")
	CombatUtil.area_skill(world, pos, s, combat.team, combat.character)
