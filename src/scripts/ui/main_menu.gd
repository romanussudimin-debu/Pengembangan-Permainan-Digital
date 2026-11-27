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
var _pita: Control  ## sapaan kanan bawah (disembunyikan saat panel terbuka)
var _ketukan_logo: Array[int] = []  ## waktu ketukan logo (ekspor analitik tersembunyi: 5x dalam 3 detik)
var _panel_daftar: NinePatchRect  ## panel Pilih Level / Pencapaian (isinya dibangun ulang tiap dibuka)


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
	logo.gui_input.connect(_ketuk_logo)
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
		lanjut.pressed.connect(GameState.lanjutkan)
	var baris_prestasi := _baris_menu(kolom)
	if GameState.level_tertinggi > 1:
		var pilih := _tombol_kecil(Prestasi.teks("pilih_level"), baris_prestasi)
		pilih.pressed.connect(_tampilkan_pilih_level)
	var capai := _tombol_kecil(Prestasi.teks("judul_menu"), baris_prestasi)
	capai.pressed.connect(_tampilkan_pencapaian)
	var baris_mode := _baris_menu(kolom)
	_tombol_mode = _tombol_kecil(_teks_mode(), baris_mode)
	_tombol_mode.pressed.connect(_ganti_mode)
	var baris_info := _baris_menu(kolom)
	var cara := _tombol_kecil("Cara Bermain", baris_info)
	cara.pressed.connect(_tampilkan_info.bind(_teks_cara_bermain()))
	var tentang := _tombol_kecil("Tentang", baris_info)
	tentang.pressed.connect(_tampilkan_info.bind(_teks_tentang()))
	var baris_layar := _baris_menu(kolom)
	_tombol_layar = _tombol_kecil(_teks_layar(), baris_layar)
	_tombol_layar.pressed.connect(_ganti_layar)
	if not OS.has_feature("web"):
		var keluar := _tombol_kecil("Keluar", baris_layar)
		keluar.pressed.connect(func() -> void: get_tree().quit())

	# Sapaan dan nama tema yang sedang tampil (kanan bawah)
	var pita := Gaya.panel_songke(Vector2(338, 300), Vector2(294, 50))
	_pita = pita
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

	_panel_info = Gaya.panel_songke(Vector2(244, 14), Vector2(388, 338))
	_panel_info.visible = false
	ui.add_child(_panel_info)
	_label_info = RichTextLabel.new()  # bisa digulir (roda mouse / geser jari)
	_label_info.position = Vector2(16, 14)
	_label_info.size = Vector2(356, 278)
	_label_info.scroll_active = true
	_label_info.add_theme_font_size_override("normal_font_size", 9)
	_label_info.add_theme_color_override("default_color", Gaya.PUTIH)
	_panel_info.add_child(_label_info)
	var tutup := Gaya.tombol("Tutup")
	tutup.position = Vector2(114, 300)
	tutup.pressed.connect(func() -> void:
		_panel_info.visible = false
		_pita.visible = true
		_label_tema.visible = true)
	_panel_info.add_child(tutup)
	_panel_daftar = Gaya.panel_songke(Vector2(244, 14), Vector2(388, 338))
	_panel_daftar.visible = false
	ui.add_child(_panel_daftar)
	_tombol_mulai.grab_focus()


## Tombol menu berukuran besar (mudah diketuk di layar sentuh).
func _tombol_menu(teks: String, kolom: VBoxContainer) -> Button:
	var b := Gaya.tombol(teks)
	b.custom_minimum_size = Vector2(196, 27)
	b.add_theme_font_size_override("font_size", 12)
	kolom.add_child(b)
	return b


func _baris_menu(kolom: VBoxContainer) -> HBoxContainer:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 4)
	kolom.add_child(baris)
	return baris


func _tombol_kecil(teks: String, baris: HBoxContainer) -> Button:
	var b := Gaya.tombol(teks)
	b.custom_minimum_size = Vector2(96, 27)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 10)
	b.add_theme_constant_override("h_separation", 0)
	baris.add_child(b)
	return b


func _kosongkan_daftar(judul: String) -> void:
	for anak in _panel_daftar.get_children():
		anak.queue_free()
	_panel_info.visible = false
	_panel_daftar.visible = true
	_pita.visible = false
	_label_tema.visible = false
	var l := Gaya.label(judul, 14, Gaya.KUNING)
	l.position = Vector2(16, 10)
	_panel_daftar.add_child(l)
	var tutup := Gaya.tombol(Prestasi.teks("kembali"))
	tutup.position = Vector2(114, 300)
	tutup.pressed.connect(func() -> void:
		_panel_daftar.visible = false
		_pita.visible = true
		_label_tema.visible = true)
	_panel_daftar.add_child(tutup)


