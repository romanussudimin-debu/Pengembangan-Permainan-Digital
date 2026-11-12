extends StatePenampil
## Pukulan + follow-through. Momen pukul diteruskan ke pengendali pertunjukan.

const LAMA_STATE: float = 0.7
var _sudah_selesai: bool = false


func mulai_state(_data: Dictionary) -> void:
	_sudah_selesai = false
	penampil.isyarat.visible = false
	penampil.model.momen_pukul.connect(_saat_momen_pukul, CONNECT_ONE_SHOT)
	penampil.model.lepas_pukulan()


func _saat_momen_pukul() -> void:
	penampil.pukulan_mendarat.emit()


func proses(_delta: float) -> void:
	if waktu >= LAMA_STATE and not _sudah_selesai:
		_sudah_selesai = true
		mesin.ganti("Siaga")
		penampil.serangan_selesai.emit()


func keluar() -> void:
	if penampil.model.momen_pukul.is_connected(_saat_momen_pukul):
		penampil.model.momen_pukul.disconnect(_saat_momen_pukul)
