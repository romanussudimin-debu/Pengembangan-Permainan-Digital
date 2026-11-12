extends Node3D
## Level utama: Kampung adat Wae Rebo dalam 3D.
## 7 Mbaru Niang melingkari compang; arena caci di timur; kartu budaya disimpan di dalam rumah.

const ADEGAN_PEMAIN: PackedScene = preload("res://scenes/pemain.tscn")
const ADEGAN_DUEL: String = "res://scenes/duel_caci.tscn"
const ADEGAN_ENDING: String = "res://scenes/ending.tscn"

const TITIK_MUNCUL: Dictionary = {
	"awal": Vector3(0, 0.2, 22),
	"arena": Vector3(18, 0.2, 2),
}
const PUSAT_ARENA := Vector3(26, 0, 0)

## Sudut (derajat) 7 Mbaru Niang; indeks 0 = mbaru gendang (rumah utama, utara).
const SUDUT_RUMAH: Array = [-90.0, -130.0, -170.0, 150.0, 110.0, -50.0, 40.0]
const JARI_KAMPUNG: float = 15.0

## Kartu budaya yang ditemukan dengan masuk ke Mbaru Niang (indeks rumah -> id kartu).
## Rumah 0 adalah mbaru gendang; lainnya mbaru gena.
const KARTU_DI_RUMAH: Dictionary = {0: "mbaru_niang", 1: "gong_gendang", 4: "wae_rebo", 6: "penti"}

const DATA_LAWAN: Array = [
	{"nama": "Rangga", "dialog": "rangga_ajak", "posisi": Vector3(23, 0, -4), "songke": "res://assets/textures/songke_biru.png"},
	{"nama": "Fransi", "dialog": "fransi_ajak", "posisi": Vector3(27, 0, -5), "songke": "res://assets/textures/songke_hijau.png"},
	{"nama": "Ema Agus", "dialog": "agus_ajak", "posisi": Vector3(31, 0, -3), "songke": "res://assets/textures/songke_kuning.png"},
]

var pemain: Pemain
var kamera: KameraIkut
var _cahaya_rumah: Dictionary = {}  ## id kartu -> OmniLight3D penanda pintu


func _ready() -> void:
	_bangun_dunia()
	_bangun_npc()
	_bangun_kartu()
	_munculkan_pemain()
	add_child(preload("res://scripts/ui/hud.gd").new())
	AudioManager.putar_musik("kampung")
	GameState.ubah_state(GameState.State.BERMAIN)
	if not GameState.sudah_bertemu_tua:
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
	Dunia.papan(self, Vector3(17, 0, -1.5), "Arena Caci")
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
		if pos.distance_to(PUSAT_ARENA) > 8.0 and pos.distance_to(TITIK_MUNCUL["awal"]) > 5.0 and pos.distance_to(Vector3(-11.8, 0, 17.2)) > 6.0:
			Dunia.pohon(self, pos, acak.randf_range(0.8, 1.4))
	for i in 12:
		var a: float = TAU * i / 12.0
		Dunia.bukit(self, Vector3(cos(a) * 60, -4, sin(a) * 60), acak.randf_range(14, 22), acak.randf_range(10, 20))


func _bangun_npc() -> void:
	var tua := _npc("Tu'a Golo", Vector3(0, 0, 5.8), "res://assets/textures/songke_kuning.png", Color("1b1818"), Color("e8b430"), false)
	tua.diajak_bicara.connect(_bicara_tua)
	var ine := _npc("Ine Wela", Vector3(-8, 0, 0.5), "res://assets/textures/songke_hijau.png", Color("b02a2a"), Color("2e7d46"), false, true)
	ine.diajak_bicara.connect(_bicara_ine)
	for i in DATA_LAWAN.size():
		var d: Dictionary = DATA_LAWAN[i]
		var n := _npc(d["nama"], d["posisi"], d["songke"], Color.WHITE, Color("b02a2a"), true)
		n.model.mode = "siaga"
		n.diajak_bicara.connect(_bicara_lawan.bind(i))
	# Perempuan kampung yang menyiapkan kopi untuk para pemain caci, di tepi arena
	for data: Array in [["Ine Rosa", Vector3(21, 0, 4), "res://assets/textures/songke_merah.png", Color("2c5c96")],
			["Ine Lina", Vector3(23, 0, 5.6), "res://assets/textures/songke_hijau.png", Color("e8e2d2")]]:
		var p := NpcKampung.new()
		p.nama = data[0]
		p.position = data[1]
		p.tekstur_songke = load(data[2])
		p.warna_baju = data[3]
		p.perempuan = true
		p.bawa_nampan = true
		add_child(p)
		p.model.rotation.y = atan2(-(PUSAT_ARENA.x - p.position.x), -(PUSAT_ARENA.z - p.position.z))
		p.diajak_bicara.connect(_bicara_pembawa_kopi)


func _npc(nama: String, posisi: Vector3, songke: String, baju: Color, ikat: Color, caci: bool, perempuan: bool = false) -> NpcKampung:
	var n := NpcKampung.new()
	n.nama = nama
	n.position = posisi
	n.tekstur_songke = load(songke)
	n.warna_baju = baju
	n.warna_ikat = ikat
	n.pemain_caci = caci
	n.perempuan = perempuan
	add_child(n)
	return n


