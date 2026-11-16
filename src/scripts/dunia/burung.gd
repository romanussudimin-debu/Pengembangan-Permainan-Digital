class_name Burung
extends Node3D
## Burung di sawah (tantangan Mengusir Burung, Level 2):
##   "pipit" - kecil, cokelat, berkelompok memakan bulir padi (hama, boleh diusir).
##   "kuntul" - putih, berkaki dan berleher panjang, berjalan pelan memakan serangga (jangan diusir).
## Animasi prosedural: pipit mematuk & mengepak, kuntul melangkah pelan. terbang() = pergi ke langit.

@export_enum("pipit", "kuntul") var jenis: String = "pipit"

var _waktu: float = 0.0
var _model: Node3D
var _sayap: Array[Node3D] = []
var _kepala: Node3D
var _kaki: Array[Node3D] = []
var _terbang: bool = false
var tujuan_jalan: Vector3 = Vector3.INF  ## kuntul berjalan pelan ke titik ini


func _ready() -> void:
	_waktu = randf() * 3.0
	_model = Node3D.new()
	add_child(_model)
	if jenis == "kuntul":
		_bangun_kuntul()
	else:
		_bangun_pipit()


func _mat(warna: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = warna
	m.roughness = 0.9
	return m


func _bola(r: float, induk: Node3D, pos: Vector3, warna: Color, skala := Vector3.ONE) -> MeshInstance3D:
	var b := SphereMesh.new()
	b.radius = r
	b.height = r * 2.0
	b.radial_segments = 8
	b.rings = 4
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.position = pos
	mi.scale = skala
	mi.material_override = _mat(warna)
	induk.add_child(mi)
	return mi


func _silinder(r: float, h: float, induk: Node3D, pos: Vector3, warna: Color) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 5
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position = pos
	mi.material_override = _mat(warna)
	induk.add_child(mi)
	return mi


func _bangun_pipit() -> void:
	_bola(0.11, _model, Vector3(0, 0.13, 0), Color("8a6440"), Vector3(1.0, 0.85, 1.35))
	_kepala = Node3D.new()
	_kepala.position = Vector3(0, 0.2, -0.12)
	_model.add_child(_kepala)
	_bola(0.07, _kepala, Vector3.ZERO, Color("5a3e28"))
	var paruh := _silinder(0.02, 0.06, _kepala, Vector3(0, -0.01, -0.07), Color("3a2a1c"))
	paruh.rotation.x = PI / 2.0
	for s: float in [-1.0, 1.0]:
		var sayap := Node3D.new()
		sayap.position = Vector3(0.09 * s, 0.16, 0)
		_model.add_child(sayap)
		var bulu := BoxMesh.new()
		bulu.size = Vector3(0.14, 0.02, 0.18)
		var mi := MeshInstance3D.new()
		mi.mesh = bulu
		mi.position = Vector3(0.06 * s, 0, 0)
		mi.material_override = _mat(Color("6a4a30"))
		sayap.add_child(mi)
		_sayap.append(sayap)


func _bangun_kuntul() -> void:
	var putih := Color("f4f2ea")
	_bola(0.22, _model, Vector3(0, 0.95, 0), putih, Vector3(0.85, 0.8, 1.45))
	var leher := _silinder(0.05, 0.45, _model, Vector3(0, 1.22, -0.22), putih)
	leher.rotation.x = -0.5
	_kepala = Node3D.new()
	_kepala.position = Vector3(0, 1.44, -0.36)
	_model.add_child(_kepala)
	_bola(0.08, _kepala, Vector3.ZERO, putih)
	var paruh := _silinder(0.02, 0.22, _kepala, Vector3(0, -0.02, -0.14), Color("e8b430"))
	paruh.rotation.x = PI / 2.0
	for s: float in [-1.0, 1.0]:
		var kaki := Node3D.new()
		kaki.position = Vector3(0.07 * s, 0.82, 0.02)
		_model.add_child(kaki)
		_silinder(0.02, 0.82, kaki, Vector3(0, -0.41, 0), Color("3a3430"))
		_kaki.append(kaki)


func _process(delta: float) -> void:
	_waktu += delta
	if _terbang:
		position += Vector3(0, 4.0, 2.0) * delta
		for i in _sayap.size():
			_sayap[i].rotation.z = sin(_waktu * 30.0) * 0.9 * (1.0 if i == 0 else -1.0)
		return
	if jenis == "pipit":
		# Mematuk bulir padi (secondary action) dan sesekali mengepak
		_kepala.rotation.x = maxf(sin(_waktu * 7.0), 0.0) * 0.8
		for i in _sayap.size():
			_sayap[i].rotation.z = (sin(_waktu * 25.0) * 0.5 if fmod(_waktu, 2.0) < 0.3 else 0.0) * (1.0 if i == 0 else -1.0)
	else:
		# Kuntul berjalan pelan, kepala maju-mundur
		if tujuan_jalan != Vector3.INF:
			var arah: Vector3 = tujuan_jalan - position
			arah.y = 0.0
			if arah.length() > 0.1:
				position += arah.normalized() * minf(0.45 * delta, arah.length())
				rotation.y = lerp_angle(rotation.y, atan2(-arah.x, -arah.z), delta * 3.0)
				for i in _kaki.size():
					_kaki[i].rotation.x = sin(_waktu * 4.0 + i * PI) * 0.35
		_kepala.position.z = -0.36 + sin(_waktu * 4.0) * 0.04


## Burung terbang pergi lalu menghilang.
func terbang() -> void:
	if _terbang:
		return
	_terbang = true
	if not is_inside_tree():
		queue_free()
		return
	get_tree().create_timer(1.2, false).timeout.connect(queue_free)
