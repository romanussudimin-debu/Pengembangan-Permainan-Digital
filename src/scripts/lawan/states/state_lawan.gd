class_name StateLawan
extends StateDasar
## Dasar state lawan caci dengan pewaktu internal (ikut berhenti saat game dijeda).

var waktu: float = 0.0

var lawan: LawanCaci:
	get:
		return pemilik as LawanCaci


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
