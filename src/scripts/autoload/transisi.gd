extends CanvasLayer
## Transisi antar-scene dengan efek fade (ease in/out).

var _tirai: ColorRect
var _sibuk: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tirai = ColorRect.new()
	_tirai.color = Color(0.08, 0.06, 0.06)
	_tirai.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tirai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tirai.modulate.a = 0.0
	add_child(_tirai)


func pindah_scene(path: String) -> void:
	if _sibuk:
		return
	_sibuk = true
	_tirai.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_tirai, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_tirai, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_tirai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sibuk = false


func sedang_transisi() -> bool:
	return _sibuk
