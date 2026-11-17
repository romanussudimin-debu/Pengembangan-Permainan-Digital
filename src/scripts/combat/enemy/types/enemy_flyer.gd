class_name EnemyFlyer
extends EnemyBase
## Penerbang (lebah, pipit, kalong). Melayang di data.fly_height, bergerak zig-zag (data.zigzag).
## data.swoop: terbang tinggi tak terjangkau panah, lalu menukik rendah saat menyerang
## (saat itulah ia bisa dipanah).

const SWOOP_HIGH: float = 3.6
const SWOOP_LOW: float = 0.9

var _phase: float = 0.0
var _low_time: float = 0.0


func _setup() -> void:
	gravity_enabled = false
	_phase = randf() * TAU
	if data.swoop:
		targetable = false
		global_position.y = home.y + SWOOP_HIGH


func _move(horizontal: Vector3, delta: float) -> void:
	_phase += delta * 6.0
	var h: Vector3 = horizontal
	if data.zigzag > 0.0 and h.length() > 0.1:
		var side := Vector3(-h.z, 0, h.x).normalized()
		h += side * sin(_phase) * data.zigzag * data.move_speed
	super._move(h, delta)


func _change_state(s: State) -> void:
	super._change_state(s)
	if s == State.ATTACK and data.swoop:
		_low_time = data.attack_windup + 1.3  # menukik dan tetap rendah sebentar


func _after_physics(delta: float) -> void:
	var height: float = data.fly_height
	if data.swoop:
		_low_time = maxf(_low_time - delta, 0.0)
		height = SWOOP_LOW if _low_time > 0.0 else SWOOP_HIGH
		targetable = _low_time > 0.0
		hurtbox.monitorable = targetable or is_dead
	var bob: float = sin(_phase * 0.5) * 0.15
	velocity.y = (home.y + height + bob - global_position.y) * 5.0
