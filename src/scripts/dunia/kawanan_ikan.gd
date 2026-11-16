class_name KawananIkan
extends Node3D
## Kawanan ikan kecil yang berputar di sekitar titik pusat (Level 3, Manjarite).
## kaget() = ikan berhamburan menjauh lalu kembali berkumpul pelan.

const JUMLAH: int = 7
const JARI: float = 1.4

var _ikan: Array[Node3D] = []
var _waktu: float = 0.0
var _sebar: float = 0.0


func _ready() -> void:
	var warna: Array[Color] = [Color("f08a30"), Color("f2d040"), Color("4aa8d8")]
	for i in JUMLAH:
		var ikan := Node3D.new()
		add_child(ikan)
		var badan := SphereMesh.new()
		badan.radius = 0.09
		badan.height = 0.14
		badan.radial_segments = 6
		badan.rings = 3
		var mi := MeshInstance3D.new()
		mi.mesh = badan
		mi.scale = Vector3(0.7, 0.9, 1.6)
		var m := StandardMaterial3D.new()
		m.albedo_color = warna[i % warna.size()]
		mi.material_override = m
		ikan.add_child(mi)
		var ekor := MeshInstance3D.new()
		var kotak := BoxMesh.new()
		kotak.size = Vector3(0.02, 0.1, 0.08)
		ekor.mesh = kotak
		ekor.position = Vector3(0, 0, 0.16)
		ekor.material_override = m
		ikan.add_child(ekor)
		_ikan.append(ikan)


func kaget() -> void:
	_sebar = 1.0


func _process(delta: float) -> void:
	_waktu += delta
	_sebar = maxf(_sebar - delta * 0.4, 0.0)
	for i in _ikan.size():
		var a: float = _waktu * 0.9 + TAU * i / JUMLAH
		var r: float = JARI * (0.6 + 0.4 * sin(i * 1.7)) + _sebar * 3.5
		var p := Vector3(cos(a) * r, sin(_waktu * 2.0 + i) * 0.15, sin(a) * r)
		_ikan[i].position = p
		_ikan[i].rotation.y = -a  # menghadap arah berenang (tangensial)
