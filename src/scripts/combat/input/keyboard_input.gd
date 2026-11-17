class_name KeyboardInput
extends PlayerInput
## Input lokal: WASD/panah (juga joystick sentuh lewat aksi Input), mouse untuk membidik,
## klik kiri menembak, Q/E/R skill, F ultimate, Spasi lompat.
## Bila pemain tidak memakai mouse (layar sentuh), bidikan otomatis ke musuh terdekat.

const SKILL_ACTIONS: Array[String] = ["skill_1", "skill_2", "skill_3", "ultimate"]

var _mouse_used: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		# Mouse tiruan dari sentuhan (Android) diabaikan; tembak di HP lewat tombol sentuh
		if event.device != InputEvent.DEVICE_ID_EMULATION:
			_mouse_used = true
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		_mouse_used = false


func update_input(character: Node3D, _delta: float) -> void:
	if not GameState.sedang(GameState.State.BERMAIN):
		clear()
		return
	var v: Vector2 = Input.get_vector("kiri", "kanan", "maju", "mundur")
	move_dir = camera_relative(character, v)
	jump_pressed = Input.is_action_just_pressed("lompat")
	jump_held = Input.is_action_pressed("lompat")
	interact_pressed = Input.is_action_just_pressed("interaksi")
	shoot_held = Input.is_action_pressed("shoot") and _mouse_used
	for i in SKILL_ACTIONS.size():
		skill_pressed[i] = Input.is_action_just_pressed(SKILL_ACTIONS[i])
	auto_aim = not _mouse_used
	has_aim_point = false
	if _mouse_used:
		var point: Variant = mouse_ground_point(character)
		if point != null:
			aim_point = point
			has_aim_point = true


## Arah stik/WASD diputar mengikuti arah hadap kamera (kamera bisa diputar pemain).
static func camera_relative(character: Node3D, v: Vector2) -> Vector3:
	var dir := Vector3(v.x, 0.0, v.y)
	var cam := character.get_viewport().get_camera_3d()
	if cam:
		var forward: Vector3 = -cam.global_transform.basis.z
		forward.y = 0.0
		if forward.length() > 0.01:
			dir = dir.rotated(Vector3.UP, atan2(-forward.x, -forward.z))
	return dir


## Titik di bidang setinggi dada karakter yang ditunjuk kursor mouse.
static func mouse_ground_point(character: Node3D) -> Variant:
	var vp := character.get_viewport()
	var cam := vp.get_camera_3d()
	if cam == null:
		return null
	var mouse: Vector2 = vp.get_mouse_position()
	var origin: Vector3 = cam.project_ray_origin(mouse)
	var normal: Vector3 = cam.project_ray_normal(mouse)
	var plane := Plane(Vector3.UP, character.global_position.y + CombatConst.COMBAT_HEIGHT)
	return plane.intersects_ray(origin, normal)
