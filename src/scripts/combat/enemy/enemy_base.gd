class_name EnemyBase
extends CharacterBody3D
## Musuh dasar dengan state machine: IDLE, PATROL, CHASE, ATTACK, HURT, FLEE, DEAD.
## Jenis khusus menurunkan kelas ini (EnemyCharger, EnemyThief, EnemyShield, EnemyFlyer,
## EnemyAmbusher) dan semua stat dibaca dari EnemyData. Buat musuh dengan EnemyBase.create(data).
## AI dan damage hanya dijalankan oleh otoritas (host / mode Solo).

signal defeated(enemy: EnemyBase)

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, FLEE, DEAD }

const GRAVITY: float = 20.0

@export var data: EnemyData

var state: State = State.IDLE
var is_dead: bool = false
var targetable: bool = true  ## false = tidak bisa dibidik (bersembunyi, terbang tinggi)
var gravity_enabled: bool = true
var hit_effect: SkillData  ## efek racun/lambat/dorong dari data, dipakai serangan jarak dekat & proyektil
var health: HealthComponent
var hurtbox: Hurtbox
var hitbox: Hitbox
var model: Node3D
var hp_bar: HealthBar3D
var status: StatusEffects
var target: Node3D
var damage: float = 10.0
var home: Vector3
var _state_time: float = 0.0
var _cooldown: float = 0.0
var _patrol_point: Vector3
var _knockback: Vector3 = Vector3.ZERO
var _attack_fired: bool = false
var _telegraph: MeshInstance3D
var _telegraph_mat: StandardMaterial3D
var bonus_coins: int = 0  ## koin tambahan saat kalah (mis. curian yang direbut kembali)
var _strafe_dir: float = 1.0
var _strafe_time: float = 0.0


## Pabrik: memilih kelas sesuai data.behavior.
static func create(enemy_data: EnemyData) -> EnemyBase:
	var e: EnemyBase
	match enemy_data.behavior:
		"charger":
			e = EnemyCharger.new()
		"thief":
			e = EnemyThief.new()
		"shield":
			e = EnemyShield.new()
		"flyer":
			e = EnemyFlyer.new()
		"ambush":
			e = EnemyAmbusher.new()
		_:
			e = EnemyBase.new()
	e.data = enemy_data
	e.name = enemy_data.id
	return e


## Membuat dan menempatkan musuh di `pos` (koordinat dunia) di bawah `parent`.
static func spawn(parent: Node3D, enemy_data: EnemyData, pos: Vector3) -> EnemyBase:
	var e: EnemyBase = create(enemy_data)
	e.position = parent.to_local(pos) if parent.is_inside_tree() else pos
	parent.add_child(e)
	return e


func _ready() -> void:
	if data == null:
		data = EnemyData.new()
	collision_layer = CombatConst.LAYER_ENEMY
	collision_mask = CombatConst.LAYER_WORLD | CombatConst.LAYER_ENEMY
	home = global_position
	_patrol_point = home
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4 * data.scale
	capsule.height = 1.8 * data.scale
	shape.shape = capsule
	shape.position.y = 0.9 * data.scale
	add_child(shape)
	_build_model()
	health = HealthComponent.new()
	health.max_hp = data.max_hp * CombatManager.difficulty("enemy_hp") * CombatManager.enemy_hp_scale()
	add_child(health)
	damage = data.damage * CombatManager.difficulty("enemy_damage")
	hurtbox = Hurtbox.create_capsule(self, health, CombatConst.TEAM_ENEMIES, 0.5 * data.scale, 2.0 * data.scale)
	status = StatusEffects.new()
	status.health = health
	add_child(status)
	hurtbox.status = status
	hitbox = Hitbox.create_sphere(self, 0.8 * data.scale, Vector3(0, 1.0, -0.9) * data.scale)
	hitbox.team = CombatConst.TEAM_ENEMIES
	hitbox.source = self
	hit_effect = _make_hit_effect()
	hitbox.effect = hit_effect
	hp_bar = HealthBar3D.create(self, data.bar_height * data.scale, Color("e8643a"))
	_build_telegraph()
	health.damaged.connect(_on_damaged)
	health.changed.connect(func(hp: float, max_hp: float) -> void: hp_bar.set_ratio(hp / max_hp))
	health.died.connect(_on_died)
	hurtbox.hit.connect(_on_hit)
	CombatManager.register_enemy(self)
	_setup()
	_change_state(State.IDLE)


