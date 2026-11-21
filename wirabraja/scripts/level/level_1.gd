extends Node3D
## Level 1 — Alun-Alun Lor Keraton Kasunanan Surakarta.
## Menghitung buta yang ada di scene, memberi tahu GameManager, lalu
## memunculkan bos Ditya Kalamurka setelah semua buta dikalahkan.

@export var scene_bos: PackedScene
## Jeda (detik) antara buta terakhir kalah dan bos muncul.
@export var jeda_munculnya_bos: float = 2.0

@onready var _titik_bos: Marker3D = $TitikMunculBos
@onready var _hud: Hud = $HUD

var _bos_sudah_muncul: bool = false


func _ready() -> void:
	GameManager.state_berubah.connect(_saat_state_berubah)
	var jumlah_buta := get_tree().get_nodes_in_group("buta").size()
	GameManager.mulai_level(jumlah_buta)


func _saat_state_berubah(state_baru: GameManager.State) -> void:
	if state_baru == GameManager.State.BOS and not _bos_sudah_muncul:
		_bos_sudah_muncul = true
		_hud.tampilkan_pengumuman("Bumi bergetar... Ditya Kalamurka bangkit!")
		# Koneksi ke timer otomatis putus bila level dimuat ulang sebelum waktunya.
		get_tree().create_timer(jeda_munculnya_bos).timeout.connect(_munculkan_bos)


func _munculkan_bos() -> void:
	if scene_bos == null or not is_inside_tree():
		push_error("Level 1: scene_bos belum diisi.")
		return
	var bos := scene_bos.instantiate() as Node3D
	add_child(bos)
	bos.global_position = _titik_bos.global_position
	GameManager.lapor_bos_muncul(bos)
