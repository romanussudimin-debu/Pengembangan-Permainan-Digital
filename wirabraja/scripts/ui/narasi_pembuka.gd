extends Control
## Narasi pembuka bergaya dalang, ditampilkan sebelum Level 1.
## Alur: kayon di tengah kelir + judul lakon -> kayon disingkirkan ke samping ->
## janturan (narasi) baris demi baris -> kayon kembali ke tengah -> masuk level.
## Kontrol: Spasi/Enter/klik = lanjut (atau tampilkan teks utuh), Esc/Tab = lewati.

## Dipancarkan saat narasi selesai atau dilewati (sebelum pindah ke level).
signal selesai

@export_file("*.tscn") var scene_level: String = "res://scenes/level/level_1.tscn"
## False dipakai uji otomatis agar tidak berpindah scene.
@export var pindah_otomatis: bool = true

## Teks janturan. Istilah Jawa: kacarita = dikisahkan; mangkana = demikianlah.
@export var baris_narasi: PackedStringArray = [
	"Hong wilaheng...",
	"Kacarita, ing Keraton Surakarta Hadiningrat, langit mendadak gelap. Angin dari arah hutan Gandamayit berembus membawa hawa angkara.",
	"Bala buta datang menyerbu alun-alun: buta prajurit bergada kayu, buta kilat yang lincah bagai sambaran petir, buta gempal sebesar gajah, dan buta pelempar batu.",
	"Di belakang mereka menunggu Ditya Kalamurka, raksasa yang dikuasai angkara murka, yang hendak merebut ketenteraman negeri.",
	"Hanya satu ksatria yang berdiri menjaga gerbang: Raden Wirabraja, ksatria berbudi luhur yang bersenjatakan gada.",
	"Sang ksatria tidak gentar. Ia memegang pitutur para leluhur: becik ketitik, ala ketara. Yang baik akan tampak, yang jahat akan terungkap.",
	"Mangkana... perang pun dimulai!",
]
## Detik per huruf untuk efek ketik.
@export var kecepatan_ketik: float = 0.028

@onready var _kayon: Kayon = %Kayon
@onready var _judul: Label = %JudulLakon
@onready var _teks: Label = %TeksNarasi
@onready var _kotak: Control = %KotakNarasi
@onready var _petunjuk: Label = %Petunjuk
@onready var _tirai: ColorRect = %Tirai

var indeks_baris: int = -1
var _tween_ketik: Tween
var _sibuk: bool = true   # selama animasi kayon, input lanjut diabaikan
var _selesai: bool = false
var _posisi_tengah: Vector2


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.putar_musik("narasi")
	_kotak.modulate.a = 0.0
	_judul.modulate.a = 0.0
	_tirai.color.a = 1.0
	await get_tree().process_frame
	_posisi_tengah = _kayon.position
	# Pembukaan: tirai terang, kayon bergoyang, judul lakon muncul.
	var t := create_tween()
	t.tween_property(_tirai, "color:a", 0.0, 1.2)
	t.tween_callback(AudioManager.putar_sfx.bind("gong"))
	t.tween_property(_judul, "modulate:a", 1.0, 0.8)
	t.tween_interval(1.6)
	t.tween_callback(_singkirkan_kayon)


func _process(_delta: float) -> void:
	# Kayon bergoyang pelan seperti digerakkan dalang.
	_kayon.rotation = sin(Time.get_ticks_msec() * 0.0018) * 0.05 + float(_kayon.get_meta("miring", 0.0))


func _unhandled_input(event: InputEvent) -> void:
	if _selesai:
		return
	if event.is_action_pressed("narasi_lewati"):
		_akhiri()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("narasi_lanjut") or (event is InputEventMouseButton and event.is_pressed()
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_lanjut()


func _singkirkan_kayon() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(_judul, "modulate:a", 0.0, 0.5)
	t.tween_property(_kayon, "position", _posisi_tengah + Vector2(-size.x * 0.33, 40.0), 0.9) \
			.set_trans(Tween.TRANS_SINE)
	t.tween_property(_kayon, "scale", Vector2(0.7, 0.7), 0.9)
	t.tween_method(func(v: float) -> void: _kayon.set_meta("miring", v), 0.0, -0.25, 0.9)
	t.tween_property(_kotak, "modulate:a", 1.0, 0.6).set_delay(0.5)
	t.chain().tween_callback(func() -> void:
		_sibuk = false
		_lanjut()
	)


func _lanjut() -> void:
	if _sibuk:
		return
	# Bila teks masih diketik, tampilkan utuh dulu.
	if _tween_ketik and _tween_ketik.is_running():
		_tween_ketik.kill()
		_teks.visible_ratio = 1.0
		return
	indeks_baris += 1
	if indeks_baris >= baris_narasi.size():
		_akhiri()
		return
	_teks.text = baris_narasi[indeks_baris]
	_teks.visible_ratio = 0.0
	AudioManager.putar_sfx("keprak")
	_tween_ketik = create_tween()
	_tween_ketik.tween_property(_teks, "visible_ratio", 1.0, _teks.text.length() * kecepatan_ketik)
	_petunjuk.text = "Spasi / Enter / klik: lanjut   ·   Esc: lewati   (%d/%d)" % [indeks_baris + 1, baris_narasi.size()]


## Penutup: kayon kembali ke tengah (tancep kayon), layar menggelap, masuk level.
func _akhiri() -> void:
	if _selesai:
		return
	_selesai = true
	_sibuk = true
	if _tween_ketik and _tween_ketik.is_valid():
		_tween_ketik.kill()
	AudioManager.putar_sfx("gong")
	var t := create_tween().set_parallel(true)
	t.tween_property(_kotak, "modulate:a", 0.0, 0.4)
	t.tween_property(_kayon, "position", _posisi_tengah, 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_property(_kayon, "scale", Vector2.ONE, 0.8)
	t.tween_method(func(v: float) -> void: _kayon.set_meta("miring", v), float(_kayon.get_meta("miring", 0.0)), 0.0, 0.8)
	t.chain().tween_property(_tirai, "color:a", 1.0, 0.8)
	t.chain().tween_callback(func() -> void:
		selesai.emit()
		if pindah_otomatis:
			get_tree().change_scene_to_file(scene_level)
	)
