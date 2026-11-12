extends CanvasLayer
## Menu jeda (pause): lanjut, koleksi kartu budaya, volume, kembali ke menu utama.

var _akar: Control
var _panel_kartu: RichTextLabel
var _tombol_lanjut: Button
var _state_sebelum: int = GameState.State.BERMAIN


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bangun_ui()
	_akar.visible = false


func _bangun_ui() -> void:
	_akar = Control.new()
	_akar.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_akar)

	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.6)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_akar.add_child(gelap)

	var panel := Gaya.panel_songke(Vector2(40, 30), Vector2(560, 300))
	_akar.add_child(panel)

	var judul := Gaya.label("JEDA", 16, Gaya.KUNING)
	judul.position = Vector2(20, 12)
	panel.add_child(judul)

	var kolom := VBoxContainer.new()
	kolom.position = Vector2(20, 44)
	kolom.size = Vector2(170, 250)
	kolom.add_theme_constant_override("separation", 4)
	panel.add_child(kolom)

	_tombol_lanjut = Gaya.tombol("Lanjutkan")
	_tombol_lanjut.pressed.connect(tutup)
	kolom.add_child(_tombol_lanjut)

	kolom.add_child(Gaya.label("Volume Musik", 9, Gaya.PUTIH))
	kolom.add_child(_slider("Musik"))
	kolom.add_child(Gaya.label("Volume Efek Suara", 9, Gaya.PUTIH))
	kolom.add_child(_slider("SFX"))
	kolom.add_child(Gaya.label("Volume Suara Dialog", 9, Gaya.PUTIH))
	var slider_suara := HSlider.new()
	slider_suara.min_value = 0.0
	slider_suara.max_value = 1.0
	slider_suara.step = 0.05
	slider_suara.value = DialogManager.volume_suara
	slider_suara.custom_minimum_size = Vector2(160, 16)
	slider_suara.value_changed.connect(func(v: float) -> void: DialogManager.volume_suara = v)
	kolom.add_child(slider_suara)
	var cek_teks := CheckBox.new()
	cek_teks.text = "Tampilkan teks dialog"
	cek_teks.add_theme_font_size_override("font_size", 9)
	cek_teks.button_pressed = DialogManager.tampilkan_teks
	cek_teks.toggled.connect(func(aktif: bool) -> void: DialogManager.tampilkan_teks = aktif)
	kolom.add_child(cek_teks)

	var ke_menu := Gaya.tombol("Ke Menu Utama")
	ke_menu.pressed.connect(_ke_menu)
	kolom.add_child(ke_menu)

	var label_kartu := Gaya.label("Koleksi Kartu Budaya", 11, Gaya.KUNING)
	label_kartu.position = Vector2(210, 16)
	panel.add_child(label_kartu)

	_panel_kartu = RichTextLabel.new()
	_panel_kartu.position = Vector2(210, 40)
	_panel_kartu.size = Vector2(330, 245)
	_panel_kartu.bbcode_enabled = true
	_panel_kartu.add_theme_font_size_override("normal_font_size", 9)
	_panel_kartu.add_theme_font_size_override("bold_font_size", 10)
	panel.add_child(_panel_kartu)


func _slider(bus: String) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = AudioManager.ambil_volume(bus)
	s.custom_minimum_size = Vector2(160, 16)
	s.value_changed.connect(func(v: float) -> void: AudioManager.atur_volume(bus, v))
	return s


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("jeda"):
		return
	if _akar.visible:
		tutup()
	elif (GameState.sedang(GameState.State.BERMAIN) or GameState.sedang(GameState.State.MINIGAME)) and not Transisi.sedang_transisi():
		buka()
	get_viewport().set_input_as_handled()


func buka() -> void:
	_state_sebelum = GameState.state
	if not GameState.ubah_state(GameState.State.JEDA):
		return
	_isi_kartu()
	_akar.visible = true
	get_tree().paused = true
	_tombol_lanjut.grab_focus()


func tutup() -> void:
	_akar.visible = false
	get_tree().paused = false
	GameState.ubah_state(_state_sebelum)


func _ke_menu() -> void:
	_akar.visible = false
	GameState.ubah_state(GameState.State.MENU)
	Transisi.pindah_scene("res://scenes/main_menu.tscn")


func _isi_kartu() -> void:
	var teks: String = "[color=#c9c2b0]%d dari %d kartu terkumpul[/color]\n\n" % [GameState.kartu_terkumpul.size(), GameState.jumlah_kartu_total()]
	for k: Dictionary in GameState.semua_kartu():
		if GameState.kartu_terkumpul.has(k["id"]):
			var isi: Array = k["isi"]
			teks += "[b][color=#e8b430]%s[/color][/b]\n%s\n\n" % [k["judul"], " ".join(PackedStringArray(isi))]
		else:
			teks += "[b][color=#6b6560]??? (belum ditemukan)[/color][/b]\n\n"
	_panel_kartu.text = teks
