extends Node3D
## Level 2: LINGKO LODOK — lahan adat di luar kampung (gendang one, lingko pe'ang).
## Alur (FSM tahap level):
##   SAMBUT  -> temui Tu'a Teno di lodok (pusat lingko)
##   AIR     -> alirkan air dari wae teku (mini-game SaluranAir)
##   BUKIT   -> naik ke bukit batu dan pandang lingko dari atas
##   SELESAI -> level tamat (GameState.selesaikan_level)
## Pematang sempit dan ada yang putus: jatuh ke lumpur = kembali ke titik aman terakhir.
## Mode Sulit: batas waktu "sebelum senja"; jatuh mengurangi waktu.

enum Tahap { SAMBUT, AIR, BUKIT, SELESAI }

const ADEGAN_PEMAIN: PackedScene = preload("res://scenes/pemain.tscn")
const SALURAN: Script = preload("res://scripts/minigame/saluran_air.gd")
const DATA: JSON = preload("res://data/lingko.json")
const NOMOR_LEVEL: int = 2

const TITIK_MUNCUL := Vector3(0, 0.2, 24.0)
const Y_ATAS: float = DuniaLingko.TINGGI_PEMATANG
## Jari-jari pematang melingkar: dalam, tengah, luar. Lodok = panggung pusat.
const JARI_LODOK: float = 2.6
const JARI_DALAM: float = 5.5
const JARI_TENGAH: float = 10.5
const JARI_LUAR: float = 16.0
const JARI_TEPI: float = JARI_LUAR + DuniaLingko.LEBAR_PEMATANG / 2.0
const POS_WAE_TEKU := Vector3(0, 0, -21.5)
const POS_PUNCAK_BUKIT := Vector3(-19.2, 4.5, 15.6)

## Batas waktu Mode Sulit (detik permainan, hanya berjalan saat bermain bebas) dan pengurangannya.
const WAKTU_SULIT: float = 420.0
const DENDA_JATUH: float = 10.0

var pemain: Pemain
var kamera: KameraIkut
var tahap: int = Tahap.SAMBUT

var _tu_a_teno: NpcKampung
var _petak: MeshInstance3D
var _saluran: MeshInstance3D
var _area_wae_teku: Interaktif
var _area_bukit: Interaktif

var _titik_aman: Vector3 = TITIK_MUNCUL
var _titik_cek: Vector3 = TITIK_MUNCUL  ## tempat mengulang bila nyawa habis saat menyusuri pematang
var _minigame: Node = null
var _ruas_rapuh: Array = []  ## {node: [...], asal: [...], waktu, runtuh}
var _sudah_tahu_rapuh: bool = false

var _jeda_jatuh: float = 0.0
var _sisa_waktu: float = WAKTU_SULIT
var _waktu_berjalan: bool = false
var _waktu_habis: bool = false
var _matahari: DirectionalLight3D
var _langit: ProceduralSkyMaterial
var _kamera_pandang: Camera3D

# UI level (sisa waktu Mode Sulit)
var _ui: CanvasLayer
var _label_waktu: Label
var _label_denda: Label


func _ready() -> void:
	GameState.level = NOMOR_LEVEL
	_bangun_dunia()
	_bangun_warga()
	_munculkan_pemain()
	add_child(preload("res://scripts/ui/hud.gd").new())
	_bangun_ui()
	AudioManager.putar_musik("kampung")
	GameState.ubah_state(GameState.State.BERMAIN)
	_atur_tahap(Tahap.SAMBUT)
	AudioManager.putar_sfx("gong")
	get_tree().create_timer(1.0, false).timeout.connect(_pembuka)


func _dialog() -> Dictionary:
	return DATA.data["dialog"]


# ------------------------------------------------------------------ dunia

