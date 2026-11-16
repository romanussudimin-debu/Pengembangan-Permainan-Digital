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
	1: "res://scenes/pendakian.tscn",  # Level 1 dimulai dengan mendaki ke Wae Rebo, lalu kampung
	2: "res://scenes/lingko.tscn",
	3: "res://scenes/peta_kapal.tscn",
}
## Level 3: setiap destinasi dimainkan di scene pulau yang sama (dibangun dari data/labuan_bajo.json).
const ADEGAN_PULAU: String = "res://scenes/pulau.tscn"
const ADEGAN_ENDING: String = "res://scenes/ending.tscn"
## Layar antar-level: "Level N berhasil" + tombol lanjut + animasi orb level berikutnya.
const ADEGAN_LEVEL_SELESAI: String = "res://scenes/level_selesai.tscn"
const DATA_LEVEL: JSON = preload("res://data/level.json")
const BERKAS_SIMPAN: String = "user://simpanan.cfg"
const NAMA_LEVEL: Dictionary = {1: "Kampung Wae Rebo", 2: "Lingko Lodok", 3: "Songke ke Labuan Bajo"}

var state: int = State.MENU

# --- Progres ---
var langkah_rantai: int = 0  ## indeks tantangan berikutnya di DATA_RANTAI
var kartu_terkumpul: Array[String] = []

# --- Level & pengaturan ---
var level: int = 1  ## level yang sedang dimainkan
var level_tertinggi: int = 1  ## level terjauh yang sudah terbuka (disimpan)
var kartu_awal_level: Array[String] = []  ## kartu saat level dimulai (untuk mengulang level)
var teks_cepat: bool = false  ## pengaturan: teks dialog langsung tampil utuh (disimpan)
var mode_sulit: bool = false  ## Sulit: batas waktu "sebelum senja", kesempatan salah lebih sedikit
var tujuan_khusus: String = ""  ## teks tujuan yang diatur level aktif (Level 2 dst.)
var level_baru_selesai: int = 0  ## level yang baru tamat (dibaca layar Level Berhasil)
var waktu_mulai_level: int = 0  ## Time.get_ticks_msec() saat level dimulai
var durasi_level_terakhir: float = 0.0  ## detik, untuk ringkasan akhir level

# --- Sub-progres Level 3 (disimpan) ---
var pulau_selesai: int = 0  ## jumlah destinasi yang sudah tuntas (destinasi terbuka berurutan)
var pulau_aktif: int = 0  ## indeks destinasi yang sedang dikunjungi
var terjual_total: int = 0  ## kain/foto yang terjual di destinasi yang sudah tuntas
var pembuka_l3_dilihat: bool = false
var benang_emas: int = 0  ## benang emas terkumpul di Level 1 (pencapaian "Penjelajah")


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
	pulau_selesai = 0
	pulau_aktif = 0
	terjual_total = 0
	pembuka_l3_dilihat = false
	progres_berubah.emit()


# ------------------------------------------------------------- level & simpanan

## Dipanggil saat level `n` tamat: progres disimpan lalu pindah ke level berikutnya
## (atau ke ending bila level berikutnya belum ada).
## Layar "Level N berhasil" ditampilkan dulu; pemain sendiri yang menekan tombol lanjut.
func selesaikan_level(n: int) -> void:
	tujuan_khusus = ""
	kartu_awal_level.assign(kartu_terkumpul)
	level_baru_selesai = n
	Prestasi.selesai_level(n)
	Analitik.catat("level_selesai", {
		"durasi": int((Time.get_ticks_msec() - waktu_mulai_level) / 1000.0) if waktu_mulai_level > 0 else 0,
		"nyawa_hilang": Nyawa.hilang_di_level, "bintang": int(Prestasi.bintang_terbaik.get(n, 0)),
	})
	durasi_level_terakhir = (Time.get_ticks_msec() - waktu_mulai_level) / 1000.0 if waktu_mulai_level > 0 else 0.0
	if ADEGAN_LEVEL.has(n + 1):
		level = n + 1
		level_tertinggi = maxi(level_tertinggi, level)
	simpan()
	Transisi.pindah_scene(ADEGAN_LEVEL_SELESAI)


## Dipanggil saat pemain mulai memainkan level `n` (dari menu atau layar antar-level).
func mulai_level(n: int) -> void:
	level = n
	waktu_mulai_level = Time.get_ticks_msec()
	Prestasi.mulai_level()
	Analitik.catat("level_mulai")
	Nyawa.isi_penuh()
	tujuan_khusus = ""
	Transisi.pindah_scene(ADEGAN_LEVEL[n])


