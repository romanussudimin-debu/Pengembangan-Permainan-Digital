@tool
class_name Pembangun
extends RefCounted
## Fungsi bantu untuk menyusun bangunan placeholder dari bentuk dasar Godot
## (BoxMesh, CylinderMesh, SphereMesh). Dipakai oleh skrip pendopo, gerbang,
## pagar, dan beringin. Node hasil bangunan tidak disimpan ke file .tscn
## (owner tidak diisi), sehingga selalu dibangun ulang dari parameter @export.


## Kotak berwarna. Bila `tabrakan` true dan `induk` adalah StaticBody3D, ditambahkan collision.
static func kotak(induk: Node3D, ukuran: Vector3, posisi: Vector3, warna: Color,
		tabrakan: bool = true, logam: bool = false, rotasi_y: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = ukuran
	var mi := _mesh(induk, mesh, posisi, warna, logam, rotasi_y)
	if tabrakan and induk is CollisionObject3D:
		var bentuk := BoxShape3D.new()
		bentuk.size = ukuran
		_tabrakan(induk, bentuk, posisi, rotasi_y)
	return mi


static func silinder(induk: Node3D, radius: float, tinggi: float, posisi: Vector3, warna: Color,
		tabrakan: bool = true, logam: bool = false, radius_atas: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if radius_atas < 0.0 else radius_atas
	mesh.height = tinggi
	mesh.radial_segments = 12
	var mi := _mesh(induk, mesh, posisi, warna, logam, 0.0)
	if tabrakan and induk is CollisionObject3D:
		var bentuk := CylinderShape3D.new()
		bentuk.radius = radius
		bentuk.height = tinggi
		_tabrakan(induk, bentuk, posisi, 0.0)
	return mi


static func bola(induk: Node3D, radius: float, posisi: Vector3, warna: Color,
		logam: bool = false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return _mesh(induk, mesh, posisi, warna, logam, 0.0)


## Atap limas/tajug persegi panjang (tanpa collision).
## `ukuran_bawah`/`ukuran_atas` adalah panjang (x) dan lebar (z) alas & puncak.
static func limas(induk: Node3D, ukuran_bawah: Vector2, ukuran_atas: Vector2, tinggi: float,
		posisi: Vector3, warna: Color) -> Node3D:
	# CylinderMesh 4 sisi diputar 45° = limas persegi; lalu induknya diskalakan
	# agar alas menjadi persegi panjang.
	var pengskala := Node3D.new()
	induk.add_child(pengskala)
	pengskala.position = posisi
	pengskala.scale = Vector3(ukuran_bawah.x * 0.5, 1.0, ukuran_bawah.y * 0.5)
	var rasio_atas := ukuran_atas.x / maxf(ukuran_bawah.x, 0.001)
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 4
	mesh.rings = 1
	mesh.bottom_radius = sqrt(2.0)
	mesh.top_radius = sqrt(2.0) * rasio_atas
	mesh.height = tinggi
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = PaletJawa.bahan(warna)
	mi.rotation.y = PI * 0.25
	pengskala.add_child(mi)
	return pengskala


static func hapus_anak(induk: Node) -> void:
	for anak: Node in induk.get_children():
		induk.remove_child(anak)
		anak.queue_free()


static func _mesh(induk: Node3D, mesh: Mesh, posisi: Vector3, warna: Color, logam: bool,
		rotasi_y: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = PaletJawa.bahan(warna, logam)
	mi.position = posisi
	mi.rotation.y = rotasi_y
	induk.add_child(mi)
	return mi


static func _tabrakan(induk: Node3D, bentuk: Shape3D, posisi: Vector3, rotasi_y: float) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = bentuk
	cs.position = posisi
	cs.rotation.y = rotasi_y
	induk.add_child(cs)
