extends Node
## PlayerProfile (autoload): nama pemain yang tampil di atas kepala Nggohak, di lobi multiplayer,
## papan skor PvP, dan layar menang. Disimpan di user://player_profile.cfg.

signal name_changed(new_name: String)

const FILE: String = "user://player_profile.cfg"
const DEFAULT_NAME: String = "Nggohak"
const MIN_LEN: int = 3
const MAX_LEN: int = 12

var player_name: String = DEFAULT_NAME
var has_saved: bool = false  ## false = layar "Isi Nama" muncul saat pertama kali bermain


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(FILE) == OK:
		var n: String = str(cfg.get_value("profil", "nama", DEFAULT_NAME))
		if validate(n) == "":
			player_name = clean(n)
			has_saved = true


## Hapus spasi di awal/akhir dan rapatkan spasi ganda.
static func clean(raw: String) -> String:
	var s: String = raw.strip_edges()
	while s.contains("  "):
		s = s.replace("  ", " ")
	return s


## "" bila valid; selain itu pesan kesalahan untuk ditampilkan.
static func validate(raw: String) -> String:
	var s: String = clean(raw)
	if s.length() < MIN_LEN:
		return "Nama minimal 3 huruf"
	if s.length() > MAX_LEN:
		return "Nama maksimal 12 karakter"
	var re := RegEx.new()
	re.compile("^[A-Za-z0-9 ]+$")
	if re.search(s) == null:
		return "Hanya huruf, angka, dan spasi"
	return ""


func set_player_name(raw: String) -> bool:
	if validate(raw) != "":
		return false
	player_name = clean(raw)
	has_saved = true
	var cfg := ConfigFile.new()
	cfg.set_value("profil", "nama", player_name)
	cfg.save(FILE)
	name_changed.emit(player_name)
	return true


## Nama unik di satu room: Nggohak, Nggohak2, Nggohak3, ... (dipakai host saat pemain bergabung).
static func unique_name(wanted: String, taken: Array) -> String:
	var base: String = clean(wanted)
	if not taken.has(base):
		return base
	var i: int = 2
	while taken.has("%s%d" % [base.left(MAX_LEN - 1), i]):
		i += 1
	return "%s%d" % [base.left(MAX_LEN - 1), i]
