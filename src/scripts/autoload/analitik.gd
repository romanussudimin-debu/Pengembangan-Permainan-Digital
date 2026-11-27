extends Node
## ANALITIK PLAYTEST (lokal, tanpa internet): mencatat kejadian ke user://analitik.json
## untuk bahan laporan playtest. Tidak ada data pribadi; hanya kejadian permainan.
## Kejadian: sesi_mulai, level_mulai, level_selesai (durasi, nyawa hilang, bintang), nyawa_hilang
## (penyebab + tantangan), ulangi (nyawa habis), dialog_dilewati, koleksi_dibuka, pencapaian.
## Drop-off = kejadian terakhir tiap sesi (berkas disimpan setiap kali ada kejadian).
## Ekspor tersembunyi: ketuk logo menu utama 5x -> Salin CSV / Salin JSON / Simpan CSV.
## EVENT level_completed (skema v2, lihat docs/event-tracking.md): satu event per level tamat
## (GameState.selesaikan_level), disimpan terpisah di user://analitik/event_log.json.
## EVENT daily_login (skema v1): satu event per hari kalender saat game dibuka, dengan hari berturut-turut
## (streak) dan total hari bermain. Status login disimpan di user://analitik/login.cfg.

const BERKAS: String = "user://analitik.json"
const MAKS_KEJADIAN: int = 3000
const FOLDER_EVENT: String = "user://analitik"
const BERKAS_EVENT: String = "user://analitik/event_log.json"
const MAKS_EVENT: int = 500
const VERSI_SKEMA: int = 2  ## v2: tanpa field mode & koin_didapat (mode LAN dan tempur dihapus)
const VERSI_SKEMA_LOGIN: int = 1
const BERKAS_LOGIN: String = "user://analitik/login.cfg"
const JENIS_EVENT: Array[String] = ["level_completed", "daily_login"]
const MAKS_LANGKAH_DETIK: float = 0.5  ## jeda antar-frame lebih lama (tab disembunyikan, macet) tidak dihitung penuh

var kejadian: Array = []
var sesi: int = 0
var event_log: Array = []  ## event level_completed & daily_login (maks. MAKS_EVENT terakhir)
var _mulai_ms: int = 0
var _detik_level: float = 0.0  ## durasi level aktif tanpa waktu jeda
var _level_berjalan: bool = false
var _tik_terakhir: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_muat()
	sesi = 1
	for k: Dictionary in kejadian:
		sesi = maxi(sesi, int(k.get("sesi", 0)) + 1)
	_mulai_ms = Time.get_ticks_msec()
	catat("sesi_mulai", {"mode": "sulit" if GameState.mode_sulit else "normal", "platform": OS.get_name()})
	Nyawa.dikurangi.connect(func(penyebab: String, tantangan: String) -> void:
		catat("nyawa_hilang", {"penyebab": penyebab, "tantangan": tantangan}))
	Nyawa.habis.connect(func(tantangan: String) -> void: catat("ulangi", {"tantangan": tantangan}))
	Prestasi.diraih.connect(func(id: String) -> void: catat("pencapaian", {"id": id}))
	GameState.level_dimulai.connect(_on_level_dimulai)
	GameState.level_selesai.connect(catat_level_selesai)
	_tik_terakhir = Time.get_ticks_usec()
	_muat_event_log()
	print("[Analitik] ringkasan_level %s" % JSON.stringify(ringkasan_level()))
	catat_login_harian()


## Menghitung durasi level aktif. Selama pohon scene dijeda (Menu Jeda, panel "Nyawa habis")
## waktu tidak bertambah; mengulang tantangan tidak mereset durasi.
func _process(_delta: float) -> void:
	var sekarang: int = Time.get_ticks_usec()
	if _level_berjalan and not get_tree().paused:
		_detik_level += minf((sekarang - _tik_terakhir) / 1000000.0, MAKS_LANGKAH_DETIK)
	_tik_terakhir = sekarang


func _on_level_dimulai(_n: int) -> void:
	_detik_level = 0.0
	_level_berjalan = true


## Mencatat satu kejadian lalu langsung menyimpan (agar drop-off tetap terekam saat tab ditutup).
func catat(jenis: String, data: Dictionary = {}) -> void:
	var k: Dictionary = {
		"sesi": sesi,
		"t": snappedf((Time.get_ticks_msec() - _mulai_ms) / 1000.0, 0.1),
		"jenis": jenis,
		"level": GameState.level,
		"mode": "sulit" if GameState.mode_sulit else "normal",
	}
	k.merge(data)
	kejadian.append(k)
	if kejadian.size() > MAKS_KEJADIAN:
		kejadian = kejadian.slice(kejadian.size() - MAKS_KEJADIAN)
	_simpan()


