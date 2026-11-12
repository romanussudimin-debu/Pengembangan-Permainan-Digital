extends StatePemain

var _sudah_dipotong: bool = false


func masuk(_data: Dictionary) -> void:
	_sudah_dipotong = false
	pemain.lompat()
	pemain.model.mode = "udara"


func physics_update(delta: float) -> void:
	pemain.terapkan_gravitasi(delta)
	# Tinggi lompatan variabel: lepas tombol lebih awal = lompatan lebih rendah
	if not _sudah_dipotong and not Input.is_action_pressed("lompat") and pemain.velocity.y > 0.0:
		pemain.velocity.y *= 0.5
		_sudah_dipotong = true
	pemain.gerak_horizontal(delta, pemain.arah_input())
	pemain.move_and_slide()
	if pemain.velocity.y <= 0.0:
		mesin.ganti("Jatuh")