func _bangun_dunia() -> void:
	Dunia.lingkungan(self)
	for anak in get_children():
		if anak is DirectionalLight3D:
			_matahari = anak
		elif anak is WorldEnvironment:
			_langit = (anak as WorldEnvironment).environment.sky.sky_material as ProceduralSkyMaterial
	Dunia.tanah(self, 220.0)
	Dunia.batas_dunia(self, 33.0)
	# Petak sawah (kering sampai air wae teku dialirkan) dan lodok di pusat
	_petak = DuniaLingko.petak_sawah(self, JARI_LODOK - 0.1, JARI_TEPI)
	DuniaLingko.lodok(self, JARI_LODOK)
	# Pematang melingkar; sebagian putus sehingga pemain harus melompat
	# Pematang rapuh (tanah gelap & retak) runtuh 0,8 detik setelah diinjak
	_ruas_rapuh.append_array(DuniaLingko.pematang_lingkar(self, JARI_DALAM, [135.0, -30.0], 1.5, [100.0, -120.0]))
	_ruas_rapuh.append_array(DuniaLingko.pematang_lingkar(self, JARI_TENGAH, [45.0, 160.0, -135.0], 1.5, [110.0, -60.0, 20.0]))
	for r: Dictionary in _ruas_rapuh:
		r["waktu"] = 0.0
		r["runtuh"] = false
	DuniaLingko.pematang_lingkar(self, JARI_LUAR)
	# Pematang menjari dari lodok (celah di antara potongan = pematang putus)
	DuniaLingko.pematang_jari(self, 90.0, [[JARI_LODOK - 0.2, 7.3], [8.8, JARI_LUAR]])  # selatan (jalan masuk)
	DuniaLingko.pematang_jari(self, -90.0, [[JARI_LODOK - 0.2, 12.5], [14.0, JARI_LUAR]])  # utara
	DuniaLingko.pematang_jari(self, 0.0, [[JARI_LODOK - 0.2, 6.8], [8.3, JARI_LUAR]])  # timur
	DuniaLingko.pematang_jari(self, 180.0, [[JARI_LODOK - 0.2, JARI_LUAR]])  # barat (menuju pondok)
	DuniaLingko.pematang_jari(self, -45.0, [[JARI_DALAM, 7.4], [8.8, JARI_TENGAH]])
	DuniaLingko.pematang_jari(self, 135.0, [[JARI_TENGAH, JARI_LUAR]])
	DuniaLingko.pondok(self, Vector3(-13.3, 0, 0), PI / 2.0)
	# Jalan masuk dari selatan dan tanjakan ke pematang luar
	DuniaLingko.jalan_tanah(self, Vector3(0, 0, 30), Vector3(0, 0, JARI_TEPI + 2.4))
	DuniaLingko.tanjakan(self, Vector3(0, 0, JARI_TEPI + 2.6), Vector3(0, Y_ATAS, JARI_TEPI - 0.2))
	Dunia.papan(self, Vector3(2.4, 0, 22.5), "Lingko Lodok")
	# Wae teku di utara lingko dengan saluran menuju pematang luar
	_saluran = DuniaLingko.wae_teku(self, POS_WAE_TEKU, Vector3(0, 0, -JARI_TEPI))
	_area_wae_teku = Interaktif.new()
	_area_wae_teku.teks_petunjuk = "Wae Teku"
	_area_wae_teku.jari_jari = 2.8
	_area_wae_teku.position = POS_WAE_TEKU
	add_child(_area_wae_teku)
	_area_wae_teku.diinteraksi.connect(_interaksi_wae_teku)
	Dunia.papan(self, POS_WAE_TEKU + Vector3(-3.0, 0, 0.8), "Wae Teku")
	_bangun_bukit()
	_bangun_alam()
	# Penambah nyawa: kendi air di pematang
	for posisi: Array in [[-120.0, JARI_TENGAH], [60.0, JARI_DALAM], [150.0, JARI_LUAR]]:
		var kendi := PenambahNyawa.new()
		kendi.jenis = "kendi"
		kendi.position = _di_pematang(posisi[0], posisi[1])
		add_child(kendi)


