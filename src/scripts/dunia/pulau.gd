extends Node3D
## Level 3: satu destinasi Taman Nasional Komodo (data: data/labuan_bajo.json, indeks GameState.pulau_aktif).
## Inti: temukan wisatawan, pilih kain/foto yang cocok, ceritakan maknanya (mini-game JualSongke).
## Target 3 pembeli per pulau. Mekanik khas tiap destinasi (kesulitan naik berurutan):
##   pelabuhan - tutorial menjual
##   padar     - mendaki 3 pos; tenaga berkurang saat berjalan, minum di pos
##   pink      - pantai & air dangkal; jangan menginjak karang; pungut sampah (opsional)
##   komodo    - jalur bersama ranger; terlalu dekat komodo = kembali ke titik aman
##   taka      - pulau pasir sabit menyempit karena air pasang (batas waktu alami)
##   manjarite - berenang antar-kapal; arus mendorong pemain; jangan menginjak karang
## Mode Sulit: batas waktu per pulau, salah cerita = wisatawan pergi, tenaga lebih cepat habis,
## komodo lebih banyak, dan denda waktu saat jatuh/menginjak karang/terlalu dekat komodo.

const ADEGAN_PEMAIN: PackedScene = preload("res://scenes/pemain.tscn")
const JUAL: Script = preload("res://scripts/minigame/jual_songke.gd")
const TARGET_PEMBELI: int = 3
const Y_TENGGELAM: float = -1.0
const DENDA_JATUH: float = 10.0
const DENDA_KOMODO: float = 15.0
const KECEPATAN_DARAT: float = 5.0
const KECEPATAN_AIR: float = 2.8
## Penambah nyawa (kelapa muda) di 4 destinasi: jenis pulau -> posisi.
const POS_KELAPA: Dictionary = {
	"padar": Vector3(3.5, 2.2, 10.0), "pink": Vector3(-7.0, 0.15, -3.0),
	"komodo": Vector3(14.0, 0.0, 10.0), "manjarite": Vector3(13.0, DuniaPulau.Y_DEK, 1.6),
}

var data: Dictionary
var jenis: String
var pemain: Pemain
var kamera: KameraIkut

var _titik_muncul := Vector3(0, 0.3, 12)
var _titik_aman := Vector3(0, 0.3, 12)
var _titik_keluar := Vector3(1.7, 0, 15)
var _bisa_tenggelam: bool = true
var _npc: Array[NpcKampung] = []
var _status: Dictionary = {}  ## NpcKampung -> "ada" | "terjual" | "pergi"
var _data_npc: Dictionary = {}  ## NpcKampung -> data wisatawan
var _terjual: int = 0
var _tuntas: bool = false
var _gagal: bool = false
var _jeda_kembali: float = 0.0
var _minigame: Node = null

# Batas waktu Mode Sulit
var _waktu_berjalan: bool = false
var _sisa_waktu: float = 0.0
var _batas_waktu: float = 300.0

# Mekanik khas
var _karang: Array[Vector3] = []
var _arus: Array = []
var _garis_arus: Array = []  ## [MeshInstance3D, zona]
var _sudah_kena_arus: bool = false
var _komodo: Array[Komodo] = []
var _stamina: float = 100.0
var _pos_air_dipakai: Array[bool] = []
var _sudah_haus: bool = false
var _cakram: Array = []  ## [MeshInstance3D, CollisionShape3D, indeks]
var _pasang: float = 0.0

# UI
var _ui: CanvasLayer
var _label_waktu: Label
var _label_toast: Label
var _bar: Control
var _label_bar: Label


func _ready() -> void:
	GameState.level = 3
	data = DataLabuanBajo.pulau(GameState.pulau_aktif)
	jenis = str(data["jenis"])
	Dunia.lingkungan(self)
	DuniaPulau.laut(self)
	Dunia.batas_dunia(self, 38.0)
	_pulau_latar()
	match jenis:
		"pelabuhan":
			_bangun_pelabuhan()
		"padar":
			_bangun_padar()
		"pink":
			_bangun_pink()
		"komodo":
			_bangun_komodo()
		"taka":
			_bangun_taka()
		"manjarite":
			_bangun_manjarite()
	_bangun_wisatawan()
	_bangun_titik_keluar()
	if POS_KELAPA.has(jenis):
		var kelapa := PenambahNyawa.new()
		kelapa.jenis = "kelapa"
		kelapa.position = POS_KELAPA[jenis]
		add_child(kelapa)
	_munculkan_pemain()
	add_child(preload("res://scripts/ui/hud.gd").new())
	_bangun_ui()
	AudioManager.putar_musik("kampung")
	GameState.ubah_state(GameState.State.BERMAIN)
	_perbarui_tujuan()
	_atur_tantangan_jelajah()
	if jenis == "taka":
		_batas_waktu = float(data.get("batas_waktu_sulit", 170)) if GameState.mode_sulit else float(data.get("batas_waktu", 240))
	elif GameState.mode_sulit:
		_batas_waktu = float(data.get("batas_waktu", 300))
		_sisa_waktu = _batas_waktu
		_waktu_berjalan = true
	get_tree().create_timer(0.8, false).timeout.connect(
			func() -> void: DialogManager.mulai_baris("pembuka_pulau", data["pembuka"]))