## Event level_completed. `data` berisi level_id, nama_level, nyawa_tersisa, nyawa_maks, salah_pengecoh,
## tantangan_diulang, kartu_didapat, pertama_kali (opsional; bila tidak ada dihitung dari log).
## Waktu, durasi, kesulitan, dan versi skema diisi di sini. Tanpa data pribadi.
func catat_level_selesai(data: Dictionary) -> void:
	var level_id: int = int(data.get("level_id", GameState.level))
	var ev: Dictionary = {
		"event": "level_completed",
		"versi_skema": VERSI_SKEMA,
		"level_id": level_id,
		"nama_level": str(data.get("nama_level", GameState.NAMA_LEVEL.get(level_id, ""))),
		"kesulitan": GameState.kesulitan,
		"waktu": Time.get_datetime_string_from_system(),
		"durasi_detik": snappedf(_detik_level, 0.1),
		"nyawa_tersisa": int(data.get("nyawa_tersisa", 0)),
		"nyawa_maks": int(data.get("nyawa_maks", 0)),
		"salah_pengecoh": int(data.get("salah_pengecoh", 0)),
		"tantangan_diulang": int(data.get("tantangan_diulang", 0)),
		"kartu_didapat": Array(data.get("kartu_didapat", [])),
		"pertama_kali": bool(data["pertama_kali"]) if data.has("pertama_kali") else not _pernah_selesai(level_id),
	}
	_level_berjalan = false
	event_log.append(ev)
	if event_log.size() > MAKS_EVENT:
		event_log = event_log.slice(event_log.size() - MAKS_EVENT)
	_simpan_event_log()
	var baris: String = "[Analitik] level_completed level=%d kesulitan=%s durasi=%.1fs nyawa=%d/%d" % [
		level_id, ev["kesulitan"], ev["durasi_detik"], ev["nyawa_tersisa"], ev["nyawa_maks"]]
	print(baris + " pengecoh=%d diulang=%d kartu=%d pertama_kali=%s" % [ev["salah_pengecoh"],
		ev["tantangan_diulang"], (ev["kartu_didapat"] as Array).size(), ev["pertama_kali"]])


## Jumlah tamat dan rata-rata durasi (detik) per level dari event_log: {level_id: {"selesai", "rata_durasi"}}.
func ringkasan_level() -> Dictionary:
	var hasil: Dictionary = {}
	for ev: Dictionary in event_log:
		if ev.get("event", "") != "level_completed":
			continue
		var id: int = int(ev.get("level_id", 0))
		var r: Dictionary = hasil.get(id, {"selesai": 0, "total": 0.0})
		r["selesai"] = int(r["selesai"]) + 1
		r["total"] = float(r["total"]) + float(ev.get("durasi_detik", 0.0))
		hasil[id] = r
	for id: int in hasil:
		var r: Dictionary = hasil[id]
		hasil[id] = {"selesai": r["selesai"], "rata_durasi": snappedf(float(r["total"]) / int(r["selesai"]), 0.1)}
	return hasil


func _pernah_selesai(level_id: int) -> bool:
	for ev: Dictionary in event_log:
		if ev.get("event", "") == "level_completed" and int(ev.get("level_id", 0)) == level_id:
			return true
	return false


## Event daily_login: dicatat sekali per hari kalender (tanggal lokal perangkat) saat game dibuka.
## Membuka game lagi di hari yang sama tidak menambah event. `tanggal` (YYYY-MM-DD) hanya diisi saat pengujian.
func catat_login_harian(tanggal: String = "") -> void:
	if tanggal == "":
		tanggal = Time.get_date_string_from_system()
	var cfg := ConfigFile.new()
	cfg.load(BERKAS_LOGIN)  # berkas belum ada/rusak = login pertama
	var terakhir: String = str(cfg.get_value("login", "tanggal_terakhir", ""))
	if terakhir == tanggal:
		return
	var jeda: int = _selisih_hari(terakhir, tanggal) if terakhir != "" else 0
	if jeda < 0:
		return  # jam perangkat mundur: tidak dihitung sebagai hari baru (mencegah login ganda)
	var berturut: int = int(cfg.get_value("login", "hari_berturut", 0)) + 1 if jeda == 1 else 1
	var total: int = int(cfg.get_value("login", "total_hari", 0)) + 1
	var terbaik: int = maxi(int(cfg.get_value("login", "hari_berturut_terbaik", 0)), berturut)
	cfg.set_value("login", "tanggal_terakhir", tanggal)
	cfg.set_value("login", "hari_berturut", berturut)
	cfg.set_value("login", "hari_berturut_terbaik", terbaik)
	cfg.set_value("login", "total_hari", total)
	DirAccess.make_dir_recursive_absolute(FOLDER_EVENT)
	cfg.save(BERKAS_LOGIN)
	var ev: Dictionary = {
		"event": "daily_login",
		"versi_skema": VERSI_SKEMA_LOGIN,
		"tanggal": tanggal,
		"waktu": Time.get_datetime_string_from_system(),
		"hari_berturut": berturut,
		"hari_berturut_terbaik": terbaik,
		"total_hari": total,
		"jeda_hari": jeda,
		"login_pertama": terakhir == "",
		"platform": OS.get_name(),
	}
	event_log.append(ev)
	if event_log.size() > MAKS_EVENT:
		event_log = event_log.slice(event_log.size() - MAKS_EVENT)
	_simpan_event_log()
	print("[Analitik] daily_login tanggal=%s hari_berturut=%d total_hari=%d jeda_hari=%d login_pertama=%s" % [
		tanggal, berturut, total, jeda, ev["login_pertama"]])