## Pilih Level: hanya level yang sudah terbuka, dengan bintang terbaik masing-masing.
func _tampilkan_pilih_level() -> void:
	_kosongkan_daftar(Prestasi.teks("pilih_level"))
	var terbuka: int = mini(GameState.level_tertinggi, GameState.ADEGAN_LEVEL.size())
	for n in range(1, terbuka + 1):
		var b := Gaya.tombol("Level %d · %s" % [n, GameState.data_level(n).get("nama", "")])
		b.position = Vector2(20, 48 + (n - 1) * 56)
		b.custom_minimum_size = Vector2(250, 32)
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(GameState.pilih_level.bind(n))
		_panel_daftar.add_child(b)
		var bintang := Control.new()
		bintang.position = Vector2(290, 54 + (n - 1) * 56)
		bintang.size = Vector2(80, 20)
		var terbaik: int = int(Prestasi.bintang_terbaik.get(n, 0))
		bintang.draw.connect(func() -> void:
			for k in 3:
				GambarBintang.gambar(bintang, Vector2(10 + k * 24, 10), 9.0, k < terbaik, Gaya.KUNING))
		_panel_daftar.add_child(bintang)
		if n == 1:
			b.call_deferred("grab_focus")


## Daftar 7 pencapaian: medali emas bila diraih, abu-abu bila belum.
func _tampilkan_pencapaian() -> void:
	_kosongkan_daftar("%s (%d/%d)" % [Prestasi.teks("judul_menu"), Prestasi.jumlah_diraih(), Prestasi.daftar().size()])
	var daftar: Array = Prestasi.daftar()
	for i in daftar.size():
		var p: Dictionary = daftar[i]
		var ada: bool = Prestasi.sudah(str(p["id"]))
		var y: float = 38.0 + i * 35.0
		var ikon := Control.new()
		ikon.position = Vector2(16, y)
		ikon.size = Vector2(28, 28)
		ikon.draw.connect(func() -> void:
			ikon.draw_circle(Vector2(14, 14), 12.0, Gaya.KUNING if ada else Color("4a4440"))
			ikon.draw_arc(Vector2(14, 14), 12.0, 0.0, TAU, 24, Color("7a4a10") if ada else Gaya.ABU, 1.5)
			GambarBintang.gambar(ikon, Vector2(14, 14), 7.0, ada, Gaya.MERAH if ada else Gaya.ABU))
		_panel_daftar.add_child(ikon)
		var nama := Gaya.label(str(p["nama"]), 11, Gaya.KUNING if ada else Gaya.ABU)
		nama.position = Vector2(52, y - 2)
		_panel_daftar.add_child(nama)
		if not ada:
			nama.text += "  (%s)" % Prestasi.teks("terkunci")
		var syarat := Gaya.label(str(p["syarat"]), 8, Gaya.PUTIH if ada else Color("a8a092"))
		syarat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		syarat.position = Vector2(52, y + 12)
		syarat.size = Vector2(330, 22)
		syarat.add_theme_constant_override("line_spacing", -3)
		_panel_daftar.add_child(syarat)


