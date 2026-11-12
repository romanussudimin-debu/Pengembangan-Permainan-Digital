extends StateLawan
## Kuda-kuda: perisai di depan, cambuk siap.


func mulai_state(_data: Dictionary) -> void:
	lawan.model.mode = "siaga"
	lawan.isyarat.visible = false
