class_name Gaya
extends RefCounted
## Gaya UI bersama: warna (palet songke) dan pembuat elemen UI.

const HITAM := Color("1b1818")
const PUTIH := Color("e8e2d2")
const KUNING := Color("e8b430")
const MERAH := Color("b02a2a")
const HIJAU := Color("2e7d46")
const BIRU := Color("2c5c96")
const ABU := Color("8a837a")
const BINGKAI: Texture2D = preload("res://assets/textures/bingkai_songke.png")


static func label(teks: String, ukuran: int = 10, warna: Color = PUTIH) -> Label:
	var l := Label.new()
	l.text = teks
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_color_override("font_outline_color", HITAM)
	l.add_theme_constant_override("outline_size", 3)
	return l


static func panel_songke(posisi: Vector2, ukuran: Vector2) -> NinePatchRect:
	var p := NinePatchRect.new()
	p.texture = BINGKAI
	p.patch_margin_left = 8
	p.patch_margin_right = 8
	p.patch_margin_top = 8
	p.patch_margin_bottom = 8
	p.position = posisi
	p.size = ukuran
	return p


static func tombol(teks: String) -> Button:
	var b := Button.new()
	b.text = teks
	b.custom_minimum_size = Vector2(160, 26)
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", PUTIH)
	b.add_theme_color_override("font_hover_color", Color("fff1c8"))
	b.add_theme_color_override("font_focus_color", Color("fff1c8"))
	b.add_theme_color_override("font_pressed_color", Color("fff1c8"))
	b.add_theme_color_override("font_disabled_color", Color("6b6560"))
	b.add_theme_color_override("font_outline_color", HITAM)
	b.add_theme_constant_override("outline_size", 3)
	b.add_theme_stylebox_override("normal", _kotak(Color("2a1915"), Color("b08a3c")))
	b.add_theme_stylebox_override("hover", _kotak(Color("5a2420"), KUNING))
	b.add_theme_stylebox_override("focus", _kotak(Color("5a2420"), KUNING))
	b.add_theme_stylebox_override("pressed", _kotak(MERAH, Color("fff1c8")))
	b.add_theme_stylebox_override("disabled", _kotak(Color("1e1a19"), Color("4a4440")))
	b.pressed.connect(func() -> void: AudioManager.putar_sfx("klik"))
	# Ornamen belah ketupat songke di kedua ujung tombol
	b.draw.connect(_gambar_ornamen.bind(b))
	# Membesar sedikit saat disorot (ease out), kembali saat dilepas
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.mouse_entered.connect(_sorot.bind(b, true))
	b.mouse_exited.connect(_sorot.bind(b, false))
	b.focus_entered.connect(_sorot.bind(b, true))
	b.focus_exited.connect(_sorot.bind(b, false))
	return b


static func _sorot(b: Button, aktif: bool) -> void:
	if b.disabled or not b.is_inside_tree():
		return
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE * (1.05 if aktif else 1.0), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


static func _gambar_ornamen(b: Button) -> void:
	var sorot: bool = b.has_focus() or b.is_hovered()
	var tinggi: float = b.size.y
	var r: float = clampf(tinggi * 0.2, 3.0, 6.0)
	var warna_luar: Color = KUNING if not b.disabled else Color("4a4440")
	var warna_dalam: Color = MERAH if not sorot else Color("fff1c8")
	for x: float in [r + 5.0, b.size.x - r - 5.0]:
		var c := Vector2(x, tinggi / 2.0)
		b.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), warna_luar)
		var k: float = r * 0.45
		b.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -k), c + Vector2(k, 0), c + Vector2(0, k), c + Vector2(-k, 0)]), warna_dalam)
	# Garis tipis songke di bawah teks
	b.draw_line(Vector2(r * 2.0 + 10.0, tinggi - 4.0), Vector2(b.size.x - r * 2.0 - 10.0, tinggi - 4.0), Color(warna_luar, 0.35), 1.0)


static func _kotak(isi: Color, tepi: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = isi
	s.border_color = tepi
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.corner_detail = 6
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 3
	s.shadow_offset = Vector2(0, 2)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 3
	s.content_margin_bottom = 4
	s.anti_aliasing = true
	return s
