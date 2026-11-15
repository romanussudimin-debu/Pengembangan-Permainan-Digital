extends Node3D
## Menu utama berlatar panorama Manggarai (Wae Rebo, Penti & caci, lingko, komodo, Labuan Bajo).
## Kamera berpindah perlahan antar-tema (bidikan Panorama.SHOT) dengan peralihan pudar.
## Tombol dibuat besar agar mudah diketuk di HP/tablet landscape.

const ADEGAN_KAMPUNG: String = "res://scenes/kampung.tscn"
const DURASI_SHOT_MENU: float = 9.0

var _kamera: Camera3D
var _kapal: Array[Node3D] = []
var _waktu: float = 0.0
var _indeks_shot: int = 1
var _waktu_shot: float = 0.0
var _pudar: ColorRect
var _label_tema: Label
var _panel_info: NinePatchRect
var _label_info: RichTextLabel
var _tombol_mulai: Button
var _tombol_mode: Button
var _tombol_layar: Button


func _ready() -> void:
	get_tree().paused = false
	GameState.ubah_state(GameState.State.MENU)
	_kapal = Panorama.bangun(self)
	_kamera = Camera3D.new()
	_kamera.fov = 55.0
	add_child(_kamera)
	_kamera.current = true
	_bangun_ui()
	_ganti_shot(_indeks_shot)
	AudioManager.putar_musik("kampung")


func _process(delta: float) -> void:
	_waktu += delta
	_waktu_shot += delta
	Panorama.animasi_kapal(_kapal, _waktu)
	var shot: Dictionary = Panorama.SHOT[_indeks_shot]
	var p: Array = Panorama.pose(shot, _waktu_shot / DURASI_SHOT_MENU)
	_kamera.position = p[0]
	_kamera.look_at(p[1], Vector3.UP)
	if _waktu_shot >= DURASI_SHOT_MENU - 0.6 and _pudar.modulate.a == 0.0:
		var tw := create_tween()
		tw.tween_property(_pudar, "modulate:a", 1.0, 0.6)
		tw.tween_callback(_ganti_shot.bind((_indeks_shot + 1) % Panorama.SHOT.size()))
		tw.tween_property(_pudar, "modulate:a", 0.0, 0.8)


func _ganti_shot(i: int) -> void:
	_indeks_shot = i
	_waktu_shot = 0.0
	var shot: Dictionary = Panorama.SHOT[i]
	_label_tema.text = "%s  ·  %s" % [shot["judul"], shot["ket"]]


