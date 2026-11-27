extends Node3D
## Level 3: satu destinasi Taman Nasional Komodo (data: data/labuan_bajo.json, indeks GameState.pulau_aktif).
## Inti: temukan wisatawan, pilih kain/foto yang cocok, ceritakan maknanya (mini-game JualSongke).
## Target 3 pembeli per pulau. Mekanik khas tiap destinasi (kesulitan naik berurutan):
##   pelabuhan - tutorial menjual
##   padar     - mendaki 3 pos; tenaga berkurang saat berjalan, minum di pos
##   pink      - pantai & air dangkal; jangan menginjak karang; penyu dan kawanan ikan jangan diganggu
## Semua wisatawan bisa diajak ngobrol; ciri calon pembeli tampil di panel kanan.
## Menawarkan songke kepada yang bukan pembeli = -1 nyawa.
## Mode Sulit: batas waktu per pulau, salah cerita = wisatawan pergi, tenaga lebih cepat habis,
## dan denda waktu saat jatuh/menginjak karang.

const ADEGAN_PEMAIN: PackedScene = preload("res://scenes/pemain.tscn")
const JUAL: Script = preload("res://scripts/minigame/jual_songke.gd")
const TARGET_PEMBELI: int = 3
const Y_TENGGELAM: float = -1.0
const DENDA_JATUH: float = 10.0
const KECEPATAN_DARAT: float = 5.0
const KECEPATAN_AIR: float = 2.8
const JARAK_SENTUH_PENYU: float = 1.1
## Penambah nyawa (kelapa muda): jenis pulau -> posisi.
const POS_KELAPA: Dictionary = {"padar": Vector3(3.5, 2.2, 10.0), "pink": Vector3(-7.0, 0.15, -3.0)}

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
var _stamina: float = 100.0
var _pos_air_dipakai: Array[bool] = []
var _sudah_haus: bool = false
var _salah_jual: int = 0  ## salah barang/cerita di pulau ini (pencapaian "Penjual Andal")
var _penyu: Array[Penyu] = []
var _ikan: Array[KawananIkan] = []
var _jeda_ikan: float = 0.0
var _batu: Array = []  ## {"mi", "bentuk", "atas", "goyah", "t", "runtuh"}
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
	if GameState.mode_sulit:
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


func _bangun_laut() -> void:
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
		Nyawa.kurangi(DataLabuanBajo.teks("bukan_pembeli_nyawa"), true)
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
		Efek.kilau(self, npc.global_position + Vector3(0, 1.6, 0))
		Efek.teks(self, npc.global_position + Vector3(0, 3.2, 0), "Terjual!")
		npc.area.ubah_petunjuk("Terima kasih")
		_perbarui_tujuan()
		if not _cek_tuntas():
			_toast("Terjual %d/%d!" % [_terjual, _target()])
		return
	if not jual.pergi:
		return  # dibatalkan pemain; wisatawan masih bisa ditawari lagi
	_status[npc] = "pergi"
	var tw := create_tween()
	tw.tween_property(npc, "scale", Vector3(0.01, 0.01, 0.01), 0.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(npc.queue_free)
	_npc.erase(npc)
	if _calon_pembeli() + _terjual < _target():
		_gagal_pulau("gagal_pulau")
	else:
		_toast(DataLabuanBajo.teks("sisa_pembeli"))


func _target() -> int:
	return TARGET_PEMBELI


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


## Pulau tuntas bila 3 pembeli sudah membeli.
func _cek_tuntas() -> bool:
	if _tuntas or _gagal or _terjual < _target():
		return false
	_pulau_tuntas()
	return true


func _perbarui_tujuan() -> void:
	var teks: String = "%s: jual kain/foto ke %d wisatawan (terjual %d/%d). Cocokkan ciri pembeli di panel kanan." % [
		data["nama"], _target(), _terjual, _target()]
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
			_kembali_aman(DataLabuanBajo.teks("karang"), DENDA_JATUH)
			return
	if _cek_bahaya_baru(p):
		return
	if pemain.is_on_floor() and _pijakan_aman(p):
		_titik_aman = p


## Titik aman: tanah padat di sekeliling kaki, jauh dari karang dan penyu.
func _pijakan_aman(p: Vector3) -> bool:
	for k: Vector3 in _karang:
		if Vector2(p.x - k.x, p.z - k.z).length() < 2.2:
			return false
	for py: Penyu in _penyu:
		if Vector2(p.x - py.position.x, p.z - py.position.z).length() < 3.0:
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
	var asal: Vector3 = pemain.global_position
	if asal.y < 0.0:
		Efek.percikan(self, Vector3(asal.x, DuniaPulau.Y_LAUT, asal.z))
	AudioManager.putar_sfx("terkena", 0.1)
	kamera.guncang(0.4)
	var tujuan: Vector3 = _titik_aman
	if not _tanah_padat(tujuan):
		tujuan = _titik_muncul  # titik aman tidak lagi aman
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


## Pengecoh laut: penyu dan kawanan ikan. true = pemain dipindahkan.
func _cek_bahaya_baru(p: Vector3) -> bool:
	for py: Penyu in _penyu:
		if Vector2(p.x - py.position.x, p.z - py.position.z).length() < JARAK_SENTUH_PENYU and absf(p.y - py.position.y) < 1.2:
			_obrol(pemain, "Nggohak", DataLabuanBajo.teks("penyu"))
			_kembali_aman(DataLabuanBajo.teks("penyu"), DENDA_JATUH)
			return true
	for ik: KawananIkan in _ikan:
		if _jeda_ikan <= 0.0 and Vector2(p.x - ik.position.x, p.z - ik.position.z).length() < 1.3:
			_jeda_ikan = 3.0
			ik.kaget()
			AudioManager.putar_sfx("terkena", 0.1)
			_obrol(pemain, "Nggohak", DataLabuanBajo.teks("ikan"))
			Nyawa.kurangi(DataLabuanBajo.teks("ikan"))
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
				Nyawa.kurangi(DataLabuanBajo.teks("batu_goyah"), true)
				_toast(DataLabuanBajo.teks("batu_goyah"))


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
	if jenis == "padar":
		_label_bar = Gaya.label("Tenaga", 9, Gaya.PUTIH)
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
	var nilai: float = _stamina / 100.0
	var warna: Color = Gaya.HIJAU
	if nilai < 0.25:
		warna = Gaya.MERAH
	_bar.draw_rect(Rect2(Vector2.ZERO, _bar.size), Gaya.HITAM)
	_bar.draw_rect(Rect2(Vector2(1, 1), Vector2((_bar.size.x - 2) * nilai, _bar.size.y - 2)), warna)
	_bar.draw_rect(Rect2(Vector2.ZERO, _bar.size), Gaya.KUNING, false, 1.0)


func _perbarui_ui() -> void:
	if _waktu_berjalan:
		var d: int = int(ceil(_sisa_waktu))
		_label_waktu.text = "Waktu: %d:%02d" % [d / 60, d % 60]
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
