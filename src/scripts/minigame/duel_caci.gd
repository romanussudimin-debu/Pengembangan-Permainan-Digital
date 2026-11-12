extends Node3D
## Duel caci 3D. Dua mekanik utama:
##  1. TA'ANG (menangkis): baca isyarat ancang-ancang lawan, tekan tangkis tepat waktu (berbiaya stamina).
##  2. PAKI (mencambuk): tekan cambuk saat penanda di zona kuning pada bilah timing.
## Peran bergantian setiap ronde, seperti caci sesungguhnya.

signal keputusan_cambuk(hasil: String)

enum Fase { PERSIAPAN, TAANG, PAKI, HASIL }

const ADEGAN_LAWAN: PackedScene = preload("res://scenes/lawan_caci.tscn")
const ADEGAN_KAMPUNG: String = "res://scenes/kampung.tscn"
const ADEGAN_DUEL: String = "res://scenes/duel_caci.tscn"

const JUMLAH_RONDE: int = 3
const SERANGAN_PER_FASE: int = 2
const STAMINA_MAKS: float = 100.0
const BIAYA_TANGKIS: float = 30.0
const PEMULIHAN_STAMINA: float = 22.0
const JEDA_TANGKIS: float = 0.35
const BATAS_WAKTU_CAMBUK: float = 3.0
## Posisi awal perempuan pembawa kopi di tepi arena (kiri untuk Nggohak, kanan untuk lawan).
const POSISI_PEMBAWA_KOPI: Array = [Vector3(-4.2, 0, 1.6), Vector3(4.2, 0, 1.6)]

## Konfigurasi tiap lawan: makin tinggi indeks, makin sulit.
const KONFIG_LAWAN: Array = [
	{"nama": "Hingha", "songke": "res://assets/textures/songke_biru.png", "ancang_min": 1.0, "ancang_maks": 1.4,
		"jendela": 0.38, "zona": 0.26, "laju_bilah": 0.8, "tipuan": 0.0, "kartu": "caci"},
	{"nama": "Fransi", "songke": "res://assets/textures/songke_hijau.png", "ancang_min": 0.65, "ancang_maks": 1.15,
		"jendela": 0.3, "zona": 0.19, "laju_bilah": 1.15, "tipuan": 0.2, "kartu": "perlengkapan_caci"},
	{"nama": "Ema Agus", "songke": "res://assets/textures/songke_kuning.png", "ancang_min": 0.45, "ancang_maks": 1.0,
		"jendela": 0.24, "zona": 0.14, "laju_bilah": 1.5, "tipuan": 0.33, "kartu": "nilai_caci"},
]

var fase: Fase = Fase.PERSIAPAN
var poin_pemain: int = 0
var poin_lawan: int = 0
var stamina: float = STAMINA_MAKS

var _konfig: Dictionary
var _indeks_lawan: int = 0
var _nara: KarakterModel
var _lawan: LawanCaci
var _kamera: KameraIkut
var _jam: float = 0.0
var _waktu_tangkis: float = -10.0
var _menunggu_cambuk: bool = false
var _timer_cambuk: Timer
var _pembawa_kopi: Array[KarakterModel] = []

# UI
var _label_info: Label
var _label_peran: Label
var _label_skor_pemain: Label
var _label_skor_lawan: Label
var _bar_stamina: ProgressBar
var _bilah: BilahTiming
var _label_umpan: Label
var _label_petunjuk: Label
var _panel_hasil: Control


func _ready() -> void:
	_indeks_lawan = clampi(GameState.lawan_aktif, 0, KONFIG_LAWAN.size() - 1)
	_konfig = KONFIG_LAWAN[_indeks_lawan]
	_bangun_arena()
	_bangun_ui()
	AudioManager.putar_musik("caci")
	GameState.ubah_state(GameState.State.MINIGAME)
	_jalankan_duel()


# ------------------------------------------------------------- pembangunan

