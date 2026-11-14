class_name SaluranAir
extends CanvasLayer
## Mini-game MENGALIRKAN AIR DARI WAE TEKU: putar potongan saluran agar air dari mata air
## (kiri) sampai ke DUA petak sawah (kanan atas dan kanan bawah).
## Kontrol: klik/ketuk potongan untuk memutar 90°, atau panah/WASD + E/Spasi. Esc menjeda.
## Mode Sulit: jumlah putaran dibatasi (putaran minimum + 6); melebihi batas = gagal.

signal selesai(berhasil: bool)

const KOLOM: int = 6
const BARIS: int = 5
const SISI: float = 38.0
const ASAL := Vector2(206, 82)
const LONGGAR_SULIT: int = 6

## Arah sambungan sebagai bit: utara, timur, selatan, barat.
const U: int = 1
const T: int = 2
const S: int = 4
const B: int = 8
const ARAH: Dictionary = {U: Vector2i(0, -1), T: Vector2i(1, 0), S: Vector2i(0, 1), B: Vector2i(-1, 0)}
const LAWAN: Dictionary = {U: S, T: B, S: U, B: T}

const SUMBER := Vector2i(0, 2)  ## air masuk dari sisi barat sel ini
const TUJUAN: Array[Vector2i] = [Vector2i(5, 0), Vector2i(5, 4)]  ## air keluar ke sisi timur sel ini

## Susunan jawaban: dari wae teku bercabang ke dua petak.
const SOLUSI: Dictionary = {
	Vector2i(0, 2): 10, Vector2i(1, 2): 10, Vector2i(2, 2): 13,
	Vector2i(2, 1): 5, Vector2i(2, 0): 6, Vector2i(3, 0): 10, Vector2i(4, 0): 12,
	Vector2i(4, 1): 3, Vector2i(5, 1): 9, Vector2i(5, 0): 6,
	Vector2i(2, 3): 3, Vector2i(3, 3): 12, Vector2i(3, 4): 3, Vector2i(4, 4): 10, Vector2i(5, 4): 10,
}
const PENGECOH: Array[int] = [5, 10, 3, 6, 12, 9]

const WARNA_AIR := Color("5fa8d3")
const WARNA_KERING := Color("8a6a44")
const WARNA_PETAK := Color("3d5a32")

var _ubin: Dictionary = {}  ## Vector2i -> bit sambungan saat ini
var _basah: Dictionary = {}
var _kursor := Vector2i(0, 2)
var _putaran: int = 0
var _batas: int = -1  ## -1 = tanpa batas (mode Normal)
var _selesai: bool = false
var _kanvas: Control
var _label_info: Label


func _ready() -> void:
	layer = 40
	_acak()
	_bangun_ui()
	_alirkan()
	GameState.ubah_state(GameState.State.MINIGAME)


static func putar(m: int) -> int:
	return ((m << 1) | (m >> 3)) & 15


## Mengisi papan dengan solusi + pengecoh, lalu memutar setiap potongan secara acak.
func _acak() -> void:
	var acak := RandomNumberGenerator.new()
	acak.randomize()
	for y in BARIS:
		for x in KOLOM:
			var p := Vector2i(x, y)
			var m: int = SOLUSI[p] if SOLUSI.has(p) else PENGECOH[acak.randi() % PENGECOH.size()]
			for i in acak.randi_range(0, 3):
				m = putar(m)
			_ubin[p] = m
	# Pastikan papan tidak langsung terpecahkan
	if _putaran_minimum() < 4:
		_ubin[Vector2i(2, 2)] = putar(SOLUSI[Vector2i(2, 2)])
		_ubin[Vector2i(4, 0)] = putar(putar(SOLUSI[Vector2i(4, 0)]))
		_ubin[Vector2i(3, 4)] = putar(SOLUSI[Vector2i(3, 4)])
		_ubin[Vector2i(1, 2)] = putar(SOLUSI[Vector2i(1, 2)])
	if GameState.mode_sulit:
		_batas = _putaran_minimum() + LONGGAR_SULIT


## Jumlah putaran paling sedikit agar semua potongan jawaban berada di posisi benar.
func _putaran_minimum() -> int:
	var total: int = 0
	for p: Vector2i in SOLUSI:
		var m: int = _ubin[p]
		var k: int = 0
		while m != SOLUSI[p] and k < 4:
			m = putar(m)
			k += 1
		total += k
	return total


## Menyebarkan air dari sumber lewat sambungan yang saling bertemu (BFS).
func _alirkan() -> void:
	_basah.clear()
	if not (_ubin[SUMBER] & B):
		return
	var antrean: Array[Vector2i] = [SUMBER]
	_basah[SUMBER] = true
	while not antrean.is_empty():
		var p: Vector2i = antrean.pop_front()
		var m: int = _ubin[p]
		for bit: int in ARAH:
			if not (m & bit):
				continue
			var n: Vector2i = p + ARAH[bit]
			if n.x < 0 or n.y < 0 or n.x >= KOLOM or n.y >= BARIS or _basah.has(n):
				continue
			if _ubin[n] & LAWAN[bit]:
				_basah[n] = true
				antrean.append(n)


func _semua_petak_terairi() -> bool:
	for p: Vector2i in TUJUAN:
		if not _basah.has(p) or not (_ubin[p] & T):
			return false
	return true


