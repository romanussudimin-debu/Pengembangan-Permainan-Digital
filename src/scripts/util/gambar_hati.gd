class_name GambarHati
extends RefCounted
## Menggambar ikon hati (nyawa) secara prosedural: penuh (merah bermotif kilau), kosong
## (garis), atau retak (garis patahan) untuk animasi nyawa pecah.

const MERAH := Color("d63a32")
const MERAH_GELAP := Color("7a1a16")


static func _bentuk(pusat: Vector2, r: float) -> PackedVector2Array:
	var titik := PackedVector2Array()
	for i in 33:
		var t: float = TAU * i / 32.0
		# Kurva hati klasik (diskalakan): x = 16 sin^3 t, y = 13 cos t - 5 cos 2t - 2 cos 3t - cos 4t
		var x: float = 16.0 * pow(sin(t), 3)
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		titik.append(pusat + Vector2(x, y) * (r / 16.0))
	return titik


static func gambar(c: CanvasItem, pusat: Vector2, r: float, penuh: bool, retak: bool = false) -> void:
	var bentuk := _bentuk(pusat, r)
	if penuh:
		c.draw_colored_polygon(bentuk, MERAH)
		c.draw_circle(pusat + Vector2(-r * 0.4, -r * 0.35), r * 0.18, Color(1, 1, 1, 0.55))
	else:
		c.draw_colored_polygon(bentuk, Color(0.12, 0.08, 0.08, 0.7))
	bentuk.append(bentuk[0])
	c.draw_polyline(bentuk, Color("1b1818") if penuh else MERAH_GELAP, maxf(1.0, r * 0.12))
	if retak:
		var patah := PackedVector2Array([pusat + Vector2(-r * 0.1, -r * 0.6), pusat + Vector2(r * 0.15, -r * 0.2),
			pusat + Vector2(-r * 0.12, r * 0.15), pusat + Vector2(r * 0.08, r * 0.7)])
		c.draw_polyline(patah, Color("f4e8d0"), maxf(1.0, r * 0.14))