func _ketuk_logo(event: InputEvent) -> void:
	var ketuk: bool = (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
			or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if not ketuk:
		return
	var kini: int = Time.get_ticks_msec()
	_ketukan_logo.append(kini)
	_ketukan_logo = _ketukan_logo.filter(func(t: int) -> bool: return kini - t < 3000)
	if _ketukan_logo.size() >= 5:
		_ketukan_logo.clear()
		_tampilkan_analitik()


## Panel tersembunyi untuk penguji: ringkasan & ekspor data analitik playtest.
func _tampilkan_analitik() -> void:
	_kosongkan_daftar("Data Playtest (lokal)")
	var info := Gaya.label(Analitik.ringkasan(), 9, Gaya.PUTIH)
	info.position = Vector2(20, 40)
	_panel_daftar.add_child(info)
	var status := Gaya.label("", 9, Gaya.KUNING)
	status.position = Vector2(20, 270)
	status.size = Vector2(350, 24)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_daftar.add_child(status)
	var aksi: Array = [
		["Salin CSV", func() -> void:
			DisplayServer.clipboard_set(Analitik.ke_csv())
			status.text = "CSV disalin ke papan klip."],
		["Salin JSON", func() -> void:
			DisplayServer.clipboard_set(Analitik.ke_json())
			status.text = "JSON disalin ke papan klip."],
		["Simpan CSV", func() -> void: status.text = Analitik.simpan_csv()],
	]
	for i in aksi.size():
		var b := Gaya.tombol(str(aksi[i][0]))
		b.position = Vector2(20 + i * 120, 220)
		b.custom_minimum_size = Vector2(112, 30)
		b.add_theme_font_size_override("font_size", 10)
		b.pressed.connect(aksi[i][1])
		_panel_daftar.add_child(b)


func _ganti_layar() -> void:
	Layar.layar_penuh(not Layar.sedang_penuh())
	await get_tree().create_timer(0.4).timeout
	_tombol_layar.text = _teks_layar()


func _teks_layar() -> String:
	return "Keluar Layar Penuh" if Layar.sedang_penuh() else "Layar Penuh"


func _mulai() -> void:
	GameState.reset_progres()
	GameState.mulai_level(1)


## Kesulitan: Normal <-> Sulit (Sulit: 3 nyawa dan batas waktu "sebelum senja").
func _ganti_mode() -> void:
	GameState.atur_mode_sulit(not GameState.mode_sulit)
	_tombol_mode.text = _teks_mode()


func _teks_mode() -> String:
	return "Mode Sulit" if GameState.mode_sulit else "Mode Normal"


func _tampilkan_info(teks: String) -> void:
	_panel_daftar.visible = false
	_pita.visible = false
	_label_tema.visible = false
	_label_info.text = teks
	_label_info.scroll_to_line(0)
	_panel_info.visible = true


func _teks_cara_bermain() -> String:
	return """CARA BERMAIN

• WASD / panah: berjalan   • Spasi: melompat
• E: bicara / lanjut dialog   • Esc: jeda & koleksi kartu
• Kamera: tahan klik kanan + geser untuk memutar, roda mouse untuk zoom
• Di HP/tablet: joystick kiri untuk berjalan, tombol LOMPAT, BICARA, dan II (jeda); geser satu jari di separuh KANAN layar untuk memutar kamera, cubit untuk zoom, ketuk dua kali untuk meluruskan kamera. Dialog & tantangan cukup diketuk.

LEVEL 1 – KAMPUNG WAE REBO
Daki jalan hutan menuju Wae Rebo (jatuh ke sungai/jurang = -1 nyawa; awas batu retak dan jalan buntu). Di kampung, temui Tu'a Golo di dekat compang dan jawab teka-tekinya, lalu ikuti petunjuknya menuju Ine Wela untuk menenun songke.
• Teka-teki: klik, panah + Enter, atau tombol 1-4. Jawabannya ada di kartu budaya (Esc untuk membacanya lagi).
• Menenun songke: samakan kain dengan contoh motif (E/klik ganti warna benang).

LEVEL 2 – LINGKO LODOK
Temui Tu'a Teno di lodok, susuri pematang yang sempit (jatuh = kembali ke titik aman), alirkan air dari wae teku, lalu naik ke bukit batu untuk memandang lingko dari atas.

LEVEL 3 – SONGKE KE LABUAN BAJO
Ikut kapal ke 3 destinasi: Pelabuhan Labuan Bajo, Pulau Padar (jaga tenaga, minum di pos, awas batu goyah), dan Pink Beach (jangan injak karang, jangan ganggu penyu dan ikan). Di tiap destinasi, jual kain songke atau foto budaya kepada 3 wisatawan: pilih barang yang cocok, lalu ceritakan maknanya.

MODE SULIT: 3 nyawa (Normal 5), batas waktu "sebelum senja", dan jatuh mengurangi waktu.

Dialog diucapkan dengan suara; teks dialog bisa dinyalakan di menu jeda."""


func _teks_tentang() -> String:
	return """TENTANG GAME

Jejak Penti di Wae Rebo adalah prototipe game 3D jelajah budaya Manggarai, Flores, NTT. Menjelang Penti (tahun baru adat), Nggohak mendaki ke Kampung Wae Rebo, menjawab teka-teki Tu'a Golo, dan menenun songke bersama Ine Wela untuk mengumpulkan kartu pengetahuan budaya. Di Level 2, ia membantu Tu'a Teno mengalirkan air ke lingko, lahan adat berbentuk jaring laba-laba. Di Level 3, ia membawa songke tenunan penenun kampung ke Labuan Bajo dan menjualnya kepada wisatawan di Taman Nasional Komodo.

Latar kampung terinspirasi Wae Rebo: tujuh Mbaru Niang yang melingkari compang. Caci ditampilkan sebagai pertunjukan saat Penti. Semua model, tekstur songke, dan musik gong-gendang dibuat sendiri secara prosedural.

Dibuat dengan Godot Engine 4 untuk tugas mata kuliah Pengembangan Permainan Digital."""
