extends Node3D
## Level 3: satu destinasi Taman Nasional Komodo (data: data/labuan_bajo.json, indeks GameState.pulau_aktif).
## Inti: temukan wisatawan, pilih kain/foto yang cocok, ceritakan maknanya (mini-game JualSongke).
## Target 3 pembeli per pulau. Mekanik khas tiap destinasi (kesulitan naik berurutan):
##   pelabuhan - tutorial menjual
##   padar     - mendaki 3 pos; tenaga berkurang saat berjalan, minum di pos
##   pink      - pantai & air dangkal; jangan menginjak karang; WAJIB pungut 5 sampah (pengecoh: kerang,
##               bintang laut tidak boleh diambil; penyu tidak boleh disentuh)
##   komodo    - jalur bersama ranger; terlalu dekat komodo = kembali ke titik aman; semak bergoyang
##               (angin = aman; komodo bersembunyi = goyang tak teratur + jejak kaki + ekor mencuat)
##   taka      - pulau pasir sabit menyempit karena air pasang (batas waktu alami)
##   manjarite - berenang antar-kapal; arus mendorong pemain; jangan menginjak karang; WAJIB pungut
##               5 sampah; terseret melewati garis pelampung = -1 nyawa
## Semua wisatawan bisa diajak ngobrol; ciri calon pembeli tampil di panel kanan.
## Menawarkan songke kepada yang bukan pembeli = -1 nyawa.
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
const TARGET_SAMPAH: int = 5
const JARAK_SENTUH_PENYU: float = 1.1
const JARAK_SEMAK: float = 2.3
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
var _sampah_wajib: int = 0  ## 0 = pulau tanpa syarat sampah
var _sampah_dipungut: int = 0
var _salah_jual: int = 0  ## salah barang/cerita di pulau ini (pencapaian "Penjual Andal")
var _salah_laut: int = 0  ## mengambil pengecoh, menyentuh satwa, menginjak karang (untuk pencapaian "Sahabat Laut")
var _penyu: Array[Penyu] = []
var _ikan: Array[KawananIkan] = []
var _jeda_ikan: float = 0.0
var _semak: Array = []  ## [Semak, Komodo]
var _batu: Array = []  ## {"mi", "bentuk", "atas", "goyah", "t", "runtuh"}
var _batas_arus: float = 0.0
var _pos_terakhir: Vector3 = Vector3.INF  ## pos minum terakhir (Padar)

# UI
var _ui: CanvasLayer
var _label_waktu: Label
var _label_toast: Label
var _bar: Control
var _label_bar: Label
var _panel_ciri: PanelCiri
var _pembeli: Array[NpcKampung] = []


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
			func() -> void: _obrol(pemain, "Nggohak", data["pembuka"].map(func(b: Dictionary) -> String: return str(b["teks"]))))


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
	for b: Dictionary in data.get("batu_pintas", []):
		_batu_pijakan(_v3(b["pos"]), b.get("goyah", false))
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
	_bangun_laut()
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
	for d: Dictionary in data.get("semak", []):
		var i: int = int(d["ruas"])
		var a: Vector3 = _v3(jalur[i])
		var b: Vector3 = _v3(jalur[i + 1])
		var arah: Vector3 = (b - a).normalized()
		var normal := Vector3(-arah.z, 0, arah.x) * float(d.get("sisi", 1))
		var semak := Semak.new()
		semak.bersembunyi = d.get("komodo", false)
		semak.position = a.lerp(b, float(d.get("t", 0.5))) + normal * 2.0
		semak.rotation.y = atan2(-normal.x, -normal.z)  # sumbu +Z lokal (jejak kaki) menghadap jalur
		add_child(semak)
		var komodo: Komodo = null
		if semak.bersembunyi:
			komodo = Komodo.new()
			komodo.titik_a = semak.position + normal * 0.5
			komodo.titik_b = komodo.titik_a
			komodo.kecepatan = 0.0
			komodo.rotation.y = semak.rotation.y  # kepala menjauhi jalur, ekor mencuat ke arah jalur
			add_child(komodo)
		_semak.append([semak, komodo])
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
	_bangun_laut()
	_batas_arus = float(data.get("batas_arus", 0.0))
	if _batas_arus > 0.0:
		# Garis pelampung merah-putih: batas aman berenang
		for i in 36:
			var a: float = TAU * i / 36.0
			var b := SphereMesh.new()
			b.radius = 0.25
			b.height = 0.4
			b.radial_segments = 8
			b.rings = 4
			Dunia.mesh(self, b, Vector3(cos(a) * _batas_arus, DuniaPulau.Y_LAUT + 0.05, sin(a) * _batas_arus),
					Dunia.mat(Color("d83a2a") if i % 2 == 0 else Color("f4f2ea")))
	_papan_info(Vector3(-1.0, DuniaPulau.Y_DEK, 17.0), "Info Awak Kapal")
	_titik_muncul = Vector3(0, DuniaPulau.Y_DEK + 0.2, 17.6)
	_titik_keluar = Vector3(0.6, DuniaPulau.Y_DEK, 18.8)