# ================================================================== pembangun pulau

## Pulau-pulau lain di kejauhan (tanpa collision) agar laut tidak kosong.
func _pulau_latar() -> void:
	var acak := RandomNumberGenerator.new()
	acak.seed = 31 + GameState.pulau_aktif
	for i in 9:
		var a: float = PI + PI * i / 8.0 + acak.randf_range(-0.1, 0.1)  # di sisi utara (jauh dari kamera)
		Dunia.bukit(self, Vector3(cos(a) * 75, -5, sin(a) * 75 - 10), acak.randf_range(12, 22), acak.randf_range(10, 22))


func _papan_info(pos: Vector3, judul: String) -> void:
	Dunia.papan(self, pos, judul)
	var area := Interaktif.new()
	area.teks_petunjuk = "Baca"
	area.jari_jari = 2.0
	area.position = pos
	add_child(area)
	area.diinteraksi.connect(_baca_info)


func _bangun_pelabuhan() -> void:
	DuniaPulau.daratan_kotak(self, Vector3(0, 0, -13), Vector2(44, 34), Color("c9c0ae"))
	for g: Array in [[Vector3(-14, 0, -25), Vector3(7, 4, 6), Color("e8e2d2")], [Vector3(-4, 0, -26), Vector3(6, 5, 5), Color("d8b878")],
			[Vector3(7, 0, -25), Vector3(8, 4, 6), Color("9ec6d8")], [Vector3(17, 0, -23), Vector3(5, 3.5, 5), Color("e8c8a8")]]:
		DuniaPulau.gedung(self, g[0], g[1], g[2])
	for p: Vector3 in [Vector3(-19, 0, -6), Vector3(19, 0, -13), Vector3(-18, 0, 1.5), Vector3(-9, 0, -18)]:
		DuniaPulau.lontar(self, p)
	DuniaPulau.dermaga(self, Vector3(0, 0, 3.0), Vector3(0, 0, 21))
	DuniaPulau.kapal(self, Vector3(3.6, 0, 15), 0.0)
	DuniaPulau.kapal(self, Vector3(-10, 0, 14), 0.3, Color("d8e8f0"))
	DuniaPulau.kapal(self, Vector3(15, 0, 11), -0.25, Color("f4e0c0"))
	_papan_info(Vector3(3.5, 0, 1.5), "Labuan Bajo")
	_titik_muncul = Vector3(0, 0.3, 13)
	_titik_keluar = Vector3(1.6, 0, 15)


## Plato bukit (silinder datar berumput) dengan collision; puncaknya di `tinggi`.
func _plato(pos: Vector3, jari: float, tinggi: float) -> void:
	Dunia.mesh(self, Dunia.silinder(jari, jari * 1.12, tinggi, 20), pos + Vector3(0, tinggi / 2.0, 0),
			Dunia.mat(DuniaPulau.WARNA_SABANA, Dunia.TEX_RUMPUT, Vector3(4, 2, 1)))
	var bentuk := CylinderShape3D.new()
	bentuk.radius = jari
	bentuk.height = tinggi
	Dunia.badan_statis(self, bentuk, pos + Vector3(0, tinggi / 2.0, 0))


