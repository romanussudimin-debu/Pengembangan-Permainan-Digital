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
	# Level 2 (Lingko Lodok)
	"Tu'a Teno": 0.7,
	"Ema Petrus": 0.85,
	"Ine Maria": 1.25,
	"Ema Bonis": 0.9,
	"Ine Sisi": 1.3,
	"Ema Gabriel": 0.95,
	"Ema Lukas": 0.82,
	"Ine Rosa": 1.18,
	"Ema Edu": 0.88,
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
var _mode_pilihan: bool = false  ## true = pilihan netral (callback menerima indeks, tanpa suara benar/salah)
var _mode_pilihan_berikut: bool = false
var _menjawab: bool = false

# Lewati / percepat dialog dan popup kartu ringkas
var _tombol_lewati: Button
var _tahan: float = 0.0
var _jeda_maju_otomatis: float = 0.0
var _panel_kartu: NinePatchRect
var _label_kartu_judul: Label
var _label_kartu_isi: Label
var _antrean_kartu: Array[Dictionary] = []
var _kartu_tampil: bool = false


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
	_bangun_popup_kartu()


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
	# Android menulis bahasa Indonesia dengan kode lama "in" (mis. "in_ID"), browser dengan "id-ID".
	for kode: String in [BAHASA_SUARA, "in"]:
		var suara: PackedStringArray = DisplayServer.tts_get_voices_for_language(kode)
		if not suara.is_empty():
			_suara_id = suara[0]
			return true
	for v: Dictionary in DisplayServer.tts_get_voices():
		var bahasa: String = str(v.get("language", "")).to_lower().replace("-", "_")
		var nama: String = str(v.get("name", "")).to_lower()
		if bahasa == "id" or bahasa == "in" or bahasa == "ind" or bahasa.begins_with("id_") or bahasa.begins_with("in_") \
				or nama.contains("indonesia"):
			_suara_id = str(v.get("id", ""))
			return _suara_id != ""
	return false


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
	# Lewati = langsung ke akhir dialog (juga tombol Tab); tahan E/Spasi/layar = cepat
	_tombol_lewati = Gaya.tombol("Lewati >>")
	_tombol_lewati.custom_minimum_size = Vector2(84, 20)
	_tombol_lewati.add_theme_font_size_override("font_size", 8)
	_tombol_lewati.focus_mode = Control.FOCUS_NONE
	_tombol_lewati.pressed.connect(lewati)
	add_child(_tombol_lewati)
	_tombol_lewati.visible = false


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
	_label_tanya_nama.text = nama + (":" if _mode_pilihan_berikut else " bertanya:")
	_mode_pilihan = _mode_pilihan_berikut
	_mode_pilihan_berikut = false
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


## Pilihan netral (bukan teka-teki): `callback` dipanggil dengan indeks pilihan (int).
func ajukan_pilihan(nama: String, pertanyaan: String, pilihan: Array, callback: Callable) -> void:
	_mode_pilihan_berikut = true
	ajukan_teka_teki(nama, pertanyaan, pilihan, -1, callback)
	_mode_pilihan_berikut = false


func _jawab(indeks: int) -> void:
	if not _menjawab:
		return
	_menjawab = false
	aktif = false
	_panel_teka_teki.visible = false
	if suara_tersedia():
		DisplayServer.tts_stop()
	GameState.ubah_state(_state_sebelum)
	var cb: Callable = _callback_jawaban
	_callback_jawaban = Callable()
	if _mode_pilihan:
		AudioManager.putar_sfx("klik")
		if cb.is_valid():
			cb.call(indeks)
		return
	var benar: bool = indeks == _indeks_benar
	AudioManager.putar_sfx("benar" if benar else "salah")
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
		_label_lanjut.text = "[E] lanjut · tahan = cepat"
		_label_lanjut.position = Vector2(470, 76)
		_tombol_lewati.position = Vector2(526, 236)
	else:
		_panel.position = Vector2(170, 300)
		_panel.size = Vector2(300, 46)
		_label_lanjut.text = "berbicara...  [E] lanjut · tahan = cepat"
		_label_lanjut.position = Vector2(14, 27)
		_tombol_lewati.position = Vector2(380, 278)
	_label_teks.visible = dengan_teks
	_tombol_lewati.visible = true


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
## Kartu budaya baru tampil sebagai popup ringkas (judul + 1 kalimat) yang tidak menghentikan
## permainan; isi lengkapnya dibaca kapan saja di menu jeda (Koleksi Kartu Budaya).
func tampilkan_kartu(id_kartu: String, callback: Callable = Callable()) -> void:
	var k: Dictionary = GameState.data_kartu(id_kartu)
	if not k.is_empty():
		AudioManager.putar_sfx("ambil")
		_antrean_kartu.append(k)
		if not _kartu_tampil:
			_kartu_berikutnya()
	if callback.is_valid():
		callback.call_deferred()


static func ringkasan_kartu(k: Dictionary) -> String:
	if k.has("ringkas"):
		return str(k["ringkas"])
	var isi: Array = k["isi"]
	var kalimat: String = str(isi[0])
	var titik: int = kalimat.find(". ")
	return kalimat.substr(0, titik + 1) if titik > 0 else kalimat