## Sampah wajib + pengecoh laut (kerang, bintang laut) + penyu + kawanan ikan. Semua benda yang bisa
## dipungut berpetunjuk sama ("Pungut") agar pemain harus mengenali bendanya sendiri.
func _bangun_laut() -> void:
	var daftar_sampah: Array = data.get("sampah", [])
	_sampah_wajib = mini(TARGET_SAMPAH, daftar_sampah.size())
	for s: Array in daftar_sampah:
		var n := DuniaPulau.sampah(self, _v3(s))
		_jadikan_pungutan(n, "sampah")
	for d: Dictionary in data.get("laut_pengecoh", []):
		var jenis_benda: String = str(d["jenis"])
		var n: Node3D = DuniaPulau.kerang(self, _v3(d["pos"])) if jenis_benda == "kerang" else DuniaPulau.bintang_laut(self, _v3(d["pos"]))
		_jadikan_pungutan(n, jenis_benda)
	for d: Dictionary in data.get("penyu", []):
		var penyu := Penyu.new()
		penyu.titik_a = _v3(d["a"])
		penyu.titik_b = _v3(d["b"])
		add_child(penyu)
		_penyu.append(penyu)
	for d: Array in data.get("ikan", []):
		var ikan := KawananIkan.new()
		ikan.position = _v3(d)
		add_child(ikan)
		_ikan.append(ikan)


func _jadikan_pungutan(n: Node3D, jenis_benda: String) -> void:
	var area := Interaktif.new()
	area.teks_petunjuk = "Pungut"
	area.jari_jari = 1.5
	n.add_child(area)
	area.diinteraksi.connect(_pungut.bind(n, jenis_benda))


## Batu pijakan jalan pintas Padar. Batu goyah: lebih gelap, miring, bergaris retak; runtuh 0,35 detik
## setelah diinjak (-1 nyawa), pulih 4 detik kemudian.
func _batu_pijakan(atas: Vector3, goyah: bool) -> void:
	var kotak := BoxMesh.new()
	kotak.size = Vector3(1.3, 0.6, 1.3)
	var warna := Color("6a625a") if goyah else Color("a09a8c")
	var mi := Dunia.mesh(self, kotak, atas - Vector3(0, 0.3, 0), Dunia.mat(warna, Dunia.TEX_BATU))
	if goyah:
		mi.rotation = Vector3(0.1, 0.4, -0.12)
		for i in 2:
			var retak := BoxMesh.new()
			retak.size = Vector3(0.05, 0.02, 0.9)
			var r := Dunia.mesh(mi, retak, Vector3(-0.2 + i * 0.35, 0.31, 0), Dunia.mat(Color("1b1818")))
			r.rotation.y = 0.5 - i
	var bentuk := BoxShape3D.new()
	bentuk.size = kotak.size
	var badan := Dunia.badan_statis(self, bentuk, atas - Vector3(0, 0.3, 0))
	if goyah:
		badan.set_meta("rapuh", true)
	_batu.append({"mi": mi, "badan": badan, "atas": atas, "goyah": goyah, "t": -1.0, "runtuh": false})


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
		if w.get("pembeli", false):
			_pembeli.append(n)