func _bangun_ui() -> void:
	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	add_child(Gaya.panel_songke(Vector2(40, 30), Vector2(560, 300)))
	var judul := Gaya.label("MENGALIRKAN AIR WAE TEKU", 16, Gaya.KUNING)
	judul.position = Vector2(60, 40)
	add_child(judul)
	var l1 := Gaya.label("Wae teku", 9, Gaya.PUTIH)
	l1.position = Vector2(66, ASAL.y + SUMBER.y * SISI + 10)
	add_child(l1)
	for p: Vector2i in TUJUAN:
		var l := Gaya.label("Petak", 9, Gaya.PUTIH)
		l.position = Vector2(ASAL.x + KOLOM * SISI + 44, ASAL.y + p.y * SISI + 10)
		add_child(l)
	_label_info = Gaya.label("", 9, Gaya.PUTIH)
	_label_info.position = Vector2(60, 282)
	_label_info.size = Vector2(520, 40)
	_label_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label_info)
	_kanvas = Control.new()
	_kanvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kanvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	_kanvas.gui_input.connect(_input_mouse)
	var berhenti := Gaya.tombol("Berhenti")
	berhenti.custom_minimum_size = Vector2(110, 24)
	berhenti.position = Vector2(470, 40)
	berhenti.focus_mode = Control.FOCUS_NONE
	berhenti.pressed.connect(_akhiri.bind(false))
	add_child(berhenti)
	_perbarui_info()


func _rect_sel(p: Vector2i) -> Rect2:
	return Rect2(ASAL + Vector2(p) * SISI, Vector2(SISI - 2, SISI - 2))


func _gambar() -> void:
	# Mata air (kiri) dan dua petak sawah (kanan)
	var y_sumber: float = ASAL.y + SUMBER.y * SISI + SISI / 2.0
	_kanvas.draw_circle(Vector2(ASAL.x - 22, y_sumber), 14.0, WARNA_AIR)
	_kanvas.draw_line(Vector2(ASAL.x - 10, y_sumber), Vector2(ASAL.x, y_sumber), WARNA_AIR, 8.0)
	for p: Vector2i in TUJUAN:
		var r := Rect2(Vector2(ASAL.x + KOLOM * SISI + 4, ASAL.y + p.y * SISI + 2), Vector2(34, SISI - 6))
		var terairi: bool = _basah.has(p) and (_ubin[p] & T)
		_kanvas.draw_rect(r, WARNA_AIR if terairi else WARNA_PETAK)
		_kanvas.draw_rect(r, Gaya.KUNING, false, 2.0)
	for p: Vector2i in _ubin:
		var r := _rect_sel(p)
		_kanvas.draw_rect(r, Color("2a2420"))
		_kanvas.draw_rect(r, Color("4a3e34"), false, 1.0)
		var pusat: Vector2 = r.get_center()
		var warna: Color = WARNA_AIR if _basah.has(p) else WARNA_KERING
		var m: int = _ubin[p]
		for bit: int in ARAH:
			if m & bit:
				var arah: Vector2 = Vector2(ARAH[bit])
				_kanvas.draw_line(pusat, pusat + arah * (SISI / 2.0), warna, 9.0)
		_kanvas.draw_circle(pusat, 5.0, warna)
	var rk := _rect_sel(_kursor).grow(2.0)
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
		_putar_sel(_kursor)
	else:
		return
	get_viewport().set_input_as_handled()


func _input_mouse(event: InputEvent) -> void:
	if _selesai or not GameState.sedang(GameState.State.MINIGAME):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var lokal: Vector2 = (event.position - ASAL) / SISI
		var sel := Vector2i(floori(lokal.x), floori(lokal.y))
		if _ubin.has(sel):
			_kursor = sel
			_putar_sel(sel)


func _gerak(arah: Vector2i) -> void:
	_kursor = Vector2i(clampi(_kursor.x + arah.x, 0, KOLOM - 1), clampi(_kursor.y + arah.y, 0, BARIS - 1))
	_kanvas.queue_redraw()


func _putar_sel(p: Vector2i) -> void:
	_ubin[p] = putar(_ubin[p])
	_putaran += 1
	AudioManager.putar_sfx("klik", 0.2)
	_alirkan()
	_kanvas.queue_redraw()
	_perbarui_info()
	if _semua_petak_terairi():
		_berhasil()
	elif _batas >= 0 and _putaran >= _batas:
		_gagal()


func _perbarui_info() -> void:
	var batas: String = (" / batas %d" % _batas) if _batas >= 0 else ""
	_label_info.text = "Klik/ketuk potongan untuk memutar (atau Panah/WASD + E). Alirkan air ke KEDUA petak.\nPutaran: %d%s" % [
		_putaran, batas]


func _berhasil() -> void:
	_selesai = true
	AudioManager.putar_sfx("berhasil")
	_label_info.text = "Air mengalir ke kedua petak! (%d putaran)" % _putaran
	get_tree().create_timer(1.5, false).timeout.connect(_akhiri.bind(true))


func _gagal() -> void:
	_selesai = true
	AudioManager.putar_sfx("gagal")
	_label_info.text = "Putaran habis sebelum air sampai ke petak."
	get_tree().create_timer(1.5, false).timeout.connect(_akhiri.bind(false))


func _akhiri(berhasil: bool) -> void:
	if not is_inside_tree():
		return
	_selesai = true
	GameState.ubah_state(GameState.State.BERMAIN)
	selesai.emit(berhasil)
	queue_free()
