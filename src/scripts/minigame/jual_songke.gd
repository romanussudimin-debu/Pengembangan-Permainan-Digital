class_name JualSongke
extends CanvasLayer
## Mini-game MENAWARKAN KARYA PENENUN (Level 3). Dua tahap:
##   1. PILIH  - pilih kain songke atau foto budaya yang cocok dengan keinginan wisatawan.
##   2. CERITA - ceritakan maknanya: jawab pertanyaan wisatawan (pilihan ganda; jawabannya
##               ada di kartu budaya yang sudah dikumpulkan).
## Salah barang atau salah cerita = -1 nyawa (sinyal `salah`). Mode Sulit: salah cerita membuat
## wisatawan langsung pergi. Kontrol: klik/ketuk, Panah/WASD + E, angka 1-3.
## Sinyal selesai(true) = terjual; selesai(false) dengan `pergi` = wisatawan pergi, tanpa = batal.

signal selesai(berhasil: bool)
signal salah(penyebab: String)  ## satu kesalahan (pengurang nyawa)

enum Tahap { PILIH, CERITA, AKHIR }

const KOLOM: int = 5
const UKURAN_UBIN := Vector2(98, 72)
const ASAL_UBIN := Vector2(56, 104)
const JARAK: float = 6.0

var batal: bool = false  ## true bila pemain menekan Berhenti (bukan gagal)
var pergi: bool = false  ## true bila wisatawan pergi karena tidak yakin

var _wisatawan: Dictionary = {}
var _barang: Array = []
var _sulit: bool = false
var _tahap: int = Tahap.PILIH
var _kursor: int = 0
var _salah_cerita: int = 0
var _diakhiri: bool = false
var _tekstur: Dictionary = {}

var _kanvas: Control
var _label_minta: Label
var _label_info: Label
var _label_tanya: Label
var _kolom_jawab: VBoxContainer


## `wisatawan` dari labuan_bajo.json; `barang` = daftar barang yang dibawa (sudah difilter).
func siapkan(wisatawan: Dictionary, barang: Array, sulit: bool) -> void:
	_wisatawan = wisatawan
	_barang = barang
	_sulit = sulit


func _ready() -> void:
	layer = 40
	for b: Dictionary in _barang:
		if b.has("tekstur"):
			_tekstur[b["id"]] = load("res://assets/textures/%s.png" % b["tekstur"])
	_bangun_ui()
	GameState.ubah_state(GameState.State.MINIGAME)


func _bangun_ui() -> void:
	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	add_child(Gaya.panel_songke(Vector2(40, 30), Vector2(560, 300)))
	var judul := Gaya.label("MENAWARKAN KARYA PENENUN", 14, Gaya.KUNING)
	judul.position = Vector2(56, 38)
	add_child(judul)
	_label_minta = Gaya.label("%s (%s): \"%s\"" % [_wisatawan["nama"], _wisatawan["asal"], _wisatawan["keinginan"]], 9, Gaya.PUTIH)
	_label_minta.position = Vector2(56, 62)
	_label_minta.size = Vector2(528, 36)
	_label_minta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label_minta)
	_kanvas = Control.new()
	_kanvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kanvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	_kanvas.gui_input.connect(_input_mouse)
	_label_tanya = Gaya.label("", 11, Gaya.PUTIH)
	_label_tanya.position = Vector2(60, 104)
	_label_tanya.size = Vector2(520, 50)
	_label_tanya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_tanya.visible = false
	add_child(_label_tanya)
	_kolom_jawab = VBoxContainer.new()
	_kolom_jawab.position = Vector2(80, 160)
	_kolom_jawab.add_theme_constant_override("separation", 8)
	_kolom_jawab.visible = false
	add_child(_kolom_jawab)
	_label_info = Gaya.label("", 9, Gaya.PUTIH)
	_label_info.position = Vector2(56, 290)
	_label_info.size = Vector2(528, 34)
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
	_label_info.text = "Pilih kain atau foto yang cocok: klik/ketuk, atau Panah + E."


# ------------------------------------------------------------------ gambar

