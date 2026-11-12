extends Node3D
## Level utama: Kampung adat Wae Rebo dalam 3D.
## 7 Mbaru Niang melingkari compang; arena caci di timur; kartu budaya tersebar.

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

const DATA_LAWAN: Array = [
	{"nama": "Rangga", "dialog": "rangga_ajak", "posisi": Vector3(23, 0, -4), "songke": "res://assets/textures/songke_biru.png"},
	{"nama": "Fransi", "dialog": "fransi_ajak", "posisi": Vector3(27, 0, -5), "songke": "res://assets/textures/songke_hijau.png"},
	{"nama": "Ema Agus", "dialog": "agus_ajak", "posisi": Vector3(31, 0, -3), "songke": "res://assets/textures/songke_kuning.png"},
]

var pemain: Pemain
var kamera: KameraIkut


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
	Dunia.tanah(self, 90.0)
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
	# Batu pijakan menuju kartu budaya (melatih lompat & collision)
	Dunia.batu_pijakan(self, Vector3(-4.5, 0, 8.5), 0.9)
	Dunia.batu_pijakan(self, Vector3(-6.5, 0, 6.2), 1.8)
	Dunia.batu_pijakan(self, Vector3(5, 0, 9), 1.0)
	Dunia.batu_pijakan(self, Vector3(7.6, 0, 6.6), 2.0, 0.9)
	Dunia.batu_pijakan(self, Vector3(9.0, 0, 3.6), 3.0, 0.9)
	# Pepohonan dan bukit (lembah berkabut)
	var acak := RandomNumberGenerator.new()
	acak.seed = 42
	for i in 26:
		var a: float = acak.randf() * TAU
		var r: float = acak.randf_range(22.0, 36.0)
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		if pos.distance_to(PUSAT_ARENA) > 8.0 and pos.distance_to(TITIK_MUNCUL["awal"]) > 5.0:
			Dunia.pohon(self, pos, acak.randf_range(0.8, 1.4))
	for i in 12:
		var a: float = TAU * i / 12.0
		Dunia.bukit(self, Vector3(cos(a) * 60, -4, sin(a) * 60), acak.randf_range(14, 22), acak.randf_range(10, 20))


func _bangun_npc() -> void:
	var tua := _npc("Tu'a Golo", Vector3(0, 0, 5.8), "res://assets/textures/songke_kuning.png", Color("1b1818"), Color("e8b430"), false)
	tua.diajak_bicara.connect(_bicara_tua)
	var ine := _npc("Ine Wela", Vector3(-8, 0, 0.5), "res://assets/textures/songke_hijau.png", Color("b02a2a"), Color("2e7d46"), false)
	ine.diajak_bicara.connect(_bicara_ine)
	for i in DATA_LAWAN.size():
		var d: Dictionary = DATA_LAWAN[i]
		var n := _npc(d["nama"], d["posisi"], d["songke"], Color.WHITE, Color("b02a2a"), true)
		n.model.mode = "siaga"
		n.diajak_bicara.connect(_bicara_lawan.bind(i))


func _npc(nama: String, posisi: Vector3, songke: String, baju: Color, ikat: Color, caci: bool) -> NpcKampung:
	var n := NpcKampung.new()
	n.nama = nama
	n.position = posisi
	n.tekstur_songke = load(songke)
	n.warna_baju = baju
	n.warna_ikat = ikat
	n.pemain_caci = caci
	add_child(n)
	return n


func _bangun_kartu() -> void:
	var daftar: Array[Array] = [
		["wae_rebo", Vector3(-6.5, 2.6, 6.2)],
		["penti", Vector3(9.0, 3.8, 3.6)],
		["mbaru_niang", Vector3(1.5, 1.0, -9)],
		["gong_gendang", Vector3(-5, 1.0, -2)],
	]
	for item in daftar:
		var id: String = item[0]
		if GameState.kartu_terkumpul.has(id):
			continue
		var k := KartuPickup.new()
		k.id_kartu = id
		k.position = item[1]
		add_child(k)
	# Compang: dilihat dan dijelaskan (tanpa dijadikan tempat bermain karena sakral)
	var area := Interaktif.new()
	area.teks_petunjuk = "Lihat Compang"
	area.jari_jari = 3.4
	area.tinggi_petunjuk = 3.2
	add_child(area)
	area.diinteraksi.connect(_lihat_compang)


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
