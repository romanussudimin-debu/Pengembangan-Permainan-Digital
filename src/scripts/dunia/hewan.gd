class_name Hewan
extends Node3D
## Hewan kampung (anjing atau ayam) sebagai hiasan yang menghidupkan suasana.
## Perilaku memakai FSM sederhana: DIAM (anjing duduk-menggoyang ekor, ayam mematuk)
## dan JALAN (berkeliaran di sekitar titik asal). Bersuara sesekali bila pemain dekat.

enum Perilaku { DIAM, JALAN }

@export_enum("anjing", "ayam") var jenis: String = "ayam"
@export var warna_utama: Color = Color("f1ede4")
@export var jari_jelajah: float = 2.5  ## radius berkeliaran dari titik asal

const JARAK_DENGAR: float = 7.0

var _perilaku: Perilaku = Perilaku.DIAM
var _asal: Vector3
var _tujuan: Vector3
var _sisa_diam: float = 1.0
var _waktu: float = 0.0
var _jeda_suara: float = 0.0
var _kecepatan: float = 1.0
var _model: Node3D
var _kepala: Node3D
var _ekor: Node3D
var _kaki: Array[Node3D] = []


func _ready() -> void:
	_asal = position
	_kecepatan = 1.6 if jenis == "anjing" else 0.8
	_jeda_suara = randf_range(3.0, 8.0)
	_model = Node3D.new()
	add_child(_model)
	if jenis == "anjing":
		_bangun_anjing()
	else:
		_bangun_ayam()
	_sisa_diam = randf_range(0.5, 3.0)


func _process(delta: float) -> void:
	_waktu += delta
	match _perilaku:
		Perilaku.DIAM:
			_proses_diam(delta)
		Perilaku.JALAN:
			_proses_jalan(delta)
	_animasi_terus()
	_coba_bersuara(delta)


func _proses_diam(delta: float) -> void:
	_sisa_diam -= delta
	for k in _kaki:
		k.rotation.x = lerpf(k.rotation.x, 0.0, delta * 8.0)
	if jenis == "ayam" and _kepala:
		# Mematuk tanah berulang
		_kepala.rotation.x = maxf(sin(_waktu * 6.0), 0.0) * 0.9
	if _sisa_diam <= 0.0:
		var sudut: float = randf() * TAU
		_tujuan = _asal + Vector3(cos(sudut), 0, sin(sudut)) * randf_range(0.5, jari_jelajah)
		_perilaku = Perilaku.JALAN


func _proses_jalan(delta: float) -> void:
	var arah: Vector3 = _tujuan - position
	arah.y = 0.0
	if arah.length() < 0.15:
		_perilaku = Perilaku.DIAM
		_sisa_diam = randf_range(1.5, 4.5)
		return
	var gerak: Vector3 = arah.normalized() * _kecepatan * delta
	position += gerak
	_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-arah.x, -arah.z), delta * 8.0)
	# Ayunan kaki bergantian
	var ayun: float = sin(_waktu * (14.0 if jenis == "anjing" else 18.0)) * 0.6
	for i in _kaki.size():
		_kaki[i].rotation.x = ayun if i % 2 == 0 else -ayun
	if jenis == "ayam" and _kepala:
		_kepala.rotation.x = sin(_waktu * 18.0) * 0.15  # kepala maju-mundur khas ayam


func _animasi_terus() -> void:
	if _ekor and jenis == "anjing":
		_ekor.rotation.z = sin(_waktu * 12.0) * 0.5  # ekor bergoyang
	_model.position.y = absf(sin(_waktu * 9.0)) * 0.03 if _perilaku == Perilaku.JALAN else 0.0


func _coba_bersuara(delta: float) -> void:
	_jeda_suara -= delta
	if _jeda_suara > 0.0:
		return
	_jeda_suara = randf_range(6.0, 12.0)
	var pemain := get_tree().get_first_node_in_group("pemain") as Node3D
	if pemain and pemain.global_position.distance_to(global_position) < JARAK_DENGAR:
		AudioManager.putar_sfx(jenis, 0.1)


# ---------------------------------------------------------------- model

