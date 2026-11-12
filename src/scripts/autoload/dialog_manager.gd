extends CanvasLayer
## Menampilkan dialog berbasis data (data/dialog.json) dan kartu pengetahuan budaya.
## Dialog DIUCAPKAN dengan Text-to-Speech (suara bahasa Indonesia dari sistem operasi);
## layar hanya menampilkan nama pembicara. Bila suara bahasa Indonesia tidak tersedia,
## atau pemain menyalakan "Tampilkan teks dialog" di menu jeda, teks ditampilkan.
## Selama dialog, GameState berada di state DIALOG lalu dikembalikan ke state sebelumnya.

signal dialog_selesai(id: String)
signal teka_teki_dijawab(benar: bool)

const DATA_DIALOG: JSON = preload("res://data/dialog.json")
const KECEPATAN_KETIK: float = 45.0  # karakter per detik (mode teks)
const JEDA_SETELAH_UCAPAN: float = 0.35
const BAHASA_SUARA: String = "id"

## Nada suara per tokoh agar setiap karakter terdengar berbeda.
const NADA_TOKOH: Dictionary = {
	"Tu'a Golo": 0.75,
	"Ema Agus": 0.8,
	"Fransi": 0.92,
	"Hingha": 1.0,
	"Pemain Caci": 0.95,
	"Nggohak": 1.05,
	"Ine Wela": 1.2,
	"Ende Lono": 1.3,
	"Marngem": 1.15,
	"Ema Yakobus": 0.78,
}

var aktif: bool = false
var tampilkan_teks: bool = false  ## diatur dari menu jeda
var volume_suara: float = 1.0  ## 0..1, diatur dari menu jeda

var _panel: NinePatchRect
var _label_nama: Label
var _label_teks: Label
var _label_lanjut: Label
var _baris: Array = []
var _indeks: int = 0
var _id: String = ""
var _state_sebelum: int = GameState.State.BERMAIN
var _callback: Callable = Callable()
var _frame_mulai: int = -1
var _tween_ketik: Tween
var _suara_id: String = ""
var _nomor_ucapan: int = 0
var _timer_lanjut: Timer

# Teka-teki (pertanyaan pilihan ganda)
var _panel_teka_teki: NinePatchRect
var _label_tanya_nama: Label
var _label_pertanyaan: Label
var _kolom_pilihan: VBoxContainer
var _indeks_benar: int = 0
var _callback_jawaban: Callable = Callable()
var _menjawab: bool = false


func _ready() -> void:
	layer = 50
	_bangun_ui()
	_panel.visible = false
	_timer_lanjut = Timer.new()
	_timer_lanjut.one_shot = true
	_timer_lanjut.timeout.connect(_maju)
	add_child(_timer_lanjut)
	_siapkan_suara()
	_bangun_ui_teka_teki()


func _siapkan_suara() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		push_warning("Text-to-Speech tidak didukung di platform ini; dialog ditampilkan sebagai teks.")
		return
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _saat_ucapan_selesai)
	if not _cari_suara():
		push_warning("Suara bahasa Indonesia belum ditemukan; dialog ditampilkan sebagai teks sampai suara tersedia.")


## Di browser (terutama HP) daftar suara dimuat belakangan, jadi pencarian diulang saat dialog dimulai.
func _cari_suara() -> bool:
	if _suara_id != "":
		return true
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return false
	var suara: PackedStringArray = DisplayServer.tts_get_voices_for_language(BAHASA_SUARA)
	if not suara.is_empty():
		_suara_id = suara[0]
	return _suara_id != ""


## True bila dialog diucapkan (ada suara bahasa Indonesia).
func suara_tersedia() -> bool:
	return _cari_suara()


func _bangun_ui() -> void:
	_panel = NinePatchRect.new()
	_panel.texture = preload("res://assets/textures/bingkai_songke.png")
	_panel.patch_margin_left = 8
	_panel.patch_margin_right = 8
	_panel.patch_margin_top = 8
	_panel.patch_margin_bottom = 8
	add_child(_panel)

	_label_nama = Gaya.label("", 11, Gaya.KUNING)
	_label_nama.position = Vector2(14, 8)
	_panel.add_child(_label_nama)

	_label_teks = Gaya.label("", 10, Gaya.PUTIH)
	_label_teks.position = Vector2(14, 24)
	_label_teks.size = Vector2(564, 54)
	_label_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_label_teks)

	_label_lanjut = Gaya.label("[E] lanjut", 8, Gaya.ABU)
	_panel.add_child(_label_lanjut)


