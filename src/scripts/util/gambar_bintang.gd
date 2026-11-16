class_name GambarBintang
## Menggambar bintang lima sudut di CanvasItem (bintang tantangan & rekor level).


static func gambar(c: CanvasItem, pusat: Vector2, r: float, isi: bool, warna: Color) -> void:
	if r < 0.5:
		return
	var titik := PackedVector2Array()
	for i in 10:
		var a: float = -PI / 2.0 + TAU * i / 10.0
		var jari: float = r if i % 2 == 0 else r * 0.45
		titik.append(pusat + Vector2(cos(a), sin(a)) * jari)
	if isi:
		c.draw_colored_polygon(titik, warna)
		titik.append(titik[0])
		c.draw_polyline(titik, Color("7a4a10"), 1.0)
	else:
		titik.append(titik[0])
		c.draw_polyline(titik, warna, 1.0)
