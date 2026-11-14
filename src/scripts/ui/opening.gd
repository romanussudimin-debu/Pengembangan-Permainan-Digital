extends Node3D
## OPENING: layar pertama game.
## 1. "Ketuk untuk memulai" (sentuhan ini juga membuka kunci suara di browser/HP dan layar penuh).
## 2. Sinematik: kamera terbang melintasi panorama Manggarai (Wae Rebo, Penti & caci, lingko,
##    komodo, Labuan Bajo) dengan judul tiap tema dan bilah sinema atas-bawah.
## 3. Penutup: judul game + "Selamat datang di Manggarai! Mari belajar budaya sambil bermain."
## Dapat dilewati kapan saja (tombol Lewati / Esc). Lalu pindah ke menu utama.

const ADEGAN_MENU: String = "res://scenes/main_menu.tscn"
const SAPAAN: String = "Selamat datang di Manggarai!"
const AJAKAN: String = "Mari belajar budaya sambil bermain."

enum Tahap { KETUK, SINEMA, PENUTUP, KELUAR }

var _tahap: int = Tahap.KETUK
var _kamera: Camera3D
var _kapal: Array[Node3D] = []
var _waktu: float = 0.0
var _indeks_shot: int = 0
var _waktu_shot: float = 0.0

var _ui: CanvasLayer
var _layar_ketuk: Control
var _label_ketuk: Label
var _bilah_atas: ColorRect
var _bilah_bawah: ColorRect
var _label_judul: Label
var _label_ket: Label
var _garis: ColorRect
var _penutup: Control
var _tombol_lewati: Button


func _ready() -> void:
	get_tree().paused = false
	GameState.ubah_state(GameState.State.MENU)
	_kapal = Panorama.bangun(self)
	_kamera = Camera3D.new()
	_kamera.fov = 55.0
	add_child(_kamera)
	_kamera.current = true
	_bangun_ui()


# ------------------------------------------------------------------ UI

func _bangun_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	_bilah_atas = _bilah(Vector2(0, -40))
	_bilah_bawah = _bilah(Vector2(0, 360))
	_label_judul = Gaya.label("", 26, Gaya.KUNING)
	_label_judul.position = Vector2(0, 262)
	_label_judul.size = Vector2(640, 36)
	_label_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_judul.add_theme_constant_override("outline_size", 6)
	_label_judul.modulate.a = 0.0
	_ui.add_child(_label_judul)
	_garis = ColorRect.new()
	_garis.color = Gaya.MERAH
	_garis.position = Vector2(270, 300)
	_garis.size = Vector2(100, 2)
	_garis.modulate.a = 0.0
	_ui.add_child(_garis)
	_label_ket = Gaya.label("", 11, Gaya.PUTIH)
	_label_ket.position = Vector2(0, 306)
	_label_ket.size = Vector2(640, 20)
	_label_ket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_ket.modulate.a = 0.0
	_ui.add_child(_label_ket)
	_bangun_penutup()
	_bangun_layar_ketuk()
	_tombol_lewati = Gaya.tombol("Lewati  >>")
	_tombol_lewati.custom_minimum_size = Vector2(100, 22)
	_tombol_lewati.position = Vector2(528, 8)
	_tombol_lewati.focus_mode = Control.FOCUS_NONE
	_tombol_lewati.visible = false
	_tombol_lewati.pressed.connect(_ke_menu)
	_ui.add_child(_tombol_lewati)


func _bilah(pos: Vector2) -> ColorRect:
	var b := ColorRect.new()
	b.color = Color(0.03, 0.02, 0.02)
	b.position = pos
	b.size = Vector2(640, 40)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(b)
	return b


func _bangun_layar_ketuk() -> void:
	_layar_ketuk = Control.new()
	_layar_ketuk.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(_layar_ketuk)
	var gelap := ColorRect.new()
	gelap.color = Color(0.05, 0.04, 0.04, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layar_ketuk.add_child(gelap)
	var pita := Gaya.panel_songke(Vector2(120, 92), Vector2(400, 150))
	_layar_ketuk.add_child(pita)
	var judul := Gaya.label("JEJAK PENTI", 38, Gaya.KUNING)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.position = Vector2(0, 14)
	judul.size = Vector2(400, 50)
	judul.add_theme_constant_override("outline_size", 6)
	pita.add_child(judul)
	var sub := Gaya.label("Petualangan Budaya Manggarai", 12, Gaya.PUTIH)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 66)
	sub.size = Vector2(400, 20)
	pita.add_child(sub)
	var tema := Gaya.label("Wae Rebo  ·  Lingko  ·  Labuan Bajo", 9, Color("c9c2b0"))
	tema.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tema.position = Vector2(0, 88)
	tema.size = Vector2(400, 16)
	pita.add_child(tema)
	_label_ketuk = Gaya.label("Ketuk layar untuk memulai", 12, Gaya.PUTIH)
	_label_ketuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_ketuk.position = Vector2(0, 264)
	_label_ketuk.size = Vector2(640, 20)
	_layar_ketuk.add_child(_label_ketuk)
	var cat := Gaya.label("Nyalakan suara untuk pengalaman terbaik", 8, Color("c9c2b0"))
	cat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat.position = Vector2(0, 288)
	cat.size = Vector2(640, 14)
	_layar_ketuk.add_child(cat)


