extends Node
## CombatManager (autoload): pusat sistem tempur. Tidak menyimpan "satu pemain";
## semua pemain dan musuh didaftarkan ke daftar, sehingga siap untuk co-op/PvP.
## Otoritas damage: host (multiplayer.is_server(); di mode Solo selalu true).

signal combat_changed(active: bool)
signal player_died(player: Node3D, respawn_time: float)
signal player_respawned(player: Node3D)
signal rewards_changed(player: Node3D)
signal leveled_up(player: Node3D, level: int)
signal shop_changed(available: bool)
signal announce(title: String, subtitle: String)  ## banner HUD (gelombang, musuh baru, bos)
signal boss_changed(boss: Node3D)

## Barang Lapak Songke (daftar eksplisit agar aman di build ekspor).
const SHOP_ITEMS: Array[ShopItem] = [
	preload("res://data/combat/shop/01_mata_panah.tres"),
	preload("res://data/combat/shop/02_tali_busur.tres"),
	preload("res://data/combat/shop/03_sarung_tebal.tres"),
	preload("res://data/combat/shop/04_ikat_leluhur.tres"),
	preload("res://data/combat/shop/05_sirih_pinang.tres"),
	preload("res://data/combat/shop/06_gelang_kaki.tres"),
	preload("res://data/combat/shop/07_kopi_wae_rebo.tres"),
]

var active: bool = false
var players: Array[Node3D] = []
var enemies: Array[Node3D] = []
var _respawn_points: Dictionary = {}  ## pemain -> Vector3 (checkpoint terakhir)
var _stats: Dictionary = {}  ## peer id -> CombatStats (progres per level cerita)
var _session_level: int = -1
var shop_available: bool = false  ## true saat jeda antar-gelombang (Lapak Songke boleh dibuka)
var break_time_left: float = 0.0  ## sisa jeda antar-gelombang (ditampilkan HUD)
var boss: Node3D  ## bos yang sedang dilawan (bar HP besar di HUD)
var story_waves_done: Dictionary = {}  ## "level:gelombang" -> true (sesi level cerita)


func is_authority() -> bool:
	return multiplayer.is_server()


func set_active(value: bool) -> void:
	if active == value:
		return
	active = value
	if not active:
		set_shop_available(false)
	combat_changed.emit(active)


func set_boss(b: Node3D) -> void:
	boss = b
	boss_changed.emit(b)


func set_shop_available(value: bool) -> void:
	if shop_available == value:
		return
	shop_available = value
	shop_changed.emit(value)


# ------------------------------------------------------------------ kesulitan

## Kunci kesulitan aktif. Tahap 6 menambah pilihan Mudah; sekarang mengikuti Mode Normal/Sulit lama.
func _difficulty_key() -> String:
	var key: String = str(GameState.get("kesulitan")) if GameState.get("kesulitan") != null else ""
	if CombatConst.DIFFICULTY.has(key):
		return key
	return "sulit" if GameState.mode_sulit else "normal"


func difficulty(stat: String) -> float:
	return float(CombatConst.DIFFICULTY[_difficulty_key()][stat])


## Pengali HP/jumlah musuh untuk co-op: 1 + 0,5 per pemain tambahan (Tahap 7).
func enemy_hp_scale() -> float:
	return 1.0 + 0.5 * maxi(players.size() - 1, 0) if players.size() > 1 else 1.0


# ------------------------------------------------------------------ pendaftaran

func register_player(p: Node3D) -> void:
	if not players.has(p):
		players.append(p)


func unregister_player(p: Node3D) -> void:
	players.erase(p)
	_respawn_points.erase(p)


# ------------------------------------------------------------------ progres (level, XP, koin)

## Progres tempur milik pemain (dibuat bila belum ada). Direset saat level cerita berganti.
func stats_for(p: Node3D) -> CombatStats:
	if GameState.level != _session_level:
		reset_session()
	var key: int = int(p.get("peer_id")) if p.get("peer_id") != null else 1
	if not _stats.has(key):
		var st := CombatStats.new()
		st.leveled_up.connect(func(lv: int) -> void: _on_level_up(key, lv))
		_stats[key] = st
	return _stats[key]


func reset_session() -> void:
	_stats.clear()
	story_waves_done.clear()
	_session_level = GameState.level


func _on_level_up(key: int, lv: int) -> void:
	for p: Node3D in players:
		if is_instance_valid(p) and (int(p.get("peer_id")) if p.get("peer_id") != null else 1) == key:
			leveled_up.emit(p, lv)


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
		if not is_instance_valid(n) or not n.is_inside_tree() or n.get("is_dead") or is_combat_dead(n) \
				or n.get("targetable") == false:
			continue
		var d: float = n.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = n
	return best


## true bila `n` adalah pemain yang sedang kalah (menunggu respawn).
func is_combat_dead(n: Node3D) -> bool:
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
	if not players.has(p):
		return
	var st: CombatStats = stats_for(p)
	st.add_coins(coins)
	st.add_xp(xp)
	rewards_changed.emit(p)

