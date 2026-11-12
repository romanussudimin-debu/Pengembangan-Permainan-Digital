extends StatePemain


func masuk(_data: Dictionary) -> void:
	pemain.model.mode = "idle"


func physics_update(delta: float) -> void:
	pemain.terapkan_gravitasi(delta)
	var arah: Vector3 = pemain.arah_input()
	pemain.gerak_horizontal(delta, arah)
	pemain.move_and_slide()
	if pemain.ingin_lompat():
		mesin.ganti("Lompat")
	elif not pemain.is_on_floor():
		mesin.ganti("Jatuh")
	elif arah != Vector3.ZERO:
		mesin.ganti("Jalan")
