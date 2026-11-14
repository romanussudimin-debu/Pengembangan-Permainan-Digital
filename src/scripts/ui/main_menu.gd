extends Node3D
## Menu utama dengan diorama 3D Wae Rebo dan kamera yang berputar perlahan.

const ADEGAN_KAMPUNG: String = "res://scenes/kampung.tscn"

var _kamera: Camera3D
var _sudut: float = 0.0
var _panel_info: NinePatchRect
var _label_info: Label
var _tombol_mulai: Button
var _tombol_mode: Button


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
	for i in 4:
		var ayam := Hewan.new()
		ayam.jenis = "ayam"
		ayam.position = Vector3(-3.0 + i * 0.7, 0, 7.5)
		ayam.warna_utama = [Color("f1ede4"), Color("9a4a22"), Color("1e1a1a"), Color("b8622a")][i]
		ayam.jari_jelajah = 1.5
		add_child(ayam)
	var anjing := Hewan.new()
	anjing.jenis = "anjing"
	anjing.position = Vector3(6, 0, 6)
	anjing.warna_utama = Color("a0703c")
	anjing.jari_jelajah = 1.5
	add_child(anjing)
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
	var judul := Gaya.label("JEJAK PENTI", 34, Gaya.KUNING)
	judul.position = Vector2(40, 40)
	ui.add_child(judul)
	var sub := Gaya.label("di Wae Rebo", 16, Gaya.PUTIH)
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
	if GameState.ada_simpanan():
		var lv: int = clampi(GameState.level_tertinggi, 1, GameState.ADEGAN_LEVEL.size())
		var lanjut := Gaya.tombol("Lanjutkan (Level %d)" % lv)
		lanjut.pressed.connect(func() -> void: GameState.lanjutkan())
		kolom.add_child(lanjut)
	_tombol_mode = Gaya.tombol(_teks_mode())
	_tombol_mode.pressed.connect(_ganti_mode)
	kolom.add_child(_tombol_mode)
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

	_panel_info = Gaya.panel_songke(Vector2(222, 16), Vector2(400, 328))
	_panel_info.visible = false
	ui.add_child(_panel_info)
	_label_info = Gaya.label("", 9, Gaya.PUTIH)
	_label_info.position = Vector2(16, 14)
	_label_info.size = Vector2(368, 270)
	_label_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_info.add_child(_label_info)
	var tutup := Gaya.tombol("Tutup")
	tutup.position = Vector2(120, 292)
	tutup.pressed.connect(func() -> void: _panel_info.visible = false)
	_panel_info.add_child(tutup)
	_tombol_mulai.grab_focus()


func _mulai() -> void:
	GameState.reset_progres()
	Transisi.pindah_scene(ADEGAN_KAMPUNG)


func _ganti_mode() -> void:
	GameState.atur_mode_sulit(not GameState.mode_sulit)
	_tombol_mode.text = _teks_mode()


func _teks_mode() -> String:
	return "Mode: Sulit" if GameState.mode_sulit else "Mode: Normal"


func _tampilkan_info(teks: String) -> void:
	_label_info.text = teks
	_panel_info.visible = true


func _teks_cara_bermain() -> String:
	return """CARA BERMAIN

• WASD / panah: berjalan   • Spasi: melompat
• E: bicara / lanjut dialog   • Esc: jeda & koleksi kartu
• Di HP/tablet: joystick kiri untuk berjalan, tombol LOMPAT, BICARA, dan II (jeda); dialog & tantangan cukup diketuk

Delapan warga kampung masing-masing menyimpan kartu budaya. Kumpulkan kartu BERURUTAN: mulailah dari Tu'a Golo di dekat compang. Setiap warga memberi tantangan, lalu petunjuk berupa teka-teki menuju warga berikutnya (lihat kiri atas). Ada warga yang menunggu di DALAM Mbaru Niang (masuklah lewat pintunya) dan ada yang suka berpindah tempat.

Tantangan:
• Teka-teki: jawab dengan klik, panah + Enter, atau tombol 1-4. Jawabannya ada di kartu yang sudah kamu kumpulkan (Esc untuk membacanya lagi).
• Menenun songke: samakan kain dengan contoh motif (E/klik ganti warna benang).
• Tabuh gong-gendang: tekan J/K atau ketuk tombol GONG/GENDANG saat ketukan tiba di garis.

LEVEL 2 – LINGKO LODOK
Undang lima kepala keluarga berdasarkan ciri-cirinya, susuri pematang yang sempit (jatuh = kembali ke titik aman), alirkan air dari wae teku, lalu bagi lingko dengan garis moso sesuai musyawarah.

MODE SULIT: ada batas waktu "sebelum senja", jatuh dan salah orang mengurangi waktu, kesempatan salah lebih sedikit, dan ukuran bagian tidak ditampilkan.

Dialog diucapkan dengan suara; teks dialog bisa dinyalakan di menu jeda."""


func _teks_tentang() -> String:
	return """TENTANG GAME

Jejak Penti di Wae Rebo adalah prototipe game 3D jelajah budaya Manggarai, Flores, NTT. Menjelang Penti (tahun baru adat), Nggohak menemui warga kampung, menjawab teka-teki, menenun songke, dan menabuh gong-gendang untuk mengumpulkan kartu pengetahuan budaya. Di Level 2, ia membantu Tu'a Teno membagi lingko, lahan adat berbentuk jaring laba-laba.

Latar kampung terinspirasi Wae Rebo: tujuh Mbaru Niang yang melingkari compang. Caci ditampilkan sebagai pertunjukan saat Penti. Semua model, tekstur songke, dan musik gong-gendang dibuat sendiri secara prosedural.

Dibuat dengan Godot Engine 4 untuk tugas mata kuliah Pengembangan Permainan Digital."""
