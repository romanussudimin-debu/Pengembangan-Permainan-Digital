class_name NpcKampung
extends Node3D
## NPC kampung: model karakter + label nama + area interaksi.
## Bila `titik_patroli` diisi, NPC berjalan bergantian ke titik-titik itu (FSM DIAM/JALAN)
## sehingga pemain harus mencarinya. NPC berhenti selama dialog atau mini-game.

signal diajak_bicara(npc: NpcKampung)

@export var nama: String = "Warga"
@export var tekstur_songke: Texture2D
@export var warna_baju: Color = Color("e8e2d2")
@export var warna_ikat: Color = Color("e8b430")
@export var pemain_caci: bool = false
@export var perempuan: bool = false
@export var bawa_nampan: bool = false
@export var titik_patroli: Array[Vector3] = []  ## posisi dunia yang dikunjungi bergantian
@export var lama_diam_min: float = 4.0
@export var lama_diam_maks: float = 9.0
@export var kecepatan: float = 1.4

enum Perilaku { DIAM, JALAN }

var _perilaku: Perilaku = Perilaku.DIAM
var _indeks_tujuan: int = 0
var _sisa_diam: float = 0.0

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
	_sisa_diam = randf_range(lama_diam_min, lama_diam_maks)


func _process(delta: float) -> void:
	if titik_patroli.is_empty() or not GameState.sedang(GameState.State.BERMAIN):
		if _perilaku == Perilaku.JALAN:
			model.mode = _mode_berdiri()
		return
	match _perilaku:
		Perilaku.DIAM:
			_sisa_diam -= delta
			if _sisa_diam <= 0.0:
				_indeks_tujuan = (_indeks_tujuan + 1) % titik_patroli.size()
				_perilaku = Perilaku.JALAN
				model.mode = "jalan"
				model.kecepatan_jalan = 0.6
		Perilaku.JALAN:
			var arah: Vector3 = titik_patroli[_indeks_tujuan] - global_position
			arah.y = 0.0
			if arah.length() < 0.2:
				_perilaku = Perilaku.DIAM
				_sisa_diam = randf_range(lama_diam_min, lama_diam_maks)
				model.mode = _mode_berdiri()
				return
			global_position += arah.normalized() * minf(kecepatan * delta, arah.length())
			model.rotation.y = lerp_angle(model.rotation.y, atan2(-arah.x, -arah.z), delta * 8.0)
			if model.mode != "jalan":
				model.mode = "jalan"


func _mode_berdiri() -> String:
	return "siaga" if pemain_caci else "idle"


func _saat_diinteraksi(pemain: Pemain) -> void:
	# NPC menoleh ke pemain saat diajak bicara
	var arah: Vector3 = pemain.global_position - global_position
	var tw := create_tween()
	tw.tween_property(model, "rotation:y", atan2(-arah.x, -arah.z), 0.25).set_ease(Tween.EASE_OUT)
	diajak_bicara.emit(self)
