class_name EfekVisual
extends RefCounted
## Kumpulan efek visual sederhana yang tidak bergantung pada bentuk model.
## Karena bekerja pada semua MeshInstance3D turunan, efek ini tetap berfungsi
## ketika model placeholder diganti dengan model 3D asli.

static var _bahan_kilat: StandardMaterial3D


## Membuat seluruh mesh di bawah `akar` berkilat merah-putih sesaat (tanda terkena).
static func kilat_kena(akar: Node3D, durasi: float = 0.12) -> void:
	if not is_instance_valid(akar) or not akar.is_inside_tree():
		return
	if _bahan_kilat == null:
		_bahan_kilat = StandardMaterial3D.new()
		_bahan_kilat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_bahan_kilat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_bahan_kilat.albedo_color = Color(1.0, 0.85, 0.75, 0.6)
	var daftar: Array[MeshInstance3D] = []
	_kumpulkan_mesh(akar, daftar)
	for m: MeshInstance3D in daftar:
		m.material_overlay = _bahan_kilat
	akar.get_tree().create_timer(durasi).timeout.connect(func() -> void:
		for m: MeshInstance3D in daftar:
			if is_instance_valid(m):
				m.material_overlay = null
	)


## Gelombang debu melingkar yang membesar lalu memudar (dipakai saat bos menghantam tanah).
static func gelombang_debu(induk: Node, posisi: Vector3, radius: float, warna: Color) -> void:
	var cincin := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	cincin.mesh = torus
	var bahan := StandardMaterial3D.new()
	bahan.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bahan.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bahan.albedo_color = warna
	cincin.material_override = bahan
	induk.add_child(cincin)
	cincin.global_position = posisi + Vector3(0.0, 0.15, 0.0)
	cincin.scale = Vector3(0.5, 1.0, 0.5)
	var t := cincin.create_tween().set_parallel(true)
	t.tween_property(cincin, "scale", Vector3(radius, 2.0, radius), 0.45).set_ease(Tween.EASE_OUT)
	t.tween_property(bahan, "albedo_color:a", 0.0, 0.45)
	t.chain().tween_callback(cincin.queue_free)


static func _kumpulkan_mesh(node: Node, hasil: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.visible:
		hasil.append(node as MeshInstance3D)
	for anak: Node in node.get_children():
		_kumpulkan_mesh(anak, hasil)
