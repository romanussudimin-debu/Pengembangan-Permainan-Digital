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
var _shop_button: Button
var _shop: LapakSongke
var _always: Control  ## lapisan yang tampil walau tempur nonaktif (banner, tombol Lapak saat jeda)
var _banner_title: Label
var _banner_sub: Label
var _banner_tween: Tween
var _boss_canvas: Control
var _label_break: Label


func _ready() -> void:
	layer = 12
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_hp_canvas = Control.new()
	_hp_canvas.position = Vector2(198, 312)
	_hp_canvas.size = Vector2(232, 42)
	_hp_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_canvas.draw.connect(_draw_hp)
	_root.add_child(_hp_canvas)
	_skills_canvas = Control.new()
	_skills_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_skills_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skills_canvas.draw.connect(_draw_skills)
	_root.add_child(_skills_canvas)
	_label_reward = Gaya.label("", 10, Gaya.KUNING)
	_label_reward.position = Vector2(232, 297)
	_root.add_child(_label_reward)
	_shop_button = Gaya.tombol("Lapak Songke [B]")
	_shop_button.position = Vector2(470, 262)
	_shop_button.custom_minimum_size = Vector2(160, 28)
	_shop_button.add_theme_font_size_override("font_size", 10)
	_shop_button.pressed.connect(open_shop)
	_shop_button.visible = false
	_root.add_child(_shop_button)
	CombatManager.shop_changed.connect(func(a: bool) -> void:
		_shop_button.visible = a
		if a:
			var tw := _shop_button.create_tween()
			_shop_button.scale = Vector2(0.6, 0.6)
			tw.tween_property(_shop_button, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
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
	_build_always_layer()


func _build_always_layer() -> void:
	_always = Control.new()
	_always.set_anchors_preset(Control.PRESET_FULL_RECT)
	_always.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_always)
	_shop_button.reparent(_always)
	_label_break = Gaya.label("", 10, Gaya.PUTIH)
	_label_break.position = Vector2(470, 244)
	_label_break.size = Vector2(160, 16)
	_label_break.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_always.add_child(_label_break)
	_banner_title = Gaya.label("", 20, Gaya.KUNING)
	_banner_title.add_theme_constant_override("outline_size", 6)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title.size = Vector2(640, 30)
	_banner_title.position = Vector2(0, 222)
	_banner_title.pivot_offset = Vector2(320, 15)
	_always.add_child(_banner_title)
	_banner_sub = Gaya.label("", 11, Gaya.PUTIH)
	_banner_sub.add_theme_constant_override("outline_size", 5)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_sub.size = Vector2(520, 36)
	_banner_sub.position = Vector2(60, 252)
	_always.add_child(_banner_sub)
	_banner_title.modulate.a = 0.0
	_banner_sub.modulate.a = 0.0
	_boss_canvas = Control.new()
	_boss_canvas.position = Vector2(160, 92)
	_boss_canvas.size = Vector2(320, 22)
	_boss_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_canvas.draw.connect(_draw_boss)
	_boss_canvas.visible = false
	_always.add_child(_boss_canvas)
	CombatManager.announce.connect(show_banner)
	CombatManager.boss_changed.connect(func(b: Node3D) -> void: _boss_canvas.visible = b != null)


## Banner tengah layar: judul besar + keterangan (gelombang, musuh baru beserta kiatnya, bos).
func show_banner(title: String, subtitle: String) -> void:
	_banner_title.text = title
	_banner_sub.text = subtitle
	if _banner_tween:
		_banner_tween.kill()
	_banner_title.scale = Vector2(1.4, 1.4)
	_banner_tween = create_tween()
	_banner_tween.set_parallel()
	_banner_tween.tween_property(_banner_title, "modulate:a", 1.0, 0.15)
	_banner_tween.tween_property(_banner_sub, "modulate:a", 1.0, 0.15)
	_banner_tween.tween_property(_banner_title, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(2.8 if subtitle.length() > 30 else 1.8)
	_banner_tween.chain().tween_property(_banner_title, "modulate:a", 0.0, 0.4)
	_banner_tween.parallel().tween_property(_banner_sub, "modulate:a", 0.0, 0.4)


## Bar HP bos: nama, bar merah (gelap saat marah), garis tengah penanda fase marah.
func _draw_boss() -> void:
	var b: Node3D = CombatManager.boss
	if b == null or not is_instance_valid(b):
		return
	var c: Control = _boss_canvas
	var h: HealthComponent = b.get("health")
	var nama: String = str((b.get("data") as EnemyData).display_name)
	var marah: bool = b.get("enraged") == true
	var r: float = h.ratio() if h else 0.0
	c.draw_rect(Rect2(0, 8, c.size.x, 14), Color(0.08, 0.05, 0.05, 0.9))
	c.draw_rect(Rect2(2, 10, (c.size.x - 4) * r, 10), Color("8a1010") if marah else Color("d8402a"))
	c.draw_line(Vector2(c.size.x * 0.5, 8), Vector2(c.size.x * 0.5, 22), Gaya.KUNING, 1.0)
	c.draw_rect(Rect2(0, 8, c.size.x, 14), Gaya.KUNING, false, 1.0)
	var font: Font = ThemeDB.fallback_font
	var teks: String = nama + ("  (MARAH!)" if marah else "")
	c.draw_string_outline(font, Vector2(0, 6), teks, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 10, 4, Gaya.HITAM)
	c.draw_string(font, Vector2(0, 6), teks, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 10, Gaya.KUNING)


func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = _find_local_player()
		if player == null:
			return
	var c: CombatPlayer = player.combat
	_hp_canvas.queue_redraw()
	_skills_canvas.queue_redraw()
	if _boss_canvas.visible:
		_boss_canvas.queue_redraw()
	_label_break.visible = CombatManager.shop_available and CombatManager.break_time_left > 0.0
	if _label_break.visible:
		_label_break.text = "Jeda: %d detik" % ceili(CombatManager.break_time_left)
	_label_reward.text = "Koin %d" % CombatManager.stats_for(player).coins
	_respawn_panel.visible = c.is_dead
	if c.is_dead:
		_label_respawn.text = "Kamu terjatuh!\nBangkit lagi dalam %d..." % ceili(c.respawn_left)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shop") and CombatManager.shop_available and _shop == null:
		get_viewport().set_input_as_handled()
		open_shop()


func open_shop() -> void:
	if player == null or _shop != null or not CombatManager.shop_available:
		return
	_shop = LapakSongke.open_for(player)
	_shop.closed.connect(func() -> void: _shop = null)


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
	# Lencana level tempur (kiri) + bar XP tipis di bawah bar energi
	var st: CombatStats = player.combat.stats
	var badge := Vector2(14, 18)
	c.draw_circle(badge, 15.0, Color(0.08, 0.06, 0.05, 0.95))
	c.draw_circle(badge, 13.0, Color("2c5c96"))
	c.draw_arc(badge, 13.0, 0.0, TAU, 24, Gaya.KUNING, 1.5)
	var lv: String = "MAX" if st.level >= CombatStats.MAX_LEVEL else str(st.level)
	var ukuran: int = 12 if lv.length() < 3 else 8
	c.draw_string(ThemeDB.fallback_font, badge + Vector2(-14, 5), lv, HORIZONTAL_ALIGNMENT_CENTER, 28, ukuran, Gaya.PUTIH)
	c.draw_set_transform(Vector2(34, 0))
	var w: float = c.size.x - 34.0
	var hp_rect := Rect2(0, 0, w, 20)
	c.draw_rect(hp_rect, Color(0.08, 0.06, 0.05, 0.85))
	var warna: Color = Color("6ad07a") if r > 0.3 else Color("d83a2a")
	if h.is_invulnerable():
		warna = Color("f2d060")  # kebal: bar keemasan
	c.draw_rect(Rect2(Vector2(2, 2), Vector2((w - 4) * r, 16)), warna)
	c.draw_rect(hp_rect, Gaya.KUNING, false, 1.0)
	var teks: String = "%d / %d" % [ceili(h.hp), int(h.max_hp)]
	c.draw_string(ThemeDB.fallback_font, Vector2(0, 15), teks, HORIZONTAL_ALIGNMENT_CENTER, w, 11, Gaya.PUTIH)
	# Bar energi (biru) di bawah HP
	var caster: SkillCaster = player.combat.caster
	var e_rect := Rect2(0, 23, w, 9)
	c.draw_rect(e_rect, Color(0.08, 0.06, 0.05, 0.85))
	c.draw_rect(Rect2(2, 25, (w - 4) * caster.energy / SkillCaster.MAX_ENERGY, 5), Color("5fa8e8"))
	c.draw_rect(e_rect, Color("5fa8e8").darkened(0.3), false, 1.0)
	# Bar XP (hijau muda) menuju level berikutnya
	var xp_r: float = 1.0 if st.level >= CombatStats.MAX_LEVEL else float(st.xp) / CombatStats.xp_needed(st.level)
	c.draw_rect(Rect2(0, 35, w, 5), Color(0.08, 0.06, 0.05, 0.85))
	c.draw_rect(Rect2(1, 36, (w - 2) * xp_r, 3), Color("a8e070"))
	c.draw_set_transform(Vector2.ZERO)


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
