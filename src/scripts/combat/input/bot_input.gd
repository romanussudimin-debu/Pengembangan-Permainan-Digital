class_name BotInput
extends PlayerInput
## "Otak" bot PvP pengisi slot kosong: memburu lawan terdekat, menjaga jarak tembak sambil
## bergerak menyamping, menembak, memakai skill saat siap, dan sesekali melompat menghindar.
## Tingkat akurasi dibuat tidak sempurna agar adil untuk anak-anak.

const PREFERRED_MIN: float = 6.0
const PREFERRED_MAX: float = 11.0

var skill_level: float = 0.7  ## 0..1 (akurasi & kecepatan reaksi)
var _strafe: float = 1.0
var _strafe_t: float = 0.0
var _skill_t: float = 2.0
var _jump_t: float = 3.0
var _wander: Vector3 = Vector3.ZERO


func update_input(character: Node3D, delta: float) -> void:
	clear()
	if not GameState.sedang(GameState.State.BERMAIN) or not CombatManager.active:
		return
	var p: Pemain = character as Pemain
	var target: Node3D = CombatManager.nearest_target(character.global_position, 40.0, p.combat.team)
	_strafe_t -= delta
	if _strafe_t <= 0.0:
		_strafe_t = randf_range(0.8, 2.0)
		_strafe = -_strafe if randf() < 0.6 else _strafe
		_wander = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	if target == null:
		move_dir = _wander * 0.6
		return
	var to: Vector3 = target.global_position - character.global_position
	to.y = 0.0
	var d: float = to.length()
	var dir: Vector3 = to / maxf(d, 0.01)
	var side := Vector3(-dir.z, 0, dir.x) * _strafe
	if d > PREFERRED_MAX:
		move_dir = (dir + side * 0.3).normalized()
	elif d < PREFERRED_MIN:
		move_dir = (-dir + side * 0.5).normalized()
	else:
		move_dir = side
	# Bidik dengan sedikit meleset (dan sedikit memperkirakan gerak lawan)
	var lead: Vector3 = Vector3.ZERO
	if target is CharacterBody3D:
		lead = (target as CharacterBody3D).velocity * (d / CombatConst.ARROW_SPEED) * skill_level
	var miss := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * (1.0 - skill_level) * 2.0
	aim_point = target.global_position + lead + miss
	has_aim_point = true
	shoot_held = d < 15.0
	_skill_t -= delta
	if _skill_t <= 0.0 and d < 12.0:
		_skill_t = randf_range(1.5, 4.0)
		skill_pressed[randi() % 4] = true
	_jump_t -= delta
	if _jump_t <= 0.0:
		_jump_t = randf_range(2.0, 5.0)
		jump_pressed = true
