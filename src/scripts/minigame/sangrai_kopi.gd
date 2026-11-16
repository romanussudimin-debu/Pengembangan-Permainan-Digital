class_name SangraiKopi
extends CanvasLayer
## Mini-game MENYANGRAI KOPI (Level 1, Ema Agus). Adaptasi kreatif dari pengolahan kopi tradisional
## Wae Rebo (diolah tanpa mesin; lihat catatan riset).
##   Tahap 1 MEMILAH : biji kopi bagus tercampur kerikil dan biji busuk. Ketuk yang buruk untuk dibuang.
##                     Pengecoh adil: kerikil lebih abu-abu dan bulat tanpa garis tengah; biji busuk lebih
##                     gelap dengan bintik hitam. Membuang biji bagus = -1 nyawa.
##   Tahap 2 MENYANGRAI: panas tungku naik sendiri; tekan Aduk (E/Spasi/ketuk) untuk meredam panas.
##                     Kematangan hanya bertambah saat panas di zona hijau. Terlalu lama di zona merah =
##                     kopi gosong (-1 nyawa) dan sangrai diulang.

signal selesai(berhasil: bool)
signal salah(penyebab: String)

enum Tahap { MEMILAH, SANGRAI, AKHIR }

const KOLOM: int = 7
const BARIS: int = 4
const SISI: float = 46.0
const ASAL := Vector2(158, 88)
const ZONA_HIJAU := Vector2(0.4, 0.7)
const BATAS_MERAH: float = 0.85
const DETIK_GOSONG: float = 1.3

var batal: bool = false
var kesalahan: int = 0  ## untuk bintang (tahap berikutnya)

var _tahap: int = Tahap.MEMILAH
var _biji: Array[Dictionary] = []  ## {jenis: "bagus"|"kerikil"|"busuk", ada: bool, goyang: float, putar: float}
var _kursor: int = 0
var _panas: float = 0.3
var _matang: float = 0.0
var _di_merah: float = 0.0
var _hembus: float = 0.0
var _waktu: float = 0.0
var _diakhiri: bool = false
var _kanvas: Control
var _label_info: Label
var _tombol_aduk: Button


func _ready() -> void:
	layer = 40
	_acak_biji()
	_bangun_ui()
	GameState.ubah_state(GameState.State.MINIGAME)


func _acak_biji() -> void:
	var jenis: Array[String] = []
	for i in 3:
		jenis.append("kerikil")
		jenis.append("busuk")
	while jenis.size() < KOLOM * BARIS:
		jenis.append("bagus")
	jenis.shuffle()
	for j: String in jenis:
		_biji.append({"jenis": j, "ada": true, "goyang": 0.0, "putar": randf_range(-0.6, 0.6)})


func _bangun_ui() -> void:
	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	add_child(Gaya.panel_songke(Vector2(40, 30), Vector2(560, 300)))
	var judul := Gaya.label("MENYANGRAI KOPI", 15, Gaya.KUNING)
	judul.position = Vector2(56, 38)
	add_child(judul)
	_label_info = Gaya.label("", 9, Gaya.PUTIH)
	_label_info.position = Vector2(56, 290)
	_label_info.size = Vector2(530, 34)
	_label_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label_info)
	_kanvas = Control.new()
	_kanvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kanvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	_kanvas.gui_input.connect(_input_mouse)
	_tombol_aduk = Gaya.tombol("Aduk [E]")
	_tombol_aduk.custom_minimum_size = Vector2(130, 34)
	_tombol_aduk.add_theme_font_size_override("font_size", 13)
	_tombol_aduk.position = Vector2(430, 236)
	_tombol_aduk.focus_mode = Control.FOCUS_NONE
	_tombol_aduk.pressed.connect(_aduk)
	_tombol_aduk.visible = false
	add_child(_tombol_aduk)
	var berhenti := Gaya.tombol("Berhenti")
	berhenti.custom_minimum_size = Vector2(110, 24)
	berhenti.position = Vector2(474, 36)
	berhenti.focus_mode = Control.FOCUS_NONE
	berhenti.pressed.connect(func() -> void:
		batal = true
		_akhiri(false))
	add_child(berhenti)
	_label_info.text = "Tahap 1: ketuk KERIKIL (abu-abu, bulat) dan BIJI BUSUK (gelap, berbintik) untuk dibuang. Biji bagus jangan dibuang!"


# ------------------------------------------------------------------ gambar

func _pusat_biji(i: int) -> Vector2:
	return ASAL + Vector2((i % KOLOM) * SISI, (i / KOLOM) * SISI) + Vector2(SISI, SISI) / 2.0


func _gambar() -> void:
	match _tahap:
		Tahap.MEMILAH:
			_gambar_tampah()
		_:
			_gambar_sangrai()


