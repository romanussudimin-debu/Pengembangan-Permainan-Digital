class_name EnemyShield
extends EnemyBase
## Penahan damage:
##  - perisai (data.front_block < 1): panah dari DEPAN hampir tidak melukai; serang dari samping/belakang.
##  - cangkang (data.shell_reduction < 1): damage kecil, kecuali sesaat setelah ia menyerang (jendela lemah).

const FRONT_DOT: float = 0.45  ## +-63 derajat dianggap "depan"
const WEAK_WINDOW: float = 1.6

var _weak: float = 0.0
var _last_block_text: float = 0.0


func _setup() -> void:
	hurtbox.damage_filter = _filter


func _filter(dmg: float, source: Node, _pos: Vector3) -> float:
	var result: float = dmg
	var label: String = ""
	if data.front_block < 1.0 and source is Node3D:
		var to_src: Vector3 = (source as Node3D).global_position - global_position
		to_src.y = 0.0
		if to_src.length() > 0.01 and forward().dot(to_src.normalized()) > FRONT_DOT:
			result *= data.front_block
			label = "Tertangkis!"
	if data.shell_reduction < 1.0 and _weak <= 0.0:
		result *= data.shell_reduction
		label = "Cangkang keras!"
	if label != "" and _last_block_text <= 0.0:
		_last_block_text = 0.8
		Efek.teks(get_parent(), global_position + Vector3(0, data.bar_height * data.scale, 0), label, Color("c9c2b0"))
		AudioManager.putar_sfx("perisai", 0.15)
	return result


func _after_physics(delta: float) -> void:
	_weak = maxf(_weak - delta, 0.0)
	_last_block_text = maxf(_last_block_text - delta, 0.0)


func _perform_attack() -> void:
	super._perform_attack()
	if data.shell_reduction < 1.0:
		_weak = WEAK_WINDOW
		Efek.teks(get_parent(), global_position + Vector3(0, 1.8, 0), "Lemah!", Gaya.KUNING)
		if model.has_method("squash"):
			model.call("squash", Vector3(1.25, 0.7, 1.25), WEAK_WINDOW)
