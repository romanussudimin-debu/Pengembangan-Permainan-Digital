class_name Buta
extends CharacterBody3D
## Buta Prajurit — raksasa jahat dengan AI sederhana berbasis state machine.
##
##   DIAM ──(pemain dalam jarak deteksi)──> MENGEJAR
##   MENGEJAR ──(pemain dalam jarak serang)──> ANCANG (ancang-ancang, tanda bagi pemain)
##   ANCANG ──(waktu habis, serangan dicek)──> PULIH ──> MENGEJAR
##   (state apa pun kecuali MATI) ──(terkena serangan)──> TERKENA ──> MENGEJAR
##   (HP habis) ──> MATI (rebah, lapor ke GameManager, lalu dihapus)
##
## Skrip ini sengaja dibuat umum (semua nilai @export) agar varian buta lain
## pada fase berikutnya cukup mewarisi kelas ini.

signal kalah

enum State { DIAM, MENGEJAR, ANCANG, PULIH, TERKENA, MATI }

@export_group("Nyawa")
@export var hp_maks: int = 75

@export_group("Gerak")
@export var kecepatan: float = 3.2
@export var kecepatan_putar: float = 6.0
@export var jarak_deteksi: float = 20.0
## Bila pemain sudah terdeteksi, buta terus mengejar sampai jarak ini.
@export var jarak_lepas: float = 35.0

@export_group("Serangan")
@export var damage: int = 10
@export var jarak_serang: float = 2.2
@export var waktu_ancang: float = 0.55
@export var waktu_pulih: float = 0.8
@export var kekuatan_dorong: float = 6.0

@export_group("Reaksi")
@export var lama_terhuyung: float = 0.35
## 0 = mudah terpental, 1 = tidak terpental sama sekali.
@export_range(0.0, 1.0) var ketahanan_dorong: float = 0.2

@onready var model: Node3D = $Model
@onready var komponen_hp: KomponenHP = $KomponenHP
@onready var _lengan_kanan: Node3D = get_node_or_null("Model/LenganKanan")
@onready var _lengan_kiri: Node3D = get_node_or_null("Model/LenganKiri")
@onready var _kaki_kanan: Node3D = get_node_or_null("Model/KakiKanan")
@onready var _kaki_kiri: Node3D = get_node_or_null("Model/KakiKiri")

var state: State = State.DIAM
var _gravitasi: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _waktu_state: float = 0.0
var _target: Pemain
var _fase_langkah: float = 0.0
var _tween_lengan: Tween


func _ready() -> void:
	add_to_group("buta")
	add_to_group("musuh")
	komponen_hp.habis.connect(_saat_mati)
	komponen_hp.inisialisasi(hp_maks)
	# Arah hadap awal dipindah ke node Model (akar tetap tanpa rotasi).
	model.rotation.y += rotation.y
	rotation.y = 0.0
	_fase_langkah = randf() * TAU  # agar langkah antar-buta tidak serempak


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravitasi * delta
	_waktu_state += delta
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("pemain") as Pemain

	# Bila permainan selesai (menang/kalah), buta berhenti menyerang.
	if not GameManager.sedang_bermain() and state != State.MATI:
		if state != State.DIAM:
			_ganti_state(State.DIAM)

	match state:
		State.DIAM:
			_rem(delta, 20.0)
			if _bisa_mengejar(jarak_deteksi):
				_ganti_state(State.MENGEJAR)
		State.MENGEJAR:
			_proses_mengejar(delta)
		State.ANCANG:
			_rem(delta, 20.0)
			_hadap_ke(_arah_ke_target(), delta)
			if _waktu_state >= waktu_ancang:
				_lakukan_serangan()
				_ganti_state(State.PULIH)
		State.PULIH:
			_rem(delta, 20.0)
			if _waktu_state >= waktu_pulih:
				_ganti_state(State.MENGEJAR)
		State.TERKENA:
			_rem(delta, 14.0)
			if _waktu_state >= lama_terhuyung:
				_ganti_state(State.MENGEJAR)
		State.MATI:
			_rem(delta, 14.0)

	move_and_slide()
	_animasi(delta)


## Dipanggil hitbox pemain.
func terima_serangan(jumlah: int, arah_dorong: Vector3, kekuatan: float = 6.0) -> void:
	if state == State.MATI:
		return
	if not komponen_hp.kurangi(jumlah):
		return
	EfekVisual.kilat_kena(model)
	if komponen_hp.mati:
		velocity = arah_dorong * kekuatan * (1.0 - ketahanan_dorong)
		return
	velocity = arah_dorong * kekuatan * (1.0 - ketahanan_dorong)
	_ganti_state(State.TERKENA)


# ---------------------------------------------------------------- AI

func _bisa_mengejar(jarak_maks: float) -> bool:
	if _target == null or _target.state == Pemain.State.MATI or not GameManager.sedang_bermain():
		return false
	return _jarak_datar_ke_target() <= jarak_maks


