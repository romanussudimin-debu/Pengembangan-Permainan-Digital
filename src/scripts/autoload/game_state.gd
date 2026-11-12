extends Node
## State game global (finite state machine tingkat game) + progres pemain.

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

var state: int = State.MENU

# --- Progres misi ---
var sudah_bertemu_tua: bool = false
var sudah_bertemu_ine: bool = false
var lawan_dikalahkan: int = 0  ## jumlah lawan caci yang sudah dikalahkan (0..3)
var lawan_aktif: int = 0  ## indeks lawan yang sedang/akan dilawan di arena
var tutorial_caci_dilihat: bool = false
var kartu_terkumpul: Array[String] = []
var titik_muncul: String = "awal"


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
	sudah_bertemu_tua = false
	sudah_bertemu_ine = false
	lawan_dikalahkan = 0
	lawan_aktif = 0
	tutorial_caci_dilihat = false
	kartu_terkumpul.clear()
	titik_muncul = "awal"
	progres_berubah.emit()


func tandai(nama_flag: String) -> void:
	set(nama_flag, true)
	progres_berubah.emit()


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


const JUMLAH_LAWAN: int = 3


func semua_misi_selesai() -> bool:
	return lawan_dikalahkan >= JUMLAH_LAWAN


func catat_kemenangan(indeks_lawan: int) -> void:
	lawan_dikalahkan = maxi(lawan_dikalahkan, indeks_lawan + 1)
	progres_berubah.emit()


func teks_tujuan() -> String:
	if not sudah_bertemu_tua:
		return "Temui Tu'a Golo di dekat compang (tengah kampung)"
	if lawan_dikalahkan < JUMLAH_LAWAN:
		var nama: Array[String] = ["Rangga", "Fransi", "Ema Agus"]
		return "Berlatih caci dengan %s (%d/%d) di arena timur" % [nama[lawan_dikalahkan], lawan_dikalahkan, JUMLAH_LAWAN]
	return "Kembali ke Tu'a Golo untuk memulai Penti"
