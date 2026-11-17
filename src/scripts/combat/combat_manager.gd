extends Node
## CombatManager (autoload): pusat sistem tempur. Tidak menyimpan "satu pemain";
## semua pemain dan musuh didaftarkan ke daftar, sehingga siap untuk co-op/PvP.
## Otoritas damage: host (multiplayer.is_server(); di mode Solo selalu true).

signal combat_changed(active: bool)
signal player_died(player: Node3D, respawn_time: float)
signal player_respawned(player: Node3D)
signal rewards_changed(player: Node3D)

var active: bool = false
var players: Array[Node3D] = []
var enemies: Array[Node3D] = []
var _respawn_points: Dictionary = {}  ## pemain -> Vector3 (checkpoint terakhir)
var _coins: Dictionary = {}  ## pemain -> int (koin sesi tempur; toko di Tahap 3)
var _xp: Dictionary = {}  ## pemain -> int


func is_authority() -> bool:
	return multiplayer.is_server()


func set_active(value: bool) -> void:
	if active == value:
		return
	active = value
	combat_changed.emit(active)


# ------------------------------------------------------------------ kesulitan

## Kunci kesulitan aktif. Tahap 6 menambah pilihan Mudah; sekarang mengikuti Mode Normal/Sulit lama.
func difficulty_key() -> String:
	var key: String = str(GameState.get("kesulitan")) if GameState.get("kesulitan") != null else ""
	if CombatConst.DIFFICULTY.has(key):
		return key
	return "sulit" if GameState.mode_sulit else "normal"


func difficulty(stat: String) -> float:
	return float(CombatConst.DIFFICULTY[difficulty_key()][stat])


## Pengali HP/jumlah musuh untuk co-op: 1 + 0,5 per pemain tambahan (Tahap 7).
func enemy_hp_scale() -> float:
	return 1.0 + 0.5 * maxi(players.size() - 1, 0) if players.size() > 1 else 1.0


# ------------------------------------------------------------------ pendaftaran

func register_player(p: Node3D) -> void:
	if not players.has(p):
		players.append(p)
		_coins[p] = 0
		_xp[p] = 0


func unregister_player(p: Node3D) -> void:
	players.erase(p)
	_respawn_points.erase(p)
	_coins.erase(p)
	_xp.erase(p)


func register_enemy(e: Node3D) -> void:
	if not enemies.has(e):
		enemies.append(e)


func unregister_enemy(e: Node3D) -> void:
	enemies.erase(e)


func alive_enemies() -> int:
	var n: int = 0
	for e: Node3D in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			n += 1
	return n


# ------------------------------------------------------------------ pencarian target

func nearest_enemy(from: Vector3, max_distance: float) -> Node3D:
	return _nearest(enemies, from, max_distance)


func nearest_player(from: Vector3, max_distance: float) -> Node3D:
	return _nearest(players, from, max_distance)


func _nearest(list: Array[Node3D], from: Vector3, max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_d: float = max_distance
	for n: Node3D in list:
		if not is_instance_valid(n) or not n.is_inside_tree() or n.get("is_dead") or _combat_dead(n):
			continue
		var d: float = n.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = n
	return best


func _combat_dead(n: Node3D) -> bool:
	var c: Variant = n.get("combat")
	return c != null and (c as Node).get("is_dead") == true


# ------------------------------------------------------------------ respawn & hadiah

func set_respawn_point(p: Node3D, point: Vector3) -> void:
	_respawn_points[p] = point


func respawn_point(p: Node3D) -> Vector3:
	return _respawn_points.get(p, p.global_position)


func respawn_time() -> float:
	return difficulty("respawn")


func add_reward(p: Node3D, coins: int, xp: int) -> void:
	if not _coins.has(p):
		return
	_coins[p] = int(_coins[p]) + coins
	_xp[p] = int(_xp[p]) + xp
	rewards_changed.emit(p)


func coins_of(p: Node3D) -> int:
	return int(_coins.get(p, 0))


func xp_of(p: Node3D) -> int:
	return int(_xp.get(p, 0))
