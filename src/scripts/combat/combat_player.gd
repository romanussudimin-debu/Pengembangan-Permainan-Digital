class_name CombatPlayer
extends Node
## Komponen tempur pada karakter pemain (anak dari Pemain): HP, busur, bidik, mati & respawn.
## Membaca perintah dari PlayerInput milik karakter, jadi sama untuk keyboard/sentuh/bot/jaringan.

signal shot(direction: Vector3)

var character: Pemain
var health: HealthComponent
var hurtbox: Hurtbox
var hp_bar: HealthBar3D
var status: StatusEffects
var caster: SkillCaster
var stats: CombatStats
var team: int = CombatConst.TEAM_PLAYERS
var player_name: String = "Nggohak"
var aim_dir: Vector3 = Vector3.FORWARD
var is_dead: bool = false
var respawn_left: float = 0.0
var aiming_time: float = 0.0  ## > 0 = tubuh menghadap arah bidik (baru saja menembak)
var _fire_cooldown: float = 0.0


func _ready() -> void:
	character = get_parent()
	health = HealthComponent.new()
	health.name = "Health"
	health.max_hp = CombatConst.PLAYER_MAX_HP
	add_child(health)
	hurtbox = Hurtbox.create_capsule(character, health, team, 0.4, 1.9)
	hurtbox.name = "Hurtbox"
	status = StatusEffects.new()
	status.health = health
	add_child(status)
	hurtbox.status = status
	caster = SkillCaster.new()
	caster.name = "Skills"
	add_child(caster)
	hp_bar = HealthBar3D.create(character, 3.0, Color("6ad07a"), player_name)
	hp_bar.always_visible = false
	health.damaged.connect(_on_damaged)
	health.changed.connect(func(hp: float, max_hp: float) -> void: hp_bar.set_ratio(hp / max_hp))
	health.died.connect(_on_died)
	CombatManager.register_player(character)
	stats = CombatManager.stats_for(character)
	stats.upgrades_changed.connect(apply_stats)
	stats.leveled_up.connect(_on_level_up)
	apply_stats()
	CombatManager.combat_changed.connect(_on_combat_changed)
	_on_combat_changed(CombatManager.active)
	if character.input is KeyboardInput:
		set_player_name(PlayerProfile.player_name)  # pemain lokal: nama dari profil


func _exit_tree() -> void:
	CombatManager.unregister_player(character)
	if stats:
		if stats.upgrades_changed.is_connected(apply_stats):
			stats.upgrades_changed.disconnect(apply_stats)
		if stats.leveled_up.is_connected(_on_level_up):
			stats.leveled_up.disconnect(_on_level_up)


## Terapkan stat dari level tempur & upgrade (HP maks naik = HP ikut bertambah sebesar selisihnya).
func apply_stats() -> void:
	var new_max: float = stats.max_hp()
	var diff: float = new_max - health.max_hp
	health.set_max_hp(new_max, false)
	if diff > 0.0 and not health.dead:
		health.heal(diff)


func speed_multiplier() -> float:
	var m: float = status.speed_multiplier()
	if CombatManager.active:
		m *= stats.move_speed_multiplier()
	return m


func damage_multiplier() -> float:
	return stats.damage_multiplier()


func _on_level_up(lv: int) -> void:
	apply_stats()
	health.heal(health.max_hp * CombatStats.LEVEL_UP_HEAL)
	var world: Node = character.get_parent()
	Efek.cincin(world, character.global_position, 2.2, Color(0.4, 0.8, 1.0, 0.9), 0.6)
	Efek.kilau(world, character.global_position + Vector3(0, 1.4, 0))
	Efek.teks(world, character.global_position + Vector3(0, 3.0, 0), "Naik Level %d!" % lv, Color("7fd0ff"))
	AudioManager.putar_sfx("kombo")
	Analitik.catat("level_tempur", {"level_tempur": lv})


## Barang habis pakai dari toko (Kopi Wae Rebo).
func use_consumable(item: ShopItem) -> void:
	if item.stat == "heal":
		health.heal(health.max_hp * item.value_per_rank)
		Efek.kilau(character.get_parent(), character.global_position + Vector3(0, 1.2, 0))


func _on_combat_changed(active: bool) -> void:
	hurtbox.monitorable = active
	hp_bar.always_visible = active
	hp_bar.visible = active
	if character.model:
		character.model.tampilkan_busur(active)
	if active:
		CombatManager.respawn_points[character] = character.global_position


func set_player_name(n: String) -> void:
	player_name = n
	hp_bar.set_label(n)


func _physics_process(delta: float) -> void:
	if not CombatManager.active:
		return
	if is_dead:
		_process_respawn(delta)
		return
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	aiming_time = maxf(aiming_time - delta, 0.0)
	var input: PlayerInput = character.input
	_update_aim(input)
	if not GameState.sedang(GameState.State.BERMAIN):
		return
	for i in input.skill_pressed.size():
		if input.skill_pressed[i]:
			caster.try_cast(i)
	if input.shoot_held and _fire_cooldown <= 0.0:
		shoot()