func _bangun_arena() -> void:
	Dunia.lingkungan(self)
	Dunia.tanah(self, 220.0)
	Dunia.arena(self, Vector3.ZERO, 4.5)
	Dunia.gong_gendang(self, Vector3(-3.5, 0, -6.5))
	Dunia.mbaru_niang(self, Vector3(-9, 0, -14), Vector3.ZERO)
	Dunia.mbaru_niang(self, Vector3(4, 0, -17), Vector3.ZERO)
	Dunia.mbaru_niang(self, Vector3(14, 0, -11), Vector3.ZERO)
	# Penonton dari kampung mengelilingi arena
	var warna: Array[String] = ["songke_merah", "songke_hijau", "songke_kuning", "songke_biru"]
	for i in 7:
		var a: float = PI + PI * (i + 0.5) / 7.0  # setengah lingkaran di belakang arena
		var pos := Vector3(cos(a) * 6.5, 0, sin(a) * 6.5)
		var p := KarakterModel.new()
		p.tekstur_songke = load("res://assets/textures/%s.png" % warna[i % warna.size()])
		p.warna_baju = [Color("e8e2d2"), Color("1b1818"), Color("b02a2a")][i % 3]
		p.position = pos
		add_child(p)
		p.rotation.y = atan2(pos.x, pos.z)  # menghadap pusat arena
		p.mode = "menari" if i % 3 == 0 else "idle"

	# Perempuan kampung pembawa kopi untuk para pemain caci
	var tekstur_kopi: Array[String] = ["songke_merah", "songke_hijau"]
	var nama_kopi: Array[String] = ["Ende Lono", "Marngem"]
	for i in POSISI_PEMBAWA_KOPI.size():
		var w := KarakterModel.new()
		w.perempuan = true
		w.bawa_nampan = true
		w.tekstur_songke = load("res://assets/textures/%s.png" % tekstur_kopi[i])
		w.warna_baju = [Color("2c5c96"), Color("e8e2d2")][i]
		w.position = POSISI_PEMBAWA_KOPI[i]
		add_child(w)
		w.rotation.y = atan2(w.position.x, w.position.z)
		Dunia.label_nama(w, nama_kopi[i], 2.2)
		_pembawa_kopi.append(w)

	_nara = KarakterModel.new()
	_nara.tekstur_songke = preload("res://assets/textures/songke_merah.png")
	_nara.telanjang_dada = true
	_nara.pakai_panggal = true
	_nara.bawa_senjata = true
	_nara.position = Vector3(-1.7, 0, 0)
	add_child(_nara)
	_nara.rotation.y = -PI / 2.0
	_nara.mode = "siaga"
	Dunia.label_nama(_nara, "Nggohak", 2.7)

	_lawan = ADEGAN_LAWAN.instantiate()
	var model_lawan: KarakterModel = _lawan.get_node("Model")
	model_lawan.tekstur_songke = load(_konfig["songke"])
	_lawan.nama = _konfig["nama"]
	_lawan.position = Vector3(1.7, 0, 0)
	add_child(_lawan)
	_lawan.model.rotation.y = PI / 2.0
	Dunia.label_nama(_lawan, _konfig["nama"], 2.7)
	_lawan.pukulan_mendarat.connect(_saat_pukulan_lawan)

	var pusat := Node3D.new()
	add_child(pusat)
	_kamera = KameraIkut.new()
	_kamera.offset_kamera = Vector3(0, 1.9, 6.2)
	_kamera.titik_lihat = Vector3(0, 1.2, 0)
	_kamera.target = pusat
	add_child(_kamera)
	_kamera.current = true

	_timer_cambuk = Timer.new()
	_timer_cambuk.one_shot = true
	_timer_cambuk.timeout.connect(_saat_waktu_cambuk_habis)
	add_child(_timer_cambuk)


