class_name Efek
## Efek "game feel" sekali pakai (otomatis terhapus):
##   percikan() - air (biru) atau lumpur (cokelat) saat jatuh/runtuh
##   debu()     - debu tanah saat mendarat
##   kilau()    - kilau emas saat memungut/berhasil
##   teks()     - teks melayang 3D ("+1", "Benar!", "-1") yang naik lalu memudar

const WARNA_AIR := Color(0.92, 0.97, 1.0, 0.95)
const WARNA_LUMPUR := Color(0.42, 0.3, 0.18, 0.95)


## Semburan partikel sederhana: `jumlah` mesh kecil dilempar dengan kecepatan acak lalu jatuh
## (lintasan balistik) dan mengecil. Dibuat manual (tanpa CPUParticles one-shot) agar tampil
## konsisten di semua renderer dan ringan di web/HP.
static func _partikel(induk: Node, pos: Vector3, warna: Color, jumlah: int, kecepatan: float, umur: float,
		ukuran: float, gravitasi: float, sebar: float = 0.7) -> void:
	var bola := SphereMesh.new()
	bola.radius = ukuran
	bola.height = ukuran * 2.0
	bola.radial_segments = 6
	bola.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = warna
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if warna.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var wadah := Node3D.new()
	induk.add_child(wadah)
	wadah.global_position = pos
	for i in jumlah:
		var mi := MeshInstance3D.new()
		mi.mesh = bola
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wadah.add_child(mi)
		var a: float = randf() * TAU
		var datar: float = randf_range(0.2, 1.0) * sebar
		var v := Vector3(cos(a) * datar, 1.0, sin(a) * datar).normalized() * randf_range(kecepatan * 0.5, kecepatan)
		var skala: float = randf_range(0.6, 1.2)
		var lama: float = umur * randf_range(0.7, 1.0)
		var tw := mi.create_tween()
		tw.tween_method(func(t: float) -> void:
			mi.position = v * t + Vector3(0, 0.5 * gravitasi * t * t, 0)
			mi.scale = Vector3.ONE * skala * (1.0 - t / lama), 0.0, lama, lama)
	wadah.get_tree().create_timer(umur + 0.1, false).timeout.connect(wadah.queue_free)


static func percikan(induk: Node, pos: Vector3, lumpur: bool = false) -> void:
	if induk == null or not induk.is_inside_tree():
		return
	_partikel(induk, pos, WARNA_LUMPUR if lumpur else WARNA_AIR, 22, 5.0, 0.8, 0.13, -12.0)
	AudioManager.putar_sfx("percik", 0.15)


static func debu(induk: Node, pos: Vector3) -> void:
	if induk == null or not induk.is_inside_tree():
		return
	_partikel(induk, pos, Color(0.78, 0.7, 0.55, 0.6), 10, 1.6, 0.5, 0.14, -1.0, 3.0)


static func kilau(induk: Node, pos: Vector3) -> void:
	if induk == null or not induk.is_inside_tree():
		return
	_partikel(induk, pos, Color(1.0, 0.85, 0.3), 16, 2.8, 0.9, 0.09, -2.0, 2.0)


static func teks(induk: Node, pos: Vector3, isi: String, warna: Color = Gaya.KUNING) -> void:
	if induk == null or not induk.is_inside_tree():
		return
	var l := Label3D.new()
	l.text = isi
	l.font_size = 48
	l.pixel_size = 0.012
	l.outline_size = 10
	l.modulate = warna
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	induk.add_child(l)
	l.global_position = pos
	l.scale = Vector3(0.3, 0.3, 0.3)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "global_position:y", pos.y + 1.2, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)