## Tampah anyaman dengan biji-biji kopi.
func _gambar_tampah() -> void:
	var c := _kanvas
	var tampah := Rect2(ASAL - Vector2(10, 10), Vector2(KOLOM * SISI + 20, BARIS * SISI + 20))
	c.draw_rect(tampah, Color("8a6a3c"))
	c.draw_rect(tampah.grow(-5.0), Color("b08a50"))
	for k in 12:  # anyaman bambu
		var x: float = tampah.position.x + 10.0 + k * 28.0
		c.draw_line(Vector2(x, tampah.position.y + 5), Vector2(x, tampah.end.y - 5), Color("9a7440"), 1.0)
	for i in _biji.size():
		var b: Dictionary = _biji[i]
		if not b["ada"]:
			continue
		var p: Vector2 = _pusat_biji(i) + Vector2(sin(_waktu * 40.0) * 3.0 * float(b["goyang"]), 0)
		_gambar_biji(p, b)
		if i == _kursor:
			c.draw_arc(_pusat_biji(i), 19.0, 0.0, TAU, 20, Gaya.PUTIH, 2.0)


func _gambar_biji(p: Vector2, b: Dictionary) -> void:
	var c := _kanvas
	c.draw_set_transform(p, float(b["putar"]), Vector2.ONE)
	match str(b["jenis"]):
		"kerikil":
			c.draw_circle(Vector2.ZERO, 11.0, Color("8a8680"))
			c.draw_circle(Vector2(-3, -3), 4.0, Color("a6a29a"))
		"busuk":
			_elips(Vector2.ZERO, Vector2(13, 9), Color("6e5a34"))
			c.draw_line(Vector2(-9, 0), Vector2(9, 1), Color("3a2a14"), 2.0)
			c.draw_circle(Vector2(4, -3), 2.6, Color("1e1408"))
		_:
			_elips(Vector2.ZERO, Vector2(13, 9), Color("c8b07a"))
			c.draw_line(Vector2(-9, 0), Vector2(9, 0), Color("8a7040"), 2.0)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _elips(p: Vector2, r: Vector2, warna: Color) -> void:
	var titik := PackedVector2Array()
	for k in 16:
		var a: float = TAU * k / 16.0
		titik.append(p + Vector2(cos(a) * r.x, sin(a) * r.y))
	_kanvas.draw_colored_polygon(titik, warna)