func _bicara(npc: NpcKampung) -> void:
	var w: Dictionary = _data_npc[npc]
	if w.get("lokal", false):
		_obrol(npc, npc.nama, w["info"])
		return
	match str(_status[npc]):
		"terjual":
			_obrol(npc, npc.nama, DataLabuanBajo.teks("sudah_beli"))
		"pergi":
			_obrol(npc, npc.nama, DataLabuanBajo.teks("sudah_pergi"))
		_:
			if _tuntas or _gagal:
				return
			var pilihan: Array = DataLabuanBajo.dialog().get("tawar_pilihan", ["Tawarkan songke", "Ngobrol saja"])
			DialogManager.ajukan_pilihan("Nggohak", DataLabuanBajo.teks("tawar_tanya") % npc.nama, pilihan,
					_pilih_tawaran.bind(npc))


## 0 = tawarkan songke, 1 = ngobrol. Menawarkan kepada yang bukan pembeli = -1 nyawa.
func _pilih_tawaran(indeks: int, npc: NpcKampung) -> void:
	if not is_instance_valid(npc):
		return
	var w: Dictionary = _data_npc[npc]
	var pembeli: bool = w.get("pembeli", false)
	if indeks != 0:
		_obrol(npc, npc.nama, w.get("keinginan", "") if pembeli else w["info"])
		return
	if not pembeli:
		_obrol(npc, npc.nama, DataLabuanBajo.teks("bukan_pembeli"))
		AudioManager.putar_sfx("gagal")
		Nyawa.kurangi(DataLabuanBajo.teks("bukan_pembeli_nyawa"))
		return
	# Keinginan wisatawan langsung tampil di layar tawaran (tanpa panel dialog terpisah)
	_obrol(npc, npc.nama, w["keinginan"])
	_mulai_jual(npc)


func _mulai_jual(npc: NpcKampung) -> void:
	var jual: JualSongke = JUAL.new()
	jual.siapkan(_data_npc[npc], DataLabuanBajo.barang_dibawa(), GameState.mode_sulit)
	jual.selesai.connect(_hasil_jual.bind(npc, jual))
	jual.salah.connect(Nyawa.kurangi)
	jual.salah.connect(func(_p: String) -> void: _salah_jual += 1)
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
		if not _cek_tuntas():
			_toast("Terjual %d/%d!" % [_terjual, TARGET_PEMBELI] if _terjual < TARGET_PEMBELI else DataLabuanBajo.teks("belum_sampah"))
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


## Obrolan ringan sebagai gelembung teks di atas tokoh (pemain tetap bisa bergerak).
func _obrol(target: Node3D, nama: String, isi: Variant) -> void:
	var daftar: Array = isi if isi is Array else [isi]
	DialogManager.gelembung(target, daftar, nama, 3.6 if target == pemain else 4.1)


func _baris(nama: String, isi: Variant) -> Array:
	var daftar: Array = isi if isi is Array else [isi]
	var baris: Array = []
	for teks: String in daftar:
		baris.append({"nama": nama, "teks": teks})
	return baris


## Pulau tuntas bila 3 pembeli DAN (di Pink Beach & Manjarite) 5 sampah sudah dipungut.
func _cek_tuntas() -> bool:
	if _tuntas or _gagal or _terjual < TARGET_PEMBELI or _sampah_dipungut < _sampah_wajib:
		return false
	_pulau_tuntas()
	return true


func _perbarui_tujuan() -> void:
	var teks: String = "%s: jual kain/foto ke %d wisatawan (terjual %d/%d). Cocokkan ciri pembeli di panel kanan." % [
		data["nama"], TARGET_PEMBELI, _terjual, TARGET_PEMBELI]
	if _sampah_wajib > 0:
		teks += " Pungut sampah plastik: %d/%d." % [_sampah_dipungut, _sampah_wajib]
	GameState.atur_tujuan(teks)
	if _panel_ciri:
		_panel_ciri.queue_redraw()


func _baca_info(_p: Pemain) -> void:
	var id: String = str(data["kartu"])
	_obrol(pemain, "Nggohak", data["info"].map(func(b: Dictionary) -> String: return str(b["teks"])))
	if GameState.kumpulkan_kartu(id):
		DialogManager.tampilkan_kartu(id)


