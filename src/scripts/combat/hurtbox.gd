class_name Hurtbox
extends Area3D
## Area yang bisa dikenai serangan (Hitbox jarak dekat atau proyektil).
## Tim yang sama tidak saling melukai.

signal hit(damage: float, source: Node, hit_position: Vector3)

@export var health: HealthComponent
var team: int = CombatConst.TEAM_ENEMIES
var entity: Node3D  ## pemilik (pemain/musuh), dipakai untuk knockback & bidik otomatis


func _init() -> void:
	collision_layer = CombatConst.LAYER_HURTBOX
	collision_mask = 0
	monitoring = false
	monitorable = true


## Membuat hurtbox kapsul pada tinggi badan dan memasangnya ke `owner_node`.
static func create_capsule(owner_node: Node3D, hp: HealthComponent, team_id: int, radius: float, height: float) -> Hurtbox:
	var hb := Hurtbox.new()
	hb.health = hp
	hb.team = team_id
	hb.entity = owner_node
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	shape.shape = capsule
	shape.position = Vector3(0, height / 2.0, 0)
	hb.add_child(shape)
	owner_node.add_child(hb)
	return hb


func receive_hit(damage: float, source: Node, hit_position: Vector3) -> bool:
	if health == null or health.dead:
		return false
	if not health.take_damage(damage, source):
		return false
	hit.emit(damage, source, hit_position)
	return true
