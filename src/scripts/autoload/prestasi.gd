extends CanvasLayer
## PRESTASI: bintang per tantangan (1-3) dan pencapaian yang tersimpan (user://prestasi.cfg).
## Bintang dihitung dari nyawa yang hilang di setiap tantangan yang didaftarkan lewat
## Nyawa.atur_tantangan(): 0 salah = 3 bintang, 1-2 salah = 2 bintang, 3+ salah = 1 bintang.
## Level 3 dikelompokkan per destinasi. Teks pencapaian di data/pencapaian.json.

signal diraih(id: String)

const DATA: JSON = preload("res://data/pencapaian.json")
const BERKAS: String = "user://prestasi.cfg"

var kesalahan: Dictionary = {}  ## nama tantangan -> nyawa hilang (level aktif), urutan sesuai pertama kali dimainkan
var ringkasan_terakhir: Array = []  ## [[nama, bintang], ...] dari level yang baru tamat
var bintang_terbaik: Dictionary = {}  ## nomor level -> bintang rata-rata terbaik (1-3)
var _diraih: Dictionary = {}  ## id -> true
var _tanda: Dictionary = {}  ## penanda bertahap, mis. "laut_pink"
var _popup: PanelContainer
var _label_popup: Label


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_muat()
	Nyawa.tantangan_berubah.connect(_catat_tantangan)
	Nyawa.berubah.connect(_nyawa_berubah)
	_bangun_popup()


# ------------------------------------------------------------------ bintang

static func bintang_dari(salah: int) -> int:
	if salah <= 0:
		return 3
	return 2 if salah <= 2 else 1


func mulai_level() -> void:
	kesalahan.clear()


func _kunci(nama: String) -> String:
	if GameState.level == 3 and nama != "":
		return str(DataLabuanBajo.pulau(GameState.pulau_aktif).get("nama", nama))
	return nama


func _catat_tantangan(nama: String) -> void:
	var k: String = _kunci(nama)
	if k != "" and not kesalahan.has(k):
		kesalahan[k] = 0


func _nyawa_berubah(_sisa: int, selisih: int) -> void:
	var k: String = _kunci(Nyawa.tantangan_aktif())
	if selisih < 0 and k != "":
		kesalahan[k] = int(kesalahan.get(k, 0)) + 1


## Dipanggil GameState.selesaikan_level: susun ringkasan bintang & simpan rekor terbaik.
func selesai_level(n: int) -> void:
	ringkasan_terakhir.clear()
	var total: int = 0
	for k: String in kesalahan:
		var b: int = bintang_dari(int(kesalahan[k]))
		ringkasan_terakhir.append([k, b])
		total += b
	if not ringkasan_terakhir.is_empty():
		var rata: int = int(round(float(total) / ringkasan_terakhir.size()))
		bintang_terbaik[n] = maxi(int(bintang_terbaik.get(n, 0)), rata)
	if Nyawa.hilang_di_level == 0:
		raih("mata_elang")
	_simpan()


# ------------------------------------------------------------------ pencapaian

func daftar() -> Array:
	return DATA.data["pencapaian"]


func teks(id: String) -> String:
	return str(DATA.data["teks"].get(id, id))


func sudah(id: String) -> bool:
	return _diraih.has(id)


func jumlah_diraih() -> int:
	return _diraih.size()


func raih(id: String) -> void:
	if _diraih.has(id):
		return
	_diraih[id] = true
	_simpan()
	diraih.emit(id)
	for p: Dictionary in daftar():
		if p["id"] == id:
			_tampilkan_popup(str(p["nama"]))


## Penanda bertahap (pencapaian yang butuh beberapa syarat). Mengembalikan true bila semua `ids` sudah ditandai.
func tandai(id: String, ids: Array) -> bool:
	_tanda[id] = true
	_simpan()
	for t: String in ids:
		if not _tanda.has(t):
			return false
	return true


# ------------------------------------------------------------------ popup

func _bangun_popup() -> void:
	_popup = PanelContainer.new()
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.1, 0.07, 0.06, 0.92)
	gaya.border_color = Gaya.KUNING
	gaya.set_border_width_all(2)
	gaya.set_corner_radius_all(10)
	gaya.content_margin_left = 14
	gaya.content_margin_right = 14
	gaya.content_margin_top = 6
	gaya.content_margin_bottom = 6
	_popup.add_theme_stylebox_override("panel", gaya)
	_popup.position = Vector2(170, -60)
	_popup.custom_minimum_size = Vector2(300, 0)
	_label_popup = Gaya.label("", 11, Gaya.KUNING)
	_label_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup.add_child(_label_popup)
	_popup.visible = false
	add_child(_popup)


func _tampilkan_popup(nama: String) -> void:
	_label_popup.text = "%s\n%s" % [teks("diraih"), nama]
	_popup.visible = true
	_popup.position.y = -60
	AudioManager.putar_sfx("berhasil")
	var tw := create_tween()
	tw.tween_property(_popup, "position:y", 8.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.4)
	tw.tween_property(_popup, "position:y", -60.0, 0.35).set_ease(Tween.EASE_IN)
	tw.tween_callback(_popup.hide)


# ------------------------------------------------------------------ simpanan

func _simpan() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("prestasi", "diraih", _diraih.keys())
	cfg.set_value("prestasi", "tanda", _tanda.keys())
	cfg.set_value("prestasi", "bintang_terbaik", bintang_terbaik)
	cfg.save(BERKAS)


func _muat() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(BERKAS) != OK:
		return
	for id: String in cfg.get_value("prestasi", "diraih", []):
		_diraih[id] = true
	for id: String in cfg.get_value("prestasi", "tanda", []):
		_tanda[id] = true
	bintang_terbaik = cfg.get_value("prestasi", "bintang_terbaik", {})