func _mat(warna: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = warna
	m.roughness = 0.9
	return m


func _mesh(induk: Node3D, m: Mesh, posisi: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = posisi
	mi.material_override = material
	induk.add_child(mi)
	return mi


func _kotak(ukuran: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = ukuran
	return b


func _bola(jari: float) -> SphereMesh:
	var b := SphereMesh.new()
	b.radius = jari
	b.height = jari * 2.0
	b.radial_segments = 10
	b.rings = 6
	return b


func _kerucut(jari: float, tinggi: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = jari
	c.height = tinggi
	c.radial_segments = 6
	return c


func _bangun_anjing() -> void:
	var m := _mat(warna_utama)
	var m_gelap := _mat(warna_utama.darkened(0.45))
	_mesh(_model, _kotak(Vector3(0.26, 0.26, 0.62)), Vector3(0, 0.45, 0), m)
	_kepala = Node3D.new()
	_kepala.position = Vector3(0, 0.62, -0.36)
	_model.add_child(_kepala)
	_mesh(_kepala, _kotak(Vector3(0.24, 0.22, 0.24)), Vector3.ZERO, m)
	_mesh(_kepala, _kotak(Vector3(0.13, 0.11, 0.16)), Vector3(0, -0.04, -0.18), m)
	_mesh(_kepala, _bola(0.03), Vector3(0, -0.01, -0.27), _mat(Color("140c08")))  # hidung
	for sisi: float in [-1.0, 1.0]:
		_mesh(_kepala, _bola(0.022), Vector3(0.06 * sisi, 0.04, -0.125), _mat(Color("140c08")))  # mata
		var telinga := _mesh(_kepala, _kerucut(0.05, 0.12), Vector3(0.08 * sisi, 0.15, 0.02), m_gelap)
		telinga.rotation.z = -0.25 * sisi
	_ekor = Node3D.new()
	_ekor.position = Vector3(0, 0.55, 0.3)
	_model.add_child(_ekor)
	var ekor := _mesh(_ekor, _kerucut(0.035, 0.3), Vector3(0, 0.12, 0.06), m_gelap)
	ekor.rotation.x = 0.5
	for x: float in [-0.09, 0.09]:
		for z: float in [-0.22, 0.22]:
			var kaki := Node3D.new()
			kaki.position = Vector3(x, 0.34, z)
			_model.add_child(kaki)
			_mesh(kaki, _kotak(Vector3(0.07, 0.34, 0.07)), Vector3(0, -0.17, 0), m)
			_kaki.append(kaki)


func _bangun_ayam() -> void:
	var m := _mat(warna_utama)
	var m_kuning := _mat(Color("e8a030"))
	var m_merah := _mat(Color("c0302a"))
	var badan := _mesh(_model, _bola(0.16), Vector3(0, 0.28, 0), m)
	badan.scale = Vector3(0.9, 0.9, 1.15)
	_kepala = Node3D.new()
	_kepala.position = Vector3(0, 0.38, -0.12)
	_model.add_child(_kepala)
	_mesh(_kepala, _bola(0.075), Vector3(0, 0.07, -0.04), m)
	var paruh := _mesh(_kepala, _kerucut(0.025, 0.07), Vector3(0, 0.06, -0.13), m_kuning)
	paruh.rotation.x = -PI / 2.0
	_mesh(_kepala, _kotak(Vector3(0.02, 0.06, 0.08)), Vector3(0, 0.15, -0.04), m_merah)  # jengger
	_mesh(_kepala, _bola(0.02), Vector3(0, 0.0, -0.1), m_merah)  # pial
	for sisi: float in [-1.0, 1.0]:
		_mesh(_kepala, _bola(0.012), Vector3(0.05 * sisi, 0.09, -0.09), _mat(Color("140c08")))
	# Bulu ekor menjulang
	for i in 3:
		var bulu := _mesh(_model, _kerucut(0.05, 0.22), Vector3(0, 0.42, 0.17), _mat(warna_utama.darkened(0.25)))
		bulu.rotation = Vector3(-0.5 + i * 0.25, 0, (i - 1) * 0.3)
	for x: float in [-0.05, 0.05]:
		var kaki := Node3D.new()
		kaki.position = Vector3(x, 0.16, 0)
		_model.add_child(kaki)
		_mesh(kaki, _kotak(Vector3(0.025, 0.16, 0.025)), Vector3(0, -0.08, 0), m_kuning)
		_kaki.append(kaki)
