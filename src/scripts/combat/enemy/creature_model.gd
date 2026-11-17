class_name CreatureModel
extends Node3D
## Model hewan low-poly prosedural untuk musuh tempur (menghadap -Z):
## kera/monyet, ular, kawanan lebah, babi hutan, tikus, kalong, kepiting, ubur-ubur, kerbau.
## API animasi sama dengan KarakterModel yang dipakai EnemyBase: mode, kecepatan_jalan,
## squash(), ancang(), lepas_pukulan().

@export_enum("monkey", "snake", "bees", "boar", "rat", "bat", "crab", "jellyfish", "buffalo") var kind: String = "boar"
@export var color: Color = Color("5a4030")
@export var accent: Color = Color("2a2018")

var mode: String = "idle"
var kecepatan_jalan: float = 0.0
var _root: Node3D
var _legs: Array[Node3D] = []
var _wings: Array[Node3D] = []
var _tail: Array[Node3D] = []
var _head: Node3D
var _parts: Array[Node3D] = []  ## lebah-lebah kecil (kawanan)
var _time: float = 0.0
var _windup: float = 0.0


func _ready() -> void:
	_time = randf() * 4.0
	_root = Node3D.new()
	add_child(_root)
	match kind:
		"monkey":
			_build_monkey()
		"snake":
			_build_snake()
		"bees":
			_build_bees()
		"boar":
			_build_quadruped(Vector3(0.55, 0.5, 1.0), 0.45, false)
		"buffalo":
			_build_quadruped(Vector3(0.9, 0.85, 1.7), 0.75, true)
		"rat":
			_build_rat()
		"bat":
			_build_bat()
		"crab":
			_build_crab()
		"jellyfish":
			_build_jellyfish()


# ------------------------------------------------------------------ bantu