## Wajan di atas tungku, biji makin cokelat, meteran panas, dan bilah kematangan.
func _gambar_sangrai() -> void:
	var c := _kanvas
	var pusat := Vector2(250, 190)
	for k in 5:  # nyala api
		var tinggi: float = 28.0 + sin(_waktu * 9.0 + k) * 8.0 + _panas * 30.0
		var x: float = pusat.x - 60.0 + k * 30.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 12, 280), Vector2(x, 280 - tinggi), Vector2(x + 12, 280)]),
				Color("ff9a3c").lerp(Color("ff3a1c"), _panas))
	c.draw_rect(Rect2(pusat.x - 100, 270, 200, 16), Color("4a3e34"))
	c.draw_circle(pusat, 92.0, Color("2a2420"))
	c.draw_circle(pusat, 84.0, Color("3a3430"))
	var hangus: float = clampf(_di_merah / DETIK_GOSONG, 0.0, 1.0) * 0.8
	var warna_biji: Color = Color("c8b07a").lerp(Color("5a3418"), _matang).lerp(Color("1a1008"), hangus)
	var acak := RandomNumberGenerator.new()
	acak.seed = 3
	for i in 22:
		var a: float = acak.randf() * TAU + _waktu * (0.6 if _hembus > 0.0 else 0.15)
		var r: float = acak.randf_range(10.0, 66.0)
		var p: Vector2 = pusat + Vector2(cos(a), sin(a)) * r
		c.draw_set_transform(p, a, Vector2.ONE)
		_elips(Vector2.ZERO, Vector2(8, 5.5), warna_biji)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Meteran panas (vertikal): biru-dingin, hijau-pas, merah-gosong
	var bar := Rect2(400, 90, 26, 180)
	c.draw_rect(bar, Color("1b1818"))
	var tinggi_merah: float = bar.size.y * (1.0 - BATAS_MERAH)
	c.draw_rect(Rect2(bar.position.x, bar.position.y, bar.size.x, tinggi_merah), Color(Gaya.MERAH, 0.6))
	var tinggi_hijau: float = bar.size.y * (ZONA_HIJAU.y - ZONA_HIJAU.x)
	c.draw_rect(Rect2(bar.position.x, bar.end.y - bar.size.y * ZONA_HIJAU.y, bar.size.x, tinggi_hijau), Color(Gaya.HIJAU, 0.8))
	var y_jarum: float = bar.end.y - bar.size.y * _panas
	c.draw_rect(Rect2(bar.position.x - 6, y_jarum - 2, bar.size.x + 12, 4), Gaya.PUTIH)
	c.draw_rect(bar, Gaya.KUNING, false, 2.0)
	c.draw_string(ThemeDB.fallback_font, Vector2(390, 84), "Panas", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Gaya.PUTIH)
	# Bilah kematangan
	c.draw_string(ThemeDB.fallback_font, Vector2(450, 104), "Kematangan", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Gaya.PUTIH)
	c.draw_rect(Rect2(450, 110, 120, 14), Color("1b1818"))
	c.draw_rect(Rect2(451, 111, 118 * _matang, 12), Color("8a5432"))
	c.draw_rect(Rect2(450, 110, 120, 14), Gaya.KUNING, false, 1.0)
	if _di_merah > 0.0:
		c.draw_string(ThemeDB.fallback_font, Vector2(450, 150), "Terlalu panas! Aduk!", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ff6a5a"))


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if _diakhiri or not GameState.sedang(GameState.State.MINIGAME):
		return
	if _tahap == Tahap.MEMILAH:
		if event.is_action_pressed("kiri"):
			_gerak(-1)
		elif event.is_action_pressed("kanan"):
			_gerak(1)
		elif event.is_action_pressed("maju"):
			_gerak(-KOLOM)
		elif event.is_action_pressed("mundur"):
			_gerak(KOLOM)
		elif event.is_action_pressed("interaksi") or event.is_action_pressed("lompat"):
			_buang(_kursor)
		else:
			return
		get_viewport().set_input_as_handled()
	elif _tahap == Tahap.SANGRAI and (event.is_action_pressed("interaksi") or event.is_action_pressed("lompat")):
		get_viewport().set_input_as_handled()
		_aduk()


func _input_mouse(event: InputEvent) -> void:
	if _diakhiri or _tahap != Tahap.MEMILAH or not GameState.sedang(GameState.State.MINIGAME):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _biji.size():
			if _biji[i]["ada"] and _pusat_biji(i).distance_to(event.position) < 20.0:
				_kursor = i
				_buang(i)
				return


func _gerak(langkah: int) -> void:
	_kursor = clampi(_kursor + langkah, 0, _biji.size() - 1)


func _buang(i: int) -> void:
	var b: Dictionary = _biji[i]
	if not b["ada"]:
		return
	if b["jenis"] == "bagus":
		# Pengecoh: biji bagus jangan dibuang
		b["goyang"] = 1.0
		kesalahan += 1
		AudioManager.putar_sfx("gagal")
		salah.emit("membuang biji kopi bagus")
		_label_info.text = "Itu biji bagus! Biji bagus berwarna krem dengan garis tengah rata."
		return
	b["ada"] = false
	AudioManager.putar_sfx("klik", 0.2)
	if _sisa_buruk() == 0:
		_mulai_sangrai()


func _sisa_buruk() -> int:
	var n: int = 0
	for b: Dictionary in _biji:
		if b["ada"] and b["jenis"] != "bagus":
			n += 1
	return n


func _mulai_sangrai() -> void:
	_tahap = Tahap.SANGRAI
	AudioManager.putar_sfx("berhasil")
	_tombol_aduk.visible = true
	_label_info.text = "Tahap 2: panas naik sendiri. Tekan ADUK agar jarum tetap di zona hijau sampai kopi matang."


func _aduk() -> void:
	if _tahap != Tahap.SANGRAI:
		return
	_panas = maxf(_panas - 0.09, 0.0)
	_hembus = 0.25
	AudioManager.putar_sfx("langkah", 0.3)


func _process(delta: float) -> void:
	_waktu += delta
	for b: Dictionary in _biji:
		b["goyang"] = maxf(float(b["goyang"]) - delta * 2.0, 0.0)
	_hembus = maxf(_hembus - delta, 0.0)
	if _tahap == Tahap.SANGRAI and not _diakhiri and GameState.sedang(GameState.State.MINIGAME):
		# Panas naik dengan hembusan api yang berubah-ubah; makin matang, makin cepat panas
		_panas = minf(_panas + delta * (0.16 + 0.1 * sin(_waktu * 1.7) + 0.08 * _matang), 1.0)
		if _panas >= ZONA_HIJAU.x and _panas <= ZONA_HIJAU.y:
			_matang = minf(_matang + delta * 0.09, 1.0)
		if _panas >= BATAS_MERAH:
			_di_merah += delta
			if _di_merah >= DETIK_GOSONG:
				_gosong()
		else:
			_di_merah = maxf(_di_merah - delta * 2.0, 0.0)
		if _matang >= 1.0:
			_berhasil()
	_kanvas.queue_redraw()


func _gosong() -> void:
	kesalahan += 1
	_di_merah = 0.0
	_matang = 0.0
	_panas = 0.3
	AudioManager.putar_sfx("gagal")
	salah.emit("kopi gosong")
	_label_info.text = "Kopinya gosong! Sangrai diulang. Aduk lebih sering saat jarum mendekati merah."


func _berhasil() -> void:
	_tahap = Tahap.AKHIR
	_tombol_aduk.visible = false
	AudioManager.putar_sfx("berhasil")
	_label_info.text = "Kopi tersangrai sempurna, harum sekali!"
	get_tree().create_timer(1.4, false).timeout.connect(_akhiri.bind(true))


func _akhiri(berhasil: bool) -> void:
	if _diakhiri or not is_inside_tree():
		return
	_diakhiri = true
	GameState.ubah_state(GameState.State.BERMAIN)
	selesai.emit(berhasil)
	queue_free()