## Bukit batu di barat daya: batu pijakan bertingkat menuju puncak untuk memandang lingko.
func _bangun_bukit() -> void:
	Dunia.batu_pijakan(self, Vector3(-12.5, 0, 21.6), 0.9, 1.0)
	Dunia.batu_pijakan(self, Vector3(-14.4, 0, 20.4), 1.8, 0.95)
	Dunia.batu_pijakan(self, Vector3(-16.1, 0, 19.0), 2.7, 0.95)
	Dunia.batu_pijakan(self, Vector3(-17.6, 0, 17.4), 3.6, 0.95)
	Dunia.batu_pijakan(self, Vector3(POS_PUNCAK_BUKIT.x, 0, POS_PUNCAK_BUKIT.z), POS_PUNCAK_BUKIT.y, 1.8)
	# Batu goyah (pengecoh): miring sedikit, lebih gelap, bergaris retak; runtuh bila dipijak
	var tinggi_goyah: float = 2.7
	var pos_goyah := Vector3(-15.0, tinggi_goyah / 2.0, 21.9)
	var mi_goyah := Dunia.mesh(self, Dunia.silinder(0.9, 1.0, tinggi_goyah, 10), pos_goyah, Dunia.mat(Color("7a756c"), Dunia.TEX_BATU))
	mi_goyah.rotation.z = 0.12
	var m_retak := Dunia.mat(Color("2a2622"))
	for k in 3:
		var garis := BoxMesh.new()
		garis.size = Vector3(1.0 - k * 0.2, 0.02, 0.05)
		var g := Dunia.mesh(mi_goyah, garis, Vector3(0.1 * k - 0.1, tinggi_goyah / 2.0 + 0.01, 0.15 * k - 0.15), m_retak)
		g.rotation.y = 0.6 + k * 0.9
	var b_goyah := CylinderShape3D.new()
	b_goyah.radius = 0.9
	b_goyah.height = tinggi_goyah
	var badan_goyah := Dunia.badan_statis(self, b_goyah, pos_goyah)
	badan_goyah.set_meta("rapuh", true)
	badan_goyah.set_meta("batu", true)
	_ruas_rapuh.append({"node": [mi_goyah, badan_goyah], "asal": [mi_goyah.position, badan_goyah.position], "waktu": 0.0, "runtuh": false})
	var m_batu := Dunia.mat(Color("8a857c"), Dunia.TEX_BATU)
	var batu_hias: Array = [[Vector3(-22, 1.2, 14), 2.0], [Vector3(-21, 0.8, 18.5), 1.6], [Vector3(-23.5, 1.6, 17), 2.4],
		[Vector3(-18.5, 0.6, 12.5), 1.2]]
	for data: Array in batu_hias:
		var batu := SphereMesh.new()
		batu.radius = data[1]
		batu.height = data[1] * 1.5
		batu.radial_segments = 8
		batu.rings = 4
		Dunia.mesh(self, batu, data[0], m_batu)
	Dunia.papan(self, Vector3(-10.4, 0, 23.0), "Bukit Batu")
	_area_bukit = Interaktif.new()
	_area_bukit.teks_petunjuk = "Pandang lingko"
	_area_bukit.jari_jari = 1.9
	_area_bukit.tinggi_petunjuk = 2.9
	_area_bukit.position = POS_PUNCAK_BUKIT
	add_child(_area_bukit)
	_area_bukit.diinteraksi.connect(_interaksi_bukit)


func _bangun_alam() -> void:
	var acak := RandomNumberGenerator.new()
	acak.seed = 7
	for i in 30:
		var a: float = acak.randf() * TAU
		var r: float = acak.randf_range(24.0, 31.0)
		var pos := Vector3(cos(a) * r, 0, sin(a) * r)
		if pos.distance_to(TITIK_MUNCUL) > 5.0 and pos.distance_to(POS_WAE_TEKU) > 5.0 \
				and pos.distance_to(Vector3(-16, 0, 18.5)) > 7.5 and absf(pos.x) > 2.5:
			Dunia.pohon(self, pos, acak.randf_range(0.8, 1.3))
	for i in 12:
		var a: float = TAU * i / 12.0
		Dunia.bukit(self, Vector3(cos(a) * 60, -4, sin(a) * 60), acak.randf_range(14, 22), acak.randf_range(10, 20))


