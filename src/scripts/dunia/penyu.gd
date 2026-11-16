class_name Penyu
extends Node3D
## Penyu laut low-poly yang berenang pelan bolak-balik antara titik A dan B (Level 3, pengecoh laut).
## Satwa dilindungi: pemain tidak boleh menyentuhnya (skrip pulau memeriksa jarak).

@export var titik_a: Vector3
@export var titik_b: Vector3
@export var kecepatan: float = 0.7

var _menuju_b: bool = true
var _waktu: float = 0.0
var _model: Node3D
var _sirip: Array[Node3D] = []


func _ready() -> void:
	position = titik_a
	_waktu = randf() * 3.0
	_model = Node3D.new()
	add_child(_model)
	var tempurung := SphereMesh.new()
	tempurung.radius = 0.45
	tempurung.height = 0.36
	tempurung.radial_segments = 10
	tempurung.rings = 4
	_bagian(tempurung, Vector3(0, 0.12, 0), Color("6a5a2c"), Vector3(1.0, 1.0, 1.25))
	var perut := SphereMesh.new()
	perut.radius = 0.42
	perut.height = 0.14
	_bagian(perut, Vector3(0, 0.04, 0), Color("d8c89a"), Vector3(1.0, 1.0, 1.2))
	var kepala := SphereMesh.new()
	kepala.radius = 0.13
	kepala.height = 0.24
	_bagian(kepala, Vector3(0, 0.1, -0.6), Color("8a8a5a"), Vector3(1.0, 0.9, 1.3))
	for s: float in [-1.0, 1.0]:
		for depan: bool in [true, false]:
			var engsel := Node3D.new()
			engsel.position = Vector3(0.36 * s, 0.06, -0.25 if depan else 0.3)
			_model.add_child(engsel)
			var sirip := BoxMesh.new()
			sirip.size = Vector3(0.42 if depan else 0.22, 0.04, 0.16)
			var mi := MeshInstance3D.new()
			mi.mesh = sirip
			mi.position = Vector3((0.2 if depan else 0.1) * s, 0, 0)
			mi.material_override = _mat(Color("7a7a4c"))
			engsel.add_child(mi)
			_sirip.append(engsel)


func _mat(warna: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = warna
	m.roughness = 0.8
	return m


func _bagian(mesh: Mesh, pos: Vector3, warna: Color, skala := Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = skala
	mi.material_override = _mat(warna)
	_model.add_child(mi)


func _process(delta: float) -> void:
	_waktu += delta
	if GameState.sedang(GameState.State.BERMAIN):
		var tujuan: Vector3 = titik_b if _menuju_b else titik_a
		var arah: Vector3 = tujuan - position
		arah.y = 0.0
		if arah.length() < 0.2:
			_menuju_b = not _menuju_b
		else:
			position += arah.normalized() * minf(kecepatan * delta, arah.length())
			_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-arah.x, -arah.z), delta * 2.0)
	# Sirip mengayuh (follow-through) dan badan naik-turun pelan
	for i in _sirip.size():
		var sisi: float = 1.0 if i < 2 else -1.0
		_sirip[i].rotation.z = sin(_waktu * 2.4 + (0.0 if i % 2 == 0 else 1.2)) * 0.45 * sisi
	_model.position.y = sin(_waktu * 1.3) * 0.04
