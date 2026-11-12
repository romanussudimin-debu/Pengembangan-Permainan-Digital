class_name TabuhGong
extends CanvasLayer
## Mini-game TABUH GONG-GENDANG: ketukan bergerak dari kanan ke garis tabuh.
## Tekan J (gong) atau K (gendang) saat ketukan tiba di garis. Berhasil bila
## minimal PERSEN_LULUS ketukan tepat.

signal selesai(berhasil: bool)

const TEMPO_BPM: float = 76.0
const JENDELA_TEPAT: float = 0.2  ## toleransi waktu (detik)
const KECEPATAN: float = 230.0  ## piksel per detik
const GARIS_X: float = 130.0
const JALUR_Y: Array[float] = [150.0, 220.0]  ## 0 = gong, 1 = gendang
const PERSEN_LULUS: float = 0.6
const JEDA_AWAL: float = 2.5
## Pola irama (G = gong, D = gendang, - = diam), satu karakter = setengah ketukan.
const POLA: String = "G-D-D-G-D-D-G---G-D-D-G-DDG-G---"

var _ketukan: Array[Dictionary] = []  ## {waktu, jalur, status: 0 menunggu, 1 tepat, 2 luput}
var _jam: float = 0.0
var _tepat: int = 0
var _selesai: bool = false
var _kanvas: Control
var _label_info: Label
var _label_umpan: Label


func _ready() -> void:
	layer = 40
	_susun_ketukan()
	_bangun_ui()
	GameState.ubah_state(GameState.State.MINIGAME)
	AudioManager.jeda_musik(true)


func _susun_ketukan() -> void:
	var setengah: float = 60.0 / TEMPO_BPM / 2.0
	for i in POLA.length():
		var c: String = POLA[i]
		if c == "G" or c == "D":
			_ketukan.append({"waktu": JEDA_AWAL + i * setengah, "jalur": 0 if c == "G" else 1, "status": 0})


func _bangun_ui() -> void:
	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	add_child(Gaya.panel_songke(Vector2(40, 40), Vector2(560, 280)))
	var judul := Gaya.label("TABUH GONG & GENDANG", 16, Gaya.KUNING)
	judul.position = Vector2(60, 50)
	add_child(judul)
	var lg := Gaya.label("GONG  [J]", 10, Gaya.KUNING)
	lg.position = Vector2(56, JALUR_Y[0] - 8)
	add_child(lg)
	var ld := Gaya.label("GENDANG  [K]", 9, Gaya.PUTIH)
	ld.position = Vector2(50, JALUR_Y[1] - 8)
	add_child(ld)
	_kanvas = Control.new()
	_kanvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kanvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	_label_umpan = Gaya.label("", 18, Gaya.KUNING)
	_label_umpan.position = Vector2(220, 90)
	_label_umpan.size = Vector2(200, 30)
	_label_umpan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label_umpan)
	_label_info = Gaya.label("", 9, Gaya.PUTIH)
	_label_info.position = Vector2(60, 280)
	add_child(_label_info)
	# Tombol sentuh/klik; button_down agar ketukan terdaftar tepat saat jari menyentuh.
	for jalur in 2:
		var b := Gaya.tombol("GONG" if jalur == 0 else "GENDANG")
		b.custom_minimum_size = Vector2(130, 34)
		b.position = Vector2(310 + jalur * 145, 254)
		b.focus_mode = Control.FOCUS_NONE
		b.button_down.connect(_tabuh_sentuh.bind(jalur))
		add_child(b)


func _process(delta: float) -> void:
	if _selesai or not GameState.sedang(GameState.State.MINIGAME):
		return
	_jam += delta
	for k in _ketukan:
		if k["status"] == 0 and _jam > float(k["waktu"]) + JENDELA_TEPAT:
			k["status"] = 2
			_umpan("Luput", Gaya.ABU)
	if Input.is_action_just_pressed("tabuh_gong"):
		_tabuh(0)
	if Input.is_action_just_pressed("tabuh_gendang"):
		_tabuh(1)
	var sisa: int = 0
	for k in _ketukan:
		if k["status"] == 0:
			sisa += 1
	_label_info.text = "Tepat: %d / %d   (lulus: %d)%s" % [_tepat, _ketukan.size(), ceili(_ketukan.size() * PERSEN_LULUS),
		"   Bersiap..." if _jam < JEDA_AWAL - 0.5 else ""]
	_kanvas.queue_redraw()
	if sisa == 0:
		_hasil()


func _tabuh_sentuh(jalur: int) -> void:
	if not _selesai and GameState.sedang(GameState.State.MINIGAME):
		_tabuh(jalur)


func _tabuh(jalur: int) -> void:
	AudioManager.putar_sfx("gong" if jalur == 0 else "gendang", 0.05)
	for k in _ketukan:
		if k["status"] == 0 and k["jalur"] == jalur and absf(float(k["waktu"]) - _jam) <= JENDELA_TEPAT:
			k["status"] = 1
			_tepat += 1
			_umpan("Tepat!", Gaya.HIJAU)
			return


func _umpan(teks: String, warna: Color) -> void:
	_label_umpan.text = teks
	_label_umpan.add_theme_color_override("font_color", warna)
	_label_umpan.pivot_offset = Vector2(100, 15)
	_label_umpan.scale = Vector2(1.4, 0.7)
	var tw := create_tween()
	tw.tween_property(_label_umpan, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _gambar() -> void:
	for j in JALUR_Y.size():
		_kanvas.draw_line(Vector2(GARIS_X - 20, JALUR_Y[j]), Vector2(580, JALUR_Y[j]), Color("5a524a"), 2.0)
	_kanvas.draw_line(Vector2(GARIS_X, JALUR_Y[0] - 30), Vector2(GARIS_X, JALUR_Y[1] + 30), Gaya.PUTIH, 3.0)
	for k in _ketukan:
		if k["status"] != 0:
			continue
		var x: float = GARIS_X + (float(k["waktu"]) - _jam) * KECEPATAN
		if x > 590.0:
			continue
		var jalur: int = k["jalur"]
		if jalur == 0:
			_kanvas.draw_circle(Vector2(x, JALUR_Y[0]), 16.0, Color("b8892c"))
			_kanvas.draw_circle(Vector2(x, JALUR_Y[0]), 6.0, Color("d4a640"))
		else:
			_kanvas.draw_rect(Rect2(x - 12, JALUR_Y[1] - 12, 24, 24), Color("7a5030"))
			_kanvas.draw_rect(Rect2(x - 12, JALUR_Y[1] - 12, 24, 6), Color("e8e2d2"))


func _hasil() -> void:
	_selesai = true
	var lulus: bool = _tepat >= ceili(_ketukan.size() * PERSEN_LULUS)
	if lulus:
		AudioManager.putar_sfx("berhasil")
		_umpan("Irama sempurna untuk Penti!", Gaya.KUNING)
	else:
		AudioManager.putar_sfx("gagal")
		_umpan("Belum pas", Gaya.MERAH)
	var t := get_tree().create_timer(1.6, false)
	t.timeout.connect(_akhiri.bind(lulus))


func _akhiri(berhasil: bool) -> void:
	AudioManager.jeda_musik(false)
	GameState.ubah_state(GameState.State.BERMAIN)
	selesai.emit(berhasil)
	queue_free()