static func _di_pematang(sudut: float, jari: float) -> Vector3:
	var a: float = deg_to_rad(sudut)
	return Vector3(cos(a) * jari, Y_ATAS, sin(a) * jari)


func _buat_npc(nama: String, data: Dictionary) -> NpcKampung:
	var n := NpcKampung.new()
	n.nama = nama
	n.tekstur_songke = load("res://assets/textures/%s.png" % data["songke"])
	n.warna_baju = data["baju"]
	n.perempuan = data.get("perempuan", false)
	if data.has("pos_dunia"):
		n.position = data["pos_dunia"]
	else:
		var p: Array = data["pos"]
		n.position = _di_pematang(p[0], p[1])
	add_child(n)
	var ke_pusat: Vector3 = Vector3(0, n.position.y, 0) - n.position
	if ke_pusat.length() > 0.1:
		n.model.rotation.y = atan2(-ke_pusat.x, -ke_pusat.z)
	n.diajak_bicara.connect(_bicara)
	return n


func _bangun_warga() -> void:
	_tu_a_teno = _buat_npc("Tu'a Teno", {"pos_dunia": Vector3(0.9, Y_ATAS, 1.5), "songke": "songke_kuning", "baju": Color("1b1818")})
	_tu_a_teno.model.rotation.y = PI  # menghadap jalan masuk (selatan)


func _munculkan_pemain() -> void:
	pemain = ADEGAN_PEMAIN.instantiate()
	add_child(pemain)
	pemain.global_position = TITIK_MUNCUL
	pemain.model.rotation.y = 0.0
	kamera = KameraIkut.new()
	kamera.target = pemain
	add_child(kamera)
	kamera.current = true


# ------------------------------------------------------------------ UI level

func _bangun_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 11
	add_child(_ui)
	_label_waktu = Gaya.label("", 10, Gaya.KUNING)
	_label_waktu.position = Vector2(456, 12)
	_label_waktu.visible = false
	_ui.add_child(_label_waktu)
	_label_denda = Gaya.label("", 10, Color("ff6a6a"))
	_label_denda.position = Vector2(456, 26)
	_label_denda.modulate.a = 0.0
	_ui.add_child(_label_denda)
	GameState.state_berubah.connect(_saat_state_berubah)


func _saat_state_berubah(_lama: int, baru: int) -> void:
	if not is_instance_valid(_ui):
		return
	var tampak: bool = baru != GameState.State.DIALOG and baru != GameState.State.MINIGAME
	_label_waktu.visible = tampak and _waktu_berjalan


func _tampilkan_denda(detik: float) -> void:
	if not _waktu_berjalan:
		return
	_sisa_waktu = maxf(_sisa_waktu - detik, 0.0)
	_label_denda.text = "-%d detik" % int(detik)
	_label_denda.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(_label_denda, "modulate:a", 0.0, 0.6)


# ------------------------------------------------------------------ tahap & tujuan

func _atur_tahap(baru: int) -> void:
	tahap = baru
	if pemain:
		_titik_cek = _titik_aman  # titik cek tahap: tempat pemain berdiri saat tahap dimulai
	_atur_tantangan_jelajah()
	match tahap:
		Tahap.SAMBUT:
			GameState.atur_tujuan("Temui Tu'a Teno di lodok, titik pusat lingko. Susuri pematang dari jalan masuk.")
		Tahap.AIR:
			GameState.atur_tujuan("Pergi ke wae teku di utara lingko dan alirkan airnya.")
		Tahap.BUKIT:
			GameState.atur_tujuan("Naik ke bukit batu di barat daya dan pandang lingko dari atas.")
		Tahap.SELESAI:
			GameState.atur_tujuan("Pulang ke kampung untuk merayakan Penti.")
	_saat_state_berubah(GameState.state, GameState.state)