## Arah bidik: titik mouse, atau bidik otomatis ke musuh terdekat; bantuan bidik sesuai kesulitan.
func _update_aim(input: PlayerInput) -> void:
	var origin: Vector3 = character.global_position
	var dir: Vector3 = aim_dir
	if input.has_aim_point:
		dir = input.aim_point - origin
	elif input.move_dir.length() > 0.2:
		dir = input.move_dir
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = aim_dir
	dir = dir.normalized()
	var target: Node3D = CombatManager.nearest_target(origin, CombatConst.AIM_ASSIST_RANGE, team)
	if target:
		var to_target: Vector3 = target.global_position - origin
		to_target.y = 0.0
		to_target = to_target.normalized()
		var assist: float = CombatManager.difficulty("aim_assist")
		if input.auto_aim and not input.has_aim_point:
			dir = to_target  # sentuh/bot: langsung ke musuh terdekat
		elif assist > 0.0 and dir.angle_to(to_target) < CombatConst.AIM_ASSIST_ANGLE * assist:
			dir = to_target  # bantuan bidik: tarik ke musuh bila hampir tepat
	aim_dir = dir


func shoot() -> void:
	_fire_cooldown = CombatConst.FIRE_INTERVAL * stats.fire_interval_multiplier()
	aiming_time = 0.6
	var from: Vector3 = character.global_position + Vector3(0, CombatConst.COMBAT_HEIGHT, 0) + aim_dir * 0.6
	Projectile.spawn(character.get_parent(), from, aim_dir, CombatConst.ARROW_SPEED,
			CombatConst.ARROW_DAMAGE * damage_multiplier(), team, character, CombatConst.ARROW_RANGE)
	character.model.lepas_panah()
	AudioManager.putar_sfx("busur", 0.15)
	shot.emit(aim_dir)


func _on_damaged(amount: float, _source: Node) -> void:
	var top: Vector3 = character.global_position + Vector3(0, 2.2, 0)
	Efek.angka_damage(character.get_parent(), top, amount)
	Efek.percikan_kena(character.get_parent(), character.global_position + Vector3(0, 1.2, 0))
	Efek.kilat(character.model)
	character.model.squash(Vector3(1.12, 0.88, 1.12), 0.2)
	get_tree().call_group("kamera_ikut", "guncang", 0.25)
	AudioManager.putar_sfx("terkena", 0.1)


func _on_died(_killer: Node) -> void:
	is_dead = true
	status.clear()
	respawn_left = CombatManager.respawn_time()
	character.velocity = Vector3.ZERO
	hp_bar.visible = false
	# Jatuh terduduk lalu memudar (tanpa darah/mayat)
	var tw := character.model.create_tween()
	tw.tween_property(character.model, "rotation:x", -1.2, 0.35).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(character.model, "scale", Vector3(1.0, 0.6, 1.0), 0.35)
	AudioManager.putar_sfx("salah")
	CombatManager.player_died.emit(character, respawn_left)


func _process_respawn(delta: float) -> void:
	respawn_left = maxf(respawn_left - delta, 0.0)
	if respawn_left <= 0.0:
		respawn()


## Hidup lagi di checkpoint terakhir dengan HP penuh dan kebal sesaat.
func respawn() -> void:
	is_dead = false
	character.velocity = Vector3.ZERO
	character.global_position = CombatManager.respawn_point(character) + Vector3(0, 0.3, 0)
	character.model.rotation.x = 0.0
	character.model.scale = Vector3.ONE
	health.revive()
	health.invulnerable_time = CombatConst.INVULNERABLE_AFTER_RESPAWN
	caster.energy = SkillCaster.MAX_ENERGY
	hp_bar.visible = true
	hp_bar.set_ratio(1.0)
	character.model.squash(Vector3(0.8, 1.25, 0.8), 0.35)
	Efek.kilau(character.get_parent(), character.global_position + Vector3(0, 1.2, 0))
	AudioManager.putar_sfx("ambil")
	CombatManager.player_respawned.emit(character)


## Aura emas berputar selama kebal (ultimate Semangat Leluhur).
func show_aura(duration: float) -> void:
	var aura := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.75
	t.outer_radius = 0.9
	t.rings = 24
	t.ring_segments = 4
	aura.mesh = t
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.82, 0.25, 0.7)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura.material_override = m
	aura.position.y = 0.15
	character.add_child(aura)
	var tw := aura.create_tween()
	tw.set_loops(int(ceil(duration / 0.5)))
	tw.tween_property(aura, "position:y", 2.2, 0.5)
	tw.tween_property(aura, "position:y", 0.15, 0.0)
	get_tree().create_timer(duration, false).timeout.connect(aura.queue_free)

