class_name BosRaksasa
extends CharacterBody3D
## Ditya Kalamurka — bos raksasa Level 1.
## Fase 1 memiliki SATU pola serangan: "Hantaman Bumi".
##
##   MUNCUL (bangkit dari tanah, kebal)
##     -> MENGEJAR (berjalan pelan mendekati pemain)
##     -> ANCANG_HANTAM (kedua lengan terangkat, lingkaran merah di tanah membesar)
##     -> HANTAM (lengan menghantam tanah; pemain di dalam lingkaran & tidak melompat terkena)
##     -> PULIH (terengah, celah terbaik untuk menyerang)
##     -> MENGEJAR ...
##   HP habis -> MATI
##
## Bos tidak terhuyung saat dipukul (super armor), hanya berkilat.

signal hp_berubah(hp: int, hp_maks: int)
signal kalah

enum State { MUNCUL, MENGEJAR, ANCANG_HANTAM, HANTAM, PULIH, MATI }

@export var nama_tampilan: String = "Ditya Kalamurka"

@export_group("Nyawa")
@export var hp_maks: int = 500

@export_group("Gerak")
@export var kecepatan: float = 2.4
@export var kecepatan_putar: float = 3.0
@export var waktu_muncul: float = 1.8

@export_group("Hantaman Bumi")
## Bos mulai ancang-ancang bila pemain sedekat ini.
@export var jarak_pemicu_hantam: float = 5.5
@export var radius_hantaman: float = 6.5
@export var damage_hantaman: int = 30
@export var waktu_ancang: float = 1.2
@export var waktu_pulih: float = 1.6
@export var kekuatan_dorong: float = 11.0
## Pemain yang sedang melompat setinggi ini (meter) lolos dari hantaman.
@export var tinggi_lolos_lompat: float = 0.5

@onready var model: Node3D = $Model
@onready var komponen_hp: KomponenHP = $KomponenHP
@onready var penanda_hantam: MeshInstance3D = $PenandaHantam
@onready var _lengan_kanan: Node3D = get_node_or_null("Model/LenganKanan")
@onready var _lengan_kiri: Node3D = get_node_or_null("Model/LenganKiri")
@onready var _kaki_kanan: Node3D = get_node_or_null("Model/KakiKanan")
@onready var _kaki_kiri: Node3D = get_node_or_null("Model/KakiKiri")

var state: State = State.MUNCUL
var _gravitasi: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _waktu_state: float = 0.0
var _target: Pemain
var _fase_langkah: float = 0.0
var _bahan_penanda: StandardMaterial3D


func _ready() -> void:
	add_to_group("bos")
	add_to_group("musuh")
	komponen_hp.hp_berubah.connect(func(h: int, m: int) -> void: hp_berubah.emit(h, m))
	komponen_hp.habis.connect(_saat_mati)
	komponen_hp.inisialisasi(hp_maks)
	# Arah hadap awal dipindah ke node Model (akar tetap tanpa rotasi).
	model.rotation.y += rotation.y
	rotation.y = 0.0
	penanda_hantam.visible = false
	_bahan_penanda = penanda_hantam.get_active_material(0) as StandardMaterial3D
	# Animasi bangkit dari bumi.
	model.position.y = -6.0
	var t := create_tween()
	t.tween_property(model, "position:y", 0.0, waktu_muncul).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravitasi * delta
	_waktu_state += delta
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("pemain") as Pemain
	var bermain := GameManager.sedang_bermain() and _target != null \
			and _target.state != Pemain.State.MATI

	match state:
		State.MUNCUL:
			_rem(delta)
			if _waktu_state >= waktu_muncul:
				_ganti_state(State.MENGEJAR)
		State.MENGEJAR:
			if not bermain:
				_rem(delta)
			else:
				var arah := _arah_ke_target()
				_hadap_ke(arah, delta)
				if _jarak_datar_ke_target() <= jarak_pemicu_hantam:
					_mulai_ancang()
				else:
					velocity.x = arah.x * kecepatan
					velocity.z = arah.z * kecepatan
		State.ANCANG_HANTAM:
			_rem(delta)
			# Lingkaran peringatan membesar mengikuti sisa waktu ancang-ancang.
			var k := clampf(_waktu_state / waktu_ancang, 0.0, 1.0)
			penanda_hantam.scale = Vector3(lerpf(0.2, 1.0, k), 1.0, lerpf(0.2, 1.0, k))
			if _bahan_penanda:
				_bahan_penanda.albedo_color.a = 0.25 + 0.35 * absf(sin(_waktu_state * 12.0))
			if _waktu_state >= waktu_ancang:
				_hantam()
		State.HANTAM:
			_rem(delta)
			if _waktu_state >= 0.25:
				_ganti_state(State.PULIH)
		State.PULIH:
			_rem(delta)
			if _waktu_state >= waktu_pulih:
				_ganti_state(State.MENGEJAR)
		State.MATI:
			_rem(delta)

	move_and_slide()
	_animasi_langkah(delta)


