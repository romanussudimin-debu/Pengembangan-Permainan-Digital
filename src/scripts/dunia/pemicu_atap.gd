class_name PemicuAtap
extends Area3D
## Area di dalam Mbaru Niang: atap disembunyikan selama pemain berada di dalam rumah,
## sehingga kamera dapat melihat isi rumah (tampilan potong).

var atap: Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_saat_masuk)
	body_exited.connect(_saat_keluar)


func _saat_masuk(body: Node3D) -> void:
	if body.is_in_group("pemain") and atap:
		atap.visible = false


func _saat_keluar(body: Node3D) -> void:
	if body.is_in_group("pemain") and atap:
		atap.visible = true
