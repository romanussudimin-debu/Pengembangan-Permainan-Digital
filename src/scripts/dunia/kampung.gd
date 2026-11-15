extends Node3D
## Level utama: Kampung adat Wae Rebo dalam 3D.
## 7 Mbaru Niang melingkari compang. Delapan warga masing-masing memegang kartu budaya;
## kartu harus dikumpulkan BERURUTAN lewat rantai teka-teki (data/rantai_teka_teki.json):
## setiap warga memberi tantangan, lalu petunjuk menuju warga berikutnya.

const ADEGAN_PEMAIN: PackedScene = preload("res://scenes/pemain.tscn")
const TENUN: Script = preload("res://scripts/minigame/tenun_songke.gd")
const TABUH: Script = preload("res://scripts/minigame/tabuh_gong.gd")
const SANGRAI: Script = preload("res://scripts/minigame/sangrai_kopi.gd")
const TANGKIS: Script = preload("res://scripts/minigame/tangkis_nggiling.gd")
const DATA_RANTAI: JSON = preload("res://data/rantai_teka_teki.json")

const TITIK_MUNCUL := Vector3(0, 0.2, 22)
const PUSAT_ARENA := Vector3(26, 0, 0)

## Sudut (derajat) 7 Mbaru Niang; indeks 0 = mbaru gendang (rumah utama, utara).
const SUDUT_RUMAH: Array = [-90.0, -130.0, -170.0, 150.0, 110.0, -50.0, 40.0]
const JARI_KAMPUNG: float = 15.0

## Warga kampung pemegang kartu. "rumah" = indeks Mbaru Niang tempat ia menunggu di DALAM;
## "patroli" = titik-titik yang dikunjungi bergantian (warga berjalan/bertukar tempat).
const DATA_WARGA: Array = [
	{"nama": "Tu'a Golo", "pos": Vector3(0, 0, 5.8), "songke": "songke_kuning", "baju": Color("1b1818")},
	{"nama": "Ine Wela", "pos": Vector3(-8, 0, 0.5), "songke": "songke_hijau", "baju": Color("b02a2a"), "perempuan": true},
	{"nama": "Ema Agus", "rumah": 0, "songke": "songke_merah", "baju": Color("e8e2d2")},
	{"nama": "Ende Lono", "rumah": 5, "songke": "songke_merah", "baju": Color("2c5c96"), "perempuan": true},
	{"nama": "Fransi", "pos": Vector3(-7.2, 0, -4.6), "songke": "songke_biru", "baju": Color("e8e2d2"),
		"patroli": [Vector3(-7.2, 0, -4.6), Vector3(-3.5, 0, -10), Vector3(-1, 0, -6.5)]},
	{"nama": "Hingha", "pos": Vector3(23, 0, -4), "songke": "songke_biru", "baju": Color.WHITE, "caci": true,
		"patroli": [Vector3(23, 0, -4), Vector3(22, 0, 5), Vector3(27, 0, -6)]},
	{"nama": "Marngem", "pos": Vector3(22, 0, 5), "songke": "songke_hijau", "baju": Color("e8e2d2"), "perempuan": true, "nampan": true,
		"patroli": [Vector3(22, 0, 5), Vector3(23, 0, -4)]},
	{"nama": "Ema Yakobus", "rumah": 3, "songke": "songke_kuning", "baju": Color.WHITE, "caci": true},
]
## Rumah berciri khusus (dipakai sebagai petunjuk): indeks -> jenis penanda.
const PENANDA_RUMAH: Dictionary = {5: "jemuran_songke", 3: "kayu_bakar"}

## Penambah nyawa: secangkir kopi Manggarai di sudut-sudut kampung.
## (Satu cangkir lagi ada di jalur pendakian, jadi Level 1 punya 4 penambah nyawa.)
const POS_KOPI: Array[Vector3] = [Vector3(-19, 0, -2), Vector3(24, 0, 7.5), Vector3(0, 0, -21)]