func _bangun_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	_pudar = ColorRect.new()
	_pudar.color = Color(0.05, 0.04, 0.04)
	_pudar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pudar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pudar.modulate.a = 0.0
	ui.add_child(_pudar)
	# Bayangan gelap di sisi kiri agar judul dan tombol mudah dibaca di atas panorama
	var bayang := TextureRect.new()
	var gradasi := GradientTexture2D.new()
	gradasi.gradient = Gradient.new()
	gradasi.gradient.set_color(0, Color(0.05, 0.04, 0.04, 0.85))
	gradasi.gradient.set_color(1, Color(0.05, 0.04, 0.04, 0.0))
	gradasi.width = 64
	gradasi.height = 4
	bayang.texture = gradasi
	bayang.stretch_mode = TextureRect.STRETCH_SCALE
	bayang.position = Vector2.ZERO
	bayang.size = Vector2(330, 360)
	bayang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(bayang)
	# Logo "Jelajah Budaya Manggarai" dengan napas pelan (skala naik-turun)
	var logo := TextureRect.new()
	logo.texture = preload("res://assets/ui/logo_manggarai.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(14, 2)
	logo.size = Vector2(100, 100)
	logo.pivot_offset = Vector2(50, 50)
	ui.add_child(logo)
	var napas := logo.create_tween().set_loops()
	napas.tween_property(logo, "scale", Vector2(1.04, 1.04), 1.6).set_trans(Tween.TRANS_SINE)
	napas.tween_property(logo, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE)
	var judul := Gaya.label("JEJAK PENTI", 26, Gaya.KUNING)
	judul.position = Vector2(118, 16)
	judul.add_theme_constant_override("outline_size", 6)
	ui.add_child(judul)
	var sub := Gaya.label("Petualangan Budaya Manggarai", 11, Gaya.PUTIH)
	sub.position = Vector2(120, 52)
	ui.add_child(sub)
	var garis := ColorRect.new()
	garis.color = Gaya.MERAH
	garis.position = Vector2(120, 70)
	garis.size = Vector2(170, 2)
	ui.add_child(garis)
	var tema := Gaya.label("Wae Rebo  ·  Lingko  ·  Labuan Bajo", 8, Color("c9c2b0"))
	tema.position = Vector2(120, 74)
	ui.add_child(tema)

	var kolom := VBoxContainer.new()
	kolom.position = Vector2(28, 104)
	kolom.add_theme_constant_override("separation", 5)
	ui.add_child(kolom)
	_tombol_mulai = _tombol_menu("Mulai Permainan", kolom)
	_tombol_mulai.pressed.connect(_mulai)
	if GameState.ada_simpanan():
		var lv: int = clampi(GameState.level_tertinggi, 1, GameState.ADEGAN_LEVEL.size())
		var lanjut := _tombol_menu("Lanjutkan (Level %d)" % lv, kolom)
		lanjut.pressed.connect(func() -> void: GameState.lanjutkan())
	_tombol_mode = _tombol_menu(_teks_mode(), kolom)
	_tombol_mode.pressed.connect(_ganti_mode)
	var cara := _tombol_menu("Cara Bermain", kolom)
	cara.pressed.connect(_tampilkan_info.bind(_teks_cara_bermain()))
	var tentang := _tombol_menu("Tentang Game", kolom)
	tentang.pressed.connect(_tampilkan_info.bind(_teks_tentang()))
	_tombol_layar = _tombol_menu(_teks_layar(), kolom)
	_tombol_layar.pressed.connect(_ganti_layar)
	if not OS.has_feature("web"):
		var keluar := _tombol_menu("Keluar", kolom)
		keluar.pressed.connect(func() -> void: get_tree().quit())

	# Sapaan dan nama tema yang sedang tampil (kanan bawah)
	var pita := Gaya.panel_songke(Vector2(338, 300), Vector2(294, 50))
	ui.add_child(pita)
	var sapa := Gaya.label("Selamat datang di Manggarai!", 11, Gaya.KUNING)
	sapa.position = Vector2(12, 6)
	pita.add_child(sapa)
	var ajak := Gaya.label("Mari belajar budaya sambil bermain.", 9, Gaya.PUTIH)
	ajak.position = Vector2(12, 26)
	pita.add_child(ajak)
	_label_tema = Gaya.label("", 8, Gaya.PUTIH)
	_label_tema.position = Vector2(338, 284)
	_label_tema.size = Vector2(294, 14)
	_label_tema.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(_label_tema)

	_panel_info = Gaya.panel_songke(Vector2(222, 16), Vector2(400, 328))
	_panel_info.visible = false
	ui.add_child(_panel_info)
	_label_info = RichTextLabel.new()  # bisa digulir (roda mouse / geser jari)
	_label_info.position = Vector2(16, 14)
	_label_info.size = Vector2(368, 270)
	_label_info.scroll_active = true
	_label_info.add_theme_font_size_override("normal_font_size", 9)
	_label_info.add_theme_color_override("default_color", Gaya.PUTIH)
	_panel_info.add_child(_label_info)
	var tutup := Gaya.tombol("Tutup")
	tutup.position = Vector2(120, 292)
	tutup.pressed.connect(func() -> void: _panel_info.visible = false)
	_panel_info.add_child(tutup)
	_tombol_mulai.grab_focus()


## Tombol menu berukuran besar (mudah diketuk di layar sentuh).
func _tombol_menu(teks: String, kolom: VBoxContainer) -> Button:
	var b := Gaya.tombol(teks)
	b.custom_minimum_size = Vector2(196, 27)
	b.add_theme_font_size_override("font_size", 12)
	kolom.add_child(b)
	return b


func _ganti_layar() -> void:
	Layar.layar_penuh(not Layar.sedang_penuh())
	await get_tree().create_timer(0.4).timeout
	_tombol_layar.text = _teks_layar()


func _teks_layar() -> String:
	return "Keluar Layar Penuh" if Layar.sedang_penuh() else "Layar Penuh"


func _mulai() -> void:
	GameState.reset_progres()
	GameState.mulai_level(1)


func _ganti_mode() -> void:
	GameState.atur_mode_sulit(not GameState.mode_sulit)
	_tombol_mode.text = _teks_mode()


func _teks_mode() -> String:
	return "Mode: Sulit" if GameState.mode_sulit else "Mode: Normal"


func _tampilkan_info(teks: String) -> void:
	_label_info.text = teks
	_label_info.scroll_to_line(0)
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

LEVEL 3 – SONGKE KE LABUAN BAJO
Ikut kapal wisata ke 6 destinasi Taman Nasional Komodo. Di tiap destinasi, jual kain songke titipan penenun atau foto budaya kepada 3 wisatawan: pilih barang yang cocok dengan keinginannya, lalu ceritakan maknanya. Tiap destinasi punya tantangan: mendaki Padar (jaga tenaga), karang di Pink Beach, komodo di Pulau Komodo, air pasang di Taka Makassar, dan arus di Teluk Manjarite.

MODE SULIT: ada batas waktu "sebelum senja", jatuh dan salah orang mengurangi waktu, kesempatan salah lebih sedikit, dan ukuran bagian tidak ditampilkan.

Dialog diucapkan dengan suara; teks dialog bisa dinyalakan di menu jeda."""


func _teks_tentang() -> String:
	return """TENTANG GAME

Jejak Penti di Wae Rebo adalah prototipe game 3D jelajah budaya Manggarai, Flores, NTT. Menjelang Penti (tahun baru adat), Nggohak menemui warga kampung, menjawab teka-teki, menenun songke, dan menabuh gong-gendang untuk mengumpulkan kartu pengetahuan budaya. Di Level 2, ia membantu Tu'a Teno membagi lingko, lahan adat berbentuk jaring laba-laba. Di Level 3, ia membawa songke tenunan penenun kampung ke Labuan Bajo dan menjualnya kepada wisatawan di Taman Nasional Komodo.

Latar kampung terinspirasi Wae Rebo: tujuh Mbaru Niang yang melingkari compang. Caci ditampilkan sebagai pertunjukan saat Penti. Semua model, tekstur songke, dan musik gong-gendang dibuat sendiri secara prosedural.

Dibuat dengan Godot Engine 4 untuk tugas mata kuliah Pengembangan Permainan Digital."""
