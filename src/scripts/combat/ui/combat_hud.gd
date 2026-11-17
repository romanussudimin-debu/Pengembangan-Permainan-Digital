class_name CombatHud
extends CanvasLayer
## HUD tempur: bar HP & energi pemain lokal, koin & XP, hitung mundur respawn,
## dan 4 ikon skill bulat dengan sapuan cooldown melingkar (Tahap 2).
## Tata letak sentuh lengkap + minimap dibuat di Tahap 6.

const SKILL_POS: Array[Vector2] = [Vector2(470, 330), Vector2(516, 330), Vector2(562, 330), Vector2(612, 318)]
const SKILL_R: Array[float] = [19.0, 19.0, 19.0, 25.0]

var player: Pemain
var _root: Control
var _hp_canvas: Control
var _label_reward: Label
var _respawn_panel: Control
var _label_respawn: Label
var _skills_canvas: Control


func _ready() -> void:
	layer = 12
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_hp_canvas = Control.new()
	_hp_canvas.position = Vector2(200, 316)
	_hp_canvas.size = Vector2(200, 34)
	_hp_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_canvas.draw.connect(_draw_hp)
	_root.add_child(_hp_canvas)
	_skills_canvas = Control.new()
	_skills_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_skills_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skills_canvas.draw.connect(_draw_skills)
	_root.add_child(_skills_canvas)
	_label_reward = Gaya.label("", 10, Gaya.KUNING)
	_label_reward.position = Vector2(200, 298)
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
	_skills_canvas.queue_redraw()
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
	var hp_rect := Rect2(0, 0, c.size.x, 20)
	c.draw_rect(hp_rect, Color(0.08, 0.06, 0.05, 0.85))
	var warna: Color = Color("6ad07a") if r > 0.3 else Color("d83a2a")
	if h.is_invulnerable():
		warna = Color("f2d060")  # kebal: bar keemasan
	c.draw_rect(Rect2(Vector2(2, 2), Vector2((c.size.x - 4) * r, 16)), warna)
	c.draw_rect(hp_rect, Gaya.KUNING, false, 1.0)
	var teks: String = "%d / %d" % [ceili(h.hp), int(h.max_hp)]
	c.draw_string(ThemeDB.fallback_font, Vector2(0, 15), teks, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 11, Gaya.PUTIH)
	# Bar energi (biru) di bawah HP
	var caster: SkillCaster = player.combat.caster
	var e_rect := Rect2(0, 23, c.size.x, 9)
	c.draw_rect(e_rect, Color(0.08, 0.06, 0.05, 0.85))
	c.draw_rect(Rect2(2, 25, (c.size.x - 4) * caster.energy / SkillCaster.MAX_ENERGY, 5), Color("5fa8e8"))
	c.draw_rect(e_rect, Color("5fa8e8").darkened(0.3), false, 1.0)


## Ikon skill: lingkaran berwarna skill; saat cooldown, sapuan gelap melingkar + sisa detik;
## redup bila energi tidak cukup. Huruf tombol di bawah ikon.
func _draw_skills() -> void:
	if player == null:
		return
	var c: Control = _skills_canvas
	var caster: SkillCaster = player.combat.caster
	var font: Font = ThemeDB.fallback_font
	for i in caster.skills.size():
		var s: SkillData = caster.skills[i]
		var pos: Vector2 = SKILL_POS[i]
		var r: float = SKILL_R[i]
		var siap: bool = caster.can_cast(i)
		c.draw_circle(pos, r + 2.0, Color(0.08, 0.06, 0.05, 0.9))
		c.draw_circle(pos, r, s.color if siap else s.color.darkened(0.55))
		_draw_icon(c, pos, r, s.kind)
		var cd: float = caster.cooldown_ratio(i)
		if cd > 0.0:
			var poly := PackedVector2Array([pos])
			var seg: int = 24
			for k in seg + 1:
				var a: float = -PI / 2.0 + TAU * cd * k / seg
				poly.append(pos + Vector2(cos(a), sin(a)) * r)
			if poly.size() >= 3:
				c.draw_colored_polygon(poly, Color(0, 0, 0, 0.6))
			var sisa: String = str(ceili(caster.cooldowns[i]))
			c.draw_string_outline(font, pos + Vector2(-r, 5), sisa, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 13, 4, Gaya.HITAM)
			c.draw_string(font, pos + Vector2(-r, 5), sisa, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 13, Gaya.PUTIH)
		c.draw_arc(pos, r, 0.0, TAU, 32, Gaya.KUNING if siap else Color("6a625a"), 2.0)
		c.draw_string_outline(font, pos + Vector2(-10, r + 9), s.key_hint, HORIZONTAL_ALIGNMENT_CENTER, 20, 9, 3, Gaya.HITAM)
		c.draw_string(font, pos + Vector2(-10, r + 9), s.key_hint, HORIZONTAL_ALIGNMENT_CENTER, 20, 9, Gaya.PUTIH)


## Ikon sederhana per jenis skill (digambar, tanpa aset gambar).
func _draw_icon(c: Control, pos: Vector2, r: float, kind: String) -> void:
	var w := Color(1, 1, 1, 0.9)
	match kind:
		"fire_arrow":
			c.draw_line(pos + Vector2(-r * 0.5, r * 0.5), pos + Vector2(r * 0.45, -r * 0.45), w, 2.0)
			c.draw_colored_polygon(PackedVector2Array([pos + Vector2(r * 0.5, -r * 0.5), pos + Vector2(r * 0.15, -r * 0.4),
					pos + Vector2(r * 0.4, -r * 0.15)]), w)
			c.draw_circle(pos + Vector2(-r * 0.35, r * 0.35), r * 0.22, Color(1, 0.9, 0.4))
		"arrow_rain":
			for k in 3:
				var x: float = (k - 1) * r * 0.4
				c.draw_line(pos + Vector2(x, -r * 0.55), pos + Vector2(x, r * 0.35), w, 2.0)
				c.draw_colored_polygon(PackedVector2Array([pos + Vector2(x - 3, r * 0.3), pos + Vector2(x + 3, r * 0.3),
						pos + Vector2(x, r * 0.55)]), w)
		"wind_arrow":
			c.draw_arc(pos, r * 0.45, 0.3, 4.6, 16, w, 2.0)
			c.draw_line(pos + Vector2(-r * 0.6, 0), pos + Vector2(r * 0.6, 0), w, 2.0)
		_:
			GambarBintang.gambar(c, pos, r * 0.6, true, Color(1, 0.95, 0.7))
