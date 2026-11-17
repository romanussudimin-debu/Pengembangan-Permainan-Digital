extends Node
## Mendaftarkan Input Map lewat kode supaya pemetaan tombol terdokumentasi di satu tempat.

const PETA_INPUT: Dictionary = {
	"kiri": [KEY_A, KEY_LEFT],
	"kanan": [KEY_D, KEY_RIGHT],
	"maju": [KEY_W, KEY_UP],
	"mundur": [KEY_S, KEY_DOWN],
	"lompat": [KEY_SPACE],
	"interaksi": [KEY_E, KEY_ENTER],
	"tabuh_gong": [KEY_J, KEY_Z],
	"tabuh_gendang": [KEY_K, KEY_X],
	"ulang": [KEY_R],
	"jeda": [KEY_ESCAPE, KEY_P],
	# Tempur (E dipakai bersama "interaksi": di luar pertempuran = interaksi, saat bertempur = skill 2)
	"skill_1": [KEY_Q],
	"skill_2": [KEY_E],
	"skill_3": [KEY_R],
	"ultimate": [KEY_F],
}

## Aksi tombol mouse: klik kiri menembak, tahan klik kanan + geser untuk memutar kamera.
const PETA_MOUSE: Dictionary = {
	"shoot": [MOUSE_BUTTON_LEFT],
	"camera_rotate": [MOUSE_BUTTON_RIGHT],
}


func _ready() -> void:
	for aksi: String in PETA_INPUT:
		if not InputMap.has_action(aksi):
			InputMap.add_action(aksi)
		for kode: int in PETA_INPUT[aksi]:
			var ev := InputEventKey.new()
			ev.physical_keycode = kode
			InputMap.action_add_event(aksi, ev)
	for aksi: String in PETA_MOUSE:
		if not InputMap.has_action(aksi):
			InputMap.add_action(aksi)
		for tombol: int in PETA_MOUSE[aksi]:
			var ev := InputEventMouseButton.new()
			ev.button_index = tombol
			InputMap.action_add_event(aksi, ev)