## Selisih hari kalender antara dua tanggal YYYY-MM-DD (negatif bila tanggal `ke` lebih awal).
static func _selisih_hari(dari: String, ke: String) -> int:
	var a: int = Time.get_unix_time_from_datetime_string(dari + "T00:00:00")
	var b: int = Time.get_unix_time_from_datetime_string(ke + "T00:00:00")
	return roundi((b - a) / 86400.0)


## Tulis aman: isi ke berkas .tmp dulu, lalu diganti nama menjadi event_log.json.
func _simpan_event_log() -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER_EVENT)
	var sementara: String = BERKAS_EVENT + ".tmp"
	var f := FileAccess.open(sementara, FileAccess.WRITE)
	if f == null:
		push_warning("[Analitik] Gagal menulis %s" % sementara)
		return
	f.store_string(JSON.stringify(event_log, "  "))
	f.close()
	if DirAccess.rename_absolute(sementara, BERKAS_EVENT) != OK:
		DirAccess.remove_absolute(BERKAS_EVENT)  # beberapa sistem menolak menimpa berkas lama
		if DirAccess.rename_absolute(sementara, BERKAS_EVENT) != OK:
			push_warning("[Analitik] Gagal mengganti %s" % BERKAS_EVENT)


## Berkas hilang atau rusak = mulai dari array kosong (tanpa crash).
func _muat_event_log() -> void:
	event_log = []
	if not FileAccess.file_exists(BERKAS_EVENT):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(BERKAS_EVENT)) != OK or not json.data is Array:
		return
	for ev: Variant in json.data:
		if ev is Dictionary and str((ev as Dictionary).get("event", "")) in JENIS_EVENT:
			event_log.append(ev)
	if event_log.size() > MAKS_EVENT:
		event_log = event_log.slice(event_log.size() - MAKS_EVENT)


func ke_json() -> String:
	return JSON.stringify(kejadian, "  ")


## CSV: satu baris per kejadian; kolom tambahan digabung sebagai "kunci=nilai".
func ke_csv() -> String:
	var baris: PackedStringArray = ["sesi,detik,jenis,level,mode,detail"]
	for k: Dictionary in kejadian:
		var detail: PackedStringArray = []
		for kunci: String in k:
			if not kunci in ["sesi", "t", "jenis", "level", "mode"]:
				detail.append("%s=%s" % [kunci, str(k[kunci])])
		var isi: String = "; ".join(detail).replace("\"", "'")
		baris.append("%d,%s,%s,%d,%s,\"%s\"" % [int(k["sesi"]), str(k["t"]), k["jenis"], int(k["level"]), k["mode"], isi])
	return "\n".join(baris)


## Ringkasan singkat untuk panel ekspor.
func ringkasan() -> String:
	var hitung: Dictionary = {}
	for k: Dictionary in kejadian:
		hitung[k["jenis"]] = int(hitung.get(k["jenis"], 0)) + 1
	var teks: PackedStringArray = ["Sesi: %d · Kejadian: %d" % [sesi, kejadian.size()]]
	for j: String in ["level_selesai", "nyawa_hilang", "ulangi", "dialog_dilewati", "koleksi_dibuka", "pencapaian"]:
		teks.append("%s: %d" % [j, int(hitung.get(j, 0))])
	return "\n".join(teks)


## Simpan CSV: di web diunduh lewat browser; di desktop/HP disimpan ke folder data pengguna.
func simpan_csv() -> String:
	var csv: String = ke_csv()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(csv.to_utf8_buffer(), "analitik_jejak_penti.csv", "text/csv")
		return "Diunduh: analitik_jejak_penti.csv"
	var jalur: String = "user://analitik_jejak_penti.csv"
	var f := FileAccess.open(jalur, FileAccess.WRITE)
	if f == null:
		return "Gagal menyimpan CSV"
	f.store_string(csv)
	f.close()
	return "Disimpan: " + ProjectSettings.globalize_path(jalur)


func hapus_semua() -> void:
	kejadian.clear()
	_simpan()


func _simpan() -> void:
	var f := FileAccess.open(BERKAS, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(kejadian))
		f.close()


func _muat() -> void:
	if not FileAccess.file_exists(BERKAS):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(BERKAS))
	if data is Array:
		kejadian = data
