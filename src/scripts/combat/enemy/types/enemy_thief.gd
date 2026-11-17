class_name EnemyThief
extends EnemyBase
## Pencuri (kera, monyet, perampok padi, penyelundup kain): menyambar koin pemain lalu kabur.
## Kalahkan sebelum lolos untuk merebut kembali curiannya (dijatuhkan sebagai koin).
## data.fly_height > 0 = memanjat pohon/tebing setelah kabur sebentar (sulit dijangkau panah).

var stolen: int = 0
var _flee_t: float = 0.0
var _climb: float = 0.0


func _setup() -> void:
	hitbox.landed.connect(_on_landed)


func _on_landed(target_hb: Hurtbox) -> void:
	if stolen > 0 or not target_hb.entity in CombatManager.players:
		return
	var st: CombatStats = CombatManager.stats_for(target_hb.entity)
	var amount: int = mini(data.steal_coins, st.coins)
	if amount <= 0:
		return
	st.add_coins(-amount)
	stolen = amount
	bonus_coins = amount
	Efek.teks(get_parent(), target_hb.entity.global_position + Vector3(0, 2.6, 0), "-%d %s!" % [amount, data.steal_label], Color("ff8a60"))
	AudioManager.putar_sfx("ambil", 0.3)
	_flee_t = 0.0
	_change_state(State.FLEE)


func _process_flee(delta: float) -> void:
	_flee_t += delta
	var p: Node3D = CombatManager.nearest_player(global_position, 60.0)
	if p:
		var away: Vector3 = global_position - p.global_position
		away.y = 0.0
		_move(away.normalized() * data.move_speed * 1.35, delta)
		_face(global_position + away, delta)
	if data.fly_height > 0.0 and _flee_t > 1.5:
		_climb = minf(_climb + delta * 1.6, data.fly_height)  # memanjat
	if _flee_t >= data.flee_time and (p == null or global_position.distance_to(p.global_position) > 9.0):
		_escape()


func _after_physics(_delta: float) -> void:
	if data.fly_height <= 0.0:
		return
	gravity_enabled = _climb <= 0.0
	if _climb > 0.0:
		velocity.y = (home.y + _climb - global_position.y) * 6.0


## Lolos membawa curian: menghilang tanpa menjatuhkan hadiah.
func _escape() -> void:
	is_dead = true
	targetable = false
	hp_bar.visible = false
	Efek.teks(get_parent(), global_position + Vector3(0, 2.5, 0), "Kabur membawa %d %s!" % [stolen, data.steal_label], Color("c9c2b0"))
	CombatManager.unregister_enemy(self)
	defeated.emit(self)
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3.ONE * 0.01, 0.4)
	tw.tween_callback(queue_free)