func data_level(n: int) -> Dictionary:
	for d: Dictionary in DATA_LEVEL.data["level"]:
		if int(d["nomor"]) == n:
			return d
	return {}


## Melanjutkan dari level terjauh yang tersimpan (kartu level sebelumnya ikut dipulihkan).
func lanjutkan() -> void:
	muat()  # baca ulang simpanan (progres di memori bisa sudah direset oleh "Mulai Permainan")
	level = clampi(level_tertinggi, 1, ADEGAN_LEVEL.size())
	kartu_terkumpul.assign(kartu_awal_level)
	langkah_rantai = rantai().size() if level > 1 else 0
	tujuan_khusus = ""
	waktu_mulai_level = Time.get_ticks_msec()
	Prestasi.mulai_level()
	Nyawa.isi_penuh()
	progres_berubah.emit()
	Transisi.pindah_scene(ADEGAN_LEVEL[level])


## Menu Pilih Level: memainkan ulang level `n` yang sudah terbuka (kartu yang sudah didapat tetap).
## Level 3 dimulai lagi dari destinasi pertama.
func pilih_level(n: int) -> void:
	muat()
	n = clampi(n, 1, mini(level_tertinggi, ADEGAN_LEVEL.size()))
	kartu_terkumpul.assign(kartu_awal_level)
	level = n
	langkah_rantai = 0 if n == 1 else rantai().size()
	if n == 3:
		pulau_selesai = 0
		pulau_aktif = 0
		terjual_total = 0
	mulai_level(n)


## Mengulang level aktif dari awal (misalnya karena waktu habis di mode Sulit).
func ulangi_level() -> void:
	kartu_terkumpul.assign(kartu_awal_level)
	Nyawa.isi_penuh()
	tujuan_khusus = ""
	progres_berubah.emit()
	Transisi.pindah_scene(ADEGAN_LEVEL[level])


func ada_simpanan() -> bool:
	return level_tertinggi > 1


## Level 3: masuk ke destinasi `i` dari peta kapal.
func kunjungi_pulau(i: int) -> void:
	pulau_aktif = i
	Nyawa.isi_penuh(false)  # tiap destinasi Level 3 dimulai dengan nyawa penuh
	tujuan_khusus = ""
	Transisi.pindah_scene(ADEGAN_PULAU)


## Level 3: destinasi `i` tuntas (3 pembeli); progres disimpan lalu kembali ke peta kapal.
func selesaikan_pulau(i: int, terjual: int) -> void:
	if i >= pulau_selesai:
		pulau_selesai = i + 1
		terjual_total += terjual
	kartu_awal_level.assign(kartu_terkumpul)
	tujuan_khusus = ""
	simpan()
	Transisi.pindah_scene(ADEGAN_LEVEL[3])


## Level 3: mengulang destinasi aktif (waktu habis, pasir tenggelam, atau pembeli tidak cukup).
func ulangi_pulau() -> void:
	kartu_terkumpul.assign(kartu_awal_level)
	Nyawa.isi_penuh(false)
	tujuan_khusus = ""
	progres_berubah.emit()
	Transisi.pindah_scene(ADEGAN_PULAU)


func atur_mode_sulit(aktif: bool) -> void:
	mode_sulit = aktif
	simpan()


func simpan() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progres", "level_tertinggi", level_tertinggi)
	cfg.set_value("progres", "kartu", kartu_awal_level)
	cfg.set_value("progres", "pulau_selesai", pulau_selesai)
	cfg.set_value("progres", "terjual_total", terjual_total)
	cfg.set_value("progres", "pembuka_l3_dilihat", pembuka_l3_dilihat)
	cfg.set_value("pengaturan", "mode_sulit", mode_sulit)
	cfg.set_value("pengaturan", "teks_cepat", teks_cepat)
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
	pulau_selesai = int(cfg.get_value("progres", "pulau_selesai", 0))
	terjual_total = int(cfg.get_value("progres", "terjual_total", 0))
	pembuka_l3_dilihat = bool(cfg.get_value("progres", "pembuka_l3_dilihat", false))
	mode_sulit = bool(cfg.get_value("pengaturan", "mode_sulit", false))
	teks_cepat = bool(cfg.get_value("pengaturan", "teks_cepat", false))


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