## Tamu untuk tantangan Mengantar Kopi. Hanya satu yang cocok dengan pesanan
## ("berbaju hijau, duduk dekat compang"); yang lain pengecoh yang mirip.
const DATA_TAMU: Array = [
	{"pos": Vector3(4.6, 0, 1.8), "baju": Color("2e7d46"), "benar": true},  # hijau, dekat compang
	{"pos": Vector3(-10.5, 0, 8.5), "baju": Color("2e7d46"), "benar": false},  # hijau, jauh dari compang
	{"pos": Vector3(-4.2, 0, -2.6), "baju": Color("2c5c96"), "benar": false},  # biru, dekat compang
	{"pos": Vector3(-4.6, 0, 2.4), "baju": Color("3a8a7a"), "benar": false},  # hijau kebiruan, dekat compang
]
## Benang emas (asli, berkilau) dan benang kuning biasa / jerami (palsu, tanpa kilau).
const POS_BENANG_ASLI: Array[Vector3] = [Vector3(-14.2, 3.0, 15.0), Vector3(-20.5, 0, -9.0), Vector3(19.5, 0, -12.5),
	Vector3(-3.5, 0, -24.0), Vector3(12.0, 0, 17.5)]
const POS_BENANG_PALSU: Array[Vector3] = [Vector3(-11.8, 2.0, 17.2), Vector3(-18.0, 0, -12.5), Vector3(21.5, 0, -9.0),
	Vector3(3.5, 0, -23.5)]
const SPEED_ANTAR: float = 3.4

var pemain: Pemain
var kamera: KameraIkut
var _rumah: Array[Node3D] = []
var _minigame: Node = null

# Mengantar Kopi
var _antar_aktif: bool = false
var _tantangan_antar: Dictionary = {}
var _tumpah: float = 0.0
var _arah_lalu := Vector3.ZERO
var _tamu: Array[NpcKampung] = []
var _anak: NpcKampung
var _ui_antar: CanvasLayer
var _bar_tumpah: Control
var _ende_lono: NpcKampung
var _pos_ambil_kopi := Vector3.ZERO

# Benang emas
var _benang_terkumpul: int = 0


func _ready() -> void:
	_bangun_dunia()
	_bangun_warga()
	_bangun_compang()
	_bangun_benang()
	_bangun_hewan()
	for p: Vector3 in POS_KOPI:
		var kopi := PenambahNyawa.new()
		kopi.jenis = "kopi"
		kopi.position = p
		add_child(kopi)
	_munculkan_pemain()
	add_child(preload("res://scripts/ui/hud.gd").new())
	AudioManager.putar_musik("kampung")
	GameState.ubah_state(GameState.State.BERMAIN)
	if GameState.langkah_rantai == 0:
		# Sambutan singkat saat pertama masuk kampung
		AudioManager.putar_sfx("gong")


func _bangun_dunia() -> void:
	Dunia.lingkungan(self)
	Dunia.tanah(self, 220.0)
	Dunia.batas_dunia(self, 40.0)
	Dunia.compang(self, Vector3.ZERO)
	# Semua Mbaru Niang dapat dimasuki; sebagian berisi pemegang kartu, sisanya pengecoh
	for i in SUDUT_RUMAH.size():
		var a: float = deg_to_rad(SUDUT_RUMAH[i])
		var pos := Vector3(cos(a), 0, sin(a)) * JARI_KAMPUNG
		_rumah.append(Dunia.mbaru_niang(self, pos, Vector3.ZERO, 1.25 if i == 0 else 1.0, true))
	for indeks: int in PENANDA_RUMAH:
		var a: float = deg_to_rad(SUDUT_RUMAH[indeks])
		var arah := Vector3(cos(a), 0, sin(a))
		var samping := Vector3(-arah.z, 0, arah.x)  # menyinggung lingkaran kampung
		var posisi: Vector3 = arah * (JARI_KAMPUNG - 4.5) + samping * 1.8
		if PENANDA_RUMAH[indeks] == "jemuran_songke":
			Dunia.jemuran_songke(self, posisi, _rumah[indeks].rotation.y, preload("res://assets/textures/songke_biru.png"))
		else:
			Dunia.kayu_bakar(self, posisi, _rumah[indeks].rotation.y)
	Dunia.alat_tenun(self, Vector3(-9.3, 0, -0.8), 0.3, preload("res://assets/textures/songke_hijau.png"))
	Dunia.gong_gendang(self, Vector3(-5, 0, -4))
	Dunia.arena(self, PUSAT_ARENA, 5.0)
	Dunia.papan(self, Vector3(17, 0, -1.5), "Arena Caci (Penti)")
	Dunia.papan(self, Vector3(3, 0, 18), "Kampung Wae Rebo")
	# Batu pijakan untuk melompat dan memandang kampung dari atas (melatih lompat & collision)
	Dunia.batu_pijakan(self, Vector3(-9, 0, 19), 1.0)
	Dunia.batu_pijakan(self, Vector3(-11.8, 0, 17.2), 2.0, 1.0)
	Dunia.batu_pijakan(self, Vector3(-14.2, 0, 15), 3.0, 0.9)
	# Pepohonan dan bukit di sekeliling lembah
	var acak := RandomNumberGenerator.new()
	acak.seed = 42
	for i in 26:
		var a: float = acak.randf() * TAU
		var r: float = acak.randf_range(22.0, 36.0)
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		if pos.distance_to(PUSAT_ARENA) > 8.0 and pos.distance_to(TITIK_MUNCUL) > 5.0 and pos.distance_to(Vector3(-11.8, 0, 17.2)) > 6.0:
			Dunia.pohon(self, pos, acak.randf_range(0.8, 1.4))
	for i in 12:
		var a: float = TAU * i / 12.0
		Dunia.bukit(self, Vector3(cos(a) * 60, -4, sin(a) * 60), acak.randf_range(14, 22), acak.randf_range(10, 20))


