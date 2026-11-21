class_name ButaGempal
extends Buta
## Buta Gempal — raksasa besar yang lambat tetapi sangat kuat.
## Perilaku khas:
##   - Tidak terhuyung saat dipukul (super armor) dan nyaris tidak terdorong.
##   - Serangan INJAK BUMI: ancang-ancang panjang (lengan terangkat tinggi), lalu
##     menghantam tanah dan melukai pemain di sekelilingnya (360°).

@export_group("Injak Bumi")
@export var radius_injak: float = 3.6


func _ready() -> void:
	tahan_terhuyung = true
	super._ready()


func _lakukan_serangan() -> void:
	_animasi_pukul()
	AudioManager.putar_sfx("injak", global_position)
	EfekVisual.gelombang_debu(get_parent(), global_position, radius_injak, Color(0.7, 0.58, 0.4, 0.7))
	if _target == null:
		return
	var d := _target.global_position - global_position
	var tinggi := d.y
	d.y = 0.0
	if d.length() <= radius_injak and tinggi < 0.6:
		_target.terima_serangan(damage, d.normalized(), kekuatan_dorong)
		_target.kamera_rig.guncang(0.12, 0.25)
