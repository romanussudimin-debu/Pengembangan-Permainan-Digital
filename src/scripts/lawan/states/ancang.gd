extends StateLawan
## Anticipation: lawan menarik larik ke belakang. Ini isyarat bagi pemain untuk menangkis.

var _durasi: float = 1.0
var _tipuan: bool = false


func mulai_state(data: Dictionary) -> void:
	_durasi = data.get("durasi", 1.0)
	_tipuan = data.get("tipuan", false)
	lawan.model.ancang(_durasi)
	lawan.isyarat.visible = true
	lawan.isyarat.modulate = Color("e8b430")
	AudioManager.putar_sfx("klik")


func proses(_delta: float) -> void:
	# Isyarat berubah merah menjelang pukulan
	if waktu > _durasi * 0.6:
		lawan.isyarat.modulate = Color("e04040")
	if waktu < _durasi:
		return
	if _tipuan:
		lawan.model.batal_aksi()
		lawan.isyarat.visible = false
		mesin.ganti("Siaga")
		lawan.serangan_selesai.emit()
	else:
		mesin.ganti("Serang")