func _bangun_warga() -> void:
	for data: Dictionary in DATA_WARGA:
		var n := NpcKampung.new()
		n.nama = data["nama"]
		n.tekstur_songke = load("res://assets/textures/%s.png" % data["songke"])
		n.warna_baju = data["baju"]
		n.perempuan = data.get("perempuan", false)
		n.pemain_caci = data.get("caci", false)
		n.bawa_nampan = data.get("nampan", false)
		var patroli: Array = data.get("patroli", [])
		for titik: Vector3 in patroli:
			n.titik_patroli.append(titik)
		var di_rumah: int = data.get("rumah", -1)
		var rumah: Node3D = _rumah[di_rumah] if di_rumah >= 0 else null
		n.position = rumah.to_global(Vector3(0, 0, 1.3)) if rumah else data["pos"]
		add_child(n)
		n.model.mode = "siaga" if n.pemain_caci else "idle"
		if rumah:
			n.model.rotation.y = rumah.rotation.y  # di dalam rumah, menghadap pintu
		else:
			var pusat: Vector3 = PUSAT_ARENA if n.position.x > 16.0 else Vector3.ZERO
			var arah: Vector3 = pusat - n.position
			n.model.rotation.y = atan2(-arah.x, -arah.z)
		n.diajak_bicara.connect(_bicara_warga)


## Anjing dan ayam berkeliaran di area terbuka (jauh dari rumah dan compang).
func _bangun_hewan() -> void:
	var daftar: Array = [
		["anjing", Vector3(4, 0, 14), Color("a0703c"), 3.5],
		["anjing", Vector3(17, 0, 4), Color("e8e0d0"), 2.5],
		["ayam", Vector3(3, 0, 10.5), Color("f1ede4"), 2.5],
		["ayam", Vector3(3.8, 0, 11.2), Color("9a4a22"), 2.5],
		["ayam", Vector3(2.2, 0, 11), Color("1e1a1a"), 2.5],
		["ayam", Vector3(6, 0, -6), Color("b8622a"), 2.5],
		["ayam", Vector3(6.6, 0, -5.4), Color("f1ede4"), 2.5],
		["ayam", Vector3(-4, 0, -8.5), Color("9a4a22"), 2.0],
	]
	for data: Array in daftar:
		var h := Hewan.new()
		h.jenis = data[0]
		h.position = data[1]
		h.warna_utama = data[2]
		h.jari_jelajah = data[3]
		add_child(h)


## Compang hanya dilihat dan dijelaskan (tidak dijadikan tempat bermain karena sakral).
func _bangun_compang() -> void:
	var area := Interaktif.new()
	area.teks_petunjuk = "Lihat Compang"
	area.jari_jari = 3.4
	area.tinggi_petunjuk = 3.2
	add_child(area)
	area.diinteraksi.connect(_lihat_compang)