func _bangun_padar() -> void:
	DuniaPulau.daratan(self, Vector3.ZERO, 28.0, DuniaPulau.WARNA_PASIR)
	Dunia.mesh(self, Dunia.silinder(23.0, 23.0, 0.03, 32), Vector3(0, 0.02, -2),
			Dunia.mat(DuniaPulau.WARNA_SABANA, Dunia.TEX_RUMPUT, Vector3(10, 10, 1)))
	# Tiga teluk berwarna: pasir hitam (utara) dan merah muda (timur laut); pasir putih di selatan
	Dunia.mesh(self, Dunia.silinder(6.0, 6.0, 0.04, 20), Vector3(-2, 0.03, -24.5), Dunia.mat(Color("3a3632"), Dunia.TEX_TANAH))
	Dunia.mesh(self, Dunia.silinder(5.0, 5.0, 0.04, 20), Vector3(18.5, 0.03, -18.5), Dunia.mat(DuniaPulau.WARNA_PASIR_PINK, Dunia.TEX_TANAH))
	# Jalur pendakian: tiga pos bertingkat dihubungkan tanjakan
	_plato(Vector3(6, 0, 8), 5.0, 2.2)
	_plato(Vector3(-4, 0, -4), 5.0, 4.4)
	_plato(Vector3(6, 0, -18), 5.5, 6.6)
	DuniaLingko.tanjakan(self, Vector3(6, 0, 19.5), Vector3(6, 2.2, 12.6), 2.2)
	DuniaLingko.tanjakan(self, Vector3(3.06, 2.2, 4.46), Vector3(-1.06, 4.4, -0.46), 2.2)
	DuniaLingko.tanjakan(self, Vector3(-1.33, 4.4, -7.74), Vector3(2.8, 6.6, -13.52), 2.2)
	for p: Vector3 in [Vector3(-14, 0, 12), Vector3(14, 0, 18), Vector3(-20, 0, -4), Vector3(18, 0, 2)]:
		DuniaPulau.lontar(self, p, 0.9)
	var pos_air: Array = data.get("pos_air", [])
	for i in pos_air.size():
		var p: Vector3 = _v3(pos_air[i])
		Dunia.mesh(self, Dunia.silinder(0.35, 0.35, 0.7, 8), p + Vector3(0, 0.35, 0), Dunia.mat(Color.WHITE, Dunia.TEX_KAYU))
		Dunia.mesh(self, Dunia.silinder(0.08, 0.08, 0.3, 8), p + Vector3(0, 0.85, 0), Dunia.mat(Color("8fd0e8")))
		var area := Interaktif.new()
		area.teks_petunjuk = "Minum (pos %d)" % (i + 1)
		area.jari_jari = 1.8
		area.position = p
		add_child(area)
		area.diinteraksi.connect(_minum.bind(i))
		_pos_air_dipakai.append(false)
	_papan_info(Vector3(9.2, 6.6, -20.0), "Puncak Padar")
	DuniaPulau.dermaga(self, Vector3(0, 0, 27), Vector3(0, 0, 38))
	DuniaPulau.kapal(self, Vector3(3.6, 0, 34), 0.0)
	_titik_muncul = Vector3(0, 0.3, 30)
	_titik_keluar = Vector3(1.6, 0, 34)


func _bangun_pink() -> void:
	DuniaPulau.dasar_dangkal(self, Vector3(0, -0.55, 0), 27.0, Color("e8c8b8"))
	DuniaPulau.daratan(self, Vector3(0, 0.15, -10), 13.0, DuniaPulau.WARNA_PASIR_PINK)
	Dunia.bukit(self, Vector3(0, -2, -27), 12, 9)
	for p: Vector3 in [Vector3(-9, 0.15, -16), Vector3(8, 0.15, -17), Vector3(-11, 0.15, -7)]:
		DuniaPulau.lontar(self, p)
	for k: Array in data.get("karang", []):
		var p := _v3(k)
		DuniaPulau.karang(self, p)
		_karang.append(p)
	for s: Array in data.get("sampah", []):
		var n := DuniaPulau.sampah(self, _v3(s))
		var area := Interaktif.new()
		area.teks_petunjuk = "Pungut sampah"
		area.jari_jari = 1.5
		n.add_child(area)
		area.diinteraksi.connect(_pungut_sampah.bind(n))
	_papan_info(Vector3(-2.5, 0.15, -2.5), "Pink Beach")
	DuniaPulau.dermaga(self, Vector3(0, 0.1, 2.0), Vector3(0, 0.1, 22))
	DuniaPulau.kapal(self, Vector3(3.6, 0, 19), 0.0)
	_titik_muncul = Vector3(0, 0.4, 18)
	_titik_keluar = Vector3(1.6, 0.1, 19)


