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

## Scene tiap level. Level yang belum dibuat diarahkan ke ending.
const ADEGAN_LEVEL: Dictionary = {
	1: "res://scenes/kampung.tscn",
	2: "res://scenes/lingko.tscn",
}
const ADEGAN_ENDING: String = "res://scenes/ending.tscn"
const BERKAS_SIMPAN: String = "user://simpanan.cfg"
const NAMA_LEVEL: Dictionary = {1: "Kampung Wae Rebo", 2: "Lingko Lodok"}

var state: int = State.MENU

# --- Progres ---
var langkah_rantai: int = 0  ## indeks tantangan berikutnya di DATA_RANTAI
var kartu_terkumpul: Array[String] = []

# --- Level & pengaturan ---
var level: int = 1  ## level yang sedang dimainkan
var level_tertinggi: int = 1  ## level terjauh yang sudah terbuka (disimpan)
var kartu_awal_level: Array[String] = []  ## kartu saat level dimulai (untuk mengulang level)
var mode_sulit: bool = false  ## Sulit: batas waktu "sebelum senja", kesempatan salah lebih sedikit
var tujuan_khusus: String = ""  ## teks tujuan yang diatur level aktif (Level 2 dst.)


func _ready() -> void:
	muat()


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
	kartu_awal_level.clear()
	level = 1
	tujuan_khusus = ""
	progres_berubah.emit()


# ------------------------------------------------------------- level & simpanan

## Dipanggil saat level `n` tamat: progres disimpan lalu pindah ke level berikutnya
## (atau ke ending bila level berikutnya belum ada).
func selesaikan_level(n: int) -> void:
	tujuan_khusus = ""
	kartu_awal_level.assign(kartu_terkumpul)
	if ADEGAN_LEVEL.has(n + 1):
		level = n + 1
		level_tertinggi = maxi(level_tertinggi, level)
		simpan()
		Transisi.pindah_scene(ADEGAN_LEVEL[level])
	else:
		simpan()
		Transisi.pindah_scene(ADEGAN_ENDING)


## Melanjutkan dari level terjauh yang tersimpan (kartu level sebelumnya ikut dipulihkan).
func lanjutkan() -> void:
	level = clampi(level_tertinggi, 1, ADEGAN_LEVEL.size())
	kartu_terkumpul.assign(kartu_awal_level)
	langkah_rantai = rantai().size() if level > 1 else 0
	tujuan_khusus = ""
	progres_berubah.emit()
	Transisi.pindah_scene(ADEGAN_LEVEL[level])


## Mengulang level aktif dari awal (misalnya karena waktu habis di mode Sulit).
func ulangi_level() -> void:
	kartu_terkumpul.assign(kartu_awal_level)
	tujuan_khusus = ""
	progres_berubah.emit()
	Transisi.pindah_scene(ADEGAN_LEVEL[level])


func ada_simpanan() -> bool:
	return level_tertinggi > 1


func atur_mode_sulit(aktif: bool) -> void:
	mode_sulit = aktif
	simpan()


func simpan() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progres", "level_tertinggi", level_tertinggi)
	cfg.set_value("progres", "kartu", kartu_awal_level)
	cfg.set_value("pengaturan", "mode_sulit", mode_sulit)
	var hasil: Error = cfg.save(BERKAS_SIMPAN)
	if hasil != OK:
		push_warning("Gagal menyimpan progres (kode %d)" % hasil)


func muat() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(BERKAS_SIMPAN) != OK:
		return
	level_tertinggi = int(cfg.get_value("progres", "level_tertinggi", 1))
	var kartu: Array = cfg.get_value("progres", "kartu", [])
	kartu_awal_level.assign(kartu)
	mode_sulit = bool(cfg.get_value("pengaturan", "mode_sulit", false))


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


## Kartu milik level tertentu (kartu tanpa kolom "level" dianggap milik Level 1).
func kartu_level(n: int) -> Array:
	var hasil: Array = []
	for k: Dictionary in semua_kartu():
		if int(k.get("level", 1)) == n:
			hasil.append(k)
	return hasil


func jumlah_terkumpul_level(n: int) -> int:
	var jumlah: int = 0
	for k: Dictionary in kartu_level(n):
		if kartu_terkumpul.has(k["id"]):
			jumlah += 1
	return jumlah


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
	if tujuan_khusus != "":
		return tujuan_khusus
	if langkah_rantai == 0:
		return "Temui Tu'a Golo di dekat compang (tengah kampung)"
	var sebelumnya: Dictionary = rantai()[mini(langkah_rantai, rantai().size()) - 1]
	return str(sebelumnya["petunjuk"])


## Level aktif (Level 2 dst.) mengatur teks tujuan di HUD lewat fungsi ini.
func atur_tujuan(teks: String) -> void:
	tujuan_khusus = teks
	progres_berubah.emit()
