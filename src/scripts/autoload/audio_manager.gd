extends Node
## Mengelola musik latar (dengan fade) dan efek suara melalui bus Musik & SFX.

const MUSIK: Dictionary = {
	"kampung": preload("res://assets/audio/musik_kampung.wav"),
	"caci": preload("res://assets/audio/musik_caci.wav"),
}

const SFX: Dictionary = {
	"cambuk": preload("res://assets/audio/cambuk.wav"),
	"perisai": preload("res://assets/audio/perisai.wav"),
	"terkena": preload("res://assets/audio/terkena.wav"),
	"lompat": preload("res://assets/audio/lompat.wav"),
	"langkah": preload("res://assets/audio/langkah.wav"),
	"ambil": preload("res://assets/audio/ambil.wav"),
	"berhasil": preload("res://assets/audio/berhasil.wav"),
	"gagal": preload("res://assets/audio/gagal.wav"),
	"klik": preload("res://assets/audio/klik.wav"),
	"gong": preload("res://assets/audio/gong.wav"),
	"gendang": preload("res://assets/audio/gendang.wav"),
}

const JUMLAH_KANAL_SFX: int = 8
const VOLUME_MUSIK_DB: float = -8.0

var _musik: AudioStreamPlayer
var _kanal_sfx: Array[AudioStreamPlayer] = []
var _musik_aktif: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_siapkan_bus("Musik")
	_siapkan_bus("SFX")
	_musik = AudioStreamPlayer.new()
	_musik.bus = "Musik"
	add_child(_musik)
	_musik.finished.connect(_ulang_musik)
	for i in JUMLAH_KANAL_SFX:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_kanal_sfx.append(p)


func _siapkan_bus(nama: String) -> void:
	if AudioServer.get_bus_index(nama) != -1:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, nama)
	AudioServer.set_bus_send(idx, "Master")


func _ulang_musik() -> void:
	_musik.play()


func putar_musik(nama: String) -> void:
	if nama == _musik_aktif or not MUSIK.has(nama):
		return
	_musik_aktif = nama
	_musik.stream = MUSIK[nama]
	_musik.volume_db = -40.0
	_musik.play()
	var tw := create_tween()
	tw.tween_property(_musik, "volume_db", VOLUME_MUSIK_DB, 1.2).set_ease(Tween.EASE_OUT)


## Menghentikan sementara / melanjutkan musik latar (dipakai saat mini-game ritme).
func jeda_musik(jeda: bool) -> void:
	_musik.stream_paused = jeda


func putar_sfx(nama: String, variasi_pitch: float = 0.0) -> void:
	if not SFX.has(nama):
		push_warning("SFX tidak ditemukan: " + nama)
		return
	for p in _kanal_sfx:
		if not p.playing:
			p.stream = SFX[nama]
			p.pitch_scale = 1.0 + randf_range(-variasi_pitch, variasi_pitch)
			p.play()
			return


func atur_volume(bus: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))


func ambil_volume(bus: String) -> float:
	var idx: int = AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx != -1 else 1.0
