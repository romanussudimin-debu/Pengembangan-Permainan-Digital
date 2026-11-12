class_name TenunSongke
extends CanvasLayer
## Mini-game MENENUN SONGKE: pemain menyamakan kain tenunannya dengan contoh motif
## belah ketupat (kain songke berdasar hitam dengan motif berwarna).
## Kontrol: panah/WASD memilih kotak, E/Spasi mengganti warna benang, 1-4 memilih warna langsung,
## atau klik kotak dengan mouse. Esc membatalkan.

signal selesai(berhasil: bool)

const UKURAN: int = 5
const SISI_KOTAK: float = 30.0
## Urutan warna benang: hitam (dasar), kuning, merah, hijau.
const WARNA_BENANG: Array[Color] = [Color("1b1818"), Color("e8b430"), Color("b02a2a"), Color("2e7d46")]
const NAMA_BENANG: Array[String] = ["hitam", "kuning", "merah", "hijau"]
const POS_CONTOH := Vector2(90, 120)
const POS_KAIN := Vector2(400, 120)

var _contoh: Array[int] = []
var _kain: Array[int] = []
var _kursor := Vector2i(2, 2)
var _langkah: int = 0
var _selesai: bool = false
var _kanvas: Control
var _label_info: Label


func _ready() -> void:
	layer = 40
	_buat_contoh()
	_kain.resize(UKURAN * UKURAN)
	_kain.fill(0)
	_bangun_ui()
	GameState.ubah_state(GameState.State.MINIGAME)


## Motif belah ketupat: cincin luar kuning, cincin dalam merah, pusat hijau.
func _buat_contoh() -> void:
	_contoh.resize(UKURAN * UKURAN)
	var pusat: int = UKURAN / 2
	for y in UKURAN:
		for x in UKURAN:
			var jarak: int = absi(x - pusat) + absi(y - pusat)
			var warna: int = 0
			match jarak:
				0:
					warna = 3
				1:
					warna = 2
				2:
					warna = 1
			_contoh[y * UKURAN + x] = warna


func _bangun_ui() -> void:
	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	var panel := Gaya.panel_songke(Vector2(40, 30), Vector2(560, 300))
	add_child(panel)
	var judul := Gaya.label("MENENUN SONGKE", 16, Gaya.KUNING)
	judul.position = Vector2(60, 40)
	add_child(judul)
	var l1 := Gaya.label("Contoh motif", 10, Gaya.PUTIH)
	l1.position = POS_CONTOH + Vector2(0, -18)
	add_child(l1)
	var l2 := Gaya.label("Kain tenunanmu", 10, Gaya.PUTIH)
	l2.position = POS_KAIN + Vector2(0, -18)
	add_child(l2)
	_label_info = Gaya.label("", 9, Gaya.PUTIH)
	_label_info.position = Vector2(60, 290)
	_label_info.size = Vector2(520, 30)
	_label_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label_info)
	_kanvas = Control.new()
	_kanvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kanvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	_kanvas.gui_input.connect(_input_mouse)
	_perbarui_info()


func _gambar() -> void:
	_gambar_grid(POS_CONTOH, _contoh, false)
	_gambar_grid(POS_KAIN, _kain, true)
	# Palet benang
	for i in WARNA_BENANG.size():
		var p := Vector2(400 + i * 40, 286 - 36)
		_kanvas.draw_rect(Rect2(p, Vector2(28, 14)), WARNA_BENANG[i])
		_kanvas.draw_rect(Rect2(p, Vector2(28, 14)), Gaya.PUTIH, false, 1.0)
		_kanvas.draw_string(ThemeDB.fallback_font, p + Vector2(10, 26), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Gaya.PUTIH)


