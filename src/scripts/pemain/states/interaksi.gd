extends StatePemain
## Pemain diam selama dialog / membaca kartu budaya.


func masuk(_data: Dictionary) -> void:
	pemain.model.mode = "idle"
	pemain.velocity.x = 0.0
	pemain.velocity.z = 0.0


func physics_update(delta: float) -> void:
	pemain.terapkan_gravitasi(delta)
	pemain.move_and_slide()
