class_name PenampilCaci
extends Node3D
## Penampil caci (pertunjukan saat Penti) yang dikendalikan FSM: Siaga, Ancang, Serang, Tangkis, Terkena.
## Pengendali pertunjukan hanya memberi perintah; detail perilaku ada di tiap state.

signal pukulan_mendarat  ## momen cambuk penampil mengenai/ditangkis
signal serangan_selesai  ## satu siklus serangan (termasuk tipuan) selesai

@onready var model: KarakterModel = $Model
@onready var mesin: StateMachine = $StateMachine
@onready var isyarat: Label3D = $Isyarat

var nama: String = "Lawan"


func _ready() -> void:
	isyarat.visible = false
	mesin.mulai()


## Perintah menyerang: ancang-ancang selama `durasi`, lalu memukul (atau menipu).
func serang(durasi_ancang: float, tipuan: bool) -> void:
	mesin.ganti("Ancang", {"durasi": durasi_ancang, "tipuan": tipuan})


func tangkis() -> void:
	mesin.ganti("Tangkis")


func terkena() -> void:
	mesin.ganti("Terkena")
