extends StatePemain


func masuk(_data: Dictionary) -> void:
	pemain.model.mode = "udara"


func physics_update(delta: float) -> void:
	pemain.terapkan_gravitasi(delta)
	var arah: Vector3 = pemain.arah_input()
	pemain.gerak_horizontal(delta, arah)
	var kecepatan_jatuh: float = pemain.velocity.y
	pemain.move_and_slide()
	if pemain.ingin_lompat():
		mesin.ganti("Lompat")
	elif pemain.is_on_floor():
		# Squash saat mendarat, makin keras jika jatuh makin cepat
		var kuat: float = clampf(-kecepatan_jatuh / 20.0, 0.05, 0.3)
		pemain.model.squash(Vector3(1.0 + kuat, 1.0 - kuat, 1.0 + kuat))
		AudioManager.putar_sfx("langkah")
		mesin.ganti("Jalan" if arah != Vector3.ZERO else "Idle")
