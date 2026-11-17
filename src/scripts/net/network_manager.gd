extends Node
## NetworkManager (autoload): multiplayer LAN 2-4 pemain (PC & Android bersama, tanpa internet).
## - Host membuat room (ENet server) dan mengumumkannya lewat LAN discovery.
## - Pemain lain menemukan room otomatis atau memasukkan IP host secara manual.
## - Lobi: nama pemain (dibuat unik oleh host), status siap; host memulai permainan.
## Host adalah otoritas: musuh, gelombang, dan damage dihitung di host (lihat NetArena).
## Di build web ENet tidak tersedia, jadi fitur ini dimatikan (available() = false).

signal lobby_changed
signal connection_failed(reason: String)
signal game_started
signal left(reason: String)

const PORT: int = 47101
const MAX_PLAYERS: int = 4
const VERSION: String = "3.1"

var players: Dictionary = {}  ## peer id -> {"name": String, "ready": bool}
var mode: String = "coop"  ## "coop" | "pvp"
var option: Dictionary = {"level": 1, "format": "1v1", "arena": "wae_rebo"}
var in_game: bool = false
var discovery: LanDiscovery


func _ready() -> void:
	discovery = LanDiscovery.new()
	add_child(discovery)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(func() -> void:
		_reset_peer()
		connection_failed.emit("Gagal tersambung ke host."))
	multiplayer.server_disconnected.connect(func() -> void:
		var was_in_game: bool = in_game
		_reset_peer()
		left.emit("Host menutup room." if was_in_game else "Koneksi ke host terputus."))


func available() -> bool:
	return not OS.has_feature("web") and ClassDB.class_exists("ENetMultiplayerPeer")


func is_online() -> bool:
	return multiplayer.has_multiplayer_peer() and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer \
			and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func is_host() -> bool:
	return is_online() and multiplayer.is_server()


func my_id() -> int:
	return multiplayer.get_unique_id() if is_online() else 1


# ------------------------------------------------------------------ host / gabung

func host() -> String:
	if not available():
		return "Main bersama tidak tersedia di versi web."
	leave()
	var peer: MultiplayerPeer = ClassDB.instantiate("ENetMultiplayerPeer")
	var err: int = peer.call("create_server", PORT, MAX_PLAYERS - 1)
	if err != OK:
		return "Tidak bisa membuat room (port %d dipakai?)." % PORT
	multiplayer.multiplayer_peer = peer
	players = {1: {"name": PlayerProfile.player_name, "ready": true}}
	discovery.start_announcing(_room_info())
	lobby_changed.emit()
	return ""


func join(ip: String) -> String:
	if not available():
		return "Main bersama tidak tersedia di versi web."
	leave()
	var peer: MultiplayerPeer = ClassDB.instantiate("ENetMultiplayerPeer")
	var err: int = peer.call("create_client", ip.strip_edges(), PORT)
	if err != OK:
		return "Alamat IP tidak valid."
	multiplayer.multiplayer_peer = peer
	return ""


func leave() -> void:
	discovery.stop_announcing()
	if is_online():
		multiplayer.multiplayer_peer.close()
	_reset_peer()


func _reset_peer() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	in_game = false
	discovery.stop_announcing()


## Alamat IP lokal perangkat ini (ditampilkan agar pemain lain bisa bergabung manual).
func local_ips() -> PackedStringArray:
	var hasil: PackedStringArray = []
	for a: String in IP.get_local_addresses():
		if a.begins_with("192.168.") or a.begins_with("10.") or a.begins_with("172."):
			hasil.append(a)
	return hasil


func _room_info() -> Dictionary:
	return {"name": PlayerProfile.player_name, "players": players.size(), "max": MAX_PLAYERS, "mode": mode,
			"port": PORT, "version": VERSION}


# ------------------------------------------------------------------ lobi

func _on_connected() -> void:
	_register.rpc_id(1, PlayerProfile.player_name, VERSION)


func _on_peer_connected(_id: int) -> void:
	pass


func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players.erase(id)
		if multiplayer.is_server():
			_sync_lobby.rpc(players, mode, option)
			discovery.update_announce(_room_info())
		lobby_changed.emit()


## Klien -> host: daftar dengan nama. Host membuat nama unik (Nggohak, Nggohak2) dan menyiarkan lobi.
@rpc("any_peer", "call_remote", "reliable")
func _register(wanted_name: String, version: String) -> void:
	if not multiplayer.is_server():
		return
	var id: int = multiplayer.get_remote_sender_id()
	if in_game or players.size() >= MAX_PLAYERS or version != VERSION:
		_kick.rpc_id(id, "Room penuh / permainan sudah dimulai / versi berbeda.")
		return
	var taken: Array = []
	for p: Dictionary in players.values():
		taken.append(p["name"])
	var clean: String = wanted_name if PlayerProfile.validate(wanted_name) == "" else "Pemain"
	players[id] = {"name": PlayerProfile.unique_name(clean, taken), "ready": false}
	_sync_lobby.rpc(players, mode, option)
	discovery.update_announce(_room_info())
	lobby_changed.emit()


@rpc("authority", "call_remote", "reliable")
func _kick(reason: String) -> void:
	leave()
	connection_failed.emit(reason)


@rpc("authority", "call_remote", "reliable")
func _sync_lobby(p: Dictionary, m: String, o: Dictionary) -> void:
	players = p
	mode = m
	option = o
	lobby_changed.emit()


func set_ready(value: bool) -> void:
	if multiplayer.is_server():
		players[1]["ready"] = value
		_sync_lobby.rpc(players, mode, option)
		lobby_changed.emit()
	else:
		_set_ready.rpc_id(1, value)


@rpc("any_peer", "call_remote", "reliable")
func _set_ready(value: bool) -> void:
	var id: int = multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and players.has(id):
		players[id]["ready"] = value
		_sync_lobby.rpc(players, mode, option)
		lobby_changed.emit()


## Host mengubah mode (coop/pvp) dan opsi (level, format 1v1/2v2/bebas, arena).
func configure(new_mode: String, new_option: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	mode = new_mode
	option = new_option
	_sync_lobby.rpc(players, mode, option)
	discovery.update_announce(_room_info())
	lobby_changed.emit()


func all_ready() -> bool:
	for p: Dictionary in players.values():
		if not p["ready"]:
			return false
	return true


func start_game() -> void:
	if not multiplayer.is_server():
		return
	_start.rpc(mode, option)


@rpc("authority", "call_local", "reliable")
func _start(m: String, o: Dictionary) -> void:
	mode = m
	option = o
	in_game = true
	if multiplayer.is_server():
		discovery.update_announce(_room_info())
	game_started.emit()
	Transisi.pindah_scene("res://scenes/net/net_arena.tscn")


## Kembali ke lobi setelah pertandingan (host memanggil untuk semua).
@rpc("authority", "call_local", "reliable")
func back_to_lobby() -> void:
	in_game = false
	for id: int in players:
		players[id]["ready"] = id == 1
	CombatManager.set_active(false)
	Transisi.pindah_scene("res://scenes/lobby.tscn")


func player_name(id: int) -> String:
	return str(players.get(id, {}).get("name", "Pemain"))
