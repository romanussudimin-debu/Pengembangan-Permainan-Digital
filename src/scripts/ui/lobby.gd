extends Control
## Layar "Main Bersama": buat room (host) / temukan room di LAN / gabung lewat IP, lalu lobi
## (nama pemain, siap/tidak, pengaturan mode oleh host). Juga "Latihan PvP" melawan bot tanpa jaringan
## (bisa dimainkan di semua platform termasuk web).

const MODE_LABEL: Dictionary = {"coop": "Co-op melawan musuh", "pvp": "PvP Arena"}
const ARENA_LABEL: Dictionary = {"wae_rebo": "Wae Rebo", "lingko": "Lingko Lodok", "labuan_bajo": "Labuan Bajo"}
const FORMAT_LABEL: Dictionary = {"1v1": "1 lawan 1", "2v2": "2 lawan 2", "bebas": "Bebas (4)"}

var _panel: NinePatchRect
var _body: Control
var _status: Label
var _rooms_box: VBoxContainer
var _ip_edit: LineEdit
var _ready_state: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	GameState.ubah_state(GameState.State.MENU)
	var bg := ColorRect.new()
	bg.color = Color("1b1214")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_panel = Gaya.panel_songke(Vector2(20, 12), Vector2(600, 336))
	add_child(_panel)
	_status = Gaya.label("", 9, Color("ff9a70"))
	_status.position = Vector2(20, 300)
	_status.size = Vector2(380, 16)
	_panel.add_child(_status)
	NetworkManager.lobby_changed.connect(_refresh)
	NetworkManager.connection_failed.connect(func(r: String) -> void:
		_status.text = r
		_show_start())
	NetworkManager.left.connect(func(r: String) -> void:
		_status.text = r
		_show_start())
	NetworkManager.discovery.rooms_changed.connect(func(_r: Dictionary) -> void: _fill_rooms())
	if NetworkManager.is_online():
		_show_lobby()
	else:
		_show_start()


func _clear() -> void:
	if _body:
		_body.queue_free()
	_body = Control.new()
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_body)


func _btn(text: String, pos: Vector2, w: float, cb: Callable, parent: Control = null) -> Button:
	var b := Gaya.tombol(text)
	b.position = pos
	b.custom_minimum_size = Vector2(w, 28)
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(cb)
	(parent if parent else _body).add_child(b)
	return b


func _lbl(text: String, pos: Vector2, size: int = 10, color: Color = Gaya.PUTIH) -> Label:
	var l := Gaya.label(text, size, color)
	l.position = pos
	_body.add_child(l)
	return l


# ------------------------------------------------------------------ layar awal

func _show_start() -> void:
	_clear()
	_lbl("Main Bersama", Vector2(20, 12), 18, Gaya.KUNING)
	_lbl("Pemain: %s" % PlayerProfile.player_name, Vector2(380, 18), 10, Gaya.KUNING)
	if not NetworkManager.available():
		_lbl("Main bersama lewat WiFi tersedia di aplikasi PC & Android.\nDi versi web kamu bisa berlatih PvP melawan bot.",
				Vector2(20, 50), 10)
	else:
		_lbl("Semua perangkat harus tersambung ke WiFi / hotspot HP yang sama.", Vector2(20, 44), 9, Color("d8d2c4"))
		_btn("Buat Room (Host)", Vector2(20, 66), 200, _host)
		_lbl("Room yang ditemukan:", Vector2(240, 66), 10, Gaya.KUNING)
		_rooms_box = VBoxContainer.new()
		_rooms_box.position = Vector2(240, 84)
		_rooms_box.custom_minimum_size = Vector2(330, 120)
		_rooms_box.add_theme_constant_override("separation", 4)
		_body.add_child(_rooms_box)
		NetworkManager.discovery.start_listening()
		_fill_rooms()
		_lbl("Atau masukkan IP host:", Vector2(20, 108), 9)
		_ip_edit = LineEdit.new()
		_ip_edit.position = Vector2(20, 126)
		_ip_edit.size = Vector2(200, 28)
		_ip_edit.placeholder_text = "192.168.43.1"
		_ip_edit.virtual_keyboard_enabled = true
		_body.add_child(_ip_edit)
		_btn("Gabung", Vector2(20, 160), 200, func() -> void: _join(_ip_edit.text))
	_btn("Latihan PvP vs Bot", Vector2(20, 214), 200, _practice)
	_btn("Kembali", Vector2(20, 252), 200, func() -> void:
		NetworkManager.discovery.stop_listening()
		NetworkManager.leave()
		Transisi.pindah_scene("res://scenes/main_menu.tscn"))


func _fill_rooms() -> void:
	if _rooms_box == null or not is_instance_valid(_rooms_box):
		return
	for c in _rooms_box.get_children():
		c.queue_free()
	var rooms: Dictionary = NetworkManager.discovery.rooms
	if rooms.is_empty():
		var l := Gaya.label("Mencari room di jaringan...", 9, Color("c9c2b0"))
		_rooms_box.add_child(l)
		return
	for ip: String in rooms:
		var r: Dictionary = rooms[ip]
		var text: String = "%s  (%d/%d)  %s" % [r.get("name", "?"), int(r.get("players", 1)), int(r.get("max", 4)),
				MODE_LABEL.get(r.get("mode", "coop"), "")]
		var b := Gaya.tombol(text)
		b.custom_minimum_size = Vector2(330, 26)
		b.add_theme_font_size_override("font_size", 10)
		b.pressed.connect(_join.bind(ip))
		_rooms_box.add_child(b)


