extends StatePemain

const JEDA_LANGKAH: float = 0.32
var _timer_langkah: float = 0.0


func masuk(_data: Dictionary) -> void:
	pemain.model.mode = "jalan"
	_timer_langkah = 0.0


func physics_update(delta: float) -> void:
	pemain.terapkan_gravitasi(delta)
	var arah: Vector3 = pemain.arah_input()
	pemain.gerak_horizontal(delta, arah)
	pemain.move_and_slide()
	_timer_langkah -= delta
	if _timer_langkah <= 0.0:
		_timer_langkah = JEDA_LANGKAH
		AudioManager.putar_sfx("langkah", 0.15)
	if pemain.ingin_lompat():
		mesin.ganti("Lompat")
	elif not pemain.is_on_floor():
		mesin.ganti("Jatuh")
	elif arah == Vector3.ZERO and pemain.kecepatan_horizontal() < 0.2:
		mesin.ganti("Idle")