func _mat(c: Color, transparent: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh(parent, b, pos, c)


func _ball(parent: Node3D, r: float, pos: Vector3, c: Color, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 8
	s.rings = 4
	var mi := _mesh(parent, s, pos, c)
	mi.scale = sc
	return mi


func _mesh(parent: Node3D, m: Mesh, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos
	mi.material_override = _mat(c, c.a < 1.0)
	parent.add_child(mi)
	return mi


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _eyes(parent: Node3D, pos: Vector3, gap: float, r: float = 0.04) -> void:
	for s: float in [-1.0, 1.0]:
		_ball(parent, r, pos + Vector3(gap * s, 0, 0), Color("f8e070"))


# ------------------------------------------------------------------ bentuk

func _build_monkey() -> void:
	_ball(_root, 0.32, Vector3(0, 0.75, 0), color, Vector3(1.0, 1.2, 0.9))
	_head = _pivot(_root, Vector3(0, 1.22, -0.05))
	_ball(_head, 0.22, Vector3.ZERO, color)
	_ball(_head, 0.15, Vector3(0, -0.04, -0.14), Color("c8a080"), Vector3(1.2, 0.8, 0.8))
	_eyes(_head, Vector3(0, 0.05, -0.19), 0.07)
	for s: float in [-1.0, 1.0]:
		var arm := _pivot(_root, Vector3(0.3 * s, 1.0, 0))
		_box(arm, Vector3(0.1, 0.55, 0.1), Vector3(0, -0.27, 0), color)
		_legs.append(arm)
		var leg := _pivot(_root, Vector3(0.15 * s, 0.45, 0))
		_box(leg, Vector3(0.12, 0.45, 0.12), Vector3(0, -0.22, 0), color)
		_legs.append(leg)
	for i in 4:
		var seg := _pivot(_root if i == 0 else _tail[i - 1], Vector3(0, 0.05 if i else 0.6, 0.25 if i == 0 else 0.22))
		_box(seg, Vector3(0.06, 0.06, 0.24), Vector3(0, 0, 0.1), color)
		_tail.append(seg)


func _build_snake() -> void:
	for i in 7:
		var seg := _pivot(_root if i == 0 else _tail[i - 1], Vector3(0, 0, 0.0 if i == 0 else 0.26))
		var r: float = 0.13 - i * 0.012
		_ball(seg, r, Vector3(0, r, 0), color if i % 2 == 0 else accent, Vector3(1.0, 0.8, 1.5))
		_tail.append(seg)
	_head = _pivot(_root, Vector3(0, 0.2, -0.22))
	_ball(_head, 0.15, Vector3.ZERO, color, Vector3(1.1, 0.75, 1.4))
	_eyes(_head, Vector3(0, 0.07, -0.12), 0.08, 0.03)


func _build_bees() -> void:
	for i in 6:
		var bee := _pivot(_root, Vector3.ZERO)
		_ball(bee, 0.09, Vector3.ZERO, Color("e8b430"), Vector3(0.9, 0.9, 1.4))
		_box(bee, Vector3(0.17, 0.05, 0.05), Vector3(0, 0, 0.02), Color("1b1818"))
		var w := _box(bee, Vector3(0.22, 0.01, 0.1), Vector3(0, 0.08, 0), Color(1, 1, 1, 0.6))
		_wings.append(w)
		_parts.append(bee)


func _build_quadruped(body: Vector3, leg_len: float, horns: bool) -> void:
	_box(_root, body, Vector3(0, leg_len + body.y * 0.5, 0), color)
	_head = _pivot(_root, Vector3(0, leg_len + body.y * 0.55, -body.z * 0.55))
	_box(_head, Vector3(body.x * 0.7, body.y * 0.65, body.z * 0.4), Vector3(0, 0, -body.z * 0.12), color.darkened(0.1))
	_box(_head, Vector3(body.x * 0.45, body.y * 0.3, 0.12), Vector3(0, -body.y * 0.12, -body.z * 0.33), accent)
	_eyes(_head, Vector3(0, body.y * 0.12, -body.z * 0.3), body.x * 0.22)
	if horns:
		for s: float in [-1.0, 1.0]:
			var h := _box(_head, Vector3(0.7, 0.1, 0.1), Vector3(0.45 * s, body.y * 0.3, -0.05), Color("e8e2d2"))
			h.rotation.z = 0.35 * s
	else:
		for s: float in [-1.0, 1.0]:  # taring babi hutan
			var t := _box(_head, Vector3(0.04, 0.14, 0.04), Vector3(0.12 * s, -0.08, -body.z * 0.36), Color("f4f2ea"))
			t.rotation.x = -0.4
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var leg := _pivot(_root, Vector3(body.x * 0.35 * x, leg_len, body.z * 0.36 * z))
			_box(leg, Vector3(0.14 * body.x / 0.55, leg_len, 0.14 * body.x / 0.55), Vector3(0, -leg_len * 0.5, 0), accent)
			_legs.append(leg)


func _build_rat() -> void:
	_ball(_root, 0.17, Vector3(0, 0.17, 0), color, Vector3(1.0, 0.8, 1.6))
	_head = _pivot(_root, Vector3(0, 0.2, -0.28))
	_ball(_head, 0.11, Vector3.ZERO, color, Vector3(1.0, 0.9, 1.3))
	for s: float in [-1.0, 1.0]:
		_ball(_head, 0.05, Vector3(0.08 * s, 0.1, 0.03), Color("d8a0a0"))
	_eyes(_head, Vector3(0, 0.04, -0.1), 0.05, 0.025)
	var tail := _pivot(_root, Vector3(0, 0.12, 0.25))
	_box(tail, Vector3(0.03, 0.03, 0.45), Vector3(0, 0, 0.22), Color("d8a0a0"))
	_tail.append(tail)


func _build_bat() -> void:
	_ball(_root, 0.18, Vector3.ZERO, color, Vector3(1.0, 1.1, 1.0))
	_head = _pivot(_root, Vector3(0, 0.2, -0.05))
	_ball(_head, 0.12, Vector3.ZERO, color)
	_eyes(_head, Vector3(0, 0.02, -0.1), 0.05, 0.03)
	for s: float in [-1.0, 1.0]:
		var w := _pivot(_root, Vector3(0.15 * s, 0.05, 0))
		_box(w, Vector3(0.6, 0.03, 0.35), Vector3(0.3 * s, 0, 0), accent)
		_wings.append(w)


func _build_crab() -> void:
	_ball(_root, 0.38, Vector3(0, 0.32, 0), color, Vector3(1.3, 0.55, 1.0))
	_eyes(_root, Vector3(0, 0.55, -0.3), 0.12, 0.05)
	for s: float in [-1.0, 1.0]:
		var claw := _pivot(_root, Vector3(0.45 * s, 0.35, -0.3))
		_ball(claw, 0.16, Vector3(0, 0, -0.12), color.lightened(0.1), Vector3(1.0, 0.7, 1.4))
		_legs.append(claw)
		for k in 3:
			var leg := _pivot(_root, Vector3(0.4 * s, 0.25, -0.1 + k * 0.17))
			var mi := _box(leg, Vector3(0.35, 0.05, 0.05), Vector3(0.17 * s, -0.08, 0), accent)
			mi.rotation.z = -0.5 * s
			_legs.append(leg)


func _build_jellyfish() -> void:
	var dome := SphereMesh.new()
	dome.radius = 0.5
	dome.height = 0.6
	dome.is_hemisphere = true
	var mi := _mesh(_root, dome, Vector3(0, 0.55, 0), Color(color, 0.7))
	mi.material_override.emission_enabled = true
	mi.material_override.emission = color * 0.4
	for i in 8:
		var a: float = TAU * i / 8.0
		var t := _pivot(_root, Vector3(cos(a) * 0.32, 0.55, sin(a) * 0.32))
		_box(t, Vector3(0.04, 0.5, 0.04), Vector3(0, -0.25, 0), Color(accent, 0.8))
		_tail.append(t)


# ------------------------------------------------------------------ animasi

func _process(delta: float) -> void:
	_time += delta
	_windup = maxf(_windup - delta, 0.0)
	var moving: bool = mode == "jalan"
	var speed: float = lerpf(5.0, 14.0, kecepatan_jalan) if moving else 2.0
	for i in _legs.size():
		var phase: float = 0.0 if i % 2 == 0 else PI
		_legs[i].rotation.x = sin(_time * speed + phase) * (0.6 if moving else 0.05)
	for i in _wings.size():
		var flap: float = sin(_time * 30.0 + i) * 0.7
		if _wings[i] is MeshInstance3D:
			_wings[i].rotation.z = flap
		else:
			_wings[i].rotation.z = flap * (1.0 if i == 0 else -1.0)
	for i in _tail.size():
		if kind == "jellyfish":
			_tail[i].rotation.x = sin(_time * 3.0 + i) * 0.3
		else:
			_tail[i].rotation.y = sin(_time * (6.0 if moving else 2.0) - i * 0.8) * (0.35 if kind == "snake" else 0.25)
	for i in _parts.size():  # kawanan lebah beterbangan acak di sekitar pusat
		var a: float = _time * 4.0 + i * 1.7
		_parts[i].position = Vector3(cos(a) * 0.45, 0.3 * sin(_time * 7.0 + i), sin(a * 1.3) * 0.45)
	if kind == "jellyfish":
		_root.scale = Vector3.ONE * (1.0 + sin(_time * 2.5) * 0.06)
	if _head and _windup > 0.0:
		_head.rotation.x = lerpf(_head.rotation.x, -0.4, delta * 10.0)  # ancang-ancang: kepala mundur
	elif _head:
		_head.rotation.x = lerpf(_head.rotation.x, 0.0, delta * 8.0)


func squash(s: Vector3, duration: float = 0.2) -> void:
	_root.scale = s
	var tw := create_tween()
	tw.tween_property(_root, "scale", Vector3.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func ancang(duration: float) -> void:
	_windup = duration
	squash(Vector3(1.1, 0.85, 1.1), duration)


func lepas_pukulan() -> void:
	_windup = 0.0
	if _head:
		_head.rotation.x = 0.5  # sergap/gigit maju
	squash(Vector3(0.9, 1.1, 1.25), 0.25)