func _pulau_tuntas() -> void:
	_tuntas = true
	if _salah_jual == 0:
		Prestasi.raih("penjual_andal")
	if _sampah_wajib > 0 and _salah_laut == 0 and Prestasi.tandai("laut_" + jenis, ["laut_pink", "laut_manjarite"]):
		Prestasi.raih("sahabat_laut")
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
	_pos_terakhir = _v3(data["pos_air"][i]) + Vector3(0, 0.3, 1.2)
	_stamina = 100.0
	_sudah_haus = false
	AudioManager.putar_sfx("ambil")
	_toast(DataLabuanBajo.teks("minum"))


func _pungut(_p: Pemain, benda: Node3D, jenis_benda: String) -> void:
	if jenis_benda != "sampah":
		# Pengecoh: kerang & bintang laut adalah bagian ekosistem, tidak boleh diambil
		_salah_laut += 1
		AudioManager.putar_sfx("gagal")
		kamera.guncang(0.3)
		_obrol(pemain, "Nggohak", DataLabuanBajo.teks(jenis_benda))
		Nyawa.kurangi(DataLabuanBajo.teks(jenis_benda))
		return
	AudioManager.putar_sfx("ambil")
	_sampah_dipungut += 1
	_toast("%s (%d/%d)" % [DataLabuanBajo.teks("sampah"), _sampah_dipungut, _sampah_wajib])
	benda.queue_free()
	_perbarui_tujuan()
	_cek_tuntas()


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
	_perbarui_batu(delta, p)
	_jeda_ikan = maxf(_jeda_ikan - delta, 0.0)
	if not GameState.sedang(GameState.State.BERMAIN) or _jeda_kembali > 0.0:
		return
	if _bisa_tenggelam and p.y < Y_TENGGELAM:
		_kembali_aman(DataLabuanBajo.teks("jatuh_laut"), DENDA_JATUH)
		return
	for k: Vector3 in _karang:
		if Vector2(p.x - k.x, p.z - k.z).length() < 1.1 and p.y < k.y + 0.7:
			_salah_laut += 1
			_kembali_aman(DataLabuanBajo.teks("karang"), DENDA_JATUH)
			return
	if _cek_bahaya_baru(p):
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
	for sm: Array in _semak:
		if (sm[0] as Semak).bersembunyi and Vector2(p.x - sm[0].position.x, p.z - sm[0].position.z).length() < JARAK_SEMAK + 1.5:
			return false
	for py: Penyu in _penyu:
		if Vector2(p.x - py.position.x, p.z - py.position.z).length() < 3.0:
			return false
	if _batas_arus > 0.0 and Vector2(p.x, p.z).length() > _batas_arus - 3.0:
		return false
	return _tanah_padat(p)


func _tanah_padat(p: Vector3) -> bool:
	var ruang := get_world_3d().direct_space_state
	for geser: Vector3 in [Vector3(0.35, 0, 0), Vector3(-0.35, 0, 0), Vector3(0, 0, 0.35), Vector3(0, 0, -0.35)]:
		var q := PhysicsRayQueryParameters3D.create(p + geser + Vector3(0, 0.5, 0), p + geser + Vector3(0, -0.4, 0), Dunia.LAPISAN_DUNIA)
		q.exclude = [pemain.get_rid()]
		var hasil: Dictionary = ruang.intersect_ray(q)
		if hasil.is_empty() or (hasil["collider"] as Object).has_meta("rapuh"):
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
	if _stamina < 25.0 and not _sudah_haus:
		_sudah_haus = true
		_toast(DataLabuanBajo.teks("haus"))
	if _stamina <= 0.0 and _jeda_kembali <= 0.0:
		# Kehabisan tenaga: -1 nyawa, kembali ke pos minum terakhir dengan tenaga penuh
		_jeda_kembali = 0.8
		AudioManager.putar_sfx("terkena", 0.1)
		kamera.guncang(0.3)
		pemain.velocity = Vector3.ZERO
		pemain.global_position = _pos_terakhir if _pos_terakhir != Vector3.INF else _titik_muncul
		_titik_aman = pemain.global_position
		_stamina = 100.0
		_sudah_haus = false
		Nyawa.kurangi(DataLabuanBajo.teks("kehabisan_tenaga"))
		_toast(DataLabuanBajo.teks("kehabisan_tenaga"))


