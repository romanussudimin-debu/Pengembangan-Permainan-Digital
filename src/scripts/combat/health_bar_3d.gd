class_name HealthBar3D
extends Node3D
## Bar HP kecil yang selalu menghadap kamera, di atas kepala pemain/musuh (+ label nama opsional).

const WIDTH: float = 0.9
const HEIGHT: float = 0.09

var _fill: MeshInstance3D
var _fill_mat: StandardMaterial3D
var _label: Label3D
var _shown: float = 1.0
var _target: float = 1.0
var always_visible: bool = false
var _base_color: Color = Color.WHITE


static func create(parent: Node3D, height_m: float, color: Color, label_text: String = "") -> HealthBar3D:
	var bar := HealthBar3D.new()
	bar.position = Vector3(0, height_m, 0)
	parent.add_child(bar)
	bar._build(color, label_text)
	return bar


func _build(color: Color, label_text: String) -> void:
	var back := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(WIDTH + 0.06, HEIGHT + 0.06)
	back.mesh = q
	back.material_override = _mat(Color(0.08, 0.06, 0.05, 0.85))
	add_child(back)
	_fill = MeshInstance3D.new()
	var qf := QuadMesh.new()
	qf.size = Vector2(WIDTH, HEIGHT)
	_fill.mesh = qf
	_base_color = color
	_fill_mat = _mat(color)
	_fill.material_override = _fill_mat
	_fill.position.z = 0.002
	add_child(_fill)
	if label_text != "":
		_label = Label3D.new()
		_label.text = label_text
		_label.font_size = 32
		_label.pixel_size = 0.009
		_label.outline_size = 8
		_label.position = Vector3(0, 0.2, 0)
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.no_depth_test = true
		add_child(_label)
	visible = always_visible


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = true
	m.render_priority = 2
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func set_ratio(r: float) -> void:
	_target = clampf(r, 0.0, 1.0)
	if not always_visible:
		visible = _target < 0.999 and _target > 0.0


func set_label(text: String) -> void:
	if _label:
		_label.text = text


func _process(delta: float) -> void:
	_shown = move_toward(_shown, _target, delta * 1.5)  # bar menyusut halus
	# Billboard: geser kiri agar menyusut dari kanan (offset di ruang kamera)
	_fill.scale.x = maxf(_shown, 0.001)
	var cam := get_viewport().get_camera_3d()
	if cam:
		var right: Vector3 = cam.global_transform.basis.x
		_fill.global_position = global_position + right * (-(1.0 - _shown) * WIDTH / 2.0) + cam.global_transform.basis.z * 0.002
	_fill_mat.albedo_color = Color("d83a2a") if _shown < 0.3 else _base_color