func _pembuka() -> void:
	if tahap == Tahap.SAMBUT and GameState.sedang(GameState.State.BERMAIN):
		_obrol(pemain, "Nggohak", _dialog()["pembuka"])


## Baris dialog dari daftar teks (atau satu teks), semuanya diucapkan oleh `nama`.
func _baris(nama: String, isi: Variant) -> Array:
	var daftar: Array = isi if isi is Array else [isi]
	var baris: Array = []
	for teks: String in daftar:
		baris.append({"nama": nama, "teks": teks})
	return baris


## Obrolan ringan sebagai gelembung teks di atas tokoh (pemain tetap bisa bergerak).
func _obrol(target: Node3D, nama: String, isi: Variant) -> void:
	var daftar: Array = isi if isi is Array else [isi]
	DialogManager.gelembung(target, daftar, nama, 3.6 if target == pemain else 3.9)


func _beri_kartu(id: String, lanjut: Callable) -> void:
	GameState.kumpulkan_kartu(id)
	DialogManager.tampilkan_kartu(id, lanjut)


# ------------------------------------------------------------------ percakapan

func _bicara(npc: NpcKampung) -> void:
	if npc == _tu_a_teno:
		_bicara_tu_a_teno()


func _bicara_tu_a_teno() -> void:
	var d: Dictionary = _dialog()
	match tahap:
		Tahap.SAMBUT:
			var baris: Array = _baris("Tu'a Teno", d["sambutan"])
			if GameState.mode_sulit:
				baris.append_array(_baris("Tu'a Teno", d["sambutan_sulit"]))
			DialogManager.mulai_baris("sambutan", baris, _setelah_sambutan)
		Tahap.AIR:
			_obrol(_tu_a_teno, "Tu'a Teno", d["menunggu_air"])
		Tahap.BUKIT:
			_obrol(_tu_a_teno, "Tu'a Teno", d["menunggu_bukit"])
		_:
			_obrol(_tu_a_teno, "Tu'a Teno", d["menunggu_bukit"])


func _setelah_sambutan() -> void:
	_beri_kartu("lingko", func() -> void:
		_atur_tahap(Tahap.AIR)
		if GameState.mode_sulit:
			_waktu_berjalan = true
			_saat_state_berubah(GameState.state, GameState.state))


# ------------------------------------------------------------------ wae teku

func _interaksi_wae_teku(_p: Pemain) -> void:
	var d: Dictionary = _dialog()
	if tahap == Tahap.AIR:
		DialogManager.mulai_baris("buka_saluran", _baris("Nggohak", d["buka_saluran"]), _mulai_saluran)
	elif tahap > Tahap.AIR:
		_obrol(pemain, "Nggohak", d["wae_teku_selesai"])
	else:
		_obrol(pemain, "Nggohak", d["lihat_wae_teku"])


func _mulai_saluran() -> void:
	var s: SaluranAir = SALURAN.new()
	s.selesai.connect(_hasil_saluran.bind(s))
	s.salah.connect(Nyawa.kurangi)
	_minigame = s
	Nyawa.atur_tantangan("Mengalirkan air wae teku", _ulangi_minigame.bind(_mulai_saluran))
	add_child(s)


func _hasil_saluran(berhasil: bool, s: SaluranAir) -> void:
	_minigame = null
	_atur_tantangan_jelajah()
	var d: Dictionary = _dialog()
	if not berhasil:
		if not s.batal:
			Nyawa.kurangi("gagal mengalirkan air")
		if not Nyawa.sedang_habis():
			_obrol(pemain, "Nggohak", d["air_gagal"])
		return
	_alirkan_air()
	_obrol(pemain, "Nggohak", d["air_berhasil"])
	_beri_kartu("wae_teku", _atur_tahap.bind(Tahap.BUKIT))


