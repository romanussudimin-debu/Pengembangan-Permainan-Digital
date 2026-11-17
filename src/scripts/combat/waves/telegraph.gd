class_name Telegraph
## Isyarat area serangan di tanah (lingkaran merah yang mengisi) untuk bos & bahaya.
## Memberi waktu bagi pemain untuk menghindar.


static func circle(parent: Node, pos: Vector3, radius: float, duration: float, color: Color = Color(0.9, 0.15, 0.1)) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = pos + Vector3(0, 0.04, 0)
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.93
	t.outer_radius = 1.0
	t.rings = 32
	t.ring_segments = 3
	ring.mesh = t
	ring.material_override = _mat(Color(color, 0.9))
	ring.scale = Vector3(radius, 0.2, radius)
	root.add_child(ring)
	var fill := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 1.0
	c.bottom_radius = 1.0
	c.height = 0.02
	c.radial_segments = 24
	fill.mesh = c
	var m := _mat(Color(color, 0.35))
	fill.material_override = m
	fill.scale = Vector3(0.05, 1, 0.05)
	root.add_child(fill)
	if CombatManager.networked():
		CombatManager.net_event.emit("telegraph", {"pos": pos, "r": radius, "dur": duration, "color": color})
	var tw := root.create_tween()
	tw.tween_property(fill, "scale", Vector3(radius, 1, radius), duration)
	tw.tween_callback(root.queue_free)
	return root


static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
