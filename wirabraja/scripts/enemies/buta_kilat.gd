class_name ButaKilat
extends Buta
## Buta Kilat — raksasa ramping yang lincah.
## Perilaku khas:
##   - Mendekat secara zig-zag sehingga sulit dibidik.
##   - Menyerang dengan TERJANGAN: ancang-ancang singkat (merunduk), lalu melesat
##     lurus beberapa meter. Pemain yang tersentuh selama terjangan terkena damage.
##   - Setelah terjangan ia terhenti sejenak (celah untuk membalas).

@export_group("Terjangan")
@export var kecepatan_terjang: float = 13.0
@export var jarak_kena_terjang: float = 1.7
@export var lebar_zigzag: float = 0.8
@export var frekuensi_zigzag: float = 4.0

var _terjang_mengenai: bool = false
var _arah_terjang: Vector3 = Vector3.FORWARD


func _proses_mengejar(delta: float) -> void:
	if not _bisa_mengejar(jarak_lepas):
		_ganti_state(State.DIAM)
		return
	var arah := _arah_ke_target()
	if _jarak_datar_ke_target() <= jarak_serang:
		_mulai_ancang()
		return
	# Gerak zig-zag: tambahkan komponen menyamping yang berayun.
	var samping := arah.cross(Vector3.UP)
	var ayun := sin(Time.get_ticks_msec() * 0.001 * frekuensi_zigzag + _fase_langkah) * lebar_zigzag
	var gerak := (arah + samping * ayun).normalized()
	velocity.x = gerak.x * kecepatan
	velocity.z = gerak.z * kecepatan
	_hadap_ke(arah, delta)


func _mulai_ancang() -> void:
	_ganti_state(State.ANCANG)
	# Merunduk sebagai tanda akan menerjang.
	var t := create_tween()
	t.tween_property(model, "rotation:x", deg_to_rad(25.0), waktu_ancang * 0.8)


func _lakukan_serangan() -> void:
	_terjang_mengenai = false
	_arah_terjang = _arah_ke_target()
	velocity.x = _arah_terjang.x * kecepatan_terjang
	velocity.z = _arah_terjang.z * kecepatan_terjang
	AudioManager.putar_sfx("terjang", global_position)
	var t := create_tween()
	t.tween_property(model, "rotation:x", deg_to_rad(-10.0), 0.12)
	t.tween_property(model, "rotation:x", 0.0, waktu_pulih * 0.6)


func _proses_pulih(_delta: float) -> void:
	# Selama terjangan masih cepat, sentuhan dengan pemain = kena.
	if _terjang_mengenai or _target == null:
		return
	if Vector2(velocity.x, velocity.z).length() < kecepatan_terjang * 0.35:
		return
	if _jarak_datar_ke_target() <= jarak_kena_terjang:
		_terjang_mengenai = true
		_target.terima_serangan(damage, _arah_terjang, kekuatan_dorong)