func _lihat_compang(_p: Pemain) -> void:
	var baris: Array = [{"nama": "Nggohak", "teks": "Compang, altar batu yang sakral. Aku hanya melihatnya dengan hormat."}]
	DialogManager.gelembung(pemain, [baris[0]["teks"]], "Nggohak", 3.6)


func _munculkan_pemain() -> void:
	pemain = ADEGAN_PEMAIN.instantiate()
	add_child(pemain)
	pemain.global_position = TITIK_MUNCUL
	pemain.model.rotation.y = 0.0
	kamera = KameraIkut.new()
	kamera.target = pemain
	add_child(kamera)
	kamera.current = true


# ------------------------------------------------------------- rantai teka-teki

func _bicara_warga(npc: NpcKampung) -> void:
	var tantangan: Dictionary = GameState.tantangan_aktif()
	if not tantangan.is_empty() and tantangan["pemegang"] == npc.nama:
		DialogManager.mulai_baris("pembuka", _baris_dari(npc.nama, tantangan["pembuka"]), _mulai_tantangan.bind(tantangan))
	elif GameState.sudah_memberi(npc.nama):
		DialogManager.gelembung(npc, [_baris_dialog("sudah_diberikan", npc.nama)[0]["teks"]], npc.nama, 3.9)
	else:
		DialogManager.gelembung(npc, [_baris_dialog("belum_giliran", npc.nama)[0]["teks"]], npc.nama, 3.9)


func _mulai_tantangan(tantangan: Dictionary) -> void:
	# Nyawa habis di tantangan ini = tantangan ini saja yang diulang
	Nyawa.atur_tantangan(str(tantangan["pemegang"]), _ulangi_tantangan.bind(tantangan))
	match str(tantangan["jenis"]):
		"tenun":
			var tenun: TenunSongke = TENUN.new()
			tenun.selesai.connect(_hasil_minigame.bind(tantangan, "tenun_gagal", tenun))
			tenun.salah.connect(Nyawa.kurangi)
			_minigame = tenun
			add_child(tenun)
		"sangrai":
			var sangrai: SangraiKopi = SANGRAI.new()
			sangrai.selesai.connect(_hasil_minigame.bind(tantangan, "tenun_gagal", sangrai))
			sangrai.salah.connect(Nyawa.kurangi)
			_minigame = sangrai
			add_child(sangrai)
		"tangkis":
			var tangkis: TangkisNggiling = TANGKIS.new()
			tangkis.selesai.connect(_hasil_minigame.bind(tantangan, "tenun_gagal", tangkis))
			tangkis.salah.connect(Nyawa.kurangi)
			_minigame = tangkis
			add_child(tangkis)
		"antar_kopi":
			_mulai_antar(tantangan)
		"gong":
			var tabuh: TabuhGong = TABUH.new()
			tabuh.selesai.connect(_hasil_minigame.bind(tantangan, "gong_gagal", tabuh))
			tabuh.salah.connect(Nyawa.kurangi)
			_minigame = tabuh
			add_child(tabuh)
		_:
			DialogManager.ajukan_teka_teki(tantangan["pemegang"], tantangan["pertanyaan"], tantangan["pilihan"],
					int(tantangan["benar"]), _hasil_teka_teki.bind(tantangan))


func _hasil_teka_teki(benar: bool, tantangan: Dictionary) -> void:
	if benar:
		_tantangan_berhasil(tantangan)
		return
	Nyawa.kurangi("salah jawab")
	if not Nyawa.sedang_habis():
		DialogManager.mulai_baris("salah", _baris_dialog("salah", tantangan["pemegang"]))


func _hasil_minigame(berhasil: bool, tantangan: Dictionary, id_gagal: String, minigame: Node) -> void:
	_minigame = null
	if berhasil:
		_tantangan_berhasil(tantangan)
		return
	if minigame.get("batal"):
		return  # pemain menekan Berhenti: tidak dihitung gagal
	Nyawa.kurangi("gagal tantangan")
	if not Nyawa.sedang_habis():
		var b: Dictionary = DialogManager.DATA_DIALOG.data[id_gagal][0]
		DialogManager.gelembung(pemain, [b["teks"]], str(b["nama"]), 3.6)


