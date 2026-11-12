extends Node3D
## Level utama: Kampung adat Wae Rebo dalam 3D.
## 7 Mbaru Niang melingkari compang. Delapan warga masing-masing memegang kartu budaya;
## kartu harus dikumpulkan BERURUTAN lewat rantai teka-teki (data/rantai_teka_teki.json):
## setiap warga memberi tantangan, lalu petunjuk menuju warga berikutnya.

const ADEGAN_PEMAIN: PackedScene = preload("res://scenes/pemain.tscn")
const ADEGAN_ENDING: String = "res://scenes/ending.tscn"
const TENUN: Script = preload("res://scripts/minigame/tenun_songke.gd")
const TABUH: Script = preload("res://scripts/minigame/tabuh_gong.gd")

const TITIK_MUNCUL := Vector3(0, 0.2, 22)
const PUSAT_ARENA := Vector3(26, 0, 0)

## Sudut (derajat) 7 Mbaru Niang; indeks 0 = mbaru gendang (rumah utama, utara).
const SUDUT_RUMAH: Array = [-90.0, -130.0, -170.0, 150.0, 110.0, -50.0, 40.0]
const JARI_KAMPUNG: float = 15.0

## Warga kampung: nama, posisi, tekstur songke, warna baju, perempuan, pemain caci, bawa nampan kopi.
const DATA_WARGA: Array = [
	["Tu'a Golo", Vector3(0, 0, 5.8), "songke_kuning", Color("1b1818"), false, false, false],
	["Ine Wela", Vector3(-8, 0, 0.5), "songke_hijau", Color("b02a2a"), true, false, false],
	["Ema Agus", Vector3(1.2, 0, -9.2), "songke_merah", Color("e8e2d2"), false, false, false],
	["Ende Lono", Vector3(-5, 0, 20), "songke_merah", Color("2c5c96"), true, false, false],
	["Fransi", Vector3(-7.2, 0, -4.6), "songke_biru", Color("e8e2d2"), false, false, false],
	["Hingha", Vector3(23, 0, -4), "songke_biru", Color.WHITE, false, true, false],
	["Marngem", Vector3(22, 0, 5), "songke_hijau", Color("e8e2d2"), true, false, true],
	["Ema Yakobus", Vector3(31, 0, -3), "songke_kuning", Color.WHITE, false, true, false],
]

var pemain: Pemain
var kamera: KameraIkut


func _ready() -> void:
	_bangun_dunia()
	_bangun_warga()
	_bangun_compang()
	_bangun_hewan()
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
	for i in SUDUT_RUMAH.size():
		var a: float = deg_to_rad(SUDUT_RUMAH[i])
		var pos := Vector3(cos(a), 0, sin(a)) * JARI_KAMPUNG
		Dunia.mbaru_niang(self, pos, Vector3.ZERO, 1.25 if i == 0 else 1.0)
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
	for data: Array in DATA_WARGA:
		var n := NpcKampung.new()
		n.nama = data[0]
		n.position = data[1]
		n.tekstur_songke = load("res://assets/textures/%s.png" % data[2])
		n.warna_baju = data[3]
		n.perempuan = data[4]
		n.pemain_caci = data[5]
		n.bawa_nampan = data[6]
		add_child(n)
		if n.pemain_caci:
			n.model.mode = "siaga"
		# Menghadap ke tengah kampung (atau ke arena bagi warga di dekat arena)
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
	var baris: Array = [{"nama": "Nggohak", "teks": "Inilah compang, altar batu berundak di tengah kampung. Tempat ini sakral, jadi aku hanya melihatnya dengan hormat."}]
	DialogManager.mulai_baris("lihat_compang", baris)


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
		DialogManager.mulai_baris("sudah_diberikan", _baris_dialog("sudah_diberikan", npc.nama))
	else:
		DialogManager.mulai_baris("belum_giliran", _baris_dialog("belum_giliran", npc.nama))


func _mulai_tantangan(tantangan: Dictionary) -> void:
	match str(tantangan["jenis"]):
		"tenun":
			var tenun: TenunSongke = TENUN.new()
			tenun.selesai.connect(_hasil_minigame.bind(tantangan, "tenun_gagal"))
			add_child(tenun)
		"gong":
			var tabuh: TabuhGong = TABUH.new()
			tabuh.selesai.connect(_hasil_minigame.bind(tantangan, "gong_gagal"))
			add_child(tabuh)
		_:
			DialogManager.ajukan_teka_teki(tantangan["pemegang"], tantangan["pertanyaan"], tantangan["pilihan"],
					int(tantangan["benar"]), _hasil_teka_teki.bind(tantangan))


func _hasil_teka_teki(benar: bool, tantangan: Dictionary) -> void:
	if benar:
		_tantangan_berhasil(tantangan)
	else:
		DialogManager.mulai_baris("salah", _baris_dialog("salah", tantangan["pemegang"]))


func _hasil_minigame(berhasil: bool, tantangan: Dictionary, id_gagal: String) -> void:
	if berhasil:
		_tantangan_berhasil(tantangan)
	else:
		DialogManager.mulai(id_gagal)


## Tantangan selesai: kartu diberikan, lalu warga menyebutkan petunjuk ke warga berikutnya.
func _tantangan_berhasil(tantangan: Dictionary) -> void:
	GameState.kumpulkan_kartu(tantangan["kartu"])
	GameState.maju_rantai()
	DialogManager.tampilkan_kartu(tantangan["kartu"], _sampaikan_petunjuk.bind(tantangan))


func _sampaikan_petunjuk(tantangan: Dictionary) -> void:
	var teks: String = ("Petunjuk berikutnya: " + str(tantangan["petunjuk"])) if not GameState.rantai_selesai() else str(tantangan["petunjuk"])
	var baris: Array = [{"nama": tantangan["pemegang"], "teks": teks}]
	if GameState.rantai_selesai():
		DialogManager.mulai_baris("penutup", baris, _mulai_penti)
	else:
		DialogManager.mulai_baris("petunjuk", baris)


func _mulai_penti() -> void:
	AudioManager.putar_sfx("gong")
	Transisi.pindah_scene(ADEGAN_ENDING)


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
