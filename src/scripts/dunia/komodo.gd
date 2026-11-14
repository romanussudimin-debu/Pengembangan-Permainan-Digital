class_name Komodo
extends Node3D
## Komodo (Varanus komodoensis) low-poly yang berpatroli bolak-balik antara titik A dan B.
## FSM sederhana: DIAM (menjulurkan lidah) dan JALAN (badan & ekor meliuk, kaki melangkah).
## Skrip pulau memeriksa jarak pemain ke komodo; terlalu dekat = kembali ke titik aman.

enum Perilaku { DIAM, JALAN }

@export var titik_a: Vector3
@export var titik_b: Vector3
@export var kecepatan: float = 1.0

const WARNA_KULIT := Color("4a4232")

var _perilaku: Perilaku = Perilaku.DIAM
var _menuju_b: bool = true
var _sisa_diam: float = 1.0
var _waktu: float = 0.0
var _model: Node3D
var _ekor: Array[Node3D] = []
var _kaki: Array[Node3D] = []
var _lidah: Node3D


func _ready() -> void:
	position = titik_a
	_sisa_diam = randf_range(0.5, 2.5)
	_bangun()


func _mat(warna: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = warna
	m.roughness = 0.9
	return m


func _bagian(induk: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	induk.add_child(mi)
	return mi


func _bangun() -> void:
	_model = Node3D.new()
	add_child(_model)
	var m_kulit := _mat(WARNA_KULIT)
	var m_perut := _mat(Color("6a6250"))
	# Badan memanjang (depan = -Z)
	var badan := CapsuleMesh.new()
	badan.radius = 0.32
	badan.height = 1.6
	var mb := _bagian(_model, badan, Vector3(0, 0.38, 0), m_kulit)
	mb.rotation.x = PI / 2.0
	mb.scale = Vector3(1.15, 1.0, 0.8)
	var perut := BoxMesh.new()
	perut.size = Vector3(0.45, 0.05, 1.1)
	_bagian(_model, perut, Vector3(0, 0.12, 0), m_perut)
	# Leher dan kepala
	var leher := CapsuleMesh.new()
	leher.radius = 0.18
	leher.height = 0.6
	var ml := _bagian(_model, leher, Vector3(0, 0.45, -0.9), m_kulit)
	ml.rotation.x = PI / 2.0 - 0.2
	var kepala := BoxMesh.new()
	kepala.size = Vector3(0.3, 0.2, 0.5)
	_bagian(_model, kepala, Vector3(0, 0.5, -1.3), m_kulit)
	for s: float in [-1.0, 1.0]:
		var mata := SphereMesh.new()
		mata.radius = 0.03
		mata.height = 0.06
		_bagian(_model, mata, Vector3(0.14 * s, 0.57, -1.35), _mat(Color("e8b430")))
	_lidah = Node3D.new()
	_lidah.position = Vector3(0, 0.46, -1.55)
	_model.add_child(_lidah)
	var lidah := BoxMesh.new()
	lidah.size = Vector3(0.05, 0.02, 0.3)
	_bagian(_lidah, lidah, Vector3(0, 0, -0.15), _mat(Color("e8a030")))
	# Ekor bersegmen (ikut meliuk: follow-through)
	var induk: Node3D = _model
	var pos := Vector3(0, 0.36, 0.8)
	for i in 5:
		var segmen := Node3D.new()
		segmen.position = pos
		induk.add_child(segmen)
		var e := CapsuleMesh.new()
		e.radius = 0.2 - i * 0.035
		e.height = 0.6
		var me := _bagian(segmen, e, Vector3(0, 0, 0.25), m_kulit)
		me.rotation.x = PI / 2.0
		_ekor.append(segmen)
		induk = segmen
		pos = Vector3(0, -0.02, 0.45)
	# Empat kaki pendek di samping badan
	for data: Vector3 in [Vector3(-0.38, 0.25, -0.5), Vector3(0.38, 0.25, -0.5), Vector3(-0.38, 0.25, 0.5), Vector3(0.38, 0.25, 0.5)]:
		var kaki := Node3D.new()
		kaki.position = data
		_model.add_child(kaki)
		var k := CapsuleMesh.new()
		k.radius = 0.08
		k.height = 0.4
		var mk := _bagian(kaki, k, Vector3(0.08 * signf(data.x), -0.12, 0), m_kulit)
		mk.rotation.z = 0.6 * signf(data.x)
		_kaki.append(kaki)


func _process(delta: float) -> void:
	_waktu += delta
	var bergerak: bool = GameState.sedang(GameState.State.BERMAIN) or GameState.sedang(GameState.State.MINIGAME)
	if bergerak:
		match _perilaku:
			Perilaku.DIAM:
				_sisa_diam -= delta
				if _sisa_diam <= 0.0:
					_perilaku = Perilaku.JALAN
			Perilaku.JALAN:
				var tujuan: Vector3 = titik_b if _menuju_b else titik_a
				var arah: Vector3 = tujuan - position
				arah.y = 0.0
				if arah.length() < 0.15:
					_menuju_b = not _menuju_b
					_perilaku = Perilaku.DIAM
					_sisa_diam = randf_range(1.5, 3.5)
				else:
					position += arah.normalized() * minf(kecepatan * delta, arah.length())
					_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-arah.x, -arah.z), delta * 4.0)
	_animasi(delta, bergerak and _perilaku == Perilaku.JALAN)


func _animasi(delta: float, berjalan: bool) -> void:
	var tempo: float = 6.0 if berjalan else 1.5
	var kuat: float = 0.35 if berjalan else 0.08
	for i in _ekor.size():
		_ekor[i].rotation.y = sin(_waktu * tempo - i * 0.7) * kuat
	for i in _kaki.size():
		var fase: float = 0.0 if i == 0 or i == 3 else PI
		_kaki[i].rotation.x = lerpf(_kaki[i].rotation.x, sin(_waktu * tempo + fase) * 0.6 if berjalan else 0.0, delta * 10.0)
	_model.rotation.z = sin(_waktu * tempo) * (0.05 if berjalan else 0.0)
	# Lidah menjulur sesekali (secondary action)
	_lidah.scale.z = 1.0 if fmod(_waktu, 2.4) < 0.35 else 0.05
