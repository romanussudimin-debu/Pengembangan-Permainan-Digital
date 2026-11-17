class_name HealthComponent
extends Node
## Komponen HP yang dipakai pemain, musuh, dan bos.
## Damage hanya diterapkan oleh otoritas (host; di mode Solo perangkat ini sendiri).

signal damaged(amount: float, source: Node)
signal healed(amount: float)
signal died(killer: Node)
signal changed(hp: float, max_hp: float)

@export var max_hp: float = 100.0

var hp: float = 100.0
var dead: bool = false
var invulnerable_time: float = 0.0  ## kebal sementara (setelah respawn, ultimate)
var damage_taken_multiplier: float = 1.0  ## dipakai buff/debuff nanti


func _ready() -> void:
	hp = max_hp


func _process(delta: float) -> void:
	if invulnerable_time > 0.0:
		invulnerable_time = maxf(invulnerable_time - delta, 0.0)


func is_invulnerable() -> bool:
	return invulnerable_time > 0.0


## Mengurangi HP. Mengembalikan true bila damage benar-benar diterapkan.
func take_damage(amount: float, source: Node = null) -> bool:
	if dead or amount <= 0.0 or is_invulnerable() or not CombatManager.is_authority():
		return false
	var final: float = amount * damage_taken_multiplier
	hp = maxf(hp - final, 0.0)
	damaged.emit(final, source)
	changed.emit(hp, max_hp)
	if hp <= 0.0:
		dead = true
		died.emit(source)
	return true


func heal(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	hp = minf(hp + amount, max_hp)
	healed.emit(amount)
	changed.emit(hp, max_hp)


func set_max_hp(value: float, refill: bool = true) -> void:
	max_hp = value
	hp = max_hp if refill else minf(hp, max_hp)
	changed.emit(hp, max_hp)


func revive() -> void:
	dead = false
	hp = max_hp
	changed.emit(hp, max_hp)


func ratio() -> float:
	return hp / max_hp if max_hp > 0.0 else 0.0