## Pengecoh tahap 6: penyu, kawanan ikan, semak berkomodo, garis pelampung. true = pemain dipindahkan.
func _cek_bahaya_baru(p: Vector3) -> bool:
	for py: Penyu in _penyu:
		if Vector2(p.x - py.position.x, p.z - py.position.z).length() < JARAK_SENTUH_PENYU and absf(p.y - py.position.y) < 1.2:
			_salah_laut += 1
			_obrol(pemain, "Nggohak", DataLabuanBajo.teks("penyu"))
			_kembali_aman(DataLabuanBajo.teks("penyu"), DENDA_JATUH)
			return true
	for ik: KawananIkan in _ikan:
		if _jeda_ikan <= 0.0 and Vector2(p.x - ik.position.x, p.z - ik.position.z).length() < 1.3:
			_jeda_ikan = 3.0
			_salah_laut += 1
			ik.kaget()
			AudioManager.putar_sfx("terkena", 0.1)
			_obrol(pemain, "Nggohak", DataLabuanBajo.teks("ikan"))
			Nyawa.kurangi(DataLabuanBajo.teks("ikan"))
	for sm: Array in _semak:
		var semak: Semak = sm[0]
		if semak.bersembunyi and Vector2(p.x - semak.position.x, p.z - semak.position.z).length() < JARAK_SEMAK:
			_komodo_menerjang(sm[1], p)
			_kembali_aman(DataLabuanBajo.teks("semak_komodo"), DENDA_KOMODO)
			return true
	if _batas_arus > 0.0 and Vector2(p.x, p.z).length() > _batas_arus:
		_kembali_aman(DataLabuanBajo.teks("terseret"), DENDA_JATUH)
		return true
	return false


## Batu goyah Padar: runtuh 0,35 detik setelah diinjak, pulih 4 detik kemudian.
func _perbarui_batu(delta: float, p: Vector3) -> void:
	for b: Dictionary in _batu:
		if not b["goyah"]:
			continue
		var atas: Vector3 = b["atas"]
		var mi: MeshInstance3D = b["mi"]
		if b["runtuh"]:
			b["t"] += delta
			if b["t"] > 4.0:
				b["runtuh"] = false
				b["t"] = -1.0
				mi.position = atas - Vector3(0, 0.3, 0)
				mi.visible = true
				(b["badan"] as StaticBody3D).get_child(0).set_deferred("disabled", false)
			continue
		var di_atas: bool = pemain.is_on_floor() and absf(p.x - atas.x) < 0.8 and absf(p.z - atas.z) < 0.8 and absf(p.y - atas.y) < 0.4
		if b["t"] < 0.0 and di_atas:
			b["t"] = 0.0
			AudioManager.putar_sfx("terkena", 0.2)
		if b["t"] >= 0.0:
			b["t"] += delta
			mi.position.x = atas.x + sin(b["t"] * 60.0) * 0.04  # bergetar sebelum runtuh
			if b["t"] > 0.35:
				b["runtuh"] = true
				b["t"] = 0.0
				(b["badan"] as StaticBody3D).get_child(0).set_deferred("disabled", true)
				var tw := create_tween()
				tw.tween_property(mi, "position:y", atas.y - 4.0, 0.6).set_ease(Tween.EASE_IN)
				tw.tween_callback(mi.hide)
				Nyawa.kurangi(DataLabuanBajo.teks("batu_goyah"))
				_toast(DataLabuanBajo.teks("batu_goyah"))


## Komodo yang bersembunyi menerjang keluar sebentar ke arah pemain, lalu kembali ke semak.
func _komodo_menerjang(komodo: Komodo, p: Vector3) -> void:
	if komodo == null:
		return
	var asal: Vector3 = komodo.titik_a
	var tuju: Vector3 = asal + (Vector3(p.x, asal.y, p.z) - asal).normalized() * 1.2
	var tw := create_tween()
	tw.tween_property(komodo, "position", tuju, 0.15)
	tw.tween_interval(0.6)
	tw.tween_property(komodo, "position", asal, 0.8)


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
	_panel_ciri = PanelCiri.new()
	_panel_ciri.pulau = self
	_ui.add_child(_panel_ciri)
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
	if _panel_ciri:
		_panel_ciri.queue_redraw()


func _toast(teks: String) -> void:
	_label_toast.text = teks
	_label_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(_label_toast, "modulate:a", 0.0, 0.6)
