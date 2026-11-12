extends CanvasLayer
## HUD kampung: tujuan saat ini, jumlah kartu budaya, dan petunjuk kontrol.

var _label_tujuan: Label
var _label_kartu: Label


func _ready() -> void:
	layer = 10
	var panel := Gaya.panel_songke(Vector2(8, 8), Vector2(420, 58))
	add_child(panel)
	_label_tujuan = Gaya.label("", 10, Gaya.PUTIH)
	_label_tujuan.position = Vector2(12, 9)
	_label_tujuan.size = Vector2(400, 28)
	_label_tujuan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_label_tujuan)
	_label_kartu = Gaya.label("", 10, Gaya.KUNING)
	_label_kartu.position = Vector2(12, 38)
	panel.add_child(_label_kartu)
	var kontrol := Gaya.label("WASD: jalan  Spasi: lompat  E: interaksi  Esc: jeda", 8, Gaya.PUTIH)
	kontrol.position = Vector2(8, 344)
	add_child(kontrol)
	GameState.progres_berubah.connect(_perbarui)
	GameState.state_berubah.connect(func(_l: int, baru: int) -> void: visible = baru != GameState.State.DIALOG)
	_perbarui()


func _perbarui() -> void:
	_label_tujuan.text = "Petunjuk: " + GameState.teks_tujuan()
	_label_kartu.text = "Kartu Budaya: %d/%d" % [GameState.kartu_terkumpul.size(), GameState.jumlah_kartu_total()]
