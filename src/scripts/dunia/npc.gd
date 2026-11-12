class_name NpcKampung
extends Node3D
## NPC kampung: model karakter + label nama + area interaksi.

signal diajak_bicara(npc: NpcKampung)

@export var nama: String = "Warga"
@export var tekstur_songke: Texture2D
@export var warna_baju: Color = Color("e8e2d2")
@export var warna_ikat: Color = Color("e8b430")
@export var pemain_caci: bool = false
@export var perempuan: bool = false
@export var bawa_nampan: bool = false

var model: KarakterModel
var area: Interaktif


func _ready() -> void:
	model = KarakterModel.new()
	if tekstur_songke:
		model.tekstur_songke = tekstur_songke
	model.warna_baju = warna_baju
	model.warna_ikat = warna_ikat
	model.telanjang_dada = pemain_caci
	model.pakai_panggal = pemain_caci
	model.bawa_senjata = pemain_caci
	model.perempuan = perempuan
	model.bawa_nampan = bawa_nampan
	add_child(model)
	Dunia.label_nama(self, nama, 3.6 if pemain_caci else 3.1)
	area = Interaktif.new()
	area.teks_petunjuk = "Bicara"
	area.tinggi_petunjuk = 3.9
	add_child(area)
	area.diinteraksi.connect(_saat_diinteraksi)


func _saat_diinteraksi(pemain: Pemain) -> void:
	# NPC menoleh ke pemain saat diajak bicara
	var arah: Vector3 = pemain.global_position - global_position
	var tw := create_tween()
	tw.tween_property(model, "rotation:y", atan2(-arah.x, -arah.z), 0.25).set_ease(Tween.EASE_OUT)
	diajak_bicara.emit(self)
