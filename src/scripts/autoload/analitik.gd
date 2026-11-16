extends Node
## ANALITIK PLAYTEST (lokal, tanpa internet): mencatat kejadian ke user://analitik.json
## untuk bahan laporan playtest. Tidak ada data pribadi; hanya kejadian permainan.
## Kejadian: sesi_mulai, level_mulai, level_selesai (durasi, nyawa hilang, bintang), nyawa_hilang
## (penyebab + tantangan), ulangi (nyawa habis), dialog_dilewati, koleksi_dibuka, pencapaian.
## Drop-off = kejadian terakhir tiap sesi (berkas disimpan setiap kali ada kejadian).
## Ekspor tersembunyi: ketuk logo menu utama 5x -> Salin CSV / Salin JSON / Simpan CSV.

const BERKAS: String = "user://analitik.json"
const MAKS_KEJADIAN: int = 3000

var kejadian: Array = []
var sesi: int = 0
var _mulai_ms: int = 0


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
