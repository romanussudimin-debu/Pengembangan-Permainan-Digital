class_name TangkisNggiling
extends CanvasLayer
## Mini-game LATIHAN TANGKIS NGGILING (Level 1, Marngem): latihan sportivitas sebelum caci.
## Marngem (model 3D) melempar bola rotan ke kiri, tengah, atau kanan. Tekan arah yang sesuai
## (A / W / D, panah, atau ketuk tombol) tepat saat bola masuk lingkaran nggiling.
## Pengecoh: lemparan TIPUAN - Marngem ancang-ancang lalu batal (ancang() + batal_aksi()).
## Tanda yang adil: saat lemparan sungguhan, bola rotan terlihat di tangannya; saat tipuan, tangannya kosong.
## -1 nyawa: menangkis tipuan, salah arah, atau terkena lemparan. Lemparan makin cepat.

signal selesai(berhasil: bool)
signal salah(penyebab: String)

enum Fase { JEDA, ANCANG, TERBANG, TIPUAN, AKHIR }

const JUMLAH_LEMPARAN: int = 14
const POS_TANGAN := Vector2(320, 150)
const POS_JALUR: Array[Vector2] = [Vector2(180, 292), Vector2(320, 300), Vector2(460, 292)]
const NAMA_JALUR: Array[String] = ["KIRI", "TENGAH", "KANAN"]
const JENDELA: float = 0.2  ## bagian akhir lintasan tempat tangkisan dihitung tepat

var batal: bool = false
var kesalahan: int = 0

var _urutan: Array[Dictionary] = []  ## {jalur: int, tipuan: bool}
var _indeks: int = 0
var _fase: int = Fase.JEDA
var _waktu_fase: float = 0.0
var _durasi_terbang: float = 1.2
var _berhasil: int = 0
var _kilat_tangkis: float = 0.0
var _jalur_tangkis: int = -1
var _diakhiri: bool = false
var _kanvas: Control
var _label_info: Label
var _model: KarakterModel


func _ready() -> void:
	layer = 40
	_susun_urutan()
	_bangun_ui()
	GameState.ubah_state(GameState.State.MINIGAME)


func _susun_urutan() -> void:
	for i in JUMLAH_LEMPARAN:
		# Tiga lemparan pertama selalu sungguhan (mengajari mekanik), tipuan muncul sesudahnya
		var tipuan: bool = i >= 3 and (i % 3 == 1 or randf() < 0.15)
		_urutan.append({"jalur": randi() % 3, "tipuan": tipuan})


func _bangun_ui() -> void:
	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	add_child(Gaya.panel_songke(Vector2(40, 30), Vector2(560, 300)))
	var judul := Gaya.label("LATIHAN TANGKIS NGGILING", 14, Gaya.KUNING)
	judul.position = Vector2(56, 38)
	add_child(judul)
	# Marngem dalam viewport 3D kecil
	var wadah := SubViewportContainer.new()
	wadah.position = Vector2(250, 56)
	wadah.size = Vector2(140, 130)
	wadah.stretch = true
	wadah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wadah)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(140, 130)
	wadah.add_child(vp)
	var cahaya := DirectionalLight3D.new()
	cahaya.rotation_degrees = Vector3(-40, 30, 0)
	vp.add_child(cahaya)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.75, 0.7)
	vp.add_child(env)
	_model = KarakterModel.new()
	_model.perempuan = true
	_model.tekstur_songke = preload("res://assets/textures/songke_hijau.png")
	_model.warna_baju = Color("e8e2d2")
	vp.add_child(_model)
	_model.rotation.y = PI  # menghadap kamera
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 1.7, 3.6)
	kamera.fov = 45.0
	vp.add_child(kamera)
	kamera.look_at(Vector3(0, 1.4, 0), Vector3.UP)
	_kanvas = Control.new()
	_kanvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kanvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	for i in 3:
		var t := Gaya.tombol(NAMA_JALUR[i])
		t.custom_minimum_size = Vector2(96, 30)
		t.position = POS_JALUR[i] + Vector2(-48, -2)
		t.focus_mode = Control.FOCUS_NONE
		t.modulate.a = 0.85
		t.pressed.connect(_tangkis.bind(i))
		add_child(t)
	_label_info = Gaya.label("", 9, Gaya.PUTIH)
	_label_info.position = Vector2(56, 60)
	_label_info.size = Vector2(186, 120)
	_label_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label_info)
	var berhenti := Gaya.tombol("Berhenti")
	berhenti.custom_minimum_size = Vector2(110, 24)
	berhenti.position = Vector2(474, 36)
	berhenti.focus_mode = Control.FOCUS_NONE
	berhenti.pressed.connect(func() -> void:
		batal = true
		_akhiri(false))
	add_child(berhenti)
	_perbarui_info()


func _perbarui_info() -> void:
	_label_info.text = ("Tangkis bola rotan dengan arah yang tepat (A / W / D atau ketuk tombol).\n\n"
		+ "Ada BOLA di tangan Marngem = lemparan sungguhan. Tangan KOSONG = tipuan, jangan ditangkis!\n\nLemparan: %d/%d") % [
		mini(_indeks + 1, JUMLAH_LEMPARAN), JUMLAH_LEMPARAN]


# ------------------------------------------------------------------ alur lemparan

