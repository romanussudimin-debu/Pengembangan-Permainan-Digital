extends Control
## Layar antar-level (dibuka GameState.selesaikan_level):
##   1. SUKSES : "LEVEL N BERHASIL!" + ringkasan (kartu, waktu, nyawa) + bintang 1-3 per tantangan
##               (muncul satu per satu, data Prestasi) + tombol "Lanjutkan ke Level N+1".
##   2. ORB    : bola atom bersinar dengan cincin orbit bermotif songke dan tulisan "LEVEL N+1",
##               nama dan tagline level, lalu tombol "Mulai Level N+1".
## Setelah level terakhir, tombolnya menuju perayaan Penti (ending).

enum Tahap { SUKSES, ORB }

const WARNA_ORBIT: Array[Color] = [Color("e8b430"), Color("b02a2a"), Color("2e7d46")]

var _tahap: int = Tahap.SUKSES
var _selesai: int = 1
var _berikut: int = 2
var _waktu: float = 0.0
var _waktu_orb: float = 0.0
var _kanvas: Control
var _grup_sukses: Control
var _grup_orb: Control
var _tombol_mulai: Button
var _label_nama: Label
var _label_tagline: Label
var _kanvas_bintang: Control
var _waktu_bintang: float = -0.6
var _bintang_berbunyi: int = 0


func _ready() -> void:
	get_tree().paused = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_selesai = maxi(GameState.level_baru_selesai, 1)
	_berikut = _selesai + 1
	GameState.ubah_state(GameState.State.MENU)  # layar menu: kontrol sentuh & menu jeda tidak tampil
	AudioManager.putar_musik("kampung")
	AudioManager.putar_sfx("gong")
	_kanvas = Control.new()
	_kanvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kanvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kanvas.draw.connect(_gambar_latar)
	add_child(_kanvas)
	_bangun_sukses()
	_bangun_orb()


func _ada_level_berikut() -> bool:
	return GameState.ADEGAN_LEVEL.has(_berikut)


# ------------------------------------------------------------------ tahap SUKSES

func _bangun_sukses() -> void:
	_grup_sukses = Control.new()
	_grup_sukses.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_grup_sukses)
	var judul := Gaya.label("LEVEL %d BERHASIL!" % _selesai, 30, Gaya.KUNING)
	judul.add_theme_constant_override("outline_size", 7)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.size = Vector2(640, 44)
	judul.position = Vector2(0, 40)
	judul.pivot_offset = Vector2(320, 22)
	_grup_sukses.add_child(judul)
	var nama := Gaya.label(str(GameState.data_level(_selesai).get("nama", "")), 13, Gaya.PUTIH)
	nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nama.size = Vector2(640, 20)
	nama.position = Vector2(0, 86)
	_grup_sukses.add_child(nama)
	# Ringkasan level
	var panel := Gaya.panel_songke(Vector2(28, 112), Vector2(250, 118))
	_grup_sukses.add_child(panel)
	var d: int = int(GameState.durasi_level_terakhir)
	var baris: Array[String] = [
		"Kartu budaya: %d / %d" % [GameState.jumlah_terkumpul_level(_selesai), GameState.kartu_level(_selesai).size()],
		"Waktu bermain: %d:%02d" % [d / 60, d % 60],
		"Nyawa tersisa: %d / %d" % [Nyawa.sisa, Nyawa.maks()],
	]
	for i in baris.size():
		var l := Gaya.label(baris[i], 11, Gaya.PUTIH)
		l.position = Vector2(22, 16 + i * 30)
		panel.add_child(l)
	var teks_tombol: String = str(GameState.DATA_LEVEL.data["penutup"]["tombol"])
	if _ada_level_berikut():
		teks_tombol = "Lanjutkan ke Level %d" % _berikut
	var tombol := Gaya.tombol(teks_tombol)
	tombol.custom_minimum_size = Vector2(240, 32)
	tombol.add_theme_font_size_override("font_size", 13)
	tombol.position = Vector2(200, 258)
	tombol.pressed.connect(_lanjut)
	_grup_sukses.add_child(tombol)
	tombol.call_deferred("grab_focus")
	if not _ada_level_berikut():
		var teks := Gaya.label(str(GameState.DATA_LEVEL.data["penutup"]["teks"]), 10, Color("c9c2b0"))
		teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		teks.size = Vector2(640, 18)
		teks.position = Vector2(0, 302)
		_grup_sukses.add_child(teks)
	# Judul muncul dengan efek "pop" (squash & stretch)
	judul.scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(judul, "scale", Vector2(1.12, 1.12), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(judul, "scale", Vector2.ONE, 0.15)
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.5).set_delay(0.3)
	_bangun_bintang()