## Nyawa habis: tutup mini-game yang terbuka lalu mulai tantangan yang sama dari awal.
func _ulangi_tantangan(tantangan: Dictionary) -> void:
	if is_instance_valid(_minigame):
		_minigame.queue_free()
		_minigame = null
	GameState.ubah_state(GameState.State.BERMAIN)
	_mulai_tantangan(tantangan)


## Tantangan selesai: kartu diberikan, lalu warga menyebutkan petunjuk ke warga berikutnya.
func _tantangan_berhasil(tantangan: Dictionary) -> void:
	GameState.kumpulkan_kartu(tantangan["kartu"])
	GameState.maju_rantai()
	if tantangan.has("kartu_bonus") and GameState.kumpulkan_kartu(tantangan["kartu_bonus"]):
		DialogManager.tampilkan_kartu(tantangan["kartu_bonus"])
	DialogManager.tampilkan_kartu(tantangan["kartu"], _sampaikan_petunjuk.bind(tantangan))


func _sampaikan_petunjuk(tantangan: Dictionary) -> void:
	var teks: String = ("Petunjuk berikutnya: " + str(tantangan["petunjuk"])) if not GameState.rantai_selesai() else str(tantangan["petunjuk"])
	var baris: Array = [{"nama": tantangan["pemegang"], "teks": teks}]
	if GameState.rantai_selesai():
		DialogManager.mulai_baris("penutup", baris, _mulai_penti)
	else:
		DialogManager.mulai_baris("petunjuk", baris)


## Level 1 tamat: lanjut ke Level 2 (Lingko Lodok). Penti kini menjadi penutup level terakhir.
func _mulai_penti() -> void:
	AudioManager.putar_sfx("gong")
	GameState.selesaikan_level(1)


## Baris dialog dari daftar teks, semuanya diucapkan oleh `nama`.
func _baris_dari(nama: String, daftar_teks: Array) -> Array:
	var baris: Array = []
	for teks: String in daftar_teks:
		baris.append({"nama": nama, "teks": teks})
	return baris


## Baris dari dialog.json; pembicara "Pemegang" diganti nama warga yang diajak bicara.
func _baris_dialog(id: String, nama: String) -> Array:
	var baris: Array = []
	for b: Dictionary in DialogManager.DATA_DIALOG.data[id]:
		var salinan: Dictionary = b.duplicate()
		if salinan.get("nama", "") == "Pemegang":
			salinan["nama"] = nama
		baris.append(salinan)
	return baris


# ------------------------------------------------------------------ Mengantar Kopi (Ende Lono)

## Pemain membawa nampan kopi ke tamu yang cocok dengan pesanan. Berbelok tajam, melompat,
## atau menabrak ayam/anak yang berlari membuat kopi tumpah (-1 nyawa, ambil kopi lagi).
func _mulai_antar(tantangan: Dictionary) -> void:
	_tantangan_antar = tantangan
	for n: Node in get_children():
		if n is NpcKampung and (n as NpcKampung).nama == "Ende Lono":
			_ende_lono = n
	_pos_ambil_kopi = _ende_lono.global_position + Vector3(0, 0.1, 0) if _ende_lono else pemain.global_position
	if _tamu.is_empty():
		_bangun_tamu()
	_ambil_kopi_baru()
	GameState.atur_tujuan("Antar kopi: %s. Jangan berbelok tajam atau melompat!" % str(tantangan.get("pesanan", "")))
	Nyawa.atur_tantangan("Mengantar kopi", _ambil_kopi_baru)


func _ambil_kopi_baru() -> void:
	_antar_aktif = true
	_tumpah = 0.0
	_arah_lalu = Vector3.ZERO
	pemain.model.atur_nampan(true)
	pemain.kecepatan = SPEED_ANTAR
	pemain.velocity = Vector3.ZERO
	pemain.global_position = _pos_ambil_kopi
	if _ui_antar == null:
		_bangun_ui_antar()
	_ui_antar.visible = true


