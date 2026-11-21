class_name ButaPelempar
extends Buta
## Buta Pelempar — raksasa yang menyerang dari jarak jauh dengan melempar batu.
## Perilaku khas:
##   - Menjaga jarak: mundur bila pemain terlalu dekat, mendekat bila terlalu jauh,
##     dan bergeser menyamping bila jaraknya sudah pas.
##   - Ancang-ancang: mengangkat batu tinggi-tinggi, lalu melemparkannya dengan
##     lintasan melengkung ke arah posisi pemain (sedikit memperkirakan gerak pemain).

@export_group("Lemparan")
@export var scene_batu: PackedScene
@export var jarak_ideal_min: float = 8.0
@export var jarak_ideal_maks: float = 14.0
@export var jarak_lempar_maks: float = 20.0
@export var kecepatan_datar_batu: float = 13.0
@export var jeda_lempar: float = 2.2

var _sisa_jeda: float = 1.0
var _arah_geser: float = 1.0


func _physics_process(delta: float) -> void:
	_sisa_jeda = maxf(_sisa_jeda - delta, 0.0)
	super._physics_process(delta)


func _proses_mengejar(delta: float) -> void:
	if not _bisa_mengejar(jarak_lepas):
		_ganti_state(State.DIAM)
		return
	var arah := _arah_ke_target()
	var jarak := _jarak_datar_ke_target()
	var gerak := Vector3.ZERO
	if jarak < jarak_ideal_min:
		gerak = -arah                                  # mundur
	elif jarak > jarak_ideal_maks:
		gerak = arah                                   # mendekat
	else:
		if randf() < 0.01:
			_arah_geser = -_arah_geser
		gerak = arah.cross(Vector3.UP) * _arah_geser * 0.6   # bergeser menyamping
	velocity.x = gerak.x * kecepatan
	velocity.z = gerak.z * kecepatan
	_hadap_ke(arah, delta)
	if _sisa_jeda <= 0.0 and jarak <= jarak_lempar_maks:
		_mulai_ancang()


func _mulai_ancang() -> void:
	_ganti_state(State.ANCANG)
	if _lengan_kanan:
		_tween_lengan = create_tween()
		_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 3.4, waktu_ancang * 0.8)


func _lakukan_serangan() -> void:
	_sisa_jeda = jeda_lempar
	if _lengan_kanan:
		_tween_lengan = create_tween()
		_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 1.2, 0.1)
		_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 0.0, 0.5)
	if scene_batu == null or _target == null:
		return
	AudioManager.putar_sfx("lempar", global_position)
	var batu := scene_batu.instantiate() as BatuLempar
	get_parent().add_child(batu)
	var awal := global_position + Vector3.UP * 3.4 * model.scale.y + (-model.global_basis.z.normalized()) * 0.8
	# Perkiraan posisi pemain saat batu tiba.
	var jarak := Vector2(_target.global_position.x - awal.x, _target.global_position.z - awal.z).length()
	var waktu := clampf(jarak / kecepatan_datar_batu, 0.5, 1.6)
	var sasaran := _target.global_position + Vector3(_target.velocity.x, 0.0, _target.velocity.z) * waktu * 0.5
	sasaran.y += 0.8
	batu.luncurkan(awal, sasaran, waktu, damage)
