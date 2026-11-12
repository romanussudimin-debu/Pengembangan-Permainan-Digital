extends StateLawan


func mulai_state(_data: Dictionary) -> void:
	lawan.model.tangkis(0.25)


func proses(_delta: float) -> void:
	if waktu >= 0.55:
		mesin.ganti("Siaga")
