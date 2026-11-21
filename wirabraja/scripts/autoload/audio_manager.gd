extends Node
## AudioManager (autoload) — satu pintu untuk musik latar dan efek suara.
##
## Cara mengganti audio: timpa file di folder audio/ dengan nama yang sama
## (lihat tabel MUSIK dan SFX di bawah, juga audio/README.md). Bila sebuah file
## tidak ada, permainan tetap berjalan tanpa suara itu (hanya muncul peringatan sekali).
##
## Bus audio "Musik" dan "SFX" dibuat otomatis bila belum ada.
## Tombol M: musik hidup/mati.

const MUSIK: Dictionary = {
	"narasi": "res://audio/musik/musik_narasi.ogg",
	"pertempuran": "res://audio/musik/musik_pertempuran.ogg",
	"bos": "res://audio/musik/musik_bos.ogg",
}

const SFX: Dictionary = {
	"ayun": "res://audio/sfx/ayun_gada.wav",
	"pukul": "res://audio/sfx/pukulan.wav",
	"kena": "res://audio/sfx/kena_serang.wav",
	"langkah": "res://audio/sfx/langkah.wav",
	"lompat": "res://audio/sfx/lompat.wav",
	"menang": "res://audio/sfx/kemenangan.wav",
	"kalah": "res://audio/sfx/kekalahan.wav",
	"buta_ayun": "res://audio/sfx/buta_ayun.wav",
	"buta_mati": "res://audio/sfx/buta_mati.wav",
	"terjang": "res://audio/sfx/terjang.wav",
	"injak": "res://audio/sfx/injak_bumi.wav",
	"lempar": "res://audio/sfx/lempar_batu.wav",
	"batu_jatuh": "res://audio/sfx/batu_jatuh.wav",
	"bos_hantam": "res://audio/sfx/bos_hantam.wav",
	"bos_raung": "res://audio/sfx/bos_raung.wav",
	"gong": "res://audio/sfx/gong.wav",
	"keprak": "res://audio/sfx/keprak.wav",
}

## Volume dasar per efek (dB). Efek yang tidak tercantum memakai 0 dB.
const VOLUME_SFX: Dictionary = {
	"langkah": -14.0, "ayun": -6.0, "lompat": -8.0, "gong": -2.0, "keprak": -4.0,
}

const JUMLAH_PEMUTAR_SFX := 12
const VOLUME_MUSIK_DB := -8.0

var musik_aktif: bool = true
var _cache: Dictionary = {}
var _sudah_diperingatkan: Dictionary = {}
var _pemutar_musik: Array[AudioStreamPlayer] = []
var _indeks_musik: int = 0
var _nama_musik: String = ""
var _pemutar_sfx: Array[AudioStreamPlayer] = []
var _indeks_sfx: int = 0
var _tween_fade: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_siapkan_bus("Musik")
	_siapkan_bus("SFX")
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Musik"
		p.volume_db = -80.0
		add_child(p)
		_pemutar_musik.append(p)
	for i in JUMLAH_PEMUTAR_SFX:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pemutar_sfx.append(p)


func _notification(what: int) -> void:
	# Hentikan suara sebelum jendela ditutup agar tidak ada stream tertahan saat keluar.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		hentikan_semua()


## Menghentikan semua musik dan efek suara seketika.
func hentikan_semua() -> void:
	_nama_musik = ""
	for p: AudioStreamPlayer in _pemutar_musik + _pemutar_sfx:
		p.stop()


func _exit_tree() -> void:
	# Hentikan & lepaskan semua stream agar tidak ada resource tertahan saat game ditutup.
	for t: Tween in _tween_fade.values():
		if t and t.is_valid():
			t.kill()
	_tween_fade.clear()
	for p: AudioStreamPlayer in _pemutar_musik + _pemutar_sfx:
		p.stop()
		p.stream = null
	_cache.clear()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("bisukan_musik"):
		musik_aktif = not musik_aktif
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Musik"), not musik_aktif)


## Memutar musik latar (berulang) dengan crossfade. Nama yang sama tidak diulang dari awal.
func putar_musik(nama: String, durasi_fade: float = 1.2) -> void:
	if nama == _nama_musik:
		return
	var stream := _muat(MUSIK.get(nama, ""), nama)
	_nama_musik = nama
	var lama := _pemutar_musik[_indeks_musik]
	_indeks_musik = 1 - _indeks_musik
	var baru := _pemutar_musik[_indeks_musik]
	_fade(lama, -80.0, durasi_fade, true)
	if stream == null:
		return
	_aktifkan_loop(stream)
	baru.stream = stream
	baru.volume_db = -40.0
	baru.play()
	_fade(baru, VOLUME_MUSIK_DB, durasi_fade, false)


func hentikan_musik(durasi_fade: float = 1.0) -> void:
	_nama_musik = ""
	for p: AudioStreamPlayer in _pemutar_musik:
		_fade(p, -80.0, durasi_fade, true)


func nama_musik_sekarang() -> String:
	return _nama_musik


## Memutar efek suara. Bila `posisi` (Vector3) diberikan, volume dilemahkan
## menurut jarak dari kamera aktif. `pitch` = 1.0 normal; diberi variasi acak kecil.
func putar_sfx(nama: String, posisi: Variant = null, pitch: float = 1.0) -> void:
	var stream := _muat(SFX.get(nama, ""), nama)
	if stream == null:
		return
	var volume: float = VOLUME_SFX.get(nama, 0.0)
	if posisi is Vector3:
		var kamera := get_viewport().get_camera_3d()
		if kamera:
			var jarak := kamera.global_position.distance_to(posisi as Vector3)
			volume -= clampf((jarak - 6.0) * 0.6, 0.0, 30.0)
	var p := _pemutar_sfx[_indeks_sfx]
	_indeks_sfx = (_indeks_sfx + 1) % _pemutar_sfx.size()
	p.stream = stream
	p.volume_db = volume
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.play()


## Untuk pengujian: apakah file audio dengan nama ini tersedia.
func tersedia(nama: String) -> bool:
	var path: String = SFX.get(nama, MUSIK.get(nama, ""))
	return path != "" and ResourceLoader.exists(path)


func _muat(path: String, nama: String) -> AudioStream:
	if path == "":
		_peringatan(nama, "nama audio '%s' tidak terdaftar" % nama)
		return null
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		_peringatan(nama, "file audio belum ada: %s (permainan tetap berjalan tanpa suara ini)" % path)
		_cache[path] = null
		return null
	var stream := load(path) as AudioStream
	_cache[path] = stream
	return stream


func _aktifkan_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		var w := stream as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


func _fade(p: AudioStreamPlayer, target_db: float, durasi: float, berhenti: bool) -> void:
	var lama: Tween = _tween_fade.get(p)
	if lama and lama.is_valid():
		lama.kill()
	var t := create_tween()
	_tween_fade[p] = t
	t.tween_property(p, "volume_db", target_db, durasi)
	if berhenti:
		t.tween_callback(p.stop)


func _siapkan_bus(nama: String) -> void:
	if AudioServer.get_bus_index(nama) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, nama)
	AudioServer.set_bus_send(i, "Master")


func _peringatan(nama: String, pesan: String) -> void:
	if _sudah_diperingatkan.has(nama):
		return
	_sudah_diperingatkan[nama] = true
	push_warning("AudioManager: " + pesan)