func _bangun_tamu() -> void:
	for d: Dictionary in DATA_TAMU:
		var n := NpcKampung.new()
		n.nama = "Tamu"
		n.wisatawan = true
		n.warna_baju = d["baju"]
		n.position = d["pos"]
		add_child(n)
		var arah: Vector3 = -n.position
		n.model.rotation.y = atan2(-arah.x, -arah.z)
		n.area.ubah_petunjuk("Beri kopi")
		n.set_meta("benar", d["benar"])
		n.diajak_bicara.connect(_beri_kopi)
		var tikar := BoxMesh.new()
		tikar.size = Vector3(1.4, 0.03, 1.0)
		Dunia.mesh(self, tikar, n.position + Vector3(0, 0.02, 0), Dunia.mat(Color("c8a868")))
		_tamu.append(n)
	# Anak yang berlari bolak-balik memotong jalan (rintangan bergerak)
	_anak = NpcKampung.new()
	_anak.nama = "Anak"
	_anak.tekstur_songke = preload("res://assets/textures/songke_kuning.png")
	_anak.warna_baju = Color("e07b39")
	_anak.position = Vector3(8.0, 0, -7.0)
	_anak.titik_patroli.append(Vector3(8.0, 0, -7.0))
	_anak.titik_patroli.append(Vector3(1.5, 0, -9.5))
	_anak.titik_patroli.append(Vector3(7.5, 0, -2.0))
	_anak.lama_diam_min = 0.3
	_anak.lama_diam_maks = 1.0
	_anak.kecepatan = 3.2
	add_child(_anak)
	_anak.model.scale = Vector3.ONE * 0.72


func _bangun_ui_antar() -> void:
	_ui_antar = CanvasLayer.new()
	_ui_antar.layer = 11
	add_child(_ui_antar)
	var label := Gaya.label("Kopi di nampan", 9, Gaya.PUTIH)
	label.position = Vector2(456, 12)
	_ui_antar.add_child(label)
	_bar_tumpah = Control.new()
	_bar_tumpah.position = Vector2(456, 28)
	_bar_tumpah.size = Vector2(150, 12)
	_bar_tumpah.draw.connect(func() -> void:
		var penuh: float = 1.0 - clampf(_tumpah, 0.0, 1.0)
		var warna: Color = Gaya.HIJAU.lerp(Gaya.MERAH, 1.0 - penuh)
		_bar_tumpah.draw_rect(Rect2(Vector2.ZERO, _bar_tumpah.size), Gaya.HITAM)
		_bar_tumpah.draw_rect(Rect2(Vector2(1, 1), Vector2((_bar_tumpah.size.x - 2) * penuh, 10)), warna)
		_bar_tumpah.draw_rect(Rect2(Vector2.ZERO, _bar_tumpah.size), Gaya.KUNING, false, 1.0))
	_ui_antar.add_child(_bar_tumpah)
	GameState.state_berubah.connect(func(_l: int, baru: int) -> void:
		if is_instance_valid(_ui_antar):
			_ui_antar.visible = _antar_aktif and baru == GameState.State.BERMAIN)


func _physics_process(delta: float) -> void:
	if not _antar_aktif or pemain == null or not GameState.sedang(GameState.State.BERMAIN):
		return
	var v := Vector3(pemain.velocity.x, 0, pemain.velocity.z)
	# Belokan tajam: perubahan arah gerak yang cepat saat sedang berjalan
	if v.length() > 1.2 and _arah_lalu.length() > 1.2:
		var laju_belok: float = _arah_lalu.angle_to(v) / delta
		_tumpah += maxf(laju_belok - 3.0, 0.0) * 0.4 * delta
	_arah_lalu = v
	if pemain.velocity.y > 2.0:
		_tumpah += 1.5 * delta  # melompat sambil membawa nampan
	for n: Node in get_children():
		var tabrak: float = 0.0
		if n is Hewan:
			tabrak = 0.85
		elif n == _anak:
			tabrak = 1.0
		if tabrak > 0.0 and (n as Node3D).global_position.distance_to(pemain.global_position) < tabrak:
			_tumpah += 1.6 * delta
	_tumpah = maxf(_tumpah - 0.1 * delta, 0.0)
	pemain.model.miringkan_nampan(clampf(_tumpah, 0.0, 1.0))
	_bar_tumpah.queue_redraw()
	if _tumpah >= 1.0:
		_kopi_tumpah()