func _bangun_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var atas := Gaya.panel_songke(Vector2(170, 6), Vector2(300, 46))
	ui.add_child(atas)
	_label_info = Gaya.label("", 10, Gaya.KUNING)
	_label_info.position = Vector2(10, 7)
	_label_info.size = Vector2(280, 14)
	_label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atas.add_child(_label_info)
	_label_peran = Gaya.label("", 10, Gaya.PUTIH)
	_label_peran.position = Vector2(10, 24)
	_label_peran.size = Vector2(280, 14)
	_label_peran.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atas.add_child(_label_peran)

	_label_skor_pemain = Gaya.label("", 14, Gaya.PUTIH)
	_label_skor_pemain.position = Vector2(12, 10)
	ui.add_child(_label_skor_pemain)
	_label_skor_lawan = Gaya.label("", 14, Gaya.PUTIH)
	_label_skor_lawan.position = Vector2(486, 10)
	_label_skor_lawan.size = Vector2(142, 20)
	_label_skor_lawan.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(_label_skor_lawan)

	var label_stamina := Gaya.label("Stamina", 8, Gaya.PUTIH)
	label_stamina.position = Vector2(12, 34)
	ui.add_child(label_stamina)
	_bar_stamina = ProgressBar.new()
	_bar_stamina.max_value = STAMINA_MAKS
	_bar_stamina.show_percentage = false
	_bar_stamina.position = Vector2(12, 46)
	_bar_stamina.size = Vector2(120, 8)
	var isi := StyleBoxFlat.new()
	isi.bg_color = Gaya.HIJAU
	var latar := StyleBoxFlat.new()
	latar.bg_color = Gaya.HITAM
	_bar_stamina.add_theme_stylebox_override("fill", isi)
	_bar_stamina.add_theme_stylebox_override("background", latar)
	ui.add_child(_bar_stamina)

	_bilah = BilahTiming.new()
	_bilah.position = Vector2(170, 290)
	_bilah.visible = false
	ui.add_child(_bilah)

	_label_umpan = Gaya.label("", 22, Gaya.KUNING)
	_label_umpan.position = Vector2(120, 120)
	_label_umpan.size = Vector2(400, 40)
	_label_umpan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_umpan.pivot_offset = Vector2(200, 20)
	ui.add_child(_label_umpan)

	_label_petunjuk = Gaya.label("", 9, Gaya.PUTIH)
	_label_petunjuk.position = Vector2(20, 330)
	_label_petunjuk.size = Vector2(600, 14)
	_label_petunjuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(_label_petunjuk)

	_panel_hasil = Gaya.panel_songke(Vector2(200, 120), Vector2(240, 120))
	_panel_hasil.visible = false
	ui.add_child(_panel_hasil)
	var judul := Gaya.label("Coba lagi?", 12, Gaya.KUNING)
	judul.position = Vector2(14, 10)
	_panel_hasil.add_child(judul)
	var kolom := VBoxContainer.new()
	kolom.position = Vector2(40, 38)
	kolom.add_theme_constant_override("separation", 8)
	_panel_hasil.add_child(kolom)
	var ulangi := Gaya.tombol("Ulangi Duel")
	ulangi.pressed.connect(func() -> void: Transisi.pindah_scene(ADEGAN_DUEL))
	kolom.add_child(ulangi)
	var pulang := Gaya.tombol("Kembali ke Kampung")
	pulang.pressed.connect(func() -> void: Transisi.pindah_scene(ADEGAN_KAMPUNG))
	kolom.add_child(pulang)
	_perbarui_ui()


# ------------------------------------------------------------- alur duel

func _jalankan_duel() -> void:
	_label_peran.text = "Bersiap..."
	await _tunggu(0.8)
	if _indeks_lawan == 0 and not GameState.tutorial_caci_dilihat:
		GameState.tutorial_caci_dilihat = true
		await _dialog("caci_tutorial")
	for ronde in JUMLAH_RONDE:
		await _fase_taang(ronde)
		await _fase_paki(ronde)
		if ronde < JUMLAH_RONDE - 1:
			await _jeda_kopi(ronde)
	await _akhiri_duel()


## Jeda antarronde: perempuan kampung mengantar kopi ke kedua pemain; stamina pulih penuh.
func _jeda_kopi(ronde: int) -> void:
	fase = Fase.PERSIAPAN
	_label_peran.text = "Jeda: kopi untuk para pemain"
	_label_petunjuk.text = ""
	var tujuan: Array = [_nara.position + Vector3(-0.3, 0, 0.9), _lawan.position + Vector3(0.3, 0, 0.9)]
	for i in _pembawa_kopi.size():
		_jalan_ke(_pembawa_kopi[i], tujuan[i], 1.4)
	await _tunggu(1.5)
	await _dialog("kopi_caci_%d" % (ronde + 1))
	stamina = STAMINA_MAKS
	AudioManager.putar_sfx("ambil")
	_umpan_balik("Stamina pulih!", Gaya.HIJAU)
	for i in _pembawa_kopi.size():
		_jalan_ke(_pembawa_kopi[i], POSISI_PEMBAWA_KOPI[i], 1.4)
	await _tunggu(1.2)