func _bangun_ui_teka_teki() -> void:
	_panel_teka_teki = Gaya.panel_songke(Vector2(90, 40), Vector2(460, 280))
	_panel_teka_teki.visible = false
	add_child(_panel_teka_teki)
	_label_tanya_nama = Gaya.label("", 11, Gaya.KUNING)
	_label_tanya_nama.position = Vector2(16, 10)
	_panel_teka_teki.add_child(_label_tanya_nama)
	_label_pertanyaan = Gaya.label("", 12, Gaya.PUTIH)
	_label_pertanyaan.position = Vector2(16, 30)
	_label_pertanyaan.size = Vector2(428, 70)
	_label_pertanyaan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_teka_teki.add_child(_label_pertanyaan)
	_kolom_pilihan = VBoxContainer.new()
	_kolom_pilihan.position = Vector2(60, 104)
	_kolom_pilihan.add_theme_constant_override("separation", 8)
	_panel_teka_teki.add_child(_kolom_pilihan)
	var bantuan := Gaya.label("Pilih dengan mouse, panah + Enter, atau tombol angka 1-4", 8, Gaya.ABU)
	bantuan.position = Vector2(16, 258)
	_panel_teka_teki.add_child(bantuan)


## Ajukan teka-teki pilihan ganda. `callback` dipanggil dengan argumen bool (benar/salah)
## setelah dialog ditutup dan state game dikembalikan.
func ajukan_teka_teki(nama: String, pertanyaan: String, pilihan: Array, indeks_benar: int, callback: Callable) -> void:
	if aktif:
		return
	_state_sebelum = GameState.state
	if not GameState.ubah_state(GameState.State.DIALOG):
		return
	aktif = true
	_menjawab = true
	_indeks_benar = indeks_benar
	_callback_jawaban = callback
	_label_tanya_nama.text = nama + " bertanya:"
	_label_pertanyaan.text = pertanyaan
	for anak in _kolom_pilihan.get_children():
		anak.queue_free()
	var ucapan: String = pertanyaan
	var huruf: Array[String] = ["A", "B", "C", "D"]
	for i in pilihan.size():
		var b := Gaya.tombol("%d.  %s" % [i + 1, str(pilihan[i])])
		b.custom_minimum_size = Vector2(340, 26)
		b.pressed.connect(_jawab.bind(i))
		_kolom_pilihan.add_child(b)
		ucapan += " %s, %s." % [huruf[i % huruf.size()], str(pilihan[i])]
	_panel_teka_teki.visible = true
	_kolom_pilihan.get_child(0).call_deferred("grab_focus")
	if suara_tersedia():
		_ucapkan(ucapan, nama)


func _jawab(indeks: int) -> void:
	if not _menjawab:
		return
	_menjawab = false
	aktif = false
	_panel_teka_teki.visible = false
	if suara_tersedia():
		DisplayServer.tts_stop()
	var benar: bool = indeks == _indeks_benar
	AudioManager.putar_sfx("berhasil" if benar else "gagal")
	GameState.ubah_state(_state_sebelum)
	var cb: Callable = _callback_jawaban
	_callback_jawaban = Callable()
	teka_teki_dijawab.emit(benar)
	if cb.is_valid():
		cb.call(benar)


func _unhandled_input(event: InputEvent) -> void:
	if not _menjawab or not event is InputEventKey or not event.pressed:
		return
	var tombol: InputEventKey = event
	var angka: int = tombol.keycode - KEY_1
	if angka >= 0 and angka < _kolom_pilihan.get_child_count():
		get_viewport().set_input_as_handled()
		_jawab(angka)


## Ukuran panel: lebar dengan teks, atau ringkas (nama pembicara saja) saat diucapkan.
func _atur_tata_letak(dengan_teks: bool) -> void:
	if dengan_teks:
		_panel.position = Vector2(24, 258)
		_panel.size = Vector2(592, 92)
		_label_lanjut.text = "[E] lanjut"
		_label_lanjut.position = Vector2(530, 76)
	else:
		_panel.position = Vector2(170, 300)
		_panel.size = Vector2(300, 46)
		_label_lanjut.text = "berbicara...  [E] lewati"
		_label_lanjut.position = Vector2(14, 27)
	_label_teks.visible = dengan_teks


