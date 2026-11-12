class_name BilahTiming
extends Control
## Bilah timing untuk peran PAKI: penanda bergerak bolak-balik, pemain menekan
## tombol cambuk ketika penanda berada di zona kuning (tepat).

@export var lebar_zona: float = 0.2  ## proporsi bilah yang termasuk "tepat"
@export var kecepatan: float = 1.0   ## siklus per detik

var posisi: float = 0.0  ## 0..1
var berjalan: bool = false
var _arah: float = 1.0
var _pusat_zona: float = 0.5


func _ready() -> void:
	custom_minimum_size = Vector2(300, 22)
	size = Vector2(300, 22)


func mulai(zona: float, laju: float) -> void:
	lebar_zona = zona
	kecepatan = laju
	posisi = 0.0
	_arah = 1.0
	_pusat_zona = randf_range(0.35, 0.65)
	berjalan = true
	visible = true


func berhenti() -> void:
	berjalan = false


func _process(delta: float) -> void:
	if not berjalan:
		return
	posisi += _arah * kecepatan * 2.0 * delta
	if posisi >= 1.0:
		posisi = 1.0
		_arah = -1.0
	elif posisi <= 0.0:
		posisi = 0.0
		_arah = 1.0
	queue_redraw()


## "tepat" (zona kuning), "hampir" (zona oranye), atau "meleset".
func nilai() -> String:
	var jarak: float = absf(posisi - _pusat_zona)
	if jarak <= lebar_zona / 2.0:
		return "tepat"
	if jarak <= lebar_zona:
		return "hampir"
	return "meleset"


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(0, 0, w, h), Gaya.HITAM)
	draw_rect(Rect2((_pusat_zona - lebar_zona) * w, 2, lebar_zona * 2.0 * w, h - 4), Color("d66e28"))
	draw_rect(Rect2((_pusat_zona - lebar_zona / 2.0) * w, 2, lebar_zona * w, h - 4), Gaya.KUNING)
	draw_rect(Rect2(0, 0, w, h), Gaya.MERAH, false, 2.0)
	var x: float = posisi * w
	draw_rect(Rect2(x - 2, -4, 4, h + 8), Gaya.PUTIH)