func _jalan_ke(model: KarakterModel, tujuan: Vector3, durasi: float) -> void:
	var arah: Vector3 = tujuan - model.position
	model.rotation.y = atan2(-arah.x, -arah.z)
	model.mode = "jalan"
	model.kecepatan_jalan = 0.5
	var tw := create_tween()
	tw.tween_property(model, "position", tujuan, durasi).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_berhenti_jalan.bind(model))


func _berhenti_jalan(model: KarakterModel) -> void:
	model.mode = "idle"
	# Menghadap ke tengah arena setelah tiba
	model.rotation.y = atan2(model.position.x, model.position.z)


func _fase_taang(ronde: int) -> void:
	fase = Fase.TAANG
	_label_peran.text = "Kamu: TA'ANG (menangkis)"
	_label_petunjuk.text = "Tunggu isyarat \"!\" lalu tekan K / X tepat sebelum larik mengenai"
	await _spanduk("Ronde %d: Kamu menjadi TA'ANG" % (ronde + 1))
	for i in SERANGAN_PER_FASE:
		await _tunggu(randf_range(0.5, 1.0))
		var durasi: float = randf_range(_konfig["ancang_min"], _konfig["ancang_maks"])
		var tipuan: bool = randf() < float(_konfig["tipuan"])
		_lawan.serang(durasi, tipuan)
		await _lawan.serangan_selesai
		if tipuan:
			_umpan_balik("Tipuan!", Gaya.ABU)
		await _tunggu(0.5)


func _fase_paki(ronde: int) -> void:
	fase = Fase.PAKI
	_label_peran.text = "Kamu: PAKI (mencambuk)"
	_label_petunjuk.text = "Tekan J / Z saat penanda di zona kuning"
	await _spanduk("Ronde %d: Kamu menjadi PAKI" % (ronde + 1))
	for i in SERANGAN_PER_FASE:
		# Bilah makin cepat sedikit di tiap ronde
		_bilah.mulai(_konfig["zona"], float(_konfig["laju_bilah"]) * (1.0 + ronde * 0.12))
		_menunggu_cambuk = true
		_timer_cambuk.start(BATAS_WAKTU_CAMBUK)
		var hasil: String = await keputusan_cambuk
		_bilah.berhenti()
		await _eksekusi_cambuk(hasil)
		_bilah.visible = false
		await _tunggu(0.6)


func _eksekusi_cambuk(hasil: String) -> void:
	if hasil == "terlambat":
		_umpan_balik("Terlambat!", Gaya.ABU)
		await _tunggu(0.4)
		return
	_nara.serang(0.28)
	await _nara.momen_pukul
	AudioManager.putar_sfx("cambuk", 0.1)
	match hasil:
		"tepat":
			_lawan.terkena()
			AudioManager.putar_sfx("terkena")
			_kamera.guncang(0.5)
			poin_pemain += 2
			_umpan_balik("Kena! +2", Gaya.KUNING)
		"hampir":
			_lawan.tangkis()
			AudioManager.putar_sfx("perisai")
			_umpan_balik("Ditangkis lawan", Gaya.PUTIH)
		_:
			_lawan.tangkis()
			_umpan_balik("Meleset", Gaya.ABU)
	_perbarui_ui()
	await _tunggu(0.5)


func _akhiri_duel() -> void:
	fase = Fase.HASIL
	_label_petunjuk.text = ""
	_bilah.visible = false
	var menang: bool = poin_pemain > poin_lawan
	var nama: String = _konfig["nama"]
	if menang:
		AudioManager.putar_sfx("berhasil")
		_nara.mode = "menari"
		await _spanduk("MENANG!  %d - %d" % [poin_pemain, poin_lawan])
		GameState.catat_kemenangan(_indeks_lawan)
		await _dialog("caci_menang", nama)
		var id_kartu: String = _konfig["kartu"]
		GameState.kumpulkan_kartu(id_kartu)
		DialogManager.tampilkan_kartu(id_kartu)
		await DialogManager.dialog_selesai
		Transisi.pindah_scene(ADEGAN_KAMPUNG)
	else:
		AudioManager.putar_sfx("gagal")
		await _spanduk("Kalah  %d - %d" % [poin_pemain, poin_lawan])
		await _dialog("caci_kalah", nama)
		_panel_hasil.visible = true
		var tombol: Button = _panel_hasil.get_child(1).get_child(0)
		tombol.grab_focus()