## Dipanggil hitbox pemain. Bos tidak terpental (super armor).
func terima_serangan(jumlah: int, _arah_dorong: Vector3, _kekuatan: float = 0.0) -> void:
	if state == State.MUNCUL or state == State.MATI:
		return
	if komponen_hp.kurangi(jumlah):
		EfekVisual.kilat_kena(model)


# ---------------------------------------------------------------- pola serangan

func _mulai_ancang() -> void:
	_ganti_state(State.ANCANG_HANTAM)
	penanda_hantam.visible = true
	penanda_hantam.scale = Vector3(0.2, 1.0, 0.2)
	var t := create_tween().set_parallel(true)
	if _lengan_kanan:
		t.tween_property(_lengan_kanan, "rotation:x", 3.1, waktu_ancang * 0.7)
	if _lengan_kiri:
		t.tween_property(_lengan_kiri, "rotation:x", 3.1, waktu_ancang * 0.7)


func _hantam() -> void:
	_ganti_state(State.HANTAM)
	penanda_hantam.visible = false
	var t := create_tween().set_parallel(true)
	if _lengan_kanan:
		t.tween_property(_lengan_kanan, "rotation:x", 0.6, 0.12).set_ease(Tween.EASE_IN)
	if _lengan_kiri:
		t.tween_property(_lengan_kiri, "rotation:x", 0.6, 0.12).set_ease(Tween.EASE_IN)
	t.chain().tween_interval(waktu_pulih * 0.6)
	if _lengan_kanan:
		t.chain().tween_property(_lengan_kanan, "rotation:x", 0.0, 0.4)
	if _lengan_kiri:
		t.parallel().tween_property(_lengan_kiri, "rotation:x", 0.0, 0.4)

	EfekVisual.gelombang_debu(get_parent(), global_position, radius_hantaman, Color(0.72, 0.6, 0.42, 0.8))
	if _target:
		_target.kamera_rig.guncang(0.25, 0.4)
		var d := _target.global_position - global_position
		var tinggi := d.y
		d.y = 0.0
		var di_udara := _target.sedang_di_udara() and tinggi >= tinggi_lolos_lompat
		if d.length() <= radius_hantaman and not di_udara:
			_target.terima_serangan(damage_hantaman, d.normalized(), kekuatan_dorong)


func _saat_mati() -> void:
	_ganti_state(State.MATI)
	penanda_hantam.visible = false
	remove_from_group("musuh")
	collision_layer = 0
	kalah.emit()
	GameManager.lapor_bos_kalah()
	var t := create_tween()
	t.tween_property(model, "rotation:x", deg_to_rad(-88.0), 1.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- utilitas

func _ganti_state(baru: State) -> void:
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


func _rem(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)


func _hadap_ke(arah: Vector3, delta: float) -> void:
	var sudut := atan2(-arah.x, -arah.z)
	model.rotation.y = lerp_angle(model.rotation.y, sudut, clampf(kecepatan_putar * delta, 0.0, 1.0))


func _animasi_langkah(delta: float) -> void:
	if state != State.MENGEJAR:
		return
	var laju_datar := Vector2(velocity.x, velocity.z).length()
	if laju_datar < 0.2:
		return
	_fase_langkah += delta * laju_datar * 1.6
	var ayun := sin(_fase_langkah) * 0.45
	if _kaki_kanan:
		_kaki_kanan.rotation.x = ayun
	if _kaki_kiri:
		_kaki_kiri.rotation.x = -ayun
	if _lengan_kanan:
		_lengan_kanan.rotation.x = -ayun * 0.6
	if _lengan_kiri:
		_lengan_kiri.rotation.x = ayun * 0.6
