class_name CombatHud
extends CanvasLayer
## HUD tempur dasar (Tahap 1): bar HP pemain lokal, koin & XP, hitung mundur respawn.
## UI lengkap ala MOBA (tombol skill bulat, minimap) dibuat di Tahap 6.

var player: Pemain
var _root: Control
var _hp_canvas: Control
var _label_reward: Label
var _respawn_panel: Control
var _label_respawn: Label


func _ready() -> void:
	layer = 12
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_hp_canvas = Control.new()
	_hp_canvas.position = Vector2(220, 326)
	_hp_canvas.size = Vector2(200, 22)
	_hp_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_canvas.draw.connect(_draw_hp)
	_root.add_child(_hp_canvas)
	_label_reward = Gaya.label("", 10, Gaya.KUNING)
	_label_reward.position = Vector2(220, 308)
	_root.add_child(_label_reward)
	_respawn_panel = ColorRect.new()
	(_respawn_panel as ColorRect).color = Color(0.25, 0.02, 0.02, 0.45)
	_respawn_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_respawn_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_respawn_panel.visible = false
	_root.add_child(_respawn_panel)
	_label_respawn = Gaya.label("", 22, Gaya.PUTIH)
	_label_respawn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_respawn.size = Vector2(640, 80)
	_label_respawn.position = Vector2(0, 140)
	_respawn_panel.add_child(_label_respawn)
	CombatManager.combat_changed.connect(func(a: bool) -> void: _root.visible = a)
	_root.visible = CombatManager.active


func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = _find_local_player()
		if player == null:
			return
	var c: CombatPlayer = player.combat
	_hp_canvas.queue_redraw()
	_label_reward.text = "Koin %d   XP %d" % [CombatManager.coins_of(player), CombatManager.xp_of(player)]
	_respawn_panel.visible = c.is_dead
	if c.is_dead:
		_label_respawn.text = "Kamu terjatuh!\nBangkit lagi dalam %d..." % ceili(c.respawn_left)


func _find_local_player() -> Pemain:
	for p: Node3D in CombatManager.players:
		if p is Pemain and (p as Pemain).input is KeyboardInput:
			return p
	return null


func _draw_hp() -> void:
	if player == null:
		return
	var h: HealthComponent = player.combat.health
	var c: Control = _hp_canvas
	var r: float = h.ratio()
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.08, 0.06, 0.05, 0.85))
	var warna: Color = Color("6ad07a") if r > 0.3 else Color("d83a2a")
	c.draw_rect(Rect2(Vector2(2, 2), Vector2((c.size.x - 4) * r, c.size.y - 4)), warna)
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Gaya.KUNING, false, 1.0)
	var teks: String = "%d / %d" % [ceili(h.hp), int(h.max_hp)]
	c.draw_string(ThemeDB.fallback_font, Vector2(0, 16), teks, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 11, Gaya.PUTIH)
