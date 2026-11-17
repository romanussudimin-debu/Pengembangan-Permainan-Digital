class_name HazardZone
extends Node3D
## Area berbahaya sementara di tanah (api obor, nanti juga racun bos): melukai tim lain
## setiap 0,5 detik selama `duration`. Damage diterapkan oleh otoritas.

const TICK: float = 0.5

var radius: float = 1.5
var dps: float = 8.0
var duration: float = 4.0
var team: int = CombatConst.TEAM_ENEMIES
var source: Node
var color: Color = Color(1.0, 0.45, 0.1, 0.55)
var _t: float = 0.0
var _tick_t: float = 0.0
var _flames: Array[MeshInstance3D] = []


static func spawn(parent: Node, pos: Vector3, r: float, damage_per_second: float, dur: float, team_id: int,
		src: Node, tint: Color = Color(1.0, 0.45, 0.1, 0.55)) -> HazardZone:
	var z := HazardZone.new()
	z.radius = r
	z.dps = damage_per_second
	z.duration = dur
	z.team = team_id
	z.source = src
	z.color = tint
	parent.add_child(z)
	z.global_position = Vector3(pos.x, pos.y, pos.z)
	return z


func _ready() -> void:
	var disc := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = 0.03
	c.radial_segments = 20
	disc.mesh = c
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material_override = m
	disc.position.y = 0.05
	add_child(disc)
	var mf := StandardMaterial3D.new()
	mf.albedo_color = Color(color.r, minf(color.g + 0.3, 1.0), color.b, 0.85)
	mf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 6:
		var a: float = TAU * i / 6.0
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.16
		cone.height = 0.5
		cone.radial_segments = 5
		var mi := MeshInstance3D.new()
		mi.mesh = cone
		mi.material_override = mf
		mi.position = Vector3(cos(a) * radius * 0.6, 0.25, sin(a) * radius * 0.6)
		add_child(mi)
		_flames.append(mi)
	Efek.cahaya(self, global_position + Vector3(0, 0.8, 0), Color(color.r, color.g, color.b), 2.0, duration, radius * 3.0)


func _process(delta: float) -> void:
	_t += delta
	for i in _flames.size():
		_flames[i].scale = Vector3(1, 0.7 + 0.4 * absf(sin(_t * 8.0 + i)), 1)
	if _t >= duration:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.3)
		tw.tween_callback(queue_free)
		set_process(false)
		return
	_tick_t += delta
	if _tick_t >= TICK and CombatManager.is_authority() and GameState.sedang(GameState.State.BERMAIN):
		_tick_t -= TICK
		for hb: Hurtbox in CombatUtil.hurtboxes_in_radius(self, global_position + Vector3(0, 0.5, 0), radius, team):
			hb.receive_hit(dps * TICK, source, hb.global_position)
