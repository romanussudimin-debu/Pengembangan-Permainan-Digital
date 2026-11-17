class_name NetworkInput
extends PlayerInput
## Input milik pemain di perangkat lain (dipakai di host). Nilai kontinu (gerak, bidik, tahan tembak)
## diperbarui dari paket tak-andal ~30x/detik; kejadian sekali (lompat, skill) lewat paket andal
## dan disimpan sampai dibaca satu kali agar tidak hilang.

var _pending_jump: bool = false
var _pending_skills: Array[bool] = [false, false, false, false]
var _last_packet_ms: int = 0


func apply_state(move: Vector2, aim: Vector3, has_aim: bool, auto: bool, shoot: bool, jump_hold: bool) -> void:
	move_dir = Vector3(move.x, 0.0, move.y).limit_length(1.0)
	aim_point = aim
	has_aim_point = has_aim
	auto_aim = auto
	shoot_held = shoot
	jump_held = jump_hold
	_last_packet_ms = Time.get_ticks_msec()


func push_event(kind: String, index: int = 0) -> void:
	if kind == "jump":
		_pending_jump = true
	elif kind == "skill" and index >= 0 and index < 4:
		_pending_skills[index] = true


func update_input(_character: Node3D, _delta: float) -> void:
	if Time.get_ticks_msec() - _last_packet_ms > 600:
		move_dir = Vector3.ZERO  # paket terputus: berhenti, jangan berjalan terus
		shoot_held = false
	jump_pressed = _pending_jump
	_pending_jump = false
	for i in 4:
		skill_pressed[i] = _pending_skills[i]
		_pending_skills[i] = false
