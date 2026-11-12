extends Node
## State game global (finite state machine tingkat game) + progres rantai teka-teki.

enum State { MENU, BERMAIN, DIALOG, JEDA, MINIGAME, SELESAI }

signal state_berubah(lama: int, baru: int)
signal progres_berubah

## Transisi yang diizinkan. Transisi lain ditolak agar state game selalu konsisten.
const TRANSISI_SAH: Dictionary = {
	State.MENU: [State.BERMAIN],
	State.BERMAIN: [State.DIALOG, State.JEDA, State.MINIGAME, State.SELESAI, State.MENU],
	State.DIALOG: [State.BERMAIN, State.MINIGAME],
	State.JEDA: [State.BERMAIN, State.MINIGAME, State.MENU],
	State.MINIGAME: [State.BERMAIN, State.JEDA, State.DIALOG, State.MENU],
	State.SELESAI: [State.MENU],
}

const DATA_KARTU: JSON = preload("res://data/kartu_budaya.json")
## Urutan warga pemegang kartu, tantangan, dan petunjuk ke warga berikutnya.
const DATA_RANTAI: JSON = preload("res://data/rantai_teka_teki.json")

var state: int = State.MENU

# --- Progres ---
var langkah_rantai: int = 0  ## indeks tantangan berikutnya di DATA_RANTAI
var kartu_terkumpul: Array[String] = []


func ubah_state(baru: int) -> bool:
	if baru == state:
		return true
	var sah: Array = TRANSISI_SAH[state]
	if not sah.has(baru):
		push_warning("Transisi state ditolak: %s -> %s" % [State.keys()[state], State.keys()[baru]])
		return false
	var lama: int = state
	state = baru
	state_berubah.emit(lama, baru)
	return true


func sedang(s: int) -> bool:
	return state == s


func reset_progres() -> void:
	langkah_rantai = 0
	kartu_terkumpul.clear()
	progres_berubah.emit()


# ------------------------------------------------------------- kartu

## Mengembalikan true jika kartu baru (belum pernah didapat).
func kumpulkan_kartu(id: String) -> bool:
	if kartu_terkumpul.has(id):
		return false
	kartu_terkumpul.append(id)
	progres_berubah.emit()
	return true


func semua_kartu() -> Array:
	return DATA_KARTU.data["kartu"]


func data_kartu(id: String) -> Dictionary:
	for k: Dictionary in semua_kartu():
		if k["id"] == id:
			return k
	return {}


func jumlah_kartu_total() -> int:
	return semua_kartu().size()


# ------------------------------------------------------------- rantai teka-teki

func rantai() -> Array:
	return DATA_RANTAI.data["rantai"]


func rantai_selesai() -> bool:
	return langkah_rantai >= rantai().size()


## Data tantangan yang sedang aktif (kosong bila rantai selesai).
func tantangan_aktif() -> Dictionary:
	if rantai_selesai():
		return {}
	return rantai()[langkah_rantai]


## True bila warga `nama` sudah menyelesaikan seluruh tantangannya.
func sudah_memberi(nama: String) -> bool:
	for i in mini(langkah_rantai, rantai().size()):
		var t: Dictionary = rantai()[i]
		if t["pemegang"] == nama and not _masih_punya_giliran(nama, i):
			return true
	return false


func _masih_punya_giliran(nama: String, setelah: int) -> bool:
	for j in range(setelah + 1, rantai().size()):
		var t: Dictionary = rantai()[j]
		if t["pemegang"] == nama and j >= langkah_rantai:
			return true
	return false


func maju_rantai() -> void:
	langkah_rantai += 1
	progres_berubah.emit()


func teks_tujuan() -> String:
	if langkah_rantai == 0:
		return "Temui Tu'a Golo di dekat compang (tengah kampung)"
	var sebelumnya: Dictionary = rantai()[mini(langkah_rantai, rantai().size()) - 1]
	return str(sebelumnya["petunjuk"])
