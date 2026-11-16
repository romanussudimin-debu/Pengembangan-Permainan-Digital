extends CanvasLayer
## HUD level: tujuan saat ini, jumlah kartu budaya, nyawa (ikon hati), dan petunjuk kontrol.

const UKURAN_HATI: float = 8.0
const JARAK_HATI: float = 20.0

var _label_tujuan: Label
var _label_kartu: Label
var _hati: Control
var _indeks_pecah: int = -1
var _waktu_pecah: float = 0.0
var _denyut: float = 0.0
var _label_plus: Label


func _ready() -> void:
	layer = 10
	var panel := Gaya.panel_songke(Vector2(8, 8), Vector2(440, 74))
	add_child(panel)
	_label_tujuan = Gaya.label("", 9, Gaya.PUTIH)
	_label_tujuan.position = Vector2(12, 9)
	_label_tujuan.size = Vector2(420, 44)
	_label_tujuan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_label_tujuan)
	_label_kartu = Gaya.label("", 10, Gaya.KUNING)
	_label_kartu.position = Vector2(12, 54)
	panel.add_child(_label_kartu)
	# Nyawa: deretan hati di kanan bawah panel
	_hati = Control.new()
	_hati.position = Vector2(332, 52)
	_hati.size = Vector2(104, 20)
	_hati.draw.connect(_gambar_hati)
	panel.add_child(_hati)
	_label_plus = Gaya.label("+1", 14, Color("7fd47f"))
	_label_plus.position = Vector2(420, 56)
	_label_plus.modulate.a = 0.0
	add_child(_label_plus)
	Nyawa.berubah.connect(_saat_nyawa_berubah)
	var kontrol := Gaya.label("WASD: jalan  Spasi: lompat  E: interaksi  Esc: jeda", 8, Gaya.PUTIH)
	kontrol.position = Vector2(8, 344)
	kontrol.visible = not KontrolSentuh.aktif_di_perangkat  # di HP diganti joystick & tombol sentuh
	add_child(kontrol)
	GameState.progres_berubah.connect(_perbarui)
	GameState.state_berubah.connect(func(_l: int, baru: int) -> void: visible = baru != GameState.State.DIALOG)
	_perbarui()


func _process(delta: float) -> void:
	if _waktu_pecah > 0.0 or _denyut > 0.0:
		_waktu_pecah = maxf(_waktu_pecah - delta, 0.0)
		_denyut = maxf(_denyut - delta, 0.0)
		_hati.queue_redraw()


func _saat_nyawa_berubah(sisa: int, selisih: int) -> void:
	if selisih < 0:
		_indeks_pecah = sisa  # hati yang baru hilang
		_waktu_pecah = 0.6
	elif selisih > 0:
		_denyut = 0.5
		_label_plus.position = Vector2(_hati.position.x + 8.0 + (sisa - 1) * JARAK_HATI, 40)
		_label_plus.modulate.a = 1.0
		var tw := create_tween().set_parallel()
		tw.tween_property(_label_plus, "position:y", 20.0, 0.8).set_ease(Tween.EASE_OUT)
		tw.tween_property(_label_plus, "modulate:a", 0.0, 0.8).set_delay(0.3)
	_hati.queue_redraw()


func _gambar_hati() -> void:
	for i in Nyawa.maks():
		var pusat := Vector2(10.0 + i * JARAK_HATI, 10.0)
		var r: float = UKURAN_HATI
		if i == _indeks_pecah and _waktu_pecah > 0.0:
			# Hati pecah: bergetar, membesar sesaat, lalu memudar menjadi kosong (retak)
			var t: float = _waktu_pecah / 0.6
			pusat += Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0)) * t
			r *= 1.0 + 0.4 * t
			GambarHati.gambar(_hati, pusat, r, false, true)
			continue
		if i == Nyawa.sisa - 1 and _denyut > 0.0:
			r *= 1.0 + 0.35 * (_denyut / 0.5)
		GambarHati.gambar(_hati, pusat, r, i < Nyawa.sisa)


func _perbarui() -> void:
	_label_tujuan.text = "Petunjuk: " + GameState.teks_tujuan()
	var lv: int = GameState.level
	_label_kartu.text = "Level %d · Kartu Budaya: %d/%d" % [lv, GameState.jumlah_terkumpul_level(lv), GameState.kartu_level(lv).size()]
