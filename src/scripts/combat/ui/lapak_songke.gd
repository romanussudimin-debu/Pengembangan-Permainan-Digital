class_name LapakSongke
extends CanvasLayer
## Toko "Lapak Songke" di sela gelombang: upgrade dibayar dengan koin dari musuh.
## Saat dibuka permainan ditahan (state MINIGAME) agar pemain bisa memilih dengan tenang.
## Tombol besar agar mudah diketuk di HP. Tutup: tombol "Lanjut Bertarung", Esc, atau B.

signal closed

const CARD_SIZE := Vector2(138, 112)

var player: Pemain
var _cards: Control
var _label_coins: Label
var _label_info: Label
var _state_before: int = GameState.State.BERMAIN
var _pause: bool = true  ## main sendiri: permainan ditahan; LAN: dunia tetap berjalan


static func open_for(p: Pemain) -> LapakSongke:
	var shop := LapakSongke.new()
	shop.player = p
	p.get_tree().root.add_child(shop)
	return shop


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_state_before = GameState.state
	_pause = not NetworkManager.is_online()
	if _pause:
		GameState.ubah_state(GameState.State.MINIGAME)
	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.55)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	var panel := Gaya.panel_songke(Vector2(14, 10), Vector2(612, 340))
	add_child(panel)
	var judul := Gaya.label("Lapak Songke", 18, Gaya.KUNING)
	judul.position = Vector2(20, 10)
	panel.add_child(judul)
	var sub := Gaya.label("Tukar koin dengan perlengkapan sebelum gelombang berikutnya.", 9, Color("c9c2b0"))
	sub.position = Vector2(22, 38)
	panel.add_child(sub)
	_label_coins = Gaya.label("", 14, Gaya.KUNING)
	_label_coins.position = Vector2(420, 14)
	_label_coins.size = Vector2(170, 24)
	_label_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_label_coins)
	_cards = Control.new()
	_cards.position = Vector2(18, 58)
	panel.add_child(_cards)
	_label_info = Gaya.label("", 10, Gaya.PUTIH)
	_label_info.position = Vector2(20, 300)
	_label_info.size = Vector2(360, 20)
	panel.add_child(_label_info)
	var lanjut := Gaya.tombol("Lanjut Bertarung")
	lanjut.position = Vector2(400, 292)
	lanjut.custom_minimum_size = Vector2(190, 32)
	lanjut.pressed.connect(close)
	panel.add_child(lanjut)
	_rebuild()
	AudioManager.putar_sfx("gendang")
	lanjut.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jeda") or event.is_action_pressed("shop"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if _pause and GameState.sedang(GameState.State.MINIGAME):
		GameState.ubah_state(GameState.State.BERMAIN if _state_before == GameState.State.MINIGAME else _state_before)
	closed.emit()
	queue_free()


func _rebuild() -> void:
	for c in _cards.get_children():
		c.queue_free()
	var stats: CombatStats = CombatManager.stats_for(player)
	_label_coins.text = "Koin: %d" % stats.coins
	var items: Array[ShopItem] = CombatManager.SHOP_ITEMS
	for i in items.size():
		var item: ShopItem = items[i]
		var col: int = i % 4
		var row: int = i / 4
		var card := _make_card(item, stats)
		card.position = Vector2(col * (CARD_SIZE.x + 7), row * (CARD_SIZE.y + 8))
		_cards.add_child(card)