## Kait untuk turunan (dipanggil setelah komponen dasar siap).
func _setup() -> void:
	pass


## Efek serangan dari data (racun, jaring/lambat, dorong/tarik). pvp_multiplier 1: target selalu pemain.
func _make_hit_effect() -> SkillData:
	var fx := SkillData.new()
	fx.pvp_multiplier = 1.0
	fx.burn_dps = data.hit_poison_dps
	fx.burn_duration = data.hit_poison_duration
	fx.burn_is_poison = data.hit_poison_dps > 0.0
	fx.slow_factor = data.hit_slow_factor
	fx.slow_duration = data.hit_slow_duration
	fx.knockback = data.hit_knockback
	return fx


func _exit_tree() -> void:
	CombatManager.unregister_enemy(self)


# ------------------------------------------------------------------ tampilan

## Model sesuai data.model_kind: perampok (KarakterModel), komodo, pipit (Burung), atau CreatureModel.
func _build_model() -> void:
	match data.model_kind:
		"bandit":
			_build_bandit()
		"komodo":
			var k := Komodo.new()
			k.dikendalikan_luar = true
			k.scale = Vector3.ONE * data.scale
			add_child(k)
			model = k
		"bird":
			var b := Burung.new()
			b.jenis = "pipit"
			b.scale = Vector3.ONE * 3.0 * data.scale
			add_child(b)
			model = b
		_:
			var c := CreatureModel.new()
			c.kind = data.model_kind
			c.color = data.body_color
			c.accent = data.accent_color
			c.scale = Vector3.ONE * data.scale
			add_child(c)
			model = c


func _build_bandit() -> void:
	var km := KarakterModel.new()
	km.warna_baju = data.body_color
	km.warna_ikat = data.accent_color
	km.skala_tubuh = 1.2 * data.scale
	km.tekstur_songke = preload("res://assets/textures/kulit_kerbau.png")  # sarung kusam, beda dari warga
	km.bawa_senjata = data.attack_type == "melee"
	km.penutup_wajah = true
	add_child(km)
	model = km


func _build_telegraph() -> void:
	# Lingkaran merah di tanah yang menebal selama ancang-ancang: isyarat adil untuk menghindar
	_telegraph = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 20
	_telegraph.mesh = disc
	_telegraph_mat = StandardMaterial3D.new()
	_telegraph_mat.albedo_color = Color(0.9, 0.15, 0.1, 0.0)
	_telegraph_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_telegraph_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_telegraph.material_override = _telegraph_mat
	_telegraph.visible = false
	add_child(_telegraph)


# ------------------------------------------------------------------ AI

func _physics_process(delta: float) -> void:
	if gravity_enabled:
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = -0.5
	if is_dead or not CombatManager.is_authority() or not GameState.sedang(GameState.State.BERMAIN):
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	_state_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	_knockback = _knockback.move_toward(Vector3.ZERO, delta * 18.0)
	_update_target()
	match state:
		State.IDLE:
			_move(Vector3.ZERO, delta)
			if target:
				_change_state(State.CHASE)
			elif _state_time > randf_range(1.5, 3.0):
				_patrol_point = home + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
				_change_state(State.PATROL)
		State.PATROL:
			_move_towards(_patrol_point, data.move_speed * 0.5, delta)
			if target:
				_change_state(State.CHASE)
			elif _flat_distance(_patrol_point) < 0.4 or _state_time > 4.0:
				_change_state(State.IDLE)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_move(Vector3.ZERO, delta)
			if _state_time > 0.18:
				_change_state(State.CHASE if target else State.IDLE)
		State.FLEE:
			_process_flee(delta)
	_after_physics(delta)
	move_and_slide()


## Kait turunan: dijalankan setiap frame sebelum move_and_slide (mis. tinggi terbang).
func _after_physics(_delta: float) -> void:
	pass


## Kabur (dipakai pencuri). Turunan menimpa.
func _process_flee(_delta: float) -> void:
	_change_state(State.IDLE)


func _update_target() -> void:
	if target and (not is_instance_valid(target) or CombatManager.is_combat_dead(target)):
		target = null
	if target == null or _flat_distance(target.global_position) > data.detect_range * 1.5:
		target = CombatManager.nearest_player(global_position, data.detect_range)


## Arah depan model (musuh menghadap -Z lokal model).
func forward() -> Vector3:
	return Vector3(0, 0, -1).rotated(Vector3.UP, model.rotation.y)


