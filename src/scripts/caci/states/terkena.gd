extends StatePenampil


func mulai_state(_data: Dictionary) -> void:
	penampil.model.terkena()


func proses(_delta: float) -> void:
	if waktu >= 0.6:
		mesin.ganti("Siaga")