func _bangun_popup_kartu() -> void:
	_panel_kartu = Gaya.panel_songke(Vector2(150, -80), Vector2(340, 64))
	_panel_kartu.visible = false
	_panel_kartu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel_kartu)
	var ikon := Control.new()
	ikon.position = Vector2(10, 10)
	ikon.size = Vector2(30, 40)
	ikon.draw.connect(func() -> void:
		ikon.draw_rect(Rect2(0, 0, 30, 40), Color("f4ecd8"))
		ikon.draw_rect(Rect2(3, 3, 24, 34), Gaya.MERAH, false, 2.0)
		ikon.draw_colored_polygon(PackedVector2Array([Vector2(15, 10), Vector2(23, 20), Vector2(15, 30), Vector2(7, 20)]), Gaya.KUNING))
	_panel_kartu.add_child(ikon)
	_label_kartu_judul = Gaya.label("", 10, Gaya.KUNING)
	_label_kartu_judul.position = Vector2(48, 7)
	_panel_kartu.add_child(_label_kartu_judul)
	_label_kartu_isi = Gaya.label("", 8, Gaya.PUTIH)
	_label_kartu_isi.position = Vector2(48, 22)
	_label_kartu_isi.size = Vector2(282, 26)
	_label_kartu_isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_kartu.add_child(_label_kartu_isi)
	var cat := Gaya.label("Isi lengkap: Esc > Koleksi Kartu Budaya", 7, Gaya.ABU)
	cat.position = Vector2(48, 48)
	_panel_kartu.add_child(cat)


func _kartu_berikutnya() -> void:
	if _antrean_kartu.is_empty():
		_kartu_tampil = false
		_panel_kartu.visible = false
		return
	_kartu_tampil = true
	var k: Dictionary = _antrean_kartu.pop_front()
	_label_kartu_judul.text = "KARTU BUDAYA BARU: " + str(k["judul"])
	_label_kartu_isi.text = ringkasan_kartu(k)
	_panel_kartu.visible = true
	_panel_kartu.position.y = -80.0
	_panel_kartu.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_panel_kartu, "position:y", 92.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.2)
	tw.tween_property(_panel_kartu, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_kartu_berikutnya)
	if suara_tersedia() and not aktif:
		_ucapkan("Kartu budaya baru, %s." % k["judul"], "Nggohak")


## Obrolan ringan: gelembung teks di atas `target` (pemain tetap bisa bergerak) dan diucapkan.
func gelembung(target: Node3D, baris: Array, nama: String = "", tinggi: float = 3.4) -> void:
	if target == null or baris.is_empty():
		return
	Gelembung.pada(target, baris, tinggi)
	if suara_tersedia() and not aktif:
		_ucapkan(" ".join(PackedStringArray(baris)), nama)


## Lewati: langsung ke akhir dialog (callback tetap dijalankan).
func lewati() -> void:
	if not aktif or _menjawab:
		return
	_timer_lanjut.stop()
	if suara_tersedia():
		DisplayServer.tts_stop()
	AudioManager.putar_sfx("klik")
	Analitik.catat("dialog_dilewati", {"baris": _indeks + 1, "dari": _baris.size()})
	_selesai()


func _tampilkan_baris() -> void:
	var b: Dictionary = _baris[_indeks]
	var nama: String = str(b.get("nama", ""))
	_label_nama.text = nama
	_label_teks.text = str(b.get("teks", ""))
	var bersuara: bool = suara_tersedia()
	_atur_tata_letak(tampilkan_teks or GameState.teks_cepat or not bersuara)
	if _tween_ketik:
		_tween_ketik.kill()
	if GameState.teks_cepat:
		_label_teks.visible_ratio = 1.0  # Teks cepat: teks langsung tampil utuh
	elif _label_teks.visible:
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


func _process(delta: float) -> void:
	if not aktif or _menjawab or Engine.get_process_frames() == _frame_mulai:
		_tahan = 0.0
		return
	if Input.is_action_just_pressed("interaksi") or Input.is_action_just_pressed("lompat"):
		_maju()
	# Tahan tombol (atau jari di layar) = dialog dipercepat: baris maju otomatis tiap 0,3 detik
	var ditahan: bool = Input.is_action_pressed("interaksi") or Input.is_action_pressed("lompat") \
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_tahan = _tahan + delta if ditahan else 0.0
	_jeda_maju_otomatis = maxf(_jeda_maju_otomatis - delta, 0.0)
	if _tahan > 0.45 and _jeda_maju_otomatis <= 0.0:
		_jeda_maju_otomatis = 0.3
		if _tween_ketik:
			_tween_ketik.kill()
		_label_teks.visible_ratio = 1.0
		_maju()


func _input(event: InputEvent) -> void:
	if not aktif or _menjawab or Engine.get_process_frames() == _frame_mulai:
		return  # klik/ketukan yang sama dengan yang membuka dialog tidak boleh melewati baris pertama
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		lewati()
		return
	if event is InputEventMouseButton and _tombol_lewati.visible and _tombol_lewati.get_global_rect().has_point(event.position):
		return  # klik tombol Lewati ditangani tombolnya sendiri
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


## Menutup dialog/teka-teki tanpa menjalankan callback (dipakai saat tantangan diulang).
func tutup_paksa() -> void:
	if not aktif:
		return
	_timer_lanjut.stop()
	if suara_tersedia():
		DisplayServer.tts_stop()
	aktif = false
	_menjawab = false
	_panel.visible = false
	_tombol_lewati.visible = false
	_panel_teka_teki.visible = false
	_callback = Callable()
	_callback_jawaban = Callable()
	GameState.ubah_state(_state_sebelum)


func _selesai() -> void:
	aktif = false
	_panel.visible = false
	_tombol_lewati.visible = false
	GameState.ubah_state(_state_sebelum)
	var cb: Callable = _callback
	_callback = Callable()
	dialog_selesai.emit(_id)
	if cb.is_valid():
		cb.call()
