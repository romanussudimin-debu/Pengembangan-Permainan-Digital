class_name BatuLempar
extends Area3D
## Batu yang dilempar Buta Pelempar. Bergerak balistik (terpengaruh gravitasi).
## Mengenai pemain -> damage; menyentuh tanah/bangunan -> pecah.

@export var umur_maks: float = 4.0

var _kecepatan: Vector3 = Vector3.ZERO
var _damage: int = 12
var _gravitasi: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _umur: float = 0.0
var _selesai: bool = false


func _ready() -> void:
	body_entered.connect(_saat_menyentuh)


## Menghitung kecepatan awal agar batu tiba di `sasaran` setelah `waktu` detik.
func luncurkan(awal: Vector3, sasaran: Vector3, waktu: float, damage: int) -> void:
	global_position = awal
	_damage = damage
	var selisih := sasaran - awal
	_kecepatan = Vector3(selisih.x / waktu, (selisih.y + 0.5 * _gravitasi * waktu * waktu) / waktu, selisih.z / waktu)


func _physics_process(delta: float) -> void:
	if _selesai:
		return
	_umur += delta
	_kecepatan.y -= _gravitasi * delta
	global_position += _kecepatan * delta
	rotation += Vector3(6.0, 4.0, 0.0) * delta
	if global_position.y < 0.15 or _umur > umur_maks:
		_pecah()


func _saat_menyentuh(tubuh: Node3D) -> void:
	if _selesai:
		return
	if tubuh is Pemain:
		var arah := _kecepatan
		arah.y = 0.0
		(tubuh as Pemain).terima_serangan(_damage, arah.normalized(), 5.0)
	_pecah()


func _pecah() -> void:
	_selesai = true
	set_deferred("monitoring", false)
	AudioManager.putar_sfx("batu_jatuh", global_position)
	EfekVisual.gelombang_debu(get_parent(), Vector3(global_position.x, 0.0, global_position.z), 1.2,
			Color(0.55, 0.5, 0.45, 0.8))
	queue_free()