func _kopi_tumpah() -> void:
	AudioManager.putar_sfx("terkena")
	DialogManager.gelembung(pemain, [str(DATA_RANTAI.data["antar"]["tumpah"])], "Nggohak", 3.6)
	Nyawa.kurangi("kopi tumpah")
	if not Nyawa.sedang_habis():
		_ambil_kopi_baru()


func _beri_kopi(tamu: NpcKampung) -> void:
	if not _antar_aktif:
		DialogManager.gelembung(tamu, [str(DATA_RANTAI.data["antar"]["tamu_lain"])], "Tamu", 3.9)
		return
	if not tamu.get_meta("benar"):
		DialogManager.gelembung(tamu, [str(DATA_RANTAI.data["antar"]["salah_tamu"])], "Tamu", 3.9)
		Nyawa.kurangi("salah tamu")
		return
	_antar_aktif = false
	pemain.model.atur_nampan(false)
	pemain.kecepatan = 5.0
	_ui_antar.visible = false
	AudioManager.putar_sfx("berhasil")
	DialogManager.gelembung(tamu, [str(DATA_RANTAI.data["antar"]["terima"])], "Tamu", 3.9)
	Nyawa.atur_tantangan("", Callable())
	_tantangan_berhasil(_tantangan_antar)


# ------------------------------------------------------------------ Benang Emas (opsional)

func _bangun_benang() -> void:
	for p: Vector3 in POS_BENANG_ASLI:
		_benang(p, true)
	for p: Vector3 in POS_BENANG_PALSU:
		_benang(p, false)


## Gulungan benang: asli = emas berkilau dengan cahaya; palsu = kuning kusam tanpa kilau.
func _benang(pos: Vector3, asli: bool) -> void:
	var g := Node3D.new()
	g.position = pos
	add_child(g)
	var m: StandardMaterial3D = Dunia.mat(Color("e8b430") if asli else Color("c8b060"))
	if asli:
		m.metallic = 0.9
		m.roughness = 0.2
		m.emission_enabled = true
		m.emission = Color("ffcc44")
		m.emission_energy_multiplier = 0.9
	var gulungan := Dunia.mesh(g, Dunia.silinder(0.22, 0.22, 0.32, 12), Vector3(0, 0.35, 0), m)
	gulungan.rotation.z = PI / 2.0
	var poros := Dunia.mesh(g, Dunia.silinder(0.08, 0.08, 0.44, 8), Vector3(0, 0.35, 0), Dunia.mat(Color("6a4428")))
	poros.rotation.z = PI / 2.0
	if asli:
		var kilau := OmniLight3D.new()
		kilau.light_color = Color("ffd060")
		kilau.light_energy = 0.8
		kilau.omni_range = 1.6
		kilau.position = Vector3(0, 0.6, 0)
		g.add_child(kilau)
		var tw := g.create_tween().set_loops()
		tw.tween_property(kilau, "light_energy", 1.5, 0.6)
		tw.tween_property(kilau, "light_energy", 0.5, 0.6)
	var area := Interaktif.new()
	area.teks_petunjuk = "Ambil benang"
	area.jari_jari = 1.4
	area.tinggi_petunjuk = 1.4
	g.add_child(area)
	area.diinteraksi.connect(_ambil_benang.bind(g, asli))


func _ambil_benang(_p: Pemain, g: Node3D, asli: bool) -> void:
	var teks: Dictionary = DATA_RANTAI.data["benang"]
	g.queue_free()
	if not asli:
		DialogManager.gelembung(pemain, [str(teks["palsu"])], "Nggohak", 3.6)
		Nyawa.kurangi("mengambil benang palsu")
		return
	_benang_terkumpul += 1
	GameState.benang_emas = maxi(GameState.benang_emas, _benang_terkumpul)
	AudioManager.putar_sfx("ambil")
	var pesan: String = str(teks["lengkap"]) if _benang_terkumpul >= POS_BENANG_ASLI.size() else "%s (%d/%d)" % [
		teks["asli"], _benang_terkumpul, POS_BENANG_ASLI.size()]
	DialogManager.gelembung(pemain, [pesan], "Nggohak", 3.6)
