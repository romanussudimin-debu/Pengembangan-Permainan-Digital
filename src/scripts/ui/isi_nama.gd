class_name IsiNama
extends CanvasLayer
## Layar "Isi Nama": muncul saat pertama kali bermain dan bisa dibuka dari menu (Ganti Nama).
## 3-12 karakter, huruf/angka/spasi; tombol Mulai aktif hanya bila nama valid.
## Di Android keyboard virtual muncul saat kolom disentuh.

signal done(player_name: String)

var _edit: LineEdit
var _ok: Button
var _msg: Label
var _button_text: String = "Mulai"


static func open(parent: Node, button_text: String = "Mulai") -> IsiNama:
	var s := IsiNama.new()
	s._button_text = button_text
	parent.add_child(s)
	return s


func _ready() -> void:
	layer = 60
	var gelap := ColorRect.new()
	gelap.color = Color(0, 0, 0, 0.6)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gelap)
	var panel := Gaya.panel_songke(Vector2(150, 70), Vector2(340, 200))
	add_child(panel)
	var judul := Gaya.label("Isi Nama", 18, Gaya.KUNING)
	judul.position = Vector2(20, 12)
	panel.add_child(judul)
	var sub := Gaya.label("Tokohmu tetap Nggohak. Namamu tampil di atas kepala,\ndi lobi, dan di papan skor.", 9, Color("d8d2c4"))
	sub.position = Vector2(22, 42)
	panel.add_child(sub)
	_edit = LineEdit.new()
	_edit.position = Vector2(22, 80)
	_edit.size = Vector2(296, 34)
	_edit.max_length = PlayerProfile.MAX_LEN
	_edit.text = PlayerProfile.player_name
	_edit.placeholder_text = PlayerProfile.DEFAULT_NAME
	_edit.add_theme_font_size_override("font_size", 16)
	_edit.virtual_keyboard_enabled = true
	_edit.select_all_on_focus = true
	_edit.text_changed.connect(_check)
	_edit.text_submitted.connect(func(_t: String) -> void: _submit())
	panel.add_child(_edit)
	_msg = Gaya.label("", 10, Color("ff8a60"))
	_msg.position = Vector2(22, 118)
	panel.add_child(_msg)
	_ok = Gaya.tombol(_button_text)
	_ok.position = Vector2(90, 146)
	_ok.custom_minimum_size = Vector2(160, 34)
	_ok.pressed.connect(_submit)
	panel.add_child(_ok)
	_check(_edit.text)
	_edit.call_deferred("grab_focus")


func _check(t: String) -> void:
	var err: String = PlayerProfile.validate(t)
	_msg.text = err
	_ok.disabled = err != ""


func _submit() -> void:
	if not PlayerProfile.set_player_name(_edit.text):
		_check(_edit.text)
		return
	AudioManager.putar_sfx("benar")
	done.emit(PlayerProfile.player_name)
	queue_free()