func _bangun_penutup() -> void:
	_penutup = Control.new()
	_penutup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_penutup.modulate.a = 0.0
	_penutup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_penutup)
	var judul := Gaya.label("JEJAK PENTI", 44, Gaya.KUNING)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.position = Vector2(0, 70)
	judul.size = Vector2(640, 60)
	judul.add_theme_constant_override("outline_size", 8)
	_penutup.add_child(judul)
	var sub := Gaya.label("Petualangan Budaya Manggarai", 13, Gaya.PUTIH)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 128)
	sub.size = Vector2(640, 20)
	_penutup.add_child(sub)
	var pita := Gaya.panel_songke(Vector2(110, 196), Vector2(420, 70))
	_penutup.add_child(pita)
	var sapa := Gaya.label(SAPAAN, 18, Gaya.KUNING)
	sapa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sapa.position = Vector2(0, 10)
	sapa.size = Vector2(420, 26)
	pita.add_child(sapa)
	var ajak := Gaya.label(AJAKAN, 12, Gaya.PUTIH)
	ajak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ajak.position = Vector2(0, 40)
	ajak.size = Vector2(420, 20)
	pita.add_child(ajak)


# ------------------------------------------------------------------ alur

func _input(event: InputEvent) -> void:
	var ditekan: bool = (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey) and event.is_pressed()
	if not ditekan:
		return
	if _tahap == Tahap.KETUK:
		get_viewport().set_input_as_handled()
		_mulai_sinema()
	elif event.is_action_pressed("jeda") and _tahap != Tahap.KELUAR:
		get_viewport().set_input_as_handled()
		_ke_menu()


func _mulai_sinema() -> void:
	_tahap = Tahap.SINEMA
	AudioManager.buka_kunci_audio()
	AudioManager.putar_musik("kampung")
	AudioManager.putar_sfx("gong")
	_tombol_lewati.visible = true
	var tw := create_tween().set_parallel()
	tw.tween_property(_layar_ketuk, "modulate:a", 0.0, 0.6)
	tw.tween_property(_bilah_atas, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_bilah_bawah, "position:y", 320.0, 0.8).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(_layar_ketuk.hide)
	_mulai_shot(0)
	_ucapkan(SAPAAN)


func _mulai_shot(i: int) -> void:
	_indeks_shot = i
	_waktu_shot = 0.0
	var shot: Dictionary = Panorama.SHOT[i]
	_label_judul.text = str(shot["judul"]).to_upper()
	_label_ket.text = str(shot["ket"])
	var durasi: float = shot["durasi"]
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.set_parallel()
	tw.tween_property(_label_judul, "modulate:a", 1.0, 0.6)
	tw.tween_property(_garis, "modulate:a", 1.0, 0.6)
	tw.tween_property(_label_ket, "modulate:a", 1.0, 0.8).set_delay(0.2)
	tw.chain().tween_interval(durasi - 2.0)
	tw.set_parallel()
	tw.tween_property(_label_judul, "modulate:a", 0.0, 0.5)
	tw.tween_property(_garis, "modulate:a", 0.0, 0.5)
	tw.tween_property(_label_ket, "modulate:a", 0.0, 0.5)
	if i > 0:
		AudioManager.putar_sfx("gendang", 0.05)


func _mulai_penutup() -> void:
	_tahap = Tahap.PENUTUP
	_waktu_shot = 0.0
	AudioManager.putar_sfx("gong")
	var tw := create_tween().set_parallel()
	tw.tween_property(_penutup, "modulate:a", 1.0, 1.2)
	tw.tween_property(_bilah_atas, "position:y", -40.0, 1.0)
	tw.tween_property(_bilah_bawah, "position:y", 360.0, 1.0)
	_ucapkan(SAPAAN + " " + AJAKAN)


func _process(delta: float) -> void:
	_waktu += delta
	Panorama.animasi_kapal(_kapal, _waktu)
	match _tahap:
		Tahap.KETUK:
			# Kamera berputar pelan di atas kampung; teks "ketuk" berdenyut
			var a: float = _waktu * 0.06
			_kamera.position = Vector3(sin(a) * 34.0, 14.0, cos(a) * 34.0)
			_kamera.look_at(Vector3(0, 2, 0), Vector3.UP)
			_label_ketuk.modulate.a = 0.55 + 0.45 * sin(_waktu * 4.0)
		Tahap.SINEMA:
			_waktu_shot += delta
			var shot: Dictionary = Panorama.SHOT[_indeks_shot]
			_terapkan_pose(shot, _waktu_shot / float(shot["durasi"]))
			if _waktu_shot >= float(shot["durasi"]):
				if _indeks_shot + 1 < Panorama.SHOT.size():
					_mulai_shot(_indeks_shot + 1)
				else:
					_mulai_penutup()
		Tahap.PENUTUP:
			_waktu_shot += delta
			_terapkan_pose(Panorama.SHOT_AKHIR, _waktu_shot / float(Panorama.SHOT_AKHIR["durasi"]))
			if _waktu_shot >= float(Panorama.SHOT_AKHIR["durasi"]) + 1.5:
				_ke_menu()


func _terapkan_pose(shot: Dictionary, t: float) -> void:
	var p: Array = Panorama.pose(shot, t)
	_kamera.position = p[0]
	_kamera.look_at(p[1], Vector3.UP)


func _ucapkan(teks: String) -> void:
	if DialogManager.suara_tersedia():
		DialogManager._ucapkan(teks, "Nggohak")


func _ke_menu() -> void:
	if _tahap == Tahap.KELUAR:
		return
	_tahap = Tahap.KELUAR
	if DialogManager.suara_tersedia():
		DisplayServer.tts_stop()
	Transisi.pindah_scene(ADEGAN_MENU)