func _make_card(item: ShopItem, stats: CombatStats) -> Control:
	var card := Panel.new()
	card.size = CARD_SIZE
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.12, 0.09, 0.08, 0.95)
	gaya.border_color = item.color.darkened(0.2)
	gaya.set_border_width_all(2)
	gaya.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", gaya)
	var r: int = stats.rank(item.id)
	var maxed: bool = item.max_rank > 0 and r >= item.max_rank
	var price: int = item.price(r)
	var ikon := Control.new()
	ikon.position = Vector2(8, 8)
	ikon.size = Vector2(30, 30)
	ikon.draw.connect(_draw_icon.bind(ikon, item))
	card.add_child(ikon)
	var nama := Gaya.label(item.display_name, 9, Gaya.KUNING)
	nama.position = Vector2(42, 6)
	nama.size = Vector2(92, 30)
	nama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nama.add_theme_constant_override("line_spacing", -4)
	card.add_child(nama)
	var desc := Gaya.label(item.description, 8, Color("d8d2c4"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(8, 40)
	desc.size = Vector2(124, 30)
	desc.add_theme_constant_override("line_spacing", -4)
	card.add_child(desc)
	if item.max_rank > 0:
		var titik := Control.new()
		titik.position = Vector2(8, 70)
		titik.size = Vector2(60, 8)
		titik.draw.connect(func() -> void:
			for k in item.max_rank:
				titik.draw_circle(Vector2(4 + k * 11, 4), 3.5, item.color if k < r else Color(1, 1, 1, 0.2)))
		card.add_child(titik)
	var beli := Gaya.tombol("Penuh" if maxed else "%d koin" % price)
	beli.position = Vector2(8, 80)
	beli.custom_minimum_size = Vector2(122, 26)
	beli.add_theme_font_size_override("font_size", 10)
	beli.disabled = maxed or stats.coins < price
	beli.pressed.connect(_buy.bind(item))
	card.add_child(beli)
	return card


func _buy(item: ShopItem) -> void:
	if NetworkManager.is_online() and not NetworkManager.is_host():
		# Klien LAN: pembelian diproses host (otoritas), hasilnya datang lewat snapshot
		var arena: Node = get_tree().current_scene
		if arena.has_method("request_buy"):
			arena.call("request_buy", item.id)
		_label_info.text = "Membeli %s..." % item.display_name
		AudioManager.putar_sfx("klik")
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if is_inside_tree():
				_rebuild())
		return
	var stats: CombatStats = CombatManager.stats_for(player)
	var alasan: String = stats.buy(item)
	if alasan != "":
		_label_info.text = alasan
		AudioManager.putar_sfx("salah")
		return
	if item.max_rank == 0:
		player.combat.use_consumable(item)
	AudioManager.putar_sfx("benar")
	_label_info.text = "Dibeli: %s" % item.display_name
	Analitik.catat("beli_lapak", {"barang": item.id, "sisa_koin": stats.coins})
	_rebuild()


## Ikon digambar sederhana sesuai jenis barang (tanpa aset gambar).
func _draw_icon(c: Control, item: ShopItem) -> void:
	var p := Vector2(15, 15)
	c.draw_circle(p, 14.0, item.color)
	c.draw_arc(p, 14.0, 0.0, TAU, 24, Gaya.KUNING, 1.5)
	var w := Color(1, 1, 1, 0.92)
	match item.stat:
		"damage":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -9), p + Vector2(6, 3), p + Vector2(-6, 3)]), w)
			c.draw_line(p + Vector2(0, 3), p + Vector2(0, 9), w, 2.0)
		"fire_rate":
			c.draw_arc(p + Vector2(-3, 0), 9.0, -1.2, 1.2, 10, w, 2.0)
			c.draw_line(p + Vector2(1, -8), p + Vector2(1, 8), w, 1.0)
		"max_hp":
			GambarHati.gambar(c, p, 8.0, true, false)
		"cooldown":
			c.draw_arc(p, 8.0, 0.0, TAU, 20, w, 2.0)
			c.draw_line(p, p + Vector2(0, -6), w, 2.0)
			c.draw_line(p, p + Vector2(4, 2), w, 2.0)
		"energy_regen":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(2, -10), p + Vector2(-5, 2), p + Vector2(0, 2),
					p + Vector2(-2, 10), p + Vector2(5, -2), p + Vector2(0, -2)]), Color("ffe066"))
		"move_speed":
			for k in 3:
				c.draw_line(p + Vector2(-8, -5 + k * 5), p + Vector2(6, -5 + k * 5), w, 1.5)
		_:
			c.draw_rect(Rect2(p + Vector2(-5, -3), Vector2(10, 10)), w)
			c.draw_arc(p + Vector2(6, 2), 3.0, -1.5, 1.5, 6, w, 1.5)
