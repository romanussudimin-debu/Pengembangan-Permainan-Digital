extends Node3D
## Ending: perayaan Penti. Warga menari mengelilingi natas diiringi gong-gendang.

var _kamera: Camera3D
var _sudut: float = 0.0


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
	_kamera = Camera3D.new()
	add_child(_kamera)
	_kamera.current = true
	_bangun_ui()


func _process(delta: float) -> void:
	_sudut += delta * 0.15
	_kamera.position = Vector3(cos(_sudut) * 16.0, 6.0, sin(_sudut) * 16.0)
	_kamera.look_at(Vector3(0, 1.5, 0), Vector3.UP)


func _bangun_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := Gaya.panel_songke(Vector2(150, 70), Vector2(340, 200))
	ui.add_child(panel)
	var judul := Gaya.label("PENTI DIMULAI!", 22, Gaya.KUNING)
	judul.position = Vector2(20, 14)
	panel.add_child(judul)
	var isi := Gaya.label("", 10, Gaya.PUTIH)
	isi.position = Vector2(20, 52)
	isi.size = Vector2(300, 100)
	isi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	isi.text = "Nggohak bertanding caci dengan berani dan sportif, lalu bergabung dalam perayaan tahun baru adat.\n\nKartu budaya terkumpul: %d dari %d\nLawan caci dikalahkan: %d dari %d" % [
		GameState.kartu_terkumpul.size(), GameState.jumlah_kartu_total(),
		GameState.lawan_dikalahkan, GameState.JUMLAH_LAWAN]
	panel.add_child(isi)
	var tombol := Gaya.tombol("Kembali ke Menu Utama")
	tombol.position = Vector2(90, 160)
	tombol.pressed.connect(func() -> void: Transisi.pindah_scene("res://scenes/main_menu.tscn"))
	panel.add_child(tombol)
	tombol.grab_focus()