func _proses_mengejar(delta: float) -> void:
	if not _bisa_mengejar(jarak_lepas):
		_ganti_state(State.DIAM)
		return
	var arah := _arah_ke_target()
	if _jarak_datar_ke_target() <= jarak_serang:
		_ganti_state(State.ANCANG)
		_animasi_ancang()
		return
	velocity.x = arah.x * kecepatan
	velocity.z = arah.z * kecepatan
	_hadap_ke(arah, delta)


func _lakukan_serangan() -> void:
	_animasi_pukul()
	if _target == null:
		return
	var ke_target := _target.global_position - global_position
	ke_target.y = 0.0
	var dalam_jangkauan := ke_target.length() <= jarak_serang + 0.6
	var di_depan := ke_target.normalized().dot(-model.global_basis.z) > 0.3
	if dalam_jangkauan and di_depan:
		_target.terima_serangan(damage, ke_target.normalized(), kekuatan_dorong)


func _saat_mati() -> void:
	_ganti_state(State.MATI)
	remove_from_group("musuh")
	# Matikan tabrakan agar tidak menghalangi pemain.
	collision_layer = 0
	collision_mask = 1
	kalah.emit()
	GameManager.lapor_buta_kalah()
	var t := create_tween()
	t.tween_property(model, "rotation:x", deg_to_rad(-85.0), 0.5).set_ease(Tween.EASE_IN)
	t.tween_interval(0.6)
	t.tween_property(model, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
	t.tween_callback(queue_free)


# ---------------------------------------------------------------- utilitas

func _ganti_state(baru: State) -> void:
	# Hentikan animasi lengan bila ancang-ancang terputus (mis. terkena serangan).
	if state == State.ANCANG and baru != State.PULIH and _tween_lengan and _tween_lengan.is_valid():
		_tween_lengan.kill()
	state = baru
	_waktu_state = 0.0


func _arah_ke_target() -> Vector3:
	if _target == null:
		return -model.global_basis.z
	var arah := _target.global_position - global_position
	arah.y = 0.0
	return arah.normalized() if arah.length_squared() > 0.0001 else -model.global_basis.z


func _jarak_datar_ke_target() -> float:
	if _target == null:
		return INF
	var d := _target.global_position - global_position
	d.y = 0.0
	return d.length()


func _rem(delta: float, gesekan: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, gesekan * delta)
	velocity.z = move_toward(velocity.z, 0.0, gesekan * delta)


func _hadap_ke(arah: Vector3, delta: float) -> void:
	var sudut := atan2(-arah.x, -arah.z)
	model.rotation.y = lerp_angle(model.rotation.y, sudut, clampf(kecepatan_putar * delta, 0.0, 1.0))


# ---------------------------------------------------------------- animasi prosedural

func _animasi_ancang() -> void:
	# Kedua lengan terangkat tinggi: tanda serangan akan datang.
	_tween_lengan = create_tween().set_parallel(true)
	if _lengan_kanan:
		_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 3.0, waktu_ancang * 0.8)
	if _lengan_kiri:
		_tween_lengan.tween_property(_lengan_kiri, "rotation:x", 2.6, waktu_ancang * 0.8)


func _animasi_pukul() -> void:
	if _tween_lengan and _tween_lengan.is_valid():
		_tween_lengan.kill()
	_tween_lengan = create_tween()
	if _lengan_kanan:
		_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 0.9, 0.1).set_ease(Tween.EASE_IN)
	if _lengan_kiri:
		_tween_lengan.parallel().tween_property(_lengan_kiri, "rotation:x", 0.7, 0.1)
	if _lengan_kanan:
		_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 0.0, waktu_pulih * 0.8)
	if _lengan_kiri:
		_tween_lengan.parallel().tween_property(_lengan_kiri, "rotation:x", 0.0, waktu_pulih * 0.8)


func _animasi(delta: float) -> void:
	if state == State.MATI or state == State.ANCANG or state == State.PULIH:
		return
	var laju_datar := Vector2(velocity.x, velocity.z).length()
	if laju_datar > 0.2:
		_fase_langkah += delta * laju_datar * 2.0
		var ayun := sin(_fase_langkah) * 0.6
		if _kaki_kanan:
			_kaki_kanan.rotation.x = ayun
		if _kaki_kiri:
			_kaki_kiri.rotation.x = -ayun
		if _lengan_kanan:
			_lengan_kanan.rotation.x = -ayun * 0.7
		if _lengan_kiri:
			_lengan_kiri.rotation.x = ayun * 0.7
		model.position.y = absf(sin(_fase_langkah)) * 0.08
	else:
		# Bernapas pelan saat diam.
		_fase_langkah += delta * 2.0
		model.position.y = sin(_fase_langkah) * 0.03
