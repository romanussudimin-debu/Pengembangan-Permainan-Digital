class_name StatePenampil
extends StateDasar
## Dasar state penampil caci dengan pewaktu internal (ikut berhenti saat game dijeda).

var waktu: float = 0.0

var penampil: PenampilCaci:
	get:
		return pemilik as PenampilCaci


func update(delta: float) -> void:
	waktu += delta
	proses(delta)


func masuk(data: Dictionary) -> void:
	waktu = 0.0
	mulai_state(data)


func mulai_state(_data: Dictionary) -> void:
	pass


func proses(_delta: float) -> void:
	pass