func _bangun_kartu() -> void:
	# Pintu Mbaru Niang yang menyimpan kartu: masuk untuk menemukannya
	for indeks: int in KARTU_DI_RUMAH:
		var id: String = KARTU_DI_RUMAH[indeks]
		var pintu: Vector3 = _posisi_pintu(indeks)
		var area := Interaktif.new()
		area.teks_petunjuk = "Masuk Mbaru Niang"
		area.jari_jari = 1.8
		area.tinggi_petunjuk = 2.6
		area.position = pintu
		add_child(area)
		area.diinteraksi.connect(_masuk_rumah.bind(id, indeks))
		if not GameState.kartu_terkumpul.has(id):
			# Cahaya hangat dari pintu menandai rumah yang masih menyimpan pengetahuan
			var cahaya := OmniLight3D.new()
			cahaya.light_color = Color("ffb057")
			cahaya.light_energy = 1.6
			cahaya.omni_range = 3.0
			cahaya.position = pintu + Vector3(0, 1.4, 0)
			add_child(cahaya)
			_cahaya_rumah[id] = cahaya
	# Compang: dilihat dan dijelaskan (tanpa dijadikan tempat bermain karena sakral)
	var area_compang := Interaktif.new()
	area_compang.teks_petunjuk = "Lihat Compang"
	area_compang.jari_jari = 3.4
	area_compang.tinggi_petunjuk = 3.2
	add_child(area_compang)
	area_compang.diinteraksi.connect(_lihat_compang)


## Titik di depan pintu rumah ke-`indeks` (pintu selalu menghadap compang).
func _posisi_pintu(indeks: int) -> Vector3:
	var a: float = deg_to_rad(SUDUT_RUMAH[indeks])
	var arah := Vector3(cos(a), 0, sin(a))
	var skala: float = 1.25 if indeks == 0 else 1.0
	return arah * (JARI_KAMPUNG - 3.6 * skala - 0.9)


func _masuk_rumah(_p: Pemain, id: String, indeks: int) -> void:
	var nama_rumah: String = "mbaru gendang" if indeks == 0 else "mbaru gena"
	if GameState.kartu_terkumpul.has(id):
		DialogManager.mulai_baris("rumah_" + id, [{"nama": "Nara", "teks": "Aku sudah berkunjung ke %s ini. Isi kartunya bisa dibaca lagi di menu jeda (Esc)." % nama_rumah}])
	else:
		DialogManager.mulai_baris("rumah_" + id, [{"nama": "Nara", "teks": "Aku masuk ke dalam %s. Ada pengetahuan yang tersimpan di sini..." % nama_rumah}],
				_temukan_kartu.bind(id))


func _temukan_kartu(id: String) -> void:
	if _cahaya_rumah.has(id):
		var cahaya: OmniLight3D = _cahaya_rumah[id]
		cahaya.queue_free()
		_cahaya_rumah.erase(id)
	_beri_kartu(id)


func _lihat_compang(_p: Pemain) -> void:
	_beri_kartu("compang")


func _munculkan_pemain() -> void:
	pemain = ADEGAN_PEMAIN.instantiate()
	add_child(pemain)
	pemain.global_position = TITIK_MUNCUL.get(GameState.titik_muncul, TITIK_MUNCUL["awal"])
	if GameState.titik_muncul == "arena":
		pemain.model.rotation.y = PI / 2.0
	else:
		pemain.model.rotation.y = 0.0
	kamera = KameraIkut.new()
	kamera.target = pemain
	add_child(kamera)
	kamera.current = true


# ------------------------------------------------------------- alur misi

func _bicara_tua(_npc_node: NpcKampung) -> void:
	if not GameState.sudah_bertemu_tua:
		DialogManager.mulai("tua_awal", GameState.tandai.bind("sudah_bertemu_tua"))
	elif GameState.semua_misi_selesai():
		DialogManager.mulai("tua_akhir", _mulai_penti)
	else:
		DialogManager.mulai("tua_belum")


func _mulai_penti() -> void:
	AudioManager.putar_sfx("gong")
	Transisi.pindah_scene(ADEGAN_ENDING)


func _bicara_pembawa_kopi(npc_node: NpcKampung) -> void:
	var baris: Array = []
	for b: Dictionary in DialogManager.DATA_DIALOG.data["pembawa_kopi"]:
		var salinan: Dictionary = b.duplicate()
		if salinan.get("nama", "") == "Perempuan":
			salinan["nama"] = npc_node.nama
		baris.append(salinan)
	DialogManager.mulai_baris("pembawa_kopi", baris)


func _bicara_ine(_npc_node: NpcKampung) -> void:
	if not GameState.sudah_bertemu_ine:
		DialogManager.mulai("ine_awal", _setelah_bicara_ine)
	else:
		DialogManager.mulai("ine_lagi")


func _setelah_bicara_ine() -> void:
	GameState.tandai("sudah_bertemu_ine")
	_beri_kartu("songke")


func _bicara_lawan(_npc_node: NpcKampung, indeks: int) -> void:
	if not GameState.sudah_bertemu_tua:
		DialogManager.mulai("lawan_belum")
	elif indeks < GameState.lawan_dikalahkan:
		DialogManager.mulai("lawan_sudah")
	elif indeks > GameState.lawan_dikalahkan:
		DialogManager.mulai("lawan_terkunci")
	else:
		var d: Dictionary = DATA_LAWAN[indeks]
		DialogManager.mulai(d["dialog"], _ke_arena.bind(indeks))


func _ke_arena(indeks: int) -> void:
	GameState.lawan_aktif = indeks
	GameState.titik_muncul = "arena"
	Transisi.pindah_scene(ADEGAN_DUEL)


## Kartu bisa dibaca ulang; hanya dihitung sekali.
func _beri_kartu(id: String) -> void:
	GameState.kumpulkan_kartu(id)
	DialogManager.tampilkan_kartu(id)
