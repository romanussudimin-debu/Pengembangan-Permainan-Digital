class_name StatusEffects
extends Node
## Efek status pada satu karakter: terbakar (damage per detik) dan lambat (pengali kecepatan).
## Damage terbakar diterapkan oleh otoritas melalui HealthComponent pemilik.

signal burn_tick(amount: float)

var health: HealthComponent
var _burn_dps: float = 0.0
var _burn_left: float = 0.0
var _burn_source: Node
var _burn_timer: float = 0.0
var _slow_factor: float = 1.0
var _slow_left: float = 0.0
var _fire_fx: Node3D


func apply_burn(dps: float, duration: float, source: Node) -> void:
	if dps <= 0.0 or duration <= 0.0:
		return
	_burn_dps = maxf(_burn_dps, dps)
	_burn_left = maxf(_burn_left, duration)
	_burn_source = source
	_show_fire(true)


func apply_slow(factor: float, duration: float) -> void:
	if duration <= 0.0 or factor >= 1.0:
		return
	_slow_factor = minf(_slow_factor, factor)
	_slow_left = maxf(_slow_left, duration)


func speed_multiplier() -> float:
	return _slow_factor if _slow_left > 0.0 else 1.0


func is_slowed() -> bool:
	return _slow_left > 0.0


func clear() -> void:
	_burn_left = 0.0
	_slow_left = 0.0
	_slow_factor = 1.0
	_show_fire(false)


func _process(delta: float) -> void:
	if _slow_left > 0.0:
		_slow_left -= delta
		if _slow_left <= 0.0:
			_slow_factor = 1.0
	if _burn_left <= 0.0:
		return
	_burn_left -= delta
	_burn_timer += delta
	if _burn_timer >= 1.0:  # satu "tik" terbakar per detik
		_burn_timer -= 1.0
		if health and not health.dead and CombatManager.is_authority():
			if health.take_damage(_burn_dps, _burn_source):
				burn_tick.emit(_burn_dps)
	if _burn_left <= 0.0:
		_burn_dps = 0.0
		_show_fire(false)


## Nyala api kecil di atas karakter selama terbakar.
func _show_fire(on: bool) -> void:
	var owner_node: Node3D = get_parent() as Node3D
	if on and _fire_fx == null and owner_node:
		_fire_fx = Node3D.new()
		owner_node.add_child(_fire_fx)
		_fire_fx.position = Vector3(0, 1.2, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1.0, 0.55, 0.15, 0.8)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for i in 3:
			var mi := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.12
			cone.height = 0.35
			cone.radial_segments = 5
			mi.mesh = cone
			mi.material_override = m
			mi.position = Vector3(cos(i * 2.1) * 0.2, 0.0, sin(i * 2.1) * 0.2)
			_fire_fx.add_child(mi)
		var tw := _fire_fx.create_tween().set_loops()
		tw.tween_property(_fire_fx, "scale", Vector3(1.1, 1.35, 1.1), 0.18)
		tw.tween_property(_fire_fx, "scale", Vector3(0.9, 0.85, 0.9), 0.18)
	elif not on and _fire_fx:
		_fire_fx.queue_free()
		_fire_fx = null
