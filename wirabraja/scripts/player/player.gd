class_name Pemain
extends CharacterBody3D
## Raden Wirabraja — ksatria yang dikendalikan pemain.
## Kontrol: WASD gerak (relatif kamera), Shift lari, Spasi lompat, klik kiri serang.
##
## State machine pemain:
##   NORMAL -> MENYERANG (klik kiri) -> NORMAL
##   NORMAL/MENYERANG -> TERKENA (diserang) -> NORMAL
##   apa pun -> MATI (HP habis)
##
## Model placeholder ada di node "Model". Untuk mengganti dengan model asli,
## ganti isi node Model; node LenganKanan/LenganKiri/KakiKanan/KakiKiri bersifat
## opsional (animasi prosedural hanya berjalan bila node tersebut ada).

signal hp_berubah(hp: int, hp_maks: int)

enum State { NORMAL, MENYERANG, TERKENA, MATI }

@export_group("Gerak")
## Kecepatan jalan ksatria (m/detik)
@export var kecepatan: float = 5.0
## Kecepatan saat menahan Shift (m/detik)
@export var kecepatan_lari: float = 8.5
@export var kekuatan_lompat: float = 6.5
@export var percepatan: float = 45.0
@export var kecepatan_putar: float = 12.0

@export_group("Nyawa")
@export var hp_maks: int = 100
## Lama kebal setelah terkena serangan (detik)
@export var waktu_kebal: float = 0.7
@export var lama_terhuyung: float = 0.25

@export_group("Serangan")
@export var damage: int = 25
@export var durasi_serangan: float = 0.42
## Jendela waktu hitbox aktif, dihitung dari awal ayunan (detik)
@export var awal_hitbox: float = 0.10
@export var akhir_hitbox: float = 0.26
@export var dorongan_ke_musuh: float = 7.0
@export var langkah_maju_serangan: float = 3.0

@onready var model: Node3D = $Model
@onready var hitbox: Area3D = $Model/Hitbox
@onready var kamera_rig: KameraOrbit = $KameraRig
@onready var komponen_hp: KomponenHP = $KomponenHP
@onready var _lengan_kanan: Node3D = get_node_or_null("Model/LenganKanan")
@onready var _lengan_kiri: Node3D = get_node_or_null("Model/LenganKiri")
@onready var _kaki_kanan: Node3D = get_node_or_null("Model/KakiKanan")
@onready var _kaki_kiri: Node3D = get_node_or_null("Model/KakiKiri")

var state: State = State.NORMAL
var _gravitasi: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _waktu_state: float = 0.0
var _sisa_kebal: float = 0.0
var _minta_serang: bool = false
var _sudah_kena: Array[Node] = []
var _fase_langkah: float = 0.0
var _tween_lengan: Tween


func _ready() -> void:
	add_to_group("pemain")
	komponen_hp.hp_berubah.connect(func(h: int, m: int) -> void: hp_berubah.emit(h, m))
	komponen_hp.habis.connect(_saat_mati)
	komponen_hp.inisialisasi(hp_maks)
	# Model menghadap arah awal node, lalu node akar dibuat tanpa rotasi
	# (rotasi hadap ditangani node Model, kamera ditangani KameraRig).
	model.rotation.y = rotation.y
	rotation.y = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("serang") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_minta_serang = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravitasi * delta
	_sisa_kebal = maxf(_sisa_kebal - delta, 0.0)
	_waktu_state += delta

	match state:
		State.NORMAL:
			_proses_gerak(delta, 1.0)
			if Input.is_action_just_pressed("lompat") and is_on_floor():
				velocity.y = kekuatan_lompat
				AudioManager.putar_sfx("lompat")
			if _minta_serang:
				_mulai_serang()
		State.MENYERANG:
			_proses_gerak(delta, 0.35)
			if _waktu_state >= awal_hitbox and _waktu_state <= akhir_hitbox:
				_periksa_hitbox()
			if _waktu_state >= durasi_serangan:
				_ganti_state(State.NORMAL)
		State.TERKENA:
			_rem(delta, 10.0)
			if _waktu_state >= lama_terhuyung:
				_ganti_state(State.NORMAL)
		State.MATI:
			_rem(delta, 8.0)

	_minta_serang = false
	move_and_slide()
	_animasi_langkah(delta)


## Dipanggil musuh/bos. `arah_dorong` adalah arah pemain terpental (tanpa komponen y).
func terima_serangan(jumlah: int, arah_dorong: Vector3, kekuatan_dorong: float = 6.0) -> void:
	if state == State.MATI or _sisa_kebal > 0.0 or not GameManager.sedang_bermain():
		return
	if not komponen_hp.kurangi(jumlah):
		return
	_sisa_kebal = waktu_kebal
	EfekVisual.kilat_kena(model)
	AudioManager.putar_sfx("kena")
	var dorong := arah_dorong
	dorong.y = 0.0
	velocity = dorong.normalized() * kekuatan_dorong + Vector3.UP * 2.5
	if state != State.MATI:
		_ganti_state(State.TERKENA)


func sedang_di_udara() -> bool:
	return not is_on_floor()


