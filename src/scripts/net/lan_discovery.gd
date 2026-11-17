class_name LanDiscovery
extends Node
## Penemuan room di jaringan lokal (WiFi / hotspot HP yang sama) lewat UDP broadcast.
## Host mengumumkan room tiap detik; pemain lain mendengarkan dan menampilkan daftar room.
## Tanpa server internet. Cadangan bila broadcast diblokir jaringan: masukkan IP host manual.

signal rooms_changed(rooms: Dictionary)

const PORT: int = 47100
const GAME_TAG: String = "JejakPentiLAN"
const ANNOUNCE_INTERVAL: float = 1.0
const ROOM_TIMEOUT: float = 3.5

var rooms: Dictionary = {}  ## ip -> {name, players, max, mode, port, seen}
var _sender: PacketPeerUDP
var _listener: PacketPeerUDP
var _announce: Dictionary = {}
var _t: float = 0.0


func start_announcing(info: Dictionary) -> void:
	_announce = info
	if _sender == null:
		_sender = PacketPeerUDP.new()
		_sender.set_broadcast_enabled(true)
		_sender.set_dest_address("255.255.255.255", PORT)


func update_announce(info: Dictionary) -> void:
	_announce = info


func stop_announcing() -> void:
	_announce = {}
	if _sender:
		_sender.close()
		_sender = null


func start_listening() -> bool:
	stop_listening()
	_listener = PacketPeerUDP.new()
	var err: Error = _listener.bind(PORT, "*")
	if err != OK:
		_listener = null
		return false
	return true


func stop_listening() -> void:
	if _listener:
		_listener.close()
		_listener = null
	rooms.clear()


func _process(delta: float) -> void:
	_t += delta
	if _sender and not _announce.is_empty() and _t >= ANNOUNCE_INTERVAL:
		_t = 0.0
		var data: Dictionary = _announce.duplicate()
		data["tag"] = GAME_TAG
		_sender.put_packet(JSON.stringify(data).to_utf8_buffer())
	if _listener == null:
		return
	var changed: bool = false
	while _listener.get_available_packet_count() > 0:
		var pkt: PackedByteArray = _listener.get_packet()
		var ip: String = _listener.get_packet_ip()
		var parsed: Variant = JSON.parse_string(pkt.get_string_from_utf8())
		if parsed is Dictionary and (parsed as Dictionary).get("tag", "") == GAME_TAG:
			var info: Dictionary = parsed
			info["seen"] = Time.get_ticks_msec()
			changed = changed or not rooms.has(ip)
			rooms[ip] = info
	var now: int = Time.get_ticks_msec()
	for ip: String in rooms.keys():
		if now - int(rooms[ip]["seen"]) > ROOM_TIMEOUT * 1000.0:
			rooms.erase(ip)
			changed = true
	if changed:
		rooms_changed.emit(rooms)