func _host() -> void:
	var err: String = NetworkManager.host()
	if err != "":
		_status.text = err
		return
	NetworkManager.discovery.stop_listening()
	_show_lobby()


func _join(ip: String) -> void:
	if ip.strip_edges() == "":
		_status.text = "Masukkan IP host dulu."
		return
	var err: String = NetworkManager.join(ip)
	if err != "":
		_status.text = err
		return
	_status.text = "Menyambung ke %s..." % ip
	NetworkManager.discovery.stop_listening()
	_show_lobby()


## Latihan tanpa jaringan: PvP 1v1 melawan bot di arena Wae Rebo.
func _practice() -> void:
	NetworkManager.discovery.stop_listening()
	NetworkManager.leave()
	NetworkManager.mode = "pvp"
	NetworkManager.option = {"level": 1, "format": "1v1", "arena": "wae_rebo"}
	Transisi.pindah_scene("res://scenes/net/net_arena.tscn")


# ------------------------------------------------------------------ lobi

func _show_lobby() -> void:
	_clear()
	_ready_state = NetworkManager.multiplayer.is_server()
	_refresh()


func _refresh() -> void:
	if not NetworkManager.is_online() and not NetworkManager.multiplayer.has_multiplayer_peer():
		return
	_clear()
	var host: bool = NetworkManager.multiplayer.is_server()
	_lbl("Lobi", Vector2(20, 12), 18, Gaya.KUNING)
	if host:
		var ips: PackedStringArray = NetworkManager.local_ips()
		_lbl("IP host: %s" % (", ".join(ips) if not ips.is_empty() else "-"), Vector2(140, 18), 10, Gaya.KUNING)
	var y: float = 48.0
	var ids: Array = NetworkManager.players.keys()
	ids.sort()
	if ids.is_empty():
		_lbl("Menunggu tersambung...", Vector2(20, y), 10)
	for id: int in ids:
		var p: Dictionary = NetworkManager.players[id]
		var tanda: String = "Host" if id == 1 else ("Siap" if p["ready"] else "Belum siap")
		_lbl("%s%s  —  %s" % ["» " if id == NetworkManager.my_id() else "", p["name"], tanda], Vector2(24, y), 11,
				Gaya.KUNING if id == NetworkManager.my_id() else Gaya.PUTIH)
		y += 22.0
	# Pengaturan permainan
	var m: String = NetworkManager.mode
	var o: Dictionary = NetworkManager.option
	var x: float = 330.0
	_lbl("Mode: " + MODE_LABEL[m], Vector2(x, 48), 11, Gaya.KUNING)
	if m == "coop":
		_lbl("Level: %d (%s)" % [int(o.get("level", 1)), ARENA_LABEL[ArenaBuilder.theme_for_level(int(o.get("level", 1)))]], Vector2(x, 68), 10)
	else:
		_lbl("Format: %s · Arena: %s" % [FORMAT_LABEL.get(o.get("format", "1v1")), ARENA_LABEL.get(o.get("arena", "wae_rebo"))],
				Vector2(x, 68), 10)
		_lbl("Slot kosong diisi bot.", Vector2(x, 84), 9, Color("c9c2b0"))
	if host:
		_btn("Ganti Mode", Vector2(x, 104), 120, func() -> void:
			NetworkManager.configure("pvp" if m == "coop" else "coop", o))
		if m == "coop":
			_btn("Level", Vector2(x + 126, 104), 120, func() -> void:
				var o2: Dictionary = o.duplicate()
				o2["level"] = int(o.get("level", 1)) % 3 + 1
				NetworkManager.configure(m, o2))
		else:
			_btn("Format", Vector2(x + 126, 104), 120, func() -> void:
				var urutan: Array = ["1v1", "2v2", "bebas"]
				var o2: Dictionary = o.duplicate()
				o2["format"] = urutan[(urutan.find(o.get("format", "1v1")) + 1) % 3]
				NetworkManager.configure(m, o2))
			_btn("Arena", Vector2(x, 138), 120, func() -> void:
				var urutan2: Array = ["wae_rebo", "lingko", "labuan_bajo"]
				var o3: Dictionary = o.duplicate()
				o3["arena"] = urutan2[(urutan2.find(o.get("arena", "wae_rebo")) + 1) % 3]
				NetworkManager.configure(m, o3))
		var mulai := _btn("Mulai!", Vector2(x, 214), 246, NetworkManager.start_game)
		mulai.disabled = not NetworkManager.all_ready()
		if mulai.disabled:
			_lbl("Menunggu semua pemain siap...", Vector2(x, 246), 9, Color("c9c2b0"))
	else:
		_btn("Belum Siap" if _ready_state else "Siap!", Vector2(x, 214), 246, func() -> void:
			_ready_state = not _ready_state
			NetworkManager.set_ready(_ready_state)
			_refresh())
	_btn("Keluar Room", Vector2(20, 252), 200, func() -> void:
		NetworkManager.leave()
		_show_start())
