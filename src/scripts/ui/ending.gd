extends Node3D
## Ending: perayaan Penti. Warga menari mengelilingi natas diiringi gong-gendang,
## dan dua penampil caci bergantian berperan sebagai paki (mencambuk) dan ta'ang (menangkis).

const ADEGAN_PENAMPIL: PackedScene = preload("res://scenes/penampil_caci.tscn")
const JEDA_SERANGAN: float = 2.6

var _kamera: Camera3D
var _sudut: float = 0.0
var _penampil: Array[PenampilCaci] = []
var _giliran: int = 0


func _ready() -> void:
	GameState.ubah_state(GameState.State.SELESAI)
	AudioManager.putar_musik("caci")
	AudioManager.putar_sfx("gong")
	Dunia.lingkungan(self)
	Dunia.tanah(self, 220.0)
	Dunia.compang(self, Vector3.ZERO)
	Dunia.gong_gendang(self, Vector3(-6, 0, -6))
	for i in 7:
		var a: float = TAU * i / 7.0
		Dunia.mbaru_niang(self, Vector3(cos(a), 0, sin(a)) * 14.0, Vector3.ZERO, 1.25 if i == 0 else 1.0)
	# Lingkaran penari (danding) di sekitar natas
	var songke: Array[String] = ["songke_merah", "songke_biru", "songke_hijau", "songke_kuning"]
	for i in 10:
		var a: float = TAU * i / 10.0
		var m := KarakterModel.new()
		m.tekstur_songke = load("res://assets/textures/%s.png" % songke[i % songke.size()])
		m.warna_baju = Color("1b1818") if i % 2 == 0 else Color("e8e2d2")
		m.position = Vector3(cos(a), 0, sin(a)) * 5.5
		add_child(m)
		m.rotation.y = atan2(m.position.x, m.position.z)
		m.mode = "menari"
	_bangun_pertunjukan_caci()
	_kamera = Camera3D.new()
	add_child(_kamera)
	_kamera.current = true
	_bangun_ui()


func _bangun_pertunjukan_caci() -> void:
	var songke: Array[String] = ["res://assets/textures/songke_biru.png", "res://assets/textures/songke_kuning.png"]
	var posisi: Array[Vector3] = [Vector3(-1.6, 0, 9.5), Vector3(1.6, 0, 9.5)]
	for i in 2:
		var p: PenampilCaci = ADEGAN_PENAMPIL.instantiate()
		var model: KarakterModel = p.get_node("Model")
		model.tekstur_songke = load(songke[i])
		p.position = posisi[i]
		add_child(p)
		p.model.rotation.y = -PI / 2.0 if i == 0 else PI / 2.0  # saling berhadapan
		_penampil.append(p)
	for i in 2:
		_penampil[i].pukulan_mendarat.connect(_saat_pukulan.bind(i))
	var t := Timer.new()
	t.wait_time = JEDA_SERANGAN
	t.autostart = true
	t.timeout.connect(_serangan_berikutnya)
	add_child(t)


## Peran bergantian seperti caci: paki menyerang, ta'ang menangkis, lalu bertukar.
func _serangan_berikutnya() -> void:
	_penampil[_giliran].serang(randf_range(0.6, 1.0), false)
	_giliran = 1 - _giliran


func _saat_pukulan(penyerang: int) -> void:
	_penampil[1 - penyerang].tangkis()
	AudioManager.putar_sfx("perisai", 0.1)


func _process(delta: float) -> void:
	_sudut += delta * 0.15
	_kamera.position = Vector3(cos(_sudut) * 16.0, 6.0, sin(_sudut) * 16.0)
	_kamera.look_at(Vector3(0, 1.5, 0), Vector3.UP)


func _bangun_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := Gaya.panel_songke(Vector2(16, 186), Vector2(360, 162))
	ui.add_child(panel)
	var judul := Gaya.label("PENTI DIMULAI!", 22, Gaya.KUNING)
	judul.position = Vector2(18, 10)
	panel.add_child(judul)
	var isi := Gaya.label("", 9, Gaya.PUTIH)
	isi.position = Vector2(18, 44)
	isi.size = Vector2(324, 80)
	isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi.text = "Nggohak telah menemui seluruh warga, menjawab teka-teki mereka, dan mengumpulkan pengetahuan budaya Manggarai. Kini ia bergabung dalam perayaan tahun baru adat sambil menyaksikan caci.\n\nKartu budaya terkumpul: %d dari %d" % [
		GameState.kartu_terkumpul.size(), GameState.jumlah_kartu_total()]
	panel.add_child(isi)
	var tombol := Gaya.tombol("Kembali ke Menu Utama")
	tombol.position = Vector2(100, 124)
	tombol.pressed.connect(func() -> void: Transisi.pindah_scene("res://scenes/main_menu.tscn"))
	panel.add_child(tombol)
	tombol.grab_focus()