func _process_chase(delta: float) -> void:
	if target == null:
		_change_state(State.IDLE)
		return
	var d: float = _flat_distance(target.global_position)
	if d <= data.attack_range and _cooldown <= 0.0:
		_change_state(State.ATTACK)
		return
	if _strafe_time > 0.0:
		# Bergeser ke samping setelah menembak (berlindung / sulit dibidik)
		_strafe_time -= delta
		var to_t: Vector3 = (target.global_position - global_position).normalized()
		_move(Vector3(-to_t.z, 0, to_t.x) * _strafe_dir * data.move_speed, delta)
		_face(target.global_position, delta)
	elif data.keep_distance > 0.0 and d < data.keep_distance:
		# Penembak mundur menjaga jarak
		var away: Vector3 = global_position - target.global_position
		_move(away.normalized() * data.move_speed, delta)
		_face(target.global_position, delta)
	elif d > data.attack_range * 0.85:
		_move_towards(target.global_position, data.move_speed, delta)
	else:
		_move(Vector3.ZERO, delta)
		_face(target.global_position, delta)


## Serangan: ancang-ancang (telegraph) -> serang -> pulih. Pemain bisa menghindar saat ancang-ancang.
func _process_attack(delta: float) -> void:
	_move(Vector3.ZERO, delta)
	if target and _state_time < data.attack_windup:
		_face(target.global_position, delta * 2.0)
	var t: float = clampf(_state_time / data.attack_windup, 0.0, 1.0)
	if not _attack_fired:
		_telegraph_mat.albedo_color.a = 0.15 + t * 0.4
		var r: float = data.attack_range * 0.6 if data.attack_type == "melee" else 0.6
		if data.attack_type == "pulse":
			r = data.attack_range
		_telegraph.scale = Vector3(r, 1, r) * (0.4 + t * 0.6)
		_telegraph.position = Vector3(0, 0.03, -data.attack_range * 0.5) if data.attack_type == "melee" else Vector3(0, 0.03, 0)
		if not gravity_enabled:
			_telegraph.global_position.y = home.y + 0.03  # musuh terbang: isyarat tetap di tanah
		_telegraph.position = _telegraph.position.rotated(Vector3.UP, model.rotation.y)
	if _state_time >= data.attack_windup and not _attack_fired:
		_attack_fired = true
		_telegraph.visible = false
		_perform_attack()
	if _state_time >= data.attack_windup + 0.35:
		_cooldown = data.attack_cooldown
		if data.strafe_after_attack:
			_strafe_dir = (1.0 if randf() < 0.5 else -1.0)
			_strafe_time = 0.9
		_change_state(State.CHASE if target else State.IDLE)


## Turunan dapat menimpa untuk serangan khas (jaring, seruduk, racun, ...).
func _perform_attack() -> void:
	if data.attack_type == "ranged":
		if target == null:
			return
		var from: Vector3 = global_position + Vector3(0, 1.3 * data.scale, 0)
		var to: Vector3 = target.global_position + Vector3(0, CombatConst.COMBAT_HEIGHT, 0)
		var p := Projectile.spawn(get_parent(), from, to - from, data.projectile_speed, damage, CombatConst.TEAM_ENEMIES,
				self, data.detect_range + 4.0, data.projectile_kind)
		p.skill = hit_effect
		if data.fire_zone_radius > 0.0:
			var world: Node = get_parent()
			p.on_impact = func(pos: Vector3, _t: Hurtbox) -> void:
				HazardZone.spawn(world, pos, data.fire_zone_radius, data.fire_zone_dps * CombatManager.difficulty("enemy_damage"),
						data.fire_zone_duration, CombatConst.TEAM_ENEMIES, self)
		AudioManager.putar_sfx("klik", 0.2)
	elif data.attack_type == "pulse":
		# Sengatan area di sekeliling (ubur-ubur)
		Efek.cincin(get_parent(), global_position, data.attack_range, Color(0.7, 0.5, 1.0, 0.8), 0.35)
		for hb: Hurtbox in CombatUtil.hurtboxes_in_radius(self, global_position + Vector3(0, 0.8, 0), data.attack_range,
				CombatConst.TEAM_ENEMIES):
			CombatUtil.apply_skill_hit(hb, hit_effect, self, global_position, damage)
		AudioManager.putar_sfx("percik", 0.2)
	else:
		hitbox.position = Vector3(0, 1.0, -0.9).rotated(Vector3.UP, model.rotation.y) * data.scale
		hitbox.damage = damage
		hitbox.activate(0.15)
		AudioManager.putar_sfx("cambuk", 0.2)
	_anim_strike()


