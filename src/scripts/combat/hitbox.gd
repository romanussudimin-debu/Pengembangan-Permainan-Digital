class_name Hitbox
extends Area3D
## Area serangan jarak dekat (pukulan, gigitan, seruduk). Aktif sesaat lewat activate(),
## lalu mengenai setiap Hurtbox tim lain paling banyak sekali per aktivasi.

signal landed(target: Hurtbox)

var damage: float = 10.0
var team: int = CombatConst.TEAM_ENEMIES
var source: Node
var effect: SkillData  ## opsional: efek racun/lambat/dorong saat kena (serangan musuh)
var _active_time: float = 0.0
var _already_hit: Array[Hurtbox] = []


func _init() -> void:
	collision_layer = 0
	collision_mask = CombatConst.LAYER_HURTBOX
	monitoring = false
	monitorable = false


## Membuat hitbox bola di depan pemilik (offset lokal).
static func create_sphere(owner_node: Node3D, radius: float, offset: Vector3) -> Hitbox:
	var hb := Hitbox.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	hb.add_child(shape)
	hb.position = offset
	owner_node.add_child(hb)
	return hb


func activate(duration: float) -> void:
	_already_hit.clear()
	_active_time = duration
	monitoring = true


func _physics_process(delta: float) -> void:
	if _active_time <= 0.0:
		return
	_active_time -= delta
	for area: Area3D in get_overlapping_areas():
		if area is Hurtbox:
			var target: Hurtbox = area
			if target.team != team and not _already_hit.has(target):
				_already_hit.append(target)
				var kena: bool
				if effect:
					kena = CombatUtil.apply_skill_hit(target, effect, source, global_position, damage)
				else:
					kena = target.receive_hit(damage, source, global_position)
				if kena:
					landed.emit(target)
	if _active_time <= 0.0:
		monitoring = false