## Panel bintang per tantangan (maks. 10 baris); bintang muncul satu per satu dengan efek pop.
func _bangun_bintang() -> void:
	var baris: Array = Prestasi.ringkasan_terakhir.slice(0, 10)
	var panel := Gaya.panel_songke(Vector2(292, 106), Vector2(320, 30 + maxi(baris.size(), 1) * 13))
	_grup_sukses.add_child(panel)
	var judul := Gaya.label(Prestasi.teks("bintang_judul"), 10, Gaya.KUNING)
	judul.position = Vector2(16, 6)
	panel.add_child(judul)
	_kanvas_bintang = Control.new()
	_kanvas_bintang.position = Vector2(16, 24)
	_kanvas_bintang.size = Vector2(290, baris.size() * 13)
	_kanvas_bintang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kanvas_bintang.draw.connect(_gambar_bintang.bind(baris))
	panel.add_child(_kanvas_bintang)


func _gambar_bintang(baris: Array) -> void:
	var c: Control = _kanvas_bintang
	var huruf: Font = ThemeDB.fallback_font
	var urutan: int = 0
	for i in baris.size():
		var y: float = i * 13.0
		var nama: String = str(baris[i][0])
		if nama.length() > 30:
			nama = nama.substr(0, 29) + "..."
		c.draw_string(huruf, Vector2(0, y + 10), nama, HORIZONTAL_ALIGNMENT_LEFT, 220, 9, Gaya.PUTIH)
		for k in 3:
			var t: float = _waktu_bintang - urutan * 0.09
			urutan += 1
			var skala: float = clampf(t / 0.18, 0.0, 1.0)
			skala = 1.0 + sin(skala * PI) * 0.5 if skala < 1.0 else 1.0  # pop: membesar lalu kembali
			if t <= 0.0:
				skala = 0.0
			var pusat := Vector2(236 + k * 16, y + 6)
			GambarBintang.gambar(c, pusat, 5.5, false, Color(1, 1, 1, 0.18))
			if k < int(baris[i][1]) and skala > 0.0:
				GambarBintang.gambar(c, pusat, 5.5 * skala, true, Gaya.KUNING)


func _proses_bintang(delta: float) -> void:
	if _kanvas_bintang == null or _tahap != Tahap.SUKSES:
		return
	_waktu_bintang += delta
	var muncul: int = int(floor(_waktu_bintang / 0.09))
	var total: int = 0
	for b: Array in Prestasi.ringkasan_terakhir.slice(0, 10):
		total += 3
	if muncul > _bintang_berbunyi and _bintang_berbunyi < total:
		_bintang_berbunyi = muncul
		if _bintang_berbunyi % 3 == 0:
			AudioManager.putar_sfx("klik", 0.1)
	_kanvas_bintang.queue_redraw()


func _lanjut() -> void:
	if not _ada_level_berikut():
		Transisi.pindah_scene(GameState.ADEGAN_ENDING)
		return
	_tahap = Tahap.ORB
	_waktu_orb = 0.0
	AudioManager.putar_sfx("gendang")
	var tw := create_tween()
	tw.tween_property(_grup_sukses, "modulate:a", 0.0, 0.35)
	tw.tween_callback(_grup_sukses.hide)
	_grup_orb.show()
	_grup_orb.modulate.a = 0.0
	create_tween().tween_property(_grup_orb, "modulate:a", 1.0, 0.5).set_delay(0.2)
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		_tombol_mulai.show()
		_tombol_mulai.grab_focus()
		AudioManager.putar_sfx("gong"))


# ------------------------------------------------------------------ tahap ORB

func _bangun_orb() -> void:
	_grup_orb = Control.new()
	_grup_orb.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grup_orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grup_orb.hide()
	add_child(_grup_orb)
	var data: Dictionary = GameState.data_level(_berikut)
	_label_nama = Gaya.label(str(data.get("nama", "")), 18, Gaya.KUNING)
	_label_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_nama.size = Vector2(640, 26)
	_label_nama.position = Vector2(0, 252)
	_grup_orb.add_child(_label_nama)
	_label_tagline = Gaya.label(str(data.get("tagline", "")), 10, Gaya.PUTIH)
	_label_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_tagline.size = Vector2(640, 18)
	_label_tagline.position = Vector2(0, 280)
	_grup_orb.add_child(_label_tagline)
	_tombol_mulai = Gaya.tombol("Mulai Level %d" % _berikut)
	_tombol_mulai.custom_minimum_size = Vector2(200, 30)
	_tombol_mulai.add_theme_font_size_override("font_size", 13)
	_tombol_mulai.position = Vector2(220, 312)
	_tombol_mulai.hide()
	_tombol_mulai.pressed.connect(func() -> void: GameState.mulai_level(_berikut))
	add_child(_tombol_mulai)