func _gambar_grid(asal: Vector2, data: Array[int], dengan_kursor: bool) -> void:
	for y in UKURAN:
		for x in UKURAN:
			var r := Rect2(asal + Vector2(x, y) * SISI_KOTAK, Vector2(SISI_KOTAK - 2, SISI_KOTAK - 2))
			_kanvas.draw_rect(r, WARNA_BENANG[data[y * UKURAN + x]])
			_kanvas.draw_rect(r, Color("3a3434"), false, 1.0)
	if dengan_kursor:
		var rk := Rect2(asal + Vector2(_kursor) * SISI_KOTAK - Vector2(2, 2), Vector2(SISI_KOTAK + 2, SISI_KOTAK + 2))
		_kanvas.draw_rect(rk, Gaya.PUTIH, false, 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if _selesai or not GameState.sedang(GameState.State.MINIGAME):
		return
	if event.is_action_pressed("kiri"):
		_gerak(Vector2i(-1, 0))
	elif event.is_action_pressed("kanan"):
		_gerak(Vector2i(1, 0))
	elif event.is_action_pressed("maju"):
		_gerak(Vector2i(0, -1))
	elif event.is_action_pressed("mundur"):
		_gerak(Vector2i(0, 1))
	elif event.is_action_pressed("interaksi") or event.is_action_pressed("lompat"):
		_ganti_warna((_kain[_indeks_kursor()] + 1) % WARNA_BENANG.size())
	elif event is InputEventKey and event.pressed and not event.echo:
		var tombol: InputEventKey = event
		var angka: int = tombol.keycode - KEY_1
		if angka >= 0 and angka < WARNA_BENANG.size():
			_ganti_warna(angka)
		elif tombol.keycode == KEY_BACKSPACE:
			_akhiri(false)
		else:
			return
	else:
		return
	get_viewport().set_input_as_handled()


func _input_mouse(event: InputEvent) -> void:
	if _selesai or not GameState.sedang(GameState.State.MINIGAME):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var lokal: Vector2 = (event.position - POS_KAIN) / SISI_KOTAK
		var sel := Vector2i(floori(lokal.x), floori(lokal.y))
		if sel.x >= 0 and sel.y >= 0 and sel.x < UKURAN and sel.y < UKURAN:
			_kursor = sel
			_ganti_warna((_kain[_indeks_kursor()] + 1) % WARNA_BENANG.size())


func _gerak(arah: Vector2i) -> void:
	_kursor = Vector2i(clampi(_kursor.x + arah.x, 0, UKURAN - 1), clampi(_kursor.y + arah.y, 0, UKURAN - 1))
	_kanvas.queue_redraw()


func _indeks_kursor() -> int:
	return _kursor.y * UKURAN + _kursor.x


func _ganti_warna(warna: int) -> void:
	_kain[_indeks_kursor()] = warna
	_langkah += 1
	AudioManager.putar_sfx("klik", 0.2)
	_kanvas.queue_redraw()
	_perbarui_info()
	if _kain == _contoh:
		_berhasil()


func _sisa_berbeda() -> int:
	var n: int = 0
	for i in _kain.size():
		if _kain[i] != _contoh[i]:
			n += 1
	return n


func _perbarui_info() -> void:
	_label_info.text = "Panah/WASD: pilih kotak · E/Spasi atau klik: ganti benang · 1-4: pilih warna · Backspace: berhenti\nKotak yang belum sama: %d · Langkah: %d · Benang terpilih: %s" % [
		_sisa_berbeda(), _langkah, NAMA_BENANG[_kain[_indeks_kursor()]]]


func _berhasil() -> void:
	_selesai = true
	AudioManager.putar_sfx("berhasil")
	_label_info.text = "Kain songke selesai ditenun! (%d langkah)" % _langkah
	var t := get_tree().create_timer(1.5, false)
	t.timeout.connect(_akhiri.bind(true))


func _akhiri(berhasil: bool) -> void:
	_selesai = true
	GameState.ubah_state(GameState.State.BERMAIN)
	selesai.emit(berhasil)
	queue_free()
