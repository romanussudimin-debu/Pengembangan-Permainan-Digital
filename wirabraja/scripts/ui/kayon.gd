@tool
class_name Kayon
extends Control
## Kayon (gunungan) sederhana yang digambar dengan kode (_draw), tanpa aset gambar.
## Dalam pertunjukan wayang kulit, kayon dipakai untuk membuka dan menutup
## pertunjukan serta menandai pergantian adegan. Di sini ia dipakai pada narasi pembuka.

@export var warna_isi: Color = Color(0.46, 0.08, 0.11)
@export var warna_garis: Color = Color(0.92, 0.72, 0.28)
@export var warna_dalam: Color = Color(0.28, 0.17, 0.09)


func _ready() -> void:
	resized.connect(queue_redraw)
	pivot_offset = Vector2(size.x * 0.5, size.y)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var garis := _bentuk(w, h, 1.0)
	draw_colored_polygon(garis, warna_isi)
	draw_polyline(garis + PackedVector2Array([garis[0]]), warna_garis, 4.0, true)
	var dalam := _bentuk(w, h, 0.82)
	draw_colored_polygon(dalam, warna_dalam)
	draw_polyline(dalam + PackedVector2Array([dalam[0]]), warna_garis, 2.0, true)

	# Pohon hayat: batang dan cabang.
	var cx := w * 0.5
	var dasar := h * 0.72
	draw_line(Vector2(cx, dasar), Vector2(cx, h * 0.12), warna_garis, 3.0, true)
	for i in 6:
		var y := lerpf(dasar - h * 0.06, h * 0.2, float(i) / 5.0)
		var lebar := w * lerpf(0.3, 0.08, float(i) / 5.0)
		for s: float in [-1.0, 1.0]:
			var titik := PackedVector2Array()
			for k in 8:
				var t := float(k) / 7.0
				titik.append(Vector2(cx + s * lebar * t, y - sin(t * PI * 0.9) * h * 0.05))
			draw_polyline(titik, warna_garis, 2.0, true)
			draw_circle(titik[titik.size() - 1], 4.0, warna_garis)

	# Gapura di bagian bawah.
	var gw := w * 0.32
	var gh := h * 0.16
	var gx := cx - gw * 0.5
	var gy := h * 0.74
	draw_rect(Rect2(gx, gy, gw, gh), warna_isi)
	draw_rect(Rect2(gx, gy, gw, gh), warna_garis, false, 2.0)
	draw_rect(Rect2(cx - gw * 0.18, gy + gh * 0.3, gw * 0.36, gh * 0.7), warna_dalam)
	draw_line(Vector2(cx, gy + gh * 0.3), Vector2(cx, gy + gh), warna_garis, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(gx - 6, gy), Vector2(gx + gw + 6, gy),
			Vector2(cx, gy - gh * 0.45)]), warna_garis)
	# Tangkai (gapit) di bawah.
	draw_line(Vector2(cx, h * 0.92), Vector2(cx, h), warna_garis, 5.0)


## Siluet gunungan: alas lebar, menggembung, lalu meruncing ke puncak.
func _bentuk(w: float, h: float, skala: float) -> PackedVector2Array:
	var titik := PackedVector2Array()
	var cx := w * 0.5
	var bawah := h * (0.92 - (1.0 - skala) * 0.12)
	var tinggi := bawah - h * (1.0 - skala) * 0.25
	var n := 24
	for i in n + 1:
		var t := float(i) / n  # 0 = bawah, 1 = puncak
		var lebar := w * 0.5 * skala * pow(1.0 - t, 0.75) * (0.85 + 0.25 * sin(t * PI * 1.2))
		titik.append(Vector2(cx + lebar, bawah - t * tinggi))
	for i in range(n - 1, -1, -1):
		var t := float(i) / n
		var lebar := w * 0.5 * skala * pow(1.0 - t, 0.75) * (0.85 + 0.25 * sin(t * PI * 1.2))
		titik.append(Vector2(cx - lebar, bawah - t * tinggi))
	return titik
