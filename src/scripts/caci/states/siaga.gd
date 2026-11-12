extends StatePenampil
## Kuda-kuda: perisai di depan, cambuk siap.


func mulai_state(_data: Dictionary) -> void:
	penampil.model.mode = "siaga"
	penampil.isyarat.visible = false