func _process(delta: float) -> void:
	if _diakhiri or not GameState.sedang(GameState.State.MINIGAME):
		return
	_waktu_fase += delta
	_kilat_tangkis = maxf(_kilat_tangkis - delta, 0.0)
	match _fase:
		Fase.JEDA:
			if _waktu_fase >= 0.9:
				_mulai_lemparan()
		Fase.ANCANG:
			if _waktu_fase >= 0.45:
				_fase = Fase.TERBANG
				_waktu_fase = 0.0
				AudioManager.putar_sfx("cambuk", 0.1)
		Fase.TERBANG:
			if _waktu_fase >= _durasi_terbang + 0.05:
				_hasil(false, "terkena lemparan")
		Fase.TIPUAN:
			if _waktu_fase >= 1.1:
				_lemparan_berikutnya()  # tipuan berhasil dihindari
	_kanvas.queue_redraw()


func _mulai_lemparan() -> void:
	if _indeks >= _urutan.size():
		_selesai_latihan()
		return
	_perbarui_info()
	_waktu_fase = 0.0
	var l: Dictionary = _urutan[_indeks]
	if l["tipuan"]:
		_fase = Fase.TIPUAN
		_model.ancang(0.45)
		get_tree().create_timer(0.55, false).timeout.connect(func() -> void:
			if is_instance_valid(_model):
				_model.batal_aksi())
	else:
		_fase = Fase.ANCANG
		_model.serang(0.45)


func _tangkis(jalur: int) -> void:
	if _diakhiri or _fase == Fase.AKHIR or _fase == Fase.JEDA:
		return
	_jalur_tangkis = jalur
	_kilat_tangkis = 0.25
	if _fase == Fase.TIPUAN:
		_hasil(false, "tertipu lemparan tipuan")
		return
	if _fase == Fase.ANCANG:
		_hasil(false, "menangkis terlalu cepat")
		return
	var t: float = _waktu_fase / _durasi_terbang
	var benar_jalur: bool = jalur == int(_urutan[_indeks]["jalur"])
	if t >= 1.0 - JENDELA and benar_jalur:
		_hasil(true, "")
	elif not benar_jalur:
		_hasil(false, "salah arah tangkisan")
	else:
		_hasil(false, "menangkis terlalu cepat")


func _hasil(tepat: bool, penyebab: String) -> void:
	if tepat:
		_berhasil += 1
		AudioManager.putar_sfx("perisai", 0.1)
	else:
		kesalahan += 1
		AudioManager.putar_sfx("terkena", 0.1)
		salah.emit(penyebab)
	_lemparan_berikutnya()


func _lemparan_berikutnya() -> void:
	_indeks += 1
	_fase = Fase.JEDA
	_waktu_fase = 0.0
	# Makin lama makin cepat
	_durasi_terbang = lerpf(1.2, 0.65, float(_indeks) / JUMLAH_LEMPARAN)


func _selesai_latihan() -> void:
	_fase = Fase.AKHIR
	AudioManager.putar_sfx("berhasil")
	_label_info.text = "Latihan selesai! Tangkisan tepat: %d. Sportif dan sigap!" % _berhasil
	get_tree().create_timer(1.6, false).timeout.connect(_akhiri.bind(true))


# ------------------------------------------------------------------ gambar

func _gambar() -> void:
	var c := _kanvas
	# Lingkaran nggiling (perisai) di tiga arah
	for i in 3:
		var p: Vector2 = POS_JALUR[i] + Vector2(0, -36)
		var nyala: bool = _kilat_tangkis > 0.0 and _jalur_tangkis == i
		c.draw_circle(p, 26.0, Color("6a4428") if not nyala else Color("e8b430"))
		c.draw_arc(p, 26.0, 0.0, TAU, 32, Gaya.KUNING, 2.0)
		c.draw_circle(p, 6.0, Gaya.KUNING)
	if _fase == Fase.AKHIR or _indeks >= _urutan.size():
		return
	var l: Dictionary = _urutan[_indeks]
	var pegang: Vector2 = POS_TANGAN + Vector2(18, -6)
	match _fase:
		Fase.ANCANG:
			_bola(pegang, 7.0)  # bola terlihat di tangan = lemparan sungguhan
		Fase.TERBANG:
			var t: float = clampf(_waktu_fase / _durasi_terbang, 0.0, 1.0)
			var tujuan: Vector2 = POS_JALUR[int(l["jalur"])] + Vector2(0, -36)
			var p: Vector2 = pegang.lerp(tujuan, t) + Vector2(0, -sin(t * PI) * 40.0)
			_bola(p, lerpf(7.0, 16.0, t))
			if t >= 1.0 - JENDELA:
				c.draw_arc(tujuan, 30.0, 0.0, TAU, 32, Gaya.PUTIH, 3.0)


func _bola(p: Vector2, r: float) -> void:
	_kanvas.draw_circle(p, r, Color("c8a050"))
	_kanvas.draw_arc(p, r * 0.7, 0.3, 2.8, 8, Color("8a6a30"), 1.5)
	_kanvas.draw_arc(p, r * 0.7, 3.4, 5.9, 8, Color("8a6a30"), 1.5)


func _unhandled_input(event: InputEvent) -> void:
	if _diakhiri or not GameState.sedang(GameState.State.MINIGAME):
		return
	var jalur: int = -1
	if event.is_action_pressed("kiri"):
		jalur = 0
	elif event.is_action_pressed("maju") or event.is_action_pressed("mundur"):
		jalur = 1
	elif event.is_action_pressed("kanan"):
		jalur = 2
	if jalur >= 0:
		get_viewport().set_input_as_handled()
		_tangkis(jalur)


func _akhiri(berhasil: bool) -> void:
	if _diakhiri or not is_inside_tree():
		return
	_diakhiri = true
	GameState.ubah_state(GameState.State.BERMAIN)
	selesai.emit(berhasil)
	queue_free()
