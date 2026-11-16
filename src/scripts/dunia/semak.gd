class_name Semak
extends Node3D
## Semak sabana Pulau Komodo (pengecoh Level 3).
##   bersembunyi = false : bergoyang pelan seirama angin (aman).
##   bersembunyi = true  : komodo bersembunyi; semak bergoyang tidak teratur, ada jejak kaki
##                         di tanah dan ujung ekor yang mencuat (tanda yang bisa dibaca pemain).

var bersembunyi: bool = false
var _daun: Array[MeshInstance3D] = []
var _waktu: float = 0.0


func _ready() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("5a7a32")
	m.roughness = 0.9
	var m2 := StandardMaterial3D.new()
	m2.albedo_color = Color("6e8a3a")
	for i in 4:
		var bola := SphereMesh.new()
		bola.radius = 0.75 - i * 0.08
		bola.height = (0.75 - i * 0.08) * 1.6
		bola.radial_segments = 8
		bola.rings = 4
		var mi := MeshInstance3D.new()
		mi.mesh = bola
		var a: float = TAU * i / 4.0
		mi.position = Vector3(cos(a) * 0.45, 0.55 + (i % 2) * 0.15, sin(a) * 0.45)
		mi.material_override = m if i % 2 == 0 else m2
		add_child(mi)
		_daun.append(mi)
	if bersembunyi:
		_bangun_tanda()


## Jejak kaki komodo menuju semak (sumbu +Z lokal menghadap jalur). Komodonya dibuat skrip pulau.
func _bangun_tanda() -> void:
	var m_jejak := StandardMaterial3D.new()
	m_jejak.albedo_color = Color("3a3022")
	for i in 5:
		var jejak := MeshInstance3D.new()
		var kotak := BoxMesh.new()
		kotak.size = Vector3(0.18, 0.02, 0.24)
		jejak.mesh = kotak
		jejak.material_override = m_jejak
		jejak.position = Vector3(0.35 * (1 if i % 2 == 0 else -1), 0.02, 1.0 + i * 0.55)
		add_child(jejak)


func _process(delta: float) -> void:
	_waktu += delta
	for i in _daun.size():
		var goyang: float
		if bersembunyi:
			# Goyangan tidak teratur dan lebih kuat (ada yang bergerak di dalam)
			goyang = (sin(_waktu * 9.0 + i * 2.1) * sin(_waktu * 1.7)) * 0.16
		else:
			goyang = sin(_waktu * 1.6) * 0.05  # angin: semua daun seirama, pelan
		_daun[i].rotation.z = goyang
		_daun[i].rotation.x = goyang * 0.6