## Mulai dialog berdasarkan id di dialog.json.
func mulai(id: String, callback: Callable = Callable()) -> void:
	var semua: Dictionary = DATA_DIALOG.data
	if not semua.has(id):
		push_error("Dialog tidak ditemukan: " + id)
		if callback.is_valid():
			callback.call()
		return
	mulai_baris(id, semua[id], callback)


## Mulai dialog dari daftar baris {"nama": ..., "teks": ...}.
func mulai_baris(id: String, baris: Array, callback: Callable = Callable()) -> void:
	if aktif:
		return
	_id = id
	_baris = baris
	_indeks = 0
	_callback = callback
	_state_sebelum = GameState.state
	if not GameState.ubah_state(GameState.State.DIALOG):
		return
	aktif = true
	_frame_mulai = Engine.get_process_frames()
	_panel.visible = true
	_tampilkan_baris()


## Tampilkan (dan ucapkan) kartu pengetahuan budaya.
func tampilkan_kartu(id_kartu: String, callback: Callable = Callable()) -> void:
	var k: Dictionary = GameState.data_kartu(id_kartu)
	if k.is_empty():
		if callback.is_valid():
			callback.call()
		return
	AudioManager.putar_sfx("ambil")
	var baris: Array = []
	var halaman: Array = k["isi"]
	for i in halaman.size():
		var teks: String = halaman[i]
		var ucapan: String = ("Kartu budaya, %s. %s" % [k["judul"], teks]) if i == 0 else teks
		baris.append({"nama": "Kartu Budaya: " + str(k["judul"]), "teks": teks, "ucapan": ucapan})
	mulai_baris("kartu_" + id_kartu, baris, callback)


func _tampilkan_baris() -> void:
	var b: Dictionary = _baris[_indeks]
	var nama: String = str(b.get("nama", ""))
	_label_nama.text = nama
	_label_teks.text = str(b.get("teks", ""))
	var bersuara: bool = suara_tersedia()
	_atur_tata_letak(tampilkan_teks or not bersuara)
	if _tween_ketik:
		_tween_ketik.kill()
	if _label_teks.visible:
		_label_teks.visible_ratio = 0.0
		_tween_ketik = create_tween()
		var durasi: float = maxf(_label_teks.text.length() / KECEPATAN_KETIK, 0.1)
		_tween_ketik.tween_property(_label_teks, "visible_ratio", 1.0, durasi)
	else:
		_label_teks.visible_ratio = 1.0
	if bersuara:
		_ucapkan(str(b.get("ucapan", b.get("teks", ""))), nama)


func _ucapkan(teks: String, nama: String) -> void:
	_nomor_ucapan += 1
	var nada: float = NADA_TOKOH.get(nama, 1.0)
	var volume: int = int(clampf(volume_suara, 0.0, 1.0) * 100.0)
	DisplayServer.tts_speak(teks, _suara_id, volume, nada, 1.0, _nomor_ucapan, true)


func _saat_ucapan_selesai(nomor: int) -> void:
	# Callback TTS bisa datang dari luar alur utama; teruskan dengan aman.
	call_deferred("_lanjut_setelah_ucapan", nomor)


func _lanjut_setelah_ucapan(nomor: int) -> void:
	if aktif and not _menjawab and nomor == _nomor_ucapan:
		_timer_lanjut.start(JEDA_SETELAH_UCAPAN)


func _process(_delta: float) -> void:
	if not aktif or _menjawab or Engine.get_process_frames() == _frame_mulai:
		return
	if Input.is_action_just_pressed("interaksi") or Input.is_action_just_pressed("lompat"):
		_maju()


func _input(event: InputEvent) -> void:
	if not aktif or _menjawab or Engine.get_process_frames() == _frame_mulai:
		return  # klik/ketukan yang sama dengan yang membuka dialog tidak boleh melewati baris pertama
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_maju()


func _maju() -> void:
	if not aktif or _menjawab:
		return
	if _label_teks.visible and _label_teks.visible_ratio < 1.0 and not suara_tersedia():
		if _tween_ketik:
			_tween_ketik.kill()
		_label_teks.visible_ratio = 1.0
		return
	_timer_lanjut.stop()
	if suara_tersedia():
		DisplayServer.tts_stop()
	AudioManager.putar_sfx("klik")
	_indeks += 1
	if _indeks < _baris.size():
		_tampilkan_baris()
	else:
		_selesai()


func _selesai() -> void:
	aktif = false
	_panel.visible = false
	GameState.ubah_state(_state_sebelum)
	var cb: Callable = _callback
	_callback = Callable()
	dialog_selesai.emit(_id)
	if cb.is_valid():
		cb.call()
