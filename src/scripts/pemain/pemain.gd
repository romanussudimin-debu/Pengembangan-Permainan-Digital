class_name Pemain
extends CharacterBody3D
## Pemain 3D (Nggohak). Logika gerak dipecah ke state: Idle, Jalan, Lompat, Jatuh, Interaksi.
## Perintah dibaca dari `input` (PlayerInput: keyboard/sentuh/bot/jaringan), bukan langsung dari Input,
## sehingga karakter yang sama bisa dikendalikan pemain lokal, bot, atau pemain lain di LAN.
## Komponen tempur (`combat`: HP, busur, respawn) aktif saat CombatManager.active.

@export var kecepatan: float = 5.0
@export var akselerasi: float = 30.0
@export var gesekan: float = 40.0
@export var kekuatan_lompat: float = 7.0
@export var gravitasi: float = 18.0
@export var gravitasi_jatuh: float = 26.0
@export var waktu_coyote: float = 0.12
@export var waktu_buffer_lompat: float = 0.12
@export var kecepatan_putar: float = 12.0

@onready var model: KarakterModel = $Model
@onready var mesin: StateMachine = $StateMachine

var input: PlayerInput  ## sumber perintah; default KeyboardInput (pemain lokal)
var combat: CombatPlayer
var interaktif_terdekat: Interaktif = null
var _dalam_jangkauan: Array[Interaktif] = []
var _sisa_coyote: float = 0.0
var _sisa_buffer: float = 0.0


func _ready() -> void:
	add_to_group("pemain")
	for anak in get_children():
		if anak is PlayerInput:
			input = anak
	if input == null:
		input = KeyboardInput.new()
		input.name = "Input"
		add_child(input)
	combat = CombatPlayer.new()
	combat.name = "Combat"
	add_child(combat)
	mesin.mulai()
	GameState.state_berubah.connect(_pada_state_game)


func _pada_state_game(_lama: int, baru: int) -> void:
	if baru == GameState.State.DIALOG:
		mesin.ganti("Interaksi")
	elif baru == GameState.State.BERMAIN and mesin.sedang("Interaksi"):
		mesin.ganti("Idle")


func boleh_bergerak() -> bool:
	return GameState.sedang(GameState.State.BERMAIN)


func _physics_process(delta: float) -> void:
	input.update_input(self, delta)
	if combat.is_dead:
		input.clear()
	# Coyote time & jump buffer membuat lompatan terasa responsif (lompat juga untuk menghindar)
	if is_on_floor():
		_sisa_coyote = waktu_coyote
	else:
		_sisa_coyote = maxf(_sisa_coyote - delta, 0.0)
	if boleh_bergerak() and input.jump_pressed:
		_sisa_buffer = waktu_buffer_lompat
	else:
		_sisa_buffer = maxf(_sisa_buffer - delta, 0.0)
	_perbarui_interaktif_terdekat()


func tambah_interaktif(objek: Interaktif) -> void:
	if not _dalam_jangkauan.has(objek):
		_dalam_jangkauan.append(objek)


func hapus_interaktif(objek: Interaktif) -> void:
	_dalam_jangkauan.erase(objek)
	objek.sorot(false)


## Memilih objek interaksi terdekat bila beberapa area tumpang-tindih.
func _perbarui_interaktif_terdekat() -> void:
	var terdekat: Interaktif = null
	var jarak_min: float = INF
	for objek in _dalam_jangkauan:
		if not is_instance_valid(objek):
			continue
		var jarak: float = global_position.distance_to(objek.global_position)
		if jarak < jarak_min:
			jarak_min = jarak
			terdekat = objek
	if terdekat != interaktif_terdekat:
		if interaktif_terdekat != null and is_instance_valid(interaktif_terdekat):
			interaktif_terdekat.sorot(false)
		interaktif_terdekat = terdekat
	if interaktif_terdekat != null:
		interaktif_terdekat.sorot(boleh_bergerak())


func _unhandled_input(event: InputEvent) -> void:
	# Saat bertempur tombol E dipakai skill, jadi interaksi dinonaktifkan
	if CombatManager.active or not input is KeyboardInput:
		return
	if event.is_action_pressed("interaksi") and boleh_bergerak() and interaktif_terdekat != null:
		get_viewport().set_input_as_handled()
		interaktif_terdekat.interaksi(self)


## Arah gerak di ruang dunia dari PlayerInput (sudah relatif terhadap arah kamera).
func arah_input() -> Vector3:
	if not boleh_bergerak() or combat.is_dead:
		return Vector3.ZERO
	return input.move_dir


func gerak_horizontal(delta: float, arah: Vector3) -> void:
	var target: Vector3 = arah * kecepatan * combat.status.speed_multiplier()
	var laju: float = akselerasi if arah != Vector3.ZERO else gesekan
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, laju * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	var hadap: Vector3 = arah
	if combat.aiming_time > 0.0:
		hadap = combat.aim_dir  # sedang menembak: badan menghadap arah bidik
	if hadap != Vector3.ZERO:
		var sudut: float = atan2(-hadap.x, -hadap.z)
		model.rotation.y = lerp_angle(model.rotation.y, sudut, kecepatan_putar * delta)
	model.kecepatan_jalan = clampf(horizontal.length() / kecepatan, 0.0, 1.0)


func terapkan_gravitasi(delta: float) -> void:
	var g: float = gravitasi_jatuh if velocity.y < 0.0 else gravitasi
	velocity.y = maxf(velocity.y - g * delta, -30.0)


func ingin_lompat() -> bool:
	return _sisa_buffer > 0.0 and _sisa_coyote > 0.0


func lompat() -> void:
	velocity.y = kekuatan_lompat
	_sisa_coyote = 0.0
	_sisa_buffer = 0.0
	AudioManager.putar_sfx("lompat", 0.1)
	model.squash(Vector3(0.85, 1.2, 0.85))


func kecepatan_horizontal() -> float:
	return Vector2(velocity.x, velocity.z).length()
