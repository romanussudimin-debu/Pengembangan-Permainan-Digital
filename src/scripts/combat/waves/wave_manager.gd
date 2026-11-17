class_name WaveManager
extends Node
## Menjalankan gelombang musuh (WaveData) di sekitar pemain, termasuk gelombang bos.
## - Musuh muncul bertahap di titik bebas rintangan 9-14 m dari pemain (bukan di zona terlarang,
##   mis. compang yang sakral).
## - Jenis musuh baru diumumkan dengan kiatnya (banner HUD) saat pertama muncul.
## - Jumlah musuh diskalakan untuk co-op. Hanya otoritas (host) yang memunculkan musuh.
## Dipakai level cerita (satu gelombang per pemicu) dan arena co-op (run_encounter: berurutan + Lapak).

signal wave_started(index: int)
signal wave_cleared(index: int)
signal encounter_finished

const SPAWN_MIN: float = 9.0
const SPAWN_MAX: float = 14.0

var world: Node3D  ## tempat musuh ditambahkan
var forbidden_zones: Array[Vector4] = []  ## (x, z, radius, 0): musuh tidak muncul di sini
var running: bool = false
var current_index: int = -1
var _alive: Array[EnemyBase] = []
var _pending: int = 0
var _seen_types: Dictionary = {}
var _encounter: EncounterData
var spawn_log: Array[Vector3] = []  ## titik muncul gelombang terakhir (uji & debug)


func _init(target_world: Node3D = null) -> void:
	world = target_world


## Memulai satu gelombang. Tempur aktif sampai semua musuh gelombang ini kalah/kabur.
func start_wave(wave: WaveData, index: int, total_waves: int = 3) -> void:
	if not CombatManager.is_authority():
		return
	running = true
	current_index = index
	CombatManager.set_active(true)
	for p: Node3D in CombatManager.players:
		CombatManager.set_respawn_point(p, p.global_position)
	var title: String = "BOS!" if wave.boss else "Gelombang %d/%d" % [index + 1, total_waves]
	CombatManager.announce.emit(title, wave.title)
	AudioManager.putar_sfx("gong")
	wave_started.emit(index)
	spawn_log.clear()
	var queue: Array[EnemyData] = []
	var n_players: int = maxi(CombatManager.players.size(), 1)
	for i in wave.enemies.size():
		for k in wave.scaled_count(i, n_players):
			queue.append(wave.enemies[i])
	queue.shuffle()
	if wave.boss:
		queue.push_front(wave.boss)
	_pending = queue.size()
	for i in queue.size():
		await get_tree().create_timer(0.9 if i == 0 else wave.spawn_delay, false).timeout
		if not is_inside_tree() or not running:
			return
		_spawn(queue[i], wave.boss == queue[i])


func _spawn(d: EnemyData, is_boss: bool) -> void:
	_pending -= 1
	var titik: Vector3 = find_spawn_point(d)
	spawn_log.append(titik)
	var e: EnemyBase = EnemyBase.spawn(world, d, titik)
	e.detect_override = 60.0  # musuh gelombang langsung memburu pemain
	e.from_wave = true
	_alive.append(e)
	e.defeated.connect(_on_defeated)
	Efek.debu(world, e.global_position + Vector3(0, 0.3, 0))
	if is_boss:
		CombatManager.set_boss(e)
	elif not _seen_types.has(d.id):
		_seen_types[d.id] = true
		if d.hint != "":
			CombatManager.announce.emit("Musuh baru: " + d.display_name, d.hint)


func _on_defeated(e: EnemyBase) -> void:
	_alive.erase(e)
	if e == CombatManager.boss:
		CombatManager.set_boss(null)
	if _alive.is_empty() and _pending <= 0 and running:
		_finish_wave()


func _finish_wave() -> void:
	running = false
	# Bersihkan sisa antek (mis. panggilan bos) agar tidak tertinggal di dunia cerita
	for e: Node3D in CombatManager.enemies.duplicate():
		if is_instance_valid(e) and e.get("from_wave"):
			(e as EnemyBase).health.take_damage(99999, null)
	CombatManager.announce.emit("Gelombang selesai!", "")
	AudioManager.putar_sfx("berhasil")
	wave_cleared.emit(current_index)


## Titik muncul acak di sekitar pemain: ada tanah di bawahnya, tidak di dalam bangunan/batu,
## dan tidak di zona terlarang. Ubur-ubur & penyergap dimunculkan lebih dekat.
func find_spawn_point(d: EnemyData) -> Vector3:
	var anchor: Vector3 = _players_center()
	var space := world.get_world_3d().direct_space_state
	var near: bool = d.ambush_range > 0.0 or d.move_speed <= 0.0
	var rmin: float = 4.0 if near else SPAWN_MIN
	var rmax: float = 7.0 if near else SPAWN_MAX
	for attempt in 24:
		var a: float = randf() * TAU
		var r: float = randf_range(rmin, rmax)
		var p: Vector3 = anchor + Vector3(cos(a) * r, 0, sin(a) * r)
		if _in_forbidden(p):
			continue
		var ray := PhysicsRayQueryParameters3D.create(p + Vector3(0, 4, 0), p + Vector3(0, -6, 0), CombatConst.LAYER_WORLD)
		var hit: Dictionary = space.intersect_ray(ray)
		if hit.is_empty():
			continue
		var ground: Vector3 = hit["position"]
		if absf(ground.y - anchor.y) > 2.5:
			continue  # hindari tebing / atap
		var shape := SphereShape3D.new()
		shape.radius = 0.7 * d.scale
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = shape
		q.transform = Transform3D(Basis.IDENTITY, ground + Vector3(0, 1.1 * d.scale, 0))
		q.collision_mask = CombatConst.LAYER_WORLD
		if space.intersect_shape(q, 1).is_empty():
			return ground + Vector3(0, 0.1, 0)
	# Cadangan: titik mana pun di sekitar pemain yang tidak berada di zona terlarang
	for attempt in 12:
		var a2: float = randf() * TAU
		var p2: Vector3 = anchor + Vector3(cos(a2), 0, sin(a2)) * rmax
		if not _in_forbidden(p2):
			return p2 + Vector3(0, 0.2, 0)
	return anchor + Vector3(0, 0.2, 0)


func _in_forbidden(p: Vector3) -> bool:
	for z: Vector4 in forbidden_zones:
		if Vector2(p.x - z.x, p.z - z.y).length() < z.z:
			return true
	return false


func _players_center() -> Vector3:
	var sum := Vector3.ZERO
	var n: int = 0
	for p: Node3D in CombatManager.players:
		if is_instance_valid(p) and p.is_inside_tree():
			sum += p.global_position
			n += 1
	return sum / n if n > 0 else Vector3.ZERO


## Arena co-op: semua gelombang berurutan dengan jeda Lapak Songke di antaranya, lalu bos.
func run_encounter(enc: EncounterData) -> void:
	_encounter = enc
	_seen_types.clear()
	for i in enc.waves.size():
		start_wave(enc.waves[i], i, enc.waves.size() - 1 if enc.waves[-1].boss else enc.waves.size())
		await wave_cleared
		if i < enc.waves.size() - 1:
			CombatManager.set_shop_available(true)
			var t: float = enc.break_time
			while t > 0.0 and is_inside_tree():
				CombatManager.break_time_left = t
				await get_tree().create_timer(0.5, false).timeout
				if GameState.sedang(GameState.State.BERMAIN):
					t -= 0.5
			CombatManager.break_time_left = 0.0
			CombatManager.set_shop_available(false)
	CombatManager.set_active(false)
	encounter_finished.emit()