func _bangun_komodo() -> void:
	DuniaPulau.daratan(self, Vector3.ZERO, 30.0, DuniaPulau.WARNA_SABANA, Dunia.TEX_RUMPUT)
	var jalur: Array = data["jalur"]
	for i in jalur.size() - 1:
		DuniaLingko.jalan_tanah(self, _v3(jalur[i]), _v3(jalur[i + 1]), 2.4)
	var acak := RandomNumberGenerator.new()
	acak.seed = 5
	for i in 40:
		var p := Vector3(acak.randf_range(-26, 26), 0, acak.randf_range(-26, 24))
		if Vector2(p.x, p.z).length() < 27.0 and _jarak_ke_jalur(p, jalur) > 3.5 and absf(p.x) > 3.0:
			if i % 3 == 0:
				Dunia.pohon(self, p, acak.randf_range(0.8, 1.2))
			else:
				DuniaPulau.lontar(self, p, acak.randf_range(0.8, 1.1))
	for k: Dictionary in data["komodo"]:
		if k.get("sulit", false) and not GameState.mode_sulit:
			continue
		var komodo := Komodo.new()
		komodo.titik_a = _v3(k["a"])
		komodo.titik_b = _v3(k["b"])
		komodo.kecepatan = 1.2 if GameState.mode_sulit else 0.9
		add_child(komodo)
		_komodo.append(komodo)
	_papan_info(Vector3(2.6, 0, 22), "Pulau Komodo")
	DuniaPulau.dermaga(self, Vector3(0, 0, 29), Vector3(0, 0, 38))
	DuniaPulau.kapal(self, Vector3(3.6, 0, 35), 0.0)
	_titik_muncul = Vector3(0, 0.3, 31)
	_titik_keluar = Vector3(1.6, 0, 35)


func _jarak_ke_jalur(p: Vector3, jalur: Array) -> float:
	var terdekat: float = INF
	for i in jalur.size() - 1:
		var a := Vector2(jalur[i][0], jalur[i][2])
		var b := Vector2(jalur[i + 1][0], jalur[i + 1][2])
		var q := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), a, b)
		terdekat = minf(terdekat, q.distance_to(Vector2(p.x, p.z)))
	return terdekat


## Taka Makassar: gosong pasir sabit dari cakram-cakram pasir yang menyusut saat air pasang.
func _bangun_taka() -> void:
	var m_pasir := Dunia.mat(DuniaPulau.WARNA_PASIR, Dunia.TEX_TANAH, Vector3(2, 2, 1))
	for i in 15:
		var a: float = deg_to_rad(200.0 + i * 10.0)
		var pos := Vector3(cos(a) * 11.0, 0, sin(a) * 11.0 + 6.0)
		var mi := Dunia.mesh(self, Dunia.silinder(3.0, 3.2, 1.6, 16), pos + Vector3(0, 0.15 - 0.8, 0), m_pasir)
		var bentuk := CylinderShape3D.new()
		bentuk.radius = 3.0
		bentuk.height = 1.6
		var badan := Dunia.badan_statis(self, bentuk, pos + Vector3(0, 0.15 - 0.8, 0))
		_cakram.append([mi, badan.get_child(0), i])
	DuniaPulau.dermaga(self, Vector3(0, 0.15, -4.5), Vector3(0, 0.15, 10))
	DuniaPulau.kapal(self, Vector3(3.6, 0, 8), 0.0)
	DuniaPulau.kapal(self, Vector3(-12, 0, 14), 0.5, Color("d8e8f0"))
	_papan_info(Vector3(-1.7, 0.15, 3.0), "Info Awak Kapal")
	_titik_muncul = Vector3(0, 0.4, 6)
	_titik_keluar = Vector3(1.6, 0.15, 7.5)


func _bangun_manjarite() -> void:
	_bisa_tenggelam = false
	DuniaPulau.dasar_dangkal(self, Vector3(0, -1.4, 0), 40.0, Color("c8b88a"))
	DuniaPulau.kapal(self, Vector3(0, 0, 20), 0.0)
	_tangga_kapal(Vector3(0, 0, 20), 0.0)
	for k: Array in data.get("kapal_berlabuh", []):
		var pos := Vector3(k[0], 0, k[1])
		DuniaPulau.kapal(self, pos, float(k[2]), Color("d8e8f0") if int(k[0]) % 2 == 0 else Color("f4e0c0"))
		_tangga_kapal(pos, float(k[2]))
	for k: Array in data.get("karang", []):
		var p := _v3(k)
		DuniaPulau.karang(self, p)
		_karang.append(p)
	_arus = data.get("arus", [])
	var m_buih := Dunia.mat(Color(1, 1, 1, 0.7))
	m_buih.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for z: Dictionary in _arus:
		var dorong := Vector2(z["dorong"][0], z["dorong"][1])
		for i in 8:
			var garis := BoxMesh.new()
			garis.size = Vector3(1.2, 0.02, 0.12) if absf(dorong.x) > absf(dorong.y) else Vector3(0.12, 0.02, 1.2)
			var mi := Dunia.mesh(self, garis, Vector3.ZERO, m_buih)
			_garis_arus.append([mi, z, randf(), randf()])
	_papan_info(Vector3(-1.0, DuniaPulau.Y_DEK, 17.0), "Info Awak Kapal")
	_titik_muncul = Vector3(0, DuniaPulau.Y_DEK + 0.2, 17.6)
	_titik_keluar = Vector3(0.6, DuniaPulau.Y_DEK, 18.8)