## Visual: saluran dan petak sawah berubah dari kering menjadi berair.
func _alirkan_air() -> void:
	var m_air := Dunia.mat(Color("5fa8d3"))
	m_air.roughness = 0.15
	_saluran.material_override = m_air
	_petak.material_override = DuniaLingko.mat_berair()
	AudioManager.putar_sfx("berhasil")


## Nyawa habis di mini-game: tutup lalu buka lagi dari awal.
func _ulangi_minigame(pembuka: Callable) -> void:
	if is_instance_valid(_minigame):
		_minigame.queue_free()
	_minigame = null
	GameState.ubah_state(GameState.State.BERMAIN)
	pembuka.call()


## Tantangan jelajah (menyusuri pematang): nyawa habis = kembali ke titik cek tahap ini.
func _atur_tantangan_jelajah() -> void:
	Nyawa.atur_tantangan("Menyusuri pematang", func() -> void:
		pemain.velocity = Vector3.ZERO
		pemain.global_position = _titik_cek + Vector3(0, 0.2, 0)
		_titik_aman = _titik_cek)


# ------------------------------------------------------------------ bukit batu

func _interaksi_bukit(_p: Pemain) -> void:
	if tahap != Tahap.BUKIT:
		_obrol(pemain, "Nggohak", _dialog()["bukit_belum"])
		return
	_atur_tahap(Tahap.SELESAI)
	_waktu_berjalan = false
	_label_waktu.visible = false
	# Kamera naik perlahan dari bukit sehingga seluruh lingko tampak dari atas
	_kamera_pandang = Camera3D.new()
	_kamera_pandang.fov = 60.0
	add_child(_kamera_pandang)
	_kamera_pandang.global_transform = kamera.global_transform
	_kamera_pandang.current = true
	var tw := create_tween()
	tw.tween_property(_kamera_pandang, "global_position", Vector3(-17.0, 25.0, 19.0), 2.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	DialogManager.mulai_baris("pandang", _baris("Nggohak", _dialog()["pandang"]), func() -> void:
		_beri_kartu("lingko_lodok", _tamat))


func _tamat() -> void:
	AudioManager.putar_sfx("gong")
	GameState.selesaikan_level(NOMOR_LEVEL)


# ------------------------------------------------------------------ per frame

func _process(delta: float) -> void:
	if _kamera_pandang:
		_kamera_pandang.look_at(Vector3(0, 0, -1.0), Vector3.UP)
	if _waktu_berjalan and not _waktu_habis and GameState.sedang(GameState.State.BERMAIN):
		_sisa_waktu = maxf(_sisa_waktu - delta, 0.0)
		if _sisa_waktu <= 0.0:
			_matahari_terbenam()
	if _waktu_berjalan:
		var detik: int = int(ceil(_sisa_waktu))
		_label_waktu.text = "Sebelum senja: %d:%02d" % [detik / 60, detik % 60]
		_atur_senja(1.0 - _sisa_waktu / WAKTU_SULIT)


## Mode Sulit: matahari makin rendah dan langit makin jingga menjelang senja.
func _atur_senja(t: float) -> void:
	if _matahari:
		_matahari.rotation_degrees.x = lerpf(-50.0, -12.0, t)
		_matahari.light_color = Color("fff1d8").lerp(Color("ff9a5a"), t)
		_matahari.light_energy = lerpf(1.1, 0.6, t)
	if _langit:
		_langit.sky_top_color = Color("6f9cc4").lerp(Color("4a4a7a"), t)
		_langit.sky_horizon_color = Color("cfdde0").lerp(Color("f0a070"), t)


func _matahari_terbenam() -> void:
	_waktu_habis = true
	_waktu_berjalan = false
	AudioManager.putar_sfx("gagal")
	DialogManager.mulai_baris("waktu_habis", _baris("Tu'a Teno", _dialog()["waktu_habis"]), GameState.ulangi_level)


func _physics_process(delta: float) -> void:
	if pemain == null:
		return
	_jeda_jatuh = maxf(_jeda_jatuh - delta, 0.0)
	var p: Vector3 = pemain.global_position
	var di_sawah: bool = Vector2(p.x, p.z).length() < JARI_TEPI and p.y < DuniaLingko.TINGGI_AIR
	_perbarui_rapuh(delta, p)
	if di_sawah:
		if _jeda_jatuh <= 0.0:
			_jatuh_ke_lumpur()
	elif pemain.is_on_floor() and _pijakan_aman(p):
		_titik_aman = p


## Pematang rapuh dan batu goyah runtuh 0,8 detik setelah diinjak, lalu pulih beberapa detik kemudian.
func _perbarui_rapuh(delta: float, p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.3, 0), p + Vector3(0, -0.4, 0), Dunia.LAPISAN_DUNIA)
	q.exclude = [pemain.get_rid()]
	var lantai: Object = get_world_3d().direct_space_state.intersect_ray(q).get("collider", null)
	for r: Dictionary in _ruas_rapuh:
		if r["runtuh"]:
			continue
		var nodes: Array = r["node"]
		if lantai == nodes[nodes.size() - 1] and pemain.is_on_floor():
			r["waktu"] = float(r["waktu"]) + delta
			var goyang := Vector3(randf_range(-0.03, 0.03), 0, randf_range(-0.03, 0.03))
			(nodes[0] as Node3D).position = (r["asal"] as Array)[0] + goyang
			if float(r["waktu"]) >= 0.8:
				_runtuhkan(r)
		else:
			r["waktu"] = 0.0