# ------------------------------------------------------------- input & resolusi

func _process(delta: float) -> void:
	_jam += delta
	stamina = minf(stamina + PEMULIHAN_STAMINA * delta, STAMINA_MAKS)
	_bar_stamina.value = stamina
	if not GameState.sedang(GameState.State.MINIGAME):
		return
	if fase == Fase.TAANG and Input.is_action_just_pressed("tangkis"):
		_coba_tangkis()
	elif fase == Fase.PAKI and _menunggu_cambuk and Input.is_action_just_pressed("serang"):
		_menunggu_cambuk = false
		_timer_cambuk.stop()
		keputusan_cambuk.emit(_bilah.nilai())


func _coba_tangkis() -> void:
	if _jam - _waktu_tangkis < JEDA_TANGKIS:
		return
	if stamina < BIAYA_TANGKIS:
		_umpan_balik("Stamina habis!", Gaya.MERAH)
		return
	stamina -= BIAYA_TANGKIS
	_waktu_tangkis = _jam
	_nara.tangkis(0.25)


func _saat_pukulan_lawan() -> void:
	var tertangkis: bool = _jam - _waktu_tangkis <= float(_konfig["jendela"])
	if tertangkis:
		AudioManager.putar_sfx("perisai", 0.1)
		poin_pemain += 1
		_umpan_balik("Tertangkis! +1", Gaya.HIJAU)
	else:
		AudioManager.putar_sfx("cambuk", 0.1)
		AudioManager.putar_sfx("terkena")
		_nara.terkena()
		_kamera.guncang(0.8)
		poin_lawan += 2
		_umpan_balik("Terkena! Lawan +2", Gaya.MERAH)
	_perbarui_ui()


func _saat_waktu_cambuk_habis() -> void:
	if _menunggu_cambuk:
		_menunggu_cambuk = false
		keputusan_cambuk.emit("terlambat")


# ------------------------------------------------------------- utilitas

func _perbarui_ui() -> void:
	_label_info.text = "Lawan %d/%d: %s" % [_indeks_lawan + 1, KONFIG_LAWAN.size(), _konfig["nama"]]
	_label_skor_pemain.text = "Nggohak: %d" % poin_pemain
	_label_skor_lawan.text = "%s: %d" % [_konfig["nama"], poin_lawan]


## Teks umpan balik yang "meletup" (squash & stretch pada UI).
func _umpan_balik(teks: String, warna: Color) -> void:
	_label_umpan.text = teks
	_label_umpan.add_theme_color_override("font_color", warna)
	_label_umpan.modulate.a = 1.0
	_label_umpan.scale = Vector2(1.5, 0.6)
	var tw := create_tween()
	tw.tween_property(_label_umpan, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.6)
	tw.tween_property(_label_umpan, "modulate:a", 0.0, 0.3)


func _spanduk(teks: String) -> void:
	AudioManager.putar_sfx("gong")
	_umpan_balik(teks, Gaya.KUNING)
	await _tunggu(1.4)


## Menunggu dengan Timer milik scene (ikut berhenti saat jeda, aman bila scene dibebaskan).
func _tunggu(detik: float) -> void:
	var t := Timer.new()
	t.one_shot = true
	add_child(t)
	t.start(detik)
	await t.timeout
	t.queue_free()


## Menjalankan dialog; nama "Lawan" diganti nama lawan sebenarnya.
func _dialog(id: String, nama_lawan: String = "") -> void:
	var sumber: Array = DialogManager.DATA_DIALOG.data[id]
	var baris: Array = []
	for b: Dictionary in sumber:
		var salinan: Dictionary = b.duplicate()
		if nama_lawan != "" and salinan.get("nama", "") == "Lawan":
			salinan["nama"] = nama_lawan
		baris.append(salinan)
	DialogManager.mulai_baris(id, baris)
	await DialogManager.dialog_selesai
