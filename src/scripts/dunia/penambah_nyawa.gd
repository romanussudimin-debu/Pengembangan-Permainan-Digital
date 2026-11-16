class_name PenambahNyawa
extends Area3D
## Penambah nyawa (+1, maksimal penuh) yang tersembunyi di dunia, bertema budaya tiap level:
## "kopi" (Level 1: secangkir kopi Manggarai), "kendi" (Level 2: kendi air), "kelapa" (Level 3: kelapa muda).
## Diambil otomatis saat disentuh pemain; melayang dan berputar pelan dengan kilau agar mudah dikenali.
## Bila nyawa masih penuh, benda tetap di tempat (tidak terbuang).

@export_enum("kopi", "kendi", "kelapa") var jenis: String = "kopi"

var _model: Node3D
var _kilau: MeshInstance3D
var _waktu: float = 0.0
var _jeda_pesan: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var bentuk := SphereShape3D.new()
	bentuk.radius = 0.8
	var c := CollisionShape3D.new()
	c.shape = bentuk
	c.position = Vector3(0, 0.8, 0)
	add_child(c)
	_model = Node3D.new()
	add_child(_model)
	match jenis:
		"kendi":
			_bangun_kendi()
		"kelapa":
			_bangun_kelapa()
		_:
			_bangun_kopi()
	_kilau = MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.45
	bola.height = 0.9
	_kilau.mesh = bola
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.4, 0.22)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_kilau.material_override = m
	_kilau.position = Vector3(0, 0.75, 0)
	add_child(_kilau)
	body_entered.connect(_saat_disentuh)


func _bangun_kopi() -> void:
	Dunia.mesh(_model, Dunia.silinder(0.32, 0.32, 0.04, 14), Vector3(0, 0.5, 0), Dunia.mat(Color("e8e2d2")))
	Dunia.mesh(_model, Dunia.silinder(0.17, 0.13, 0.26, 12), Vector3(0, 0.65, 0), Dunia.mat(Color("f4f0e6")))
	Dunia.mesh(_model, Dunia.silinder(0.155, 0.155, 0.02, 12), Vector3(0, 0.77, 0), Dunia.mat(Color("3b2416")))
	var gagang := TorusMesh.new()
	gagang.inner_radius = 0.04
	gagang.outer_radius = 0.09
	var g := Dunia.mesh(_model, gagang, Vector3(0.2, 0.66, 0), Dunia.mat(Color("f4f0e6")))
	g.rotation.x = PI / 2.0


func _bangun_kendi() -> void:
	var badan := SphereMesh.new()
	badan.radius = 0.28
	badan.height = 0.5
	Dunia.mesh(_model, badan, Vector3(0, 0.62, 0), Dunia.mat(Color("a8552e")))
	Dunia.mesh(_model, Dunia.silinder(0.08, 0.11, 0.2, 10), Vector3(0, 0.92, 0), Dunia.mat(Color("8a4424")))
	var cucuk := Dunia.mesh(_model, Dunia.silinder(0.03, 0.05, 0.22, 8), Vector3(0.22, 0.7, 0), Dunia.mat(Color("8a4424")))
	cucuk.rotation.z = -0.9
	var pita := TorusMesh.new()
	pita.inner_radius = 0.26
	pita.outer_radius = 0.29
	Dunia.mesh(_model, pita, Vector3(0, 0.62, 0), Dunia.mat(Color("e8b430")))


func _bangun_kelapa() -> void:
	var buah := SphereMesh.new()
	buah.radius = 0.3
	buah.height = 0.56
	Dunia.mesh(_model, buah, Vector3(0, 0.64, 0), Dunia.mat(Color("5f9a3a")))
	Dunia.mesh(_model, Dunia.silinder(0.12, 0.12, 0.03, 12), Vector3(0, 0.93, 0), Dunia.mat(Color("f2eee0")))
	var sedotan := Dunia.mesh(_model, Dunia.silinder(0.02, 0.02, 0.4, 6), Vector3(0.05, 1.08, 0), Dunia.mat(Color("e05a5a")))
	sedotan.rotation.z = -0.3


func _process(delta: float) -> void:
	_waktu += delta
	_jeda_pesan = maxf(_jeda_pesan - delta, 0.0)
	_model.position.y = sin(_waktu * 2.2) * 0.1
	_model.rotation.y += delta * 1.2
	_kilau.scale = Vector3.ONE * (1.0 + sin(_waktu * 4.0) * 0.12)


func _saat_disentuh(body: Node3D) -> void:
	if not body is Pemain:
		return
	if Nyawa.tambah():
		set_deferred("monitoring", false)
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "scale", Vector3.ONE * 1.6, 0.25)
		tw.tween_property(self, "position:y", position.y + 1.0, 0.25)
		tw.chain().tween_property(self, "scale", Vector3.ONE * 0.01, 0.15)
		tw.chain().tween_callback(queue_free)
	elif _jeda_pesan <= 0.0:
		_jeda_pesan = 3.0
		AudioManager.putar_sfx("klik")
