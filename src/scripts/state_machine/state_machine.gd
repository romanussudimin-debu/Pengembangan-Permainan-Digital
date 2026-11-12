class_name StateMachine
extends Node
## Finite State Machine berbasis node yang dipakai ulang oleh pemain dan NPC.
## Setiap anak bertipe StateDasar adalah satu state; nama node = nama state.

signal state_berganti(dari: String, ke: String)

@export var state_awal: StateDasar

var state_aktif: StateDasar
var _states: Dictionary = {}


## Dipanggil oleh pemilik di _ready() setelah pemilik siap.
func mulai() -> void:
	for anak in get_children():
		if anak is StateDasar:
			var s: StateDasar = anak
			s.mesin = self
			s.pemilik = get_parent()
			_states[String(s.name).to_lower()] = s
	if state_awal:
		ganti(String(state_awal.name))


func ganti(nama: String, data: Dictionary = {}) -> void:
	var kunci: String = nama.to_lower()
	if not _states.has(kunci):
		push_error("State tidak ditemukan: " + nama)
		return
	var dari: String = ""
	if state_aktif:
		dari = String(state_aktif.name)
		state_aktif.keluar()
	state_aktif = _states[kunci]
	state_aktif.masuk(data)
	state_berganti.emit(dari, String(state_aktif.name))


func sedang(nama: String) -> bool:
	return state_aktif != null and String(state_aktif.name).to_lower() == nama.to_lower()


func _process(delta: float) -> void:
	if state_aktif:
		state_aktif.update(delta)


func _physics_process(delta: float) -> void:
	if state_aktif:
		state_aktif.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if state_aktif:
		state_aktif.handle_input(event)
