extends StatePenampil
## Anticipation: penampil menarik larik ke belakang sebelum memukul (isyarat bagi penangkis).

var _durasi: float = 1.0
var _tipuan: bool = false


func mulai_state(data: Dictionary) -> void:
	_durasi = data.get("durasi", 1.0)
	_tipuan = data.get("tipuan", false)
	penampil.model.ancang(_durasi)
	penampil.isyarat.visible = true
	penampil.isyarat.modulate = Color("e8b430")
	AudioManager.putar_sfx("klik")


func proses(_delta: float) -> void:
	# Isyarat berubah merah menjelang pukulan
	if waktu > _durasi * 0.6:
		penampil.isyarat.modulate = Color("e04040")
	if waktu < _durasi:
		return
	if _tipuan:
		penampil.model.batal_aksi()
		penampil.isyarat.visible = false
		mesin.ganti("Siaga")
		penampil.serangan_selesai.emit()
	else:
		mesin.ganti("Serang")
