extends Node3D
## Menu utama dengan diorama 3D Wae Rebo dan kamera yang berputar perlahan.

const ADEGAN_KAMPUNG: String = "res://scenes/kampung.tscn"

var _kamera: Camera3D
var _sudut: float = 0.0
var _panel_info: NinePatchRect
var _label_info: Label
var _tombol_mulai: Button


func _ready() -> void:
	get_tree().paused = false
	GameState.ubah_state(GameState.State.MENU)
	_bangun_diorama()
	_bangun_ui()
	AudioManager.putar_musik("kampung")


func _bangun_diorama() -> void:
	Dunia.lingkungan(self)
	Dunia.tanah(self, 220.0)
	Dunia.compang(self, Vector3.ZERO)
	for i in 7:
		var a: float = TAU * i / 7.0
		Dunia.mbaru_niang(self, Vector3(cos(a), 0, sin(a)) * 13.0, Vector3.ZERO, 1.25 if i == 0 else 1.0)
	for i in 12:
		var a: float = TAU * i / 12.0
		Dunia.bukit(self, Vector3(cos(a) * 55, -4, sin(a) * 55), 18, 16)
	var tari := [Vector3(4, 0, 4), Vector3(-4, 0, 4), Vector3(0, 0, 6)]
	for i in tari.size():
		var m := KarakterModel.new()
		m.position = tari[i]
		m.telanjang_dada = true
		m.pakai_panggal = true
		m.bawa_senjata = true
		add_child(m)
		m.mode = "siaga"
	_kamera = Camera3D.new()
	add_child(_kamera)
	_kamera.current = true


func _process(delta: float) -> void:
	_sudut += delta * 0.08
	_kamera.position = Vector3(cos(_sudut) * 24.0, 9.0, sin(_sudut) * 24.0)
	_kamera.look_at(Vector3(0, 2, 0), Vector3.UP)


func _bangun_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var judul := Gaya.label("CACI", 40, Gaya.KUNING)
	judul.position = Vector2(40, 40)
	ui.add_child(judul)
	var sub := Gaya.label("Jejak Anak Wae Rebo", 16, Gaya.PUTIH)
	sub.position = Vector2(42, 92)
	ui.add_child(sub)
	var tag := Gaya.label("Prototipe game 3D berbasis budaya Manggarai, Flores, NTT", 9, Gaya.PUTIH)
	tag.position = Vector2(42, 116)
	ui.add_child(tag)

	var kolom := VBoxContainer.new()
	kolom.position = Vector2(42, 150)
	kolom.add_theme_constant_override("separation", 8)
	ui.add_child(kolom)
	_tombol_mulai = Gaya.tombol("Mulai Permainan")
	_tombol_mulai.pressed.connect(_mulai)
	kolom.add_child(_tombol_mulai)
	var cara := Gaya.tombol("Cara Bermain")
	cara.pressed.connect(_tampilkan_info.bind(_teks_cara_bermain()))
	kolom.add_child(cara)
	var tentang := Gaya.tombol("Tentang Game")
	tentang.pressed.connect(_tampilkan_info.bind(_teks_tentang()))
	kolom.add_child(tentang)
	if not OS.has_feature("web"):
		var keluar := Gaya.tombol("Keluar")
		keluar.pressed.connect(func() -> void: get_tree().quit())
		kolom.add_child(keluar)

	_panel_info = Gaya.panel_songke(Vector2(230, 40), Vector2(380, 280))
	_panel_info.visible = false
	ui.add_child(_panel_info)
	_label_info = Gaya.label("", 9, Gaya.PUTIH)
	_label_info.position = Vector2(16, 14)
	_label_info.size = Vector2(348, 230)
	_label_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_info.add_child(_label_info)
	var tutup := Gaya.tombol("Tutup")
	tutup.position = Vector2(110, 244)
	tutup.pressed.connect(func() -> void: _panel_info.visible = false)
	_panel_info.add_child(tutup)
	_tombol_mulai.grab_focus()


func _mulai() -> void:
	GameState.reset_progres()
	Transisi.pindah_scene(ADEGAN_KAMPUNG)


func _tampilkan_info(teks: String) -> void:
	_label_info.text = teks
	_panel_info.visible = true


func _teks_cara_bermain() -> String:
	return """CARA BERMAIN

Di kampung:
• WASD / panah: berjalan   • Spasi: melompat
• E: bicara / melihat / lanjut dialog   • Esc: jeda

Di arena caci (peran bergantian tiap ronde):
• TA'ANG: saat lawan menarik larik (tanda \"!\"), tekan K / X tepat sebelum pukulan. Menangkis memakai stamina.
• PAKI: tekan J / Z ketika penanda berada di zona kuning.

Dialog diucapkan dengan suara (E: lewati). Teks dialog bisa dinyalakan di menu jeda.

Kalahkan Rangga, Fransi, dan Ema Agus, kumpulkan kartu budaya di dalam Mbaru Niang yang pintunya bercahaya, lalu kembali ke Tu'a Golo untuk merayakan Penti."""


func _teks_tentang() -> String:
	return """TENTANG GAME

Caci: Jejak Anak Wae Rebo adalah prototipe game 3D yang mengangkat caci, tarian-tarung cambuk masyarakat Manggarai, Flores, NTT. Caci dimainkan oleh paki (pencambuk) dan ta'ang (penangkis) dengan nilai sportivitas dan persaudaraan.

Latar kampung terinspirasi Wae Rebo: Mbaru Niang yang melingkari compang. Semua model, tekstur songke, dan musik gong-gendang dibuat sendiri secara prosedural.

Dibuat dengan Godot Engine 4 untuk tugas mata kuliah Pengembangan Permainan Digital."""