func _rect_ubin(i: int) -> Rect2:
	var x: int = i % KOLOM
	var y: int = i / KOLOM
	return Rect2(ASAL_UBIN + Vector2(x * (UKURAN_UBIN.x + JARAK), y * (UKURAN_UBIN.y + 18.0)), UKURAN_UBIN)


func _gambar() -> void:
	if _tahap != Tahap.PILIH:
		return
	var huruf := ThemeDB.fallback_font
	for i in _barang.size():
		var b: Dictionary = _barang[i]
		var r := _rect_ubin(i)
		_kanvas.draw_rect(r, Color("2a2420"))
		var isi := r.grow(-6.0)
		isi.size.y -= 4.0
		if b["jenis"] == "kain":
			_kanvas.draw_texture_rect(_tekstur[b["id"]], isi, true)
		else:
			_gambar_foto(isi, str(b["gambar"]))
		_kanvas.draw_rect(r, Gaya.KUNING if i == _kursor else Color("4a3e34"), false, 3.0 if i == _kursor else 1.0)
		_kanvas.draw_string(huruf, Vector2(r.position.x, r.end.y + 11), str(b["nama"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 7, Gaya.PUTIH)


## Piktogram foto budaya (bingkai foto cetak + gambar sederhana).
func _gambar_foto(r: Rect2, gambar: String) -> void:
	_kanvas.draw_rect(r, Color("f4ecd8"))
	var dalam := r.grow(-4.0)
	_kanvas.draw_rect(dalam, Color("9ec6d8"))
	var c: Vector2 = dalam.get_center()
	var tanah := Rect2(Vector2(dalam.position.x, c.y + 6), Vector2(dalam.size.x, dalam.end.y - c.y - 6))
	match gambar:
		"mbaru_niang":
			_kanvas.draw_rect(tanah, Color("6a9a4a"))
			for dx: float in [-22.0, 0.0, 22.0]:
				var s: float = 1.2 if dx == 0.0 else 0.8
				var atap := PackedVector2Array([c + Vector2(dx, -22 * s + 6), c + Vector2(dx - 12 * s, 10), c + Vector2(dx + 12 * s, 10)])
				_kanvas.draw_colored_polygon(atap, Color("6a4a2a"))
		"compang":
			_kanvas.draw_rect(tanah, Color("6a9a4a"))
			_kanvas.draw_rect(Rect2(c + Vector2(-22, 0), Vector2(44, 10)), Color("8a857c"))
			_kanvas.draw_rect(Rect2(c + Vector2(-14, -8), Vector2(28, 8)), Color("77736b"))
			_kanvas.draw_circle(c + Vector2(0, -12), 5.0, Color("6e6a62"))
		"lingko":
			_kanvas.draw_rect(dalam, Color("8fbf5a"))
			_kanvas.draw_arc(c, 18.0, 0.0, TAU, 24, Color("5a4026"), 2.0)
			for i in 8:
				var a: float = TAU * i / 8.0 + 0.3 * (i % 3)
				_kanvas.draw_line(c, c + Vector2(cos(a), sin(a)) * 18.0, Color("5a4026"), 1.5)
		"wae_teku":
			_kanvas.draw_rect(tanah, Color("6a9a4a"))
			_kanvas.draw_circle(c + Vector2(0, 6), 12.0, Color("8a857c"))
			_kanvas.draw_circle(c + Vector2(0, 6), 9.0, Color("5fa8d3"))
		"caci":
			_kanvas.draw_rect(tanah, Color("b08a5c"))
			_kanvas.draw_circle(c + Vector2(-14, -2), 8.0, Color("c8a868"))
			_kanvas.draw_line(c + Vector2(4, -14), c + Vector2(20, 8), Color("3b2a1c"), 2.0)
			_kanvas.draw_line(c + Vector2(-2, -12), c + Vector2(-2, 10), Color("8a5432"), 3.0)


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if _diakhiri or not GameState.sedang(GameState.State.MINIGAME):
		return
	if _tahap == Tahap.PILIH:
		if event.is_action_pressed("kiri"):
			_gerak(-1)
		elif event.is_action_pressed("kanan"):
			_gerak(1)
		elif event.is_action_pressed("maju"):
			_gerak(-KOLOM)
		elif event.is_action_pressed("mundur"):
			_gerak(KOLOM)
		elif event.is_action_pressed("interaksi") or event.is_action_pressed("lompat"):
			_pilih(_kursor)
		else:
			return
		get_viewport().set_input_as_handled()
	elif _tahap == Tahap.CERITA and event is InputEventKey and event.pressed and not event.echo:
		var angka: int = (event as InputEventKey).keycode - KEY_1
		if angka >= 0 and angka < _kolom_jawab.get_child_count():
			get_viewport().set_input_as_handled()
			_jawab(angka)


func _input_mouse(event: InputEvent) -> void:
	if _diakhiri or _tahap != Tahap.PILIH or not GameState.sedang(GameState.State.MINIGAME):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _barang.size():
			if _rect_ubin(i).has_point(event.position):
				_kursor = i
				_pilih(i)
				return


func _gerak(langkah: int) -> void:
	_kursor = clampi(_kursor + langkah, 0, _barang.size() - 1)
	_kanvas.queue_redraw()


func _pilih(i: int) -> void:
	var b: Dictionary = _barang[i]
	var cocok: Array = _wisatawan["cocok"]
	if not cocok.has(b["id"]):
		salah.emit("salah barang")
		AudioManager.putar_sfx("gagal")
		_label_info.text = "%s: \"%s\" Coba barang lain." % [_wisatawan["nama"], DataLabuanBajo.teks("salah_barang")]
		_kanvas.queue_redraw()
		return
	AudioManager.putar_sfx("ambil")
	_mulai_cerita(str(b["nama"]))


func _mulai_cerita(nama_barang: String) -> void:
	_tahap = Tahap.CERITA
	_kanvas.queue_redraw()
	_label_minta.text = "%s memegang %s dan bertanya:" % [_wisatawan["nama"], nama_barang.to_lower()]
	_label_tanya.text = str(_wisatawan["tanya"])
	_label_tanya.visible = true
	_kolom_jawab.visible = true
	var ucapan: String = str(_wisatawan["tanya"])
	var pilihan: Array = _wisatawan["pilihan"]
	for i in pilihan.size():
		var tombol := Gaya.tombol("%d.  %s" % [i + 1, str(pilihan[i])])
		tombol.custom_minimum_size = Vector2(480, 28)
		tombol.pressed.connect(_jawab.bind(i))
		_kolom_jawab.add_child(tombol)
		ucapan += " %d, %s." % [i + 1, str(pilihan[i])]
	_kolom_jawab.get_child(0).call_deferred("grab_focus")
	_label_info.text = "Ceritakan maknanya. Jawabannya ada di kartu budayamu (klik, panah + Enter, atau 1-3)."
	if DialogManager.suara_tersedia():
		DialogManager._ucapkan(ucapan, str(_wisatawan["nama"]))


func _jawab(i: int) -> void:
	if _tahap != Tahap.CERITA or _diakhiri:
		return
	if DialogManager.suara_tersedia():
		DisplayServer.tts_stop()
	if i == int(_wisatawan["benar"]):
		_tahap = Tahap.AKHIR
		AudioManager.putar_sfx("berhasil")
		_label_info.text = "%s: \"%s\"  TERJUAL!" % [_wisatawan["nama"], _wisatawan["terima"]]
		_kolom_jawab.visible = false
		get_tree().create_timer(1.6, false).timeout.connect(_akhiri.bind(true))
		return
	_salah_cerita += 1
	salah.emit("salah cerita")
	AudioManager.putar_sfx("gagal")
	if _sulit:
		_tahap = Tahap.AKHIR
		pergi = true
		_kolom_jawab.visible = false
		_label_info.text = "%s: \"%s\"" % [_wisatawan["nama"], DataLabuanBajo.teks("pergi")]
		get_tree().create_timer(1.8, false).timeout.connect(_akhiri.bind(false))
	else:
		_label_info.text = "%s: \"%s\"" % [_wisatawan["nama"], DataLabuanBajo.teks("ragu")]


func _akhiri(berhasil: bool) -> void:
	if _diakhiri or not is_inside_tree():
		return
	_diakhiri = true
	GameState.ubah_state(GameState.State.BERMAIN)
	selesai.emit(berhasil)
	queue_free()