func _process(delta: float) -> void:
	_waktu += delta
	_waktu_orb += delta
	_kanvas.queue_redraw()
	_proses_bintang(delta)


## Latar: gradasi malam, pola belah ketupat songke yang berputar pelan, kilau melayang,
## dan (tahap ORB) bola atom LEVEL berikutnya.
func _gambar_latar() -> void:
	var c: Control = _kanvas
	for y in 18:
		c.draw_rect(Rect2(0, y * 20.0, 640, 20.0), Color("1b1214").lerp(Color("3a1a16"), y / 17.0))
	var pusat := Vector2(320, 150)
	for i in 24:
		var a: float = TAU * i / 24.0 + _waktu * 0.05
		var p: Vector2 = pusat + Vector2(cos(a), sin(a)) * 250.0
		_belah_ketupat(c, p, 9.0, Color(WARNA_ORBIT[i % 3], 0.25))
	for i in 30:
		var x: float = fmod(i * 97.0, 640.0)
		var y: float = 360.0 - fmod(_waktu * (12.0 + i % 5 * 4.0) + i * 53.0, 380.0)
		c.draw_circle(Vector2(x, y), 1.2 + (i % 3) * 0.5, Color(1, 0.9, 0.6, 0.35))
	if _tahap == Tahap.ORB:
		_gambar_orb(c, pusat)


func _gambar_orb(c: Control, pusat: Vector2) -> void:
	var muncul: float = ease(clampf(_waktu_orb / 0.8, 0.0, 1.0), -2.0)
	var jari: float = 58.0 * muncul + sin(_waktu * 2.5) * 2.0
	# Cahaya bertingkat (glow)
	for k in 6:
		c.draw_circle(pusat, jari + 30.0 - k * 5.0, Color(1.0, 0.75, 0.25, 0.05 + k * 0.02))
	c.draw_circle(pusat, jari, Color("5a1a16"))
	c.draw_circle(pusat, jari * 0.86, Color("8a2a20"))
	c.draw_arc(pusat, jari, 0.0, TAU, 48, Gaya.KUNING, 3.0)
	# Tiga orbit elips miring dengan "elektron" bermotif songke
	for i in 3:
		var miring: float = TAU * i / 3.0 + 0.3
		var titik := PackedVector2Array()
		for s in 49:
			var t: float = TAU * s / 48.0
			titik.append(pusat + Vector2(cos(t) * jari * 1.9, sin(t) * jari * 0.62).rotated(miring))
		c.draw_polyline(titik, Color(WARNA_ORBIT[i], 0.85 * muncul), 2.0)
		var t_e: float = _waktu * (1.6 + i * 0.4) + i * 2.0
		var e: Vector2 = pusat + Vector2(cos(t_e) * jari * 1.9, sin(t_e) * jari * 0.62).rotated(miring)
		_belah_ketupat(c, e, 7.0 * muncul, WARNA_ORBIT[i])
		c.draw_circle(e, 2.0 * muncul, Gaya.PUTIH)
	if muncul > 0.3:
		var huruf := ThemeDB.fallback_font
		c.draw_string(huruf, pusat + Vector2(-jari, -14), "LEVEL", HORIZONTAL_ALIGNMENT_CENTER, jari * 2.0, 13, Color(Gaya.PUTIH, muncul))
		var pos_angka: Vector2 = pusat + Vector2(-jari, 30)
		c.draw_string_outline(huruf, pos_angka, str(_berikut), HORIZONTAL_ALIGNMENT_CENTER, jari * 2.0, 46, 6, Color(Gaya.HITAM, muncul))
		c.draw_string(huruf, pusat + Vector2(-jari, 30), str(_berikut), HORIZONTAL_ALIGNMENT_CENTER, jari * 2.0, 46, Color(Gaya.KUNING, muncul))


func _belah_ketupat(c: Control, p: Vector2, r: float, warna: Color) -> void:
	if r < 0.5:
		return
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]), warna)