func _runtuhkan(r: Dictionary) -> void:
	r["runtuh"] = true
	AudioManager.putar_sfx("terkena", 0.2)
	Efek.percikan(self, pemain.global_position, true)  # lumpur sawah terciprat
	var nodes: Array = r["node"]
	var asal: Array = r["asal"]
	var batu: bool = (nodes[nodes.size() - 1] as Node).has_meta("batu")
	if not _sudah_tahu_rapuh or batu:
		_sudah_tahu_rapuh = true
		_obrol(pemain, "Nggohak", _dialog()["batu_goyah" if batu else "rapuh"])
	if batu:
		Nyawa.kurangi("tertipu batu goyah", true)
	var tw := create_tween().set_parallel()
	for i in nodes.size():
		tw.tween_property(nodes[i], "position:y", (asal[i] as Vector3).y - 3.0, 0.5).set_ease(Tween.EASE_IN)
	tw.chain().tween_interval(4.0)
	tw.chain().tween_callback(func() -> void:
		for i in nodes.size():
			(nodes[i] as Node3D).position = asal[i]
		r["waktu"] = 0.0
		r["runtuh"] = false)


## Titik aman bila tanah di sekeliling kaki pemain juga padat (bukan di tepi pematang).
func _pijakan_aman(p: Vector3) -> bool:
	var ruang := get_world_3d().direct_space_state
	for geser: Vector3 in [Vector3(0.35, 0, 0), Vector3(-0.35, 0, 0), Vector3(0, 0, 0.35), Vector3(0, 0, -0.35)]:
		var q := PhysicsRayQueryParameters3D.create(p + geser + Vector3(0, 0.5, 0), p + geser + Vector3(0, -0.4, 0), Dunia.LAPISAN_DUNIA)
		q.exclude = [pemain.get_rid()]
		var hasil: Dictionary = ruang.intersect_ray(q)
		if hasil.is_empty() or (hasil["collider"] as Object).has_meta("rapuh"):
			return false
	return true


func _jatuh_ke_lumpur() -> void:
	_jeda_jatuh = 0.6
	AudioManager.putar_sfx("terkena", 0.1)
	kamera.guncang(0.4)
	pemain.velocity = Vector3.ZERO
	pemain.global_position = _titik_aman + Vector3(0, 0.15, 0)
	pemain.model.squash(Vector3(1.2, 0.8, 1.2))
	if GameState.mode_sulit:
		_tampilkan_denda(DENDA_JATUH)
	Nyawa.kurangi("jatuh ke lumpur")