func _change_state(s: State) -> void:
	state = s
	_state_time = 0.0
	if s == State.ATTACK:
		_attack_fired = false
		_telegraph.visible = true
		_anim_windup(data.attack_windup)
	elif _telegraph:
		_telegraph.visible = false
	_anim_moving(s == State.CHASE or s == State.PATROL or s == State.FLEE)


# ------------------------------------------------------------------ animasi (sama untuk semua jenis model)

func _anim_windup(duration: float) -> void:
	if model.has_method("ancang"):
		model.call("ancang", duration)


func _anim_strike() -> void:
	if model.has_method("lepas_pukulan"):
		model.call("lepas_pukulan")


func _anim_moving(moving: bool) -> void:
	if "mode" in model:
		model.set("mode", "jalan" if moving else "idle")
	if model is Komodo:
		(model as Komodo).berjalan_luar = moving


# ------------------------------------------------------------------ gerak

func _move(horizontal: Vector3, delta: float) -> void:
	var target_v: Vector3 = horizontal * status.speed_multiplier() + _knockback
	velocity.x = move_toward(velocity.x, target_v.x, 30.0 * delta)
	velocity.z = move_toward(velocity.z, target_v.z, 30.0 * delta)
	if "kecepatan_jalan" in model:
		model.set("kecepatan_jalan", clampf(Vector2(velocity.x, velocity.z).length() / maxf(data.move_speed, 0.1), 0.0, 1.0))


func _move_towards(point: Vector3, speed: float, delta: float) -> void:
	var dir: Vector3 = point - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		_move(Vector3.ZERO, delta)
		return
	_move(dir.normalized() * speed, delta)
	_face(point, delta)


func _face(point: Vector3, delta: float) -> void:
	var dir: Vector3 = point - global_position
	if Vector2(dir.x, dir.z).length() < 0.01:
		return
	model.rotation.y = lerp_angle(model.rotation.y, atan2(-dir.x, -dir.z), clampf(delta * 10.0, 0.0, 1.0))


func _flat_distance(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


# ------------------------------------------------------------------ kena & kalah

## Dorongan dari skill (Panah Angin, ultimate); dikurangi ketahanan dorong musuh.
func apply_knockback(push: Vector3) -> void:
	_knockback = push * (1.0 - data.knockback_resist)

func _on_hit(_amount: float, source: Node, _hit_position: Vector3) -> void:
	if source is Node3D:
		var push: Vector3 = global_position - (source as Node3D).global_position
		push.y = 0.0
		_knockback = push.normalized() * 4.0 * (1.0 - data.knockback_resist)
		if target == null and source in CombatManager.players:
			target = source
	if state != State.ATTACK and not is_dead and data.knockback_resist < 0.9:
		_change_state(State.HURT)


func _on_damaged(amount: float, _source: Node) -> void:
	var parent: Node = get_parent()
	Efek.angka_damage(parent, global_position + Vector3(0, 2.4 * data.scale, 0), amount)
	Efek.percikan_kena(parent, global_position + Vector3(0, 1.2 * data.scale, 0))
	Efek.kilat(model)
	if model.has_method("squash"):
		model.call("squash", Vector3(1.15, 0.85, 1.15), 0.18)
	AudioManager.putar_sfx("terkena", 0.15)


## Kalah: memudar & menyusut (tanpa mayat), menjatuhkan koin dan XP.
func _on_died(killer: Node) -> void:
	is_dead = true
	state = State.DEAD
	status.clear()
	_telegraph.visible = false
	hp_bar.visible = false
	hurtbox.monitorable = false
	collision_layer = 0
	CombatPickup.drop(get_parent(), global_position, data.coins + bonus_coins, data.xp)
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3(1.2, 0.2, 1.2), 0.35).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: Efek.debu(get_parent(), global_position + Vector3(0, 0.3, 0)))
	tw.tween_property(model, "scale", Vector3.ONE * 0.01, 0.2)
	tw.tween_callback(queue_free)
	CombatManager.unregister_enemy(self)
	defeated.emit(self)
	if killer and killer.has_method("on_enemy_defeated"):
		killer.call("on_enemy_defeated", self)
