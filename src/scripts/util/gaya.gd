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
	b.custom_minimum_size = Vector2(160, 24)
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", PUTIH)
	b.add_theme_color_override("font_hover_color", KUNING)
	b.add_theme_color_override("font_focus_color", KUNING)
	b.add_theme_stylebox_override("normal", _kotak(HITAM, MERAH))
	b.add_theme_stylebox_override("hover", _kotak(Color("2a2424"), KUNING))
	b.add_theme_stylebox_override("focus", _kotak(Color("2a2424"), KUNING))
	b.add_theme_stylebox_override("pressed", _kotak(MERAH, KUNING))
	b.pressed.connect(func() -> void: AudioManager.putar_sfx("klik"))
	return b


static func _kotak(isi: Color, tepi: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = isi
	s.border_color = tepi
	s.set_border_width_all(2)
	s.set_content_margin_all(4)
	return s