# ---------------------------------------------------------------- gerak

func _proses_gerak(delta: float, pengali: float) -> void:
	var masukan := Input.get_vector("kiri", "kanan", "maju", "mundur")
	var arah := Vector3(masukan.x, 0.0, masukan.y).rotated(Vector3.UP, kamera_rig.ambil_yaw())
	var laju := kecepatan_lari if Input.is_action_pressed("lari") else kecepatan
	var target := arah * laju * pengali
	velocity.x = move_toward(velocity.x, target.x, percepatan * delta)
	velocity.z = move_toward(velocity.z, target.z, percepatan * delta)
	if arah.length_squared() > 0.01 and state == State.NORMAL:
		_hadap_ke(arah, delta)


func _rem(delta: float, gesekan: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, gesekan * delta)
	velocity.z = move_toward(velocity.z, 0.0, gesekan * delta)


func _hadap_ke(arah: Vector3, delta: float) -> void:
	# Model menghadap -Z (konvensi Godot).
	var sudut := atan2(-arah.x, -arah.z)
	model.rotation.y = lerp_angle(model.rotation.y, sudut, clampf(kecepatan_putar * delta, 0.0, 1.0))


func _arah_hadap() -> Vector3:
	return -model.global_basis.z.normalized()


# ---------------------------------------------------------------- serangan

func _mulai_serang() -> void:
	_ganti_state(State.MENYERANG)
	_sudah_kena.clear()
	# Ayunkan ke arah gerak kamera bila pemain menekan arah, agar serangan terasa responsif.
	var masukan := Input.get_vector("kiri", "kanan", "maju", "mundur")
	if masukan.length_squared() > 0.01:
		var arah := Vector3(masukan.x, 0.0, masukan.y).rotated(Vector3.UP, kamera_rig.ambil_yaw())
		model.rotation.y = atan2(-arah.x, -arah.z)
	var maju := _arah_hadap() * langkah_maju_serangan
	velocity.x = maju.x
	velocity.z = maju.z
	_animasi_ayunan()
	AudioManager.putar_sfx("ayun")


func _periksa_hitbox() -> void:
	for tubuh: Node3D in hitbox.get_overlapping_bodies():
		if tubuh == self or tubuh in _sudah_kena:
			continue
		if tubuh.has_method("terima_serangan"):
			_sudah_kena.append(tubuh)
			var arah := tubuh.global_position - global_position
			arah.y = 0.0
			tubuh.call("terima_serangan", damage, arah.normalized(), dorongan_ke_musuh)


func _saat_mati() -> void:
	_ganti_state(State.MATI)
	# Ksatria rebah ke belakang.
	var t := create_tween()
	t.tween_property(model, "rotation:x", deg_to_rad(80.0), 0.6).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(model, "position:y", 0.35, 0.6)
	GameManager.lapor_pemain_kalah()


func _ganti_state(baru: State) -> void:
	state = baru
	_waktu_state = 0.0


# ---------------------------------------------------------------- animasi prosedural

func _animasi_ayunan() -> void:
	if _lengan_kanan == null:
		return
	if _tween_lengan and _tween_lengan.is_valid():
		_tween_lengan.kill()
	_tween_lengan = create_tween()
	# Angkat gada ke atas kepala, hantamkan ke depan, lalu kembali.
	_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 3.3, awal_hitbox * 0.9)
	_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 1.0, akhir_hitbox - awal_hitbox) \
			.set_ease(Tween.EASE_IN)
	_tween_lengan.tween_property(_lengan_kanan, "rotation:x", 0.0, durasi_serangan - akhir_hitbox)


func _animasi_langkah(delta: float) -> void:
	var laju_datar := Vector2(velocity.x, velocity.z).length()
	var bergerak := is_on_floor() and laju_datar > 0.3 and state != State.MATI
	if bergerak:
		var fase_lama := _fase_langkah
		_fase_langkah += delta * laju_datar * 2.2
		# Bunyi langkah setiap kali kaki menapak (sinus melewati nol).
		if floori(fase_lama / PI) != floori(_fase_langkah / PI):
			AudioManager.putar_sfx("langkah")
	else:
		_fase_langkah = lerpf(_fase_langkah, roundf(_fase_langkah / PI) * PI, 10.0 * delta)
	var ayun := sin(_fase_langkah) * clampf(laju_datar / kecepatan_lari, 0.0, 1.0) * 0.8
	if _kaki_kanan:
		_kaki_kanan.rotation.x = ayun
	if _kaki_kiri:
		_kaki_kiri.rotation.x = -ayun
	if _lengan_kiri:
		_lengan_kiri.rotation.x = ayun * 0.8
	if _lengan_kanan and state == State.NORMAL and not (_tween_lengan and _tween_lengan.is_running()):
		_lengan_kanan.rotation.x = -ayun * 0.6
	# Di udara: kaki sedikit ditekuk.
	if not is_on_floor() and state != State.MATI:
		if _kaki_kanan:
			_kaki_kanan.rotation.x = 0.5
		if _kaki_kiri:
			_kaki_kiri.rotation.x = -0.2
