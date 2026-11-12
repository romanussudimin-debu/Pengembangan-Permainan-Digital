class_name Interaktif
extends Area3D
## Area interaksi: jika pemain berada di dalamnya, muncul petunjuk "[E] ..." dan
## pemain dapat menekan tombol interaksi.

signal diinteraksi(pemain: Pemain)

@export var teks_petunjuk: String = "Bicara"
@export var jari_jari: float = 2.2
@export var tinggi_petunjuk: float = 2.7

var _petunjuk: Label3D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	var bentuk := SphereShape3D.new()
	bentuk.radius = jari_jari
	var c := CollisionShape3D.new()
	c.shape = bentuk
	c.position = Vector3(0, 1, 0)
	add_child(c)
	_petunjuk = Label3D.new()
	_petunjuk.text = "[E] " + teks_petunjuk
	_petunjuk.font_size = 40
	_petunjuk.pixel_size = 0.006
	_petunjuk.outline_size = 10
	_petunjuk.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_petunjuk.no_depth_test = true
	_petunjuk.position = Vector3(0, tinggi_petunjuk, 0)
	_petunjuk.visible = false
	add_child(_petunjuk)
	body_entered.connect(_saat_masuk)
	body_exited.connect(_saat_keluar)


func _saat_masuk(body: Node3D) -> void:
	if body is Pemain:
		var p: Pemain = body
		p.tambah_interaktif(self)


func _saat_keluar(body: Node3D) -> void:
	if body is Pemain:
		var p: Pemain = body
		p.hapus_interaktif(self)


## Dipanggil pemain: hanya objek terdekat yang menampilkan petunjuk.
func sorot(aktif: bool) -> void:
	_petunjuk.visible = aktif


func ubah_petunjuk(teks: String) -> void:
	teks_petunjuk = teks
	if _petunjuk:
		_petunjuk.text = "[E] " + teks


func interaksi(pemain: Pemain) -> void:
	diinteraksi.emit(pemain)