## Tangga landai dari dasar laut ke dek kapal (sisi kanan kapal), untuk naik dari air.
func _tangga_kapal(pos: Vector3, rot: float) -> void:
	var basis := Basis(Vector3.UP, rot)
	var bawah: Vector3 = pos + basis * Vector3(5.6, 0, 0)
	var atas: Vector3 = pos + basis * Vector3(1.4, 0, 0)
	DuniaLingko.tanjakan(self, Vector3(bawah.x, -1.4, bawah.z), Vector3(atas.x, DuniaPulau.Y_DEK, atas.z), 1.4)


func _bangun_titik_keluar() -> void:
	var area := Interaktif.new()
	area.teks_petunjuk = "Kembali ke kapal"
	area.jari_jari = 1.6
	area.position = _titik_keluar
	add_child(area)
	area.diinteraksi.connect(_tanya_pulang)


static func _v3(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


# ================================================================== wisatawan

func _bangun_wisatawan() -> void:
	for w: Dictionary in data["wisatawan"]:
		var n := NpcKampung.new()
		n.nama = str(w["nama"])
		n.wisatawan = true
		n.warna_baju = Color(str(w.get("baju", "2c5c96")))
		n.warna_celana = Color(str(w.get("celana", "c8b48a")))
		n.warna_topi = Color(str(w.get("topi", "e8dcb8")))
		n.perempuan = w.get("perempuan", false)
		n.position = _v3(w["pos"])
		if jenis == "komodo" and n.nama.begins_with("Ranger"):
			# Ranger menyusuri jalur bersama wisatawan
			for t: Array in data["jalur"]:
				n.titik_patroli.append(_v3(t))
			n.lama_diam_min = 2.0
			n.lama_diam_maks = 4.0
			n.kecepatan = 1.2
		add_child(n)
		var ke_kamera: Vector3 = Vector3(0, 0, 6)
		n.model.rotation.y = atan2(-ke_kamera.x, -ke_kamera.z) + randf_range(-0.6, 0.6)
		n.diajak_bicara.connect(_bicara)
		_npc.append(n)
		_status[n] = "ada"
		_data_npc[n] = w


func _bicara(npc: NpcKampung) -> void:
	var w: Dictionary = _data_npc[npc]
	if not w.get("pembeli", false):
		DialogManager.mulai_baris("info_wisatawan", _baris(npc.nama, w["info"]))
		return
	match str(_status[npc]):
		"terjual":
			DialogManager.mulai_baris("sudah_beli", _baris(npc.nama, DataLabuanBajo.teks("sudah_beli")))
		"pergi":
			DialogManager.mulai_baris("sudah_pergi", _baris(npc.nama, DataLabuanBajo.teks("sudah_pergi")))
		_:
			if _tuntas or _gagal:
				return
			DialogManager.mulai_baris("minta", _baris(npc.nama, w["keinginan"]), _mulai_jual.bind(npc))


func _mulai_jual(npc: NpcKampung) -> void:
	var jual: JualSongke = JUAL.new()
	jual.siapkan(_data_npc[npc], DataLabuanBajo.barang_dibawa(), GameState.mode_sulit)
	jual.selesai.connect(_hasil_jual.bind(npc, jual))
	jual.salah.connect(Nyawa.kurangi)
	_minigame = jual
	# Nyawa habis saat menawarkan: tawaran ditutup, wisatawan tetap bisa ditawari lagi
	Nyawa.atur_tantangan("Menawarkan kepada %s" % npc.nama, func() -> void:
		if is_instance_valid(_minigame):
			_minigame.queue_free()
		_minigame = null
		GameState.ubah_state(GameState.State.BERMAIN)
		_atur_tantangan_jelajah())
	add_child(jual)


func _hasil_jual(berhasil: bool, npc: NpcKampung, jual: JualSongke) -> void:
	_minigame = null
	_atur_tantangan_jelajah()
	if berhasil:
		_status[npc] = "terjual"
		_terjual += 1
		npc.area.ubah_petunjuk("Terima kasih")
		_perbarui_tujuan()
		if _terjual >= TARGET_PEMBELI:
			_pulau_tuntas()
		else:
			_toast("Terjual %d/%d!" % [_terjual, TARGET_PEMBELI])
		return
	if not jual.pergi:
		return  # dibatalkan pemain; wisatawan masih bisa ditawari lagi
	_status[npc] = "pergi"
	var tw := create_tween()
	tw.tween_property(npc, "scale", Vector3(0.01, 0.01, 0.01), 0.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(npc.queue_free)
	_npc.erase(npc)
	if _calon_pembeli() + _terjual < TARGET_PEMBELI:
		_gagal_pulau("gagal_pulau")
	else:
		_toast(DataLabuanBajo.teks("sisa_pembeli"))


## Jumlah pembeli yang masih bisa ditawari.
func _calon_pembeli() -> int:
	var n: int = 0
	for npc: Variant in _status:  # kunci bisa berupa NPC yang sudah dihapus, jadi tidak diberi tipe
		if _status[npc] == "ada" and (_data_npc[npc] as Dictionary).get("pembeli", false):
			n += 1
	return n


func _baris(nama: String, isi: Variant) -> Array:
	var daftar: Array = isi if isi is Array else [isi]
	var baris: Array = []
	for teks: String in daftar:
		baris.append({"nama": nama, "teks": teks})
	return baris


func _perbarui_tujuan() -> void:
	GameState.atur_tujuan("%s: jual kain/foto ke %d wisatawan (terjual %d/%d). Pilih barang yang cocok, lalu ceritakan maknanya." % [
		data["nama"], TARGET_PEMBELI, _terjual, TARGET_PEMBELI])


func _baca_info(_p: Pemain) -> void:
	var id: String = str(data["kartu"])
	DialogManager.mulai_baris("info_pulau", data["info"], func() -> void:
		if GameState.kumpulkan_kartu(id):
			DialogManager.tampilkan_kartu(id))


func _pulau_tuntas() -> void:
	_tuntas = true
	_waktu_berjalan = false
	AudioManager.putar_sfx("gong")
	DialogManager.mulai_baris("pulau_tuntas", _baris("Nggohak", data["selesai"]), func() -> void:
		var id: String = str(data["kartu"])
		if GameState.kumpulkan_kartu(id):
			DialogManager.tampilkan_kartu(id, _ke_peta_tuntas)
		else:
			_ke_peta_tuntas())


func _ke_peta_tuntas() -> void:
	GameState.selesaikan_pulau(GameState.pulau_aktif, _terjual)


func _gagal_pulau(id_teks: String) -> void:
	if _gagal or _tuntas:
		return
	_gagal = true
	_waktu_berjalan = false
	AudioManager.putar_sfx("gagal")
	DialogManager.mulai_baris("gagal_pulau", _baris("Nggohak", DataLabuanBajo.teks(id_teks)), GameState.ulangi_pulau)


func _tanya_pulang(_p: Pemain) -> void:
	if _tuntas or _gagal:
		return
	DialogManager.ajukan_teka_teki("Nggohak", DataLabuanBajo.teks("tanya_pulang"), ["Ya, kembali ke peta", "Tidak, lanjut menjual"], 0,
			func(ya: bool) -> void:
				if ya:
					GameState.ulangi_level())


# ================================================================== mekanik khas

func _minum(_p: Pemain, i: int) -> void:
	if _pos_air_dipakai[i]:
		_toast(DataLabuanBajo.teks("pos_kosong"))
		return
	_pos_air_dipakai[i] = true
	_stamina = 100.0
	_sudah_haus = false
	AudioManager.putar_sfx("ambil")
	_toast(DataLabuanBajo.teks("minum"))


func _pungut_sampah(_p: Pemain, sampah: Node3D) -> void:
	AudioManager.putar_sfx("ambil")
	_toast(DataLabuanBajo.teks("sampah"))
	sampah.queue_free()


## Tantangan jelajah pulau: nyawa habis = kembali ke dermaga (penjualan yang sudah terjadi tetap).
func _atur_tantangan_jelajah() -> void:
	Nyawa.atur_tantangan("Menjelajah %s" % data["nama"], func() -> void:
		pemain.velocity = Vector3.ZERO
		pemain.global_position = _titik_muncul
		_titik_aman = _titik_muncul
		_stamina = 100.0)


func _munculkan_pemain() -> void:
	pemain = ADEGAN_PEMAIN.instantiate()
	add_child(pemain)
	pemain.global_position = _titik_muncul
	pemain.model.rotation.y = 0.0
	_titik_aman = _titik_muncul
	kamera = KameraIkut.new()
	kamera.target = pemain
	add_child(kamera)
	kamera.current = true


func _process(delta: float) -> void:
	var aktif: bool = GameState.sedang(GameState.State.BERMAIN) or GameState.sedang(GameState.State.MINIGAME)
	if _waktu_berjalan and aktif and not _tuntas and not _gagal:
		_sisa_waktu = maxf(_sisa_waktu - delta, 0.0)
		if _sisa_waktu <= 0.0:
			_gagal_pulau("waktu_habis")
	if jenis == "taka" and aktif and not _tuntas and not _gagal:
		_pasang = minf(_pasang + delta / _batas_waktu, 1.0)
		_atur_pasang()
		if _pasang >= 1.0:
			_gagal_pulau("tenggelam")
	for g: Array in _garis_arus:
		_gerak_garis_arus(g, delta)
	_perbarui_ui()


func _physics_process(delta: float) -> void:
	if pemain == null or _tuntas or _gagal:
		return
	_jeda_kembali = maxf(_jeda_kembali - delta, 0.0)
	var p: Vector3 = pemain.global_position
	var di_air: bool = p.y < -0.1
	pemain.kecepatan = KECEPATAN_AIR if di_air else KECEPATAN_DARAT
	if jenis == "padar":
		_perbarui_stamina(delta)
	if not GameState.sedang(GameState.State.BERMAIN) or _jeda_kembali > 0.0:
		return
	if _bisa_tenggelam and p.y < Y_TENGGELAM:
		_kembali_aman(DataLabuanBajo.teks("jatuh_laut"), DENDA_JATUH)
		return
	for k: Vector3 in _karang:
		if Vector2(p.x - k.x, p.z - k.z).length() < 1.1 and p.y < k.y + 0.7:
			_kembali_aman(DataLabuanBajo.teks("karang"), DENDA_JATUH)
			return
	var bahaya: float = 3.5 if GameState.mode_sulit else 3.0
	for k: Komodo in _komodo:
		if Vector2(p.x - k.position.x, p.z - k.position.z).length() < bahaya:
			_kembali_aman(DataLabuanBajo.teks("komodo_dekat"), DENDA_KOMODO)
			return
	if di_air:
		for z: Dictionary in _arus:
			if p.x > z["min"][0] and p.x < z["max"][0] and p.z > z["min"][1] and p.z < z["max"][1]:
				pemain.move_and_collide(Vector3(z["dorong"][0], 0, z["dorong"][1]) * delta)
				if not _sudah_kena_arus:
					_sudah_kena_arus = true
					_toast(DataLabuanBajo.teks("arus"))
	if pemain.is_on_floor() and _pijakan_aman(p):
		_titik_aman = p


## Titik aman: tanah padat di sekeliling kaki, jauh dari karang dan komodo.
func _pijakan_aman(p: Vector3) -> bool:
	for k: Vector3 in _karang:
		if Vector2(p.x - k.x, p.z - k.z).length() < 2.2:
			return false
	for k: Komodo in _komodo:
		if Vector2(p.x - k.position.x, p.z - k.position.z).length() < 6.5:
			return false
	return _tanah_padat(p)


func _tanah_padat(p: Vector3) -> bool:
	var ruang := get_world_3d().direct_space_state
	for geser: Vector3 in [Vector3(0.35, 0, 0), Vector3(-0.35, 0, 0), Vector3(0, 0, 0.35), Vector3(0, 0, -0.35)]:
		var q := PhysicsRayQueryParameters3D.create(p + geser + Vector3(0, 0.5, 0), p + geser + Vector3(0, -0.4, 0), Dunia.LAPISAN_DUNIA)
		q.exclude = [pemain.get_rid()]
		if ruang.intersect_ray(q).is_empty():
			return false
	return true


func _kembali_aman(pesan: String, denda: float) -> void:
	_jeda_kembali = 0.8
	AudioManager.putar_sfx("terkena", 0.1)
	kamera.guncang(0.4)
	var tujuan: Vector3 = _titik_aman
	if not _tanah_padat(tujuan):
		tujuan = _titik_muncul  # titik aman sudah tenggelam (pasang) atau tidak lagi aman
	for k: Komodo in _komodo:
		if Vector2(tujuan.x - k.position.x, tujuan.z - k.position.z).length() < 5.0:
			tujuan = _titik_muncul
	pemain.velocity = Vector3.ZERO
	pemain.global_position = tujuan + Vector3(0, 0.15, 0)
	pemain.model.squash(Vector3(1.2, 0.8, 1.2))
	Nyawa.kurangi(pesan)
	if _waktu_berjalan:
		_sisa_waktu = maxf(_sisa_waktu - denda, 0.0)
		_toast(pesan + "  (-%d detik)" % int(denda))
	else:
		_toast(pesan)


## Padar: tenaga berkurang saat berjalan (lebih cepat di tanjakan dan di Mode Sulit).
func _perbarui_stamina(delta: float) -> void:
	if not GameState.sedang(GameState.State.BERMAIN):
		return
	if pemain.kecepatan_horizontal() > 0.5:
		var laju: float = 3.6 if GameState.mode_sulit else 2.2
		if pemain.velocity.y > 0.1:
			laju *= 1.6
		_stamina = maxf(_stamina - laju * delta, 0.0)
	if _stamina <= 0.0:
		pemain.kecepatan = 2.4
		pemain.kekuatan_lompat = 5.6
		if not _sudah_haus:
			_sudah_haus = true
			_toast(DataLabuanBajo.teks("haus"))
	else:
		pemain.kekuatan_lompat = 7.0


## Taka Makassar: cakram pasir menyempit dan ujung-ujung sabit tenggelam saat air pasang.
func _atur_pasang() -> void:
	var jari: float = lerpf(3.0, 1.3, _pasang)
	var tenggelam: int = int(floor(_pasang * 5.0))
	for c: Array in _cakram:
		var mi: MeshInstance3D = c[0]
		var bentuk: CollisionShape3D = c[1]
		var i: int = c[2]
		var tampak: bool = i >= tenggelam and i < 15 - tenggelam
		mi.visible = tampak
		mi.scale = Vector3(jari / 3.0, 1.0, jari / 3.0)
		(bentuk.shape as CylinderShape3D).radius = jari
		if bentuk.disabled == tampak:
			bentuk.set_deferred("disabled", not tampak)


## Manjarite: garis buih bergerak searah arus sebagai penanda visual.
func _gerak_garis_arus(g: Array, delta: float) -> void:
	var mi: MeshInstance3D = g[0]
	var z: Dictionary = g[1]
	var dorong := Vector2(z["dorong"][0], z["dorong"][1])
	var lebar := Vector2(z["max"][0] - z["min"][0], z["max"][1] - z["min"][1])
	var maju: Vector2 = dorong.normalized()
	var arah_lebar: float = lebar.x if absf(maju.x) > 0.5 else lebar.y
	g[2] = fposmod(float(g[2]) + delta * dorong.length() / maxf(arah_lebar, 1.0), 1.0)
	var t: float = g[2]
	var s: float = g[3]
	var x: float
	var y: float
	if absf(maju.x) > 0.5:
		x = z["min"][0] + lebar.x * (t if maju.x > 0 else 1.0 - t)
		y = z["min"][1] + lebar.y * s
	else:
		x = z["min"][0] + lebar.x * s
		y = z["min"][1] + lebar.y * (t if maju.y > 0 else 1.0 - t)
	mi.position = Vector3(x, DuniaPulau.Y_LAUT + 0.03, y)


# ================================================================== UI

func _bangun_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 11
	add_child(_ui)
	_label_waktu = Gaya.label("", 10, Gaya.KUNING)
	_label_waktu.position = Vector2(456, 12)
	_ui.add_child(_label_waktu)
	_label_toast = Gaya.label("", 10, Gaya.PUTIH)
	_label_toast.position = Vector2(120, 92)
	_label_toast.size = Vector2(400, 40)
	_label_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_toast.modulate.a = 0.0
	_ui.add_child(_label_toast)
	if jenis == "padar" or jenis == "taka":
		_label_bar = Gaya.label("Tenaga" if jenis == "padar" else "Air pasang", 9, Gaya.PUTIH)
		_label_bar.position = Vector2(456, 46)
		_ui.add_child(_label_bar)
		_bar = Control.new()
		_bar.position = Vector2(456, 62)
		_bar.size = Vector2(150, 10)
		_bar.draw.connect(_gambar_bar)
		_ui.add_child(_bar)
	GameState.state_berubah.connect(func(_l: int, baru: int) -> void:
		if is_instance_valid(_ui):
			_ui.visible = baru != GameState.State.DIALOG and baru != GameState.State.MINIGAME)


func _gambar_bar() -> void:
	var nilai: float = _stamina / 100.0 if jenis == "padar" else _pasang
	var warna: Color = Gaya.HIJAU if jenis == "padar" else Color("5fa8d3")
	if jenis == "padar" and nilai < 0.25:
		warna = Gaya.MERAH
	_bar.draw_rect(Rect2(Vector2.ZERO, _bar.size), Gaya.HITAM)
	_bar.draw_rect(Rect2(Vector2(1, 1), Vector2((_bar.size.x - 2) * nilai, _bar.size.y - 2)), warna)
	_bar.draw_rect(Rect2(Vector2.ZERO, _bar.size), Gaya.KUNING, false, 1.0)


func _perbarui_ui() -> void:
	if _waktu_berjalan:
		var d: int = int(ceil(_sisa_waktu))
		_label_waktu.text = "Waktu: %d:%02d" % [d / 60, d % 60]
	elif jenis == "taka":
		var d: int = int(ceil(_batas_waktu * (1.0 - _pasang)))
		_label_waktu.text = "Sebelum pasang: %d:%02d" % [d / 60, d % 60]
	else:
		_label_waktu.text = ""
	if _bar:
		_bar.queue_redraw()


func _toast(teks: String) -> void:
	_label_toast.text = teks
	_label_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(_label_toast, "modulate:a", 0.0, 0.6)
