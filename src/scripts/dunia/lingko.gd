extends Node3D
## Level 2: LINGKO LODOK — lahan adat di luar kampung (gendang one, lingko pe'ang).
## Alur (FSM tahap level):
##   SAMBUT  -> temui Tu'a Teno di lodok (pusat lingko)
##   UNDANG  -> undang lima kepala keluarga berdasarkan ciri-cirinya (ada pengecoh)
##   REKE    -> kembali ke lodok: reke lodok (musyawarah melingkar)
##   AIR     -> alirkan air dari wae teku (mini-game SaluranAir)
##   BAGI    -> bagi tiga lingko dengan garis moso sesuai musyawarah (mini-game BagiLingko)
##   BUKIT   -> naik ke bukit batu dan pandang lingko dari atas
##   SELESAI -> level tamat (GameState.selesaikan_level)
## Pematang sempit dan ada yang putus: jatuh ke lumpur = kembali ke titik aman terakhir.
## Mode Sulit: batas waktu "sebelum senja"; jatuh dan salah orang mengurangi waktu.

enum Tahap { SAMBUT, UNDANG, REKE, AIR, BAGI, BUKIT, SELESAI }

const ADEGAN_PEMAIN: PackedScene = preload("res://scenes/pemain.tscn")
const SALURAN: Script = preload("res://scripts/minigame/saluran_air.gd")
const BAGI: Script = preload("res://scripts/minigame/bagi_lingko.gd")
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
const DENDA_SALAH_ORANG: float = 15.0

## Lima kepala keluarga (urutan sama dengan "keluarga" di lingko.json).
const DATA_KELUARGA: Array = [
	{"pos": [-90.0, JARI_TENGAH], "songke": "songke_merah", "baju": Color("e8e2d2")},
	{"pos_dunia": Vector3(2.3, 0, -20.2), "songke": "songke_hijau", "baju": Color("b02a2a"), "perempuan": true},
	{"pos": [0.0, JARI_DALAM], "songke": "songke_kuning", "baju": Color("2c5c96")},
	{"pos_dunia": Vector3(-13.3, Y_ATAS, 0.6), "songke": "songke_biru", "baju": Color("e8e2d2"), "perempuan": true},
	{"pos": [-45.0, JARI_LUAR], "songke": "songke_biru", "baju": Color("1b1818"), "keliling": true},
]
## Pengecoh (urutan sama dengan "pengecoh" di lingko.json): ciri mirip, tempat berbeda.
const DATA_PENGECOH: Array = [
	{"pos": [90.0, JARI_TENGAH], "songke": "songke_merah", "baju": Color("1b1818")},
	{"pos": [135.0, JARI_LUAR], "songke": "songke_hijau", "baju": Color("e8e2d2"), "perempuan": true},
	{"pos": [0.0, JARI_LUAR], "songke": "songke_kuning", "baju": Color("e8e2d2")},
]

var pemain: Pemain
var kamera: KameraIkut
var tahap: int = Tahap.SAMBUT

var _tu_a_teno: NpcKampung
var _tu_a_golo: NpcKampung
var _keluarga: Array[NpcKampung] = []
var _diundang: Array[bool] = [false, false, false, false, false]
var _petak: MeshInstance3D
var _saluran: MeshInstance3D
var _area_wae_teku: Interaktif
var _area_bukit: Interaktif

var _titik_aman: Vector3 = TITIK_MUNCUL
var _jeda_jatuh: float = 0.0
var _sisa_waktu: float = WAKTU_SULIT
var _waktu_berjalan: bool = false
var _waktu_habis: bool = false
var _matahari: DirectionalLight3D
var _langit: ProceduralSkyMaterial
var _kamera_pandang: Camera3D

# UI level (daftar undangan, sisa waktu, tirai)
var _ui: CanvasLayer
var _panel_undangan: NinePatchRect
var _label_undangan: RichTextLabel
var _label_waktu: Label
var _label_denda: Label
var _tirai: ColorRect


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
	DuniaLingko.pematang_lingkar(self, JARI_DALAM, [135.0, -30.0])
	DuniaLingko.pematang_lingkar(self, JARI_TENGAH, [45.0, 160.0, -135.0])
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


## Bukit batu di barat daya: batu pijakan bertingkat menuju puncak untuk memandang lingko.
func _bangun_bukit() -> void:
	Dunia.batu_pijakan(self, Vector3(-12.5, 0, 21.6), 0.9, 1.0)
	Dunia.batu_pijakan(self, Vector3(-14.4, 0, 20.4), 1.8, 0.95)
	Dunia.batu_pijakan(self, Vector3(-16.1, 0, 19.0), 2.7, 0.95)
	Dunia.batu_pijakan(self, Vector3(-17.6, 0, 17.4), 3.6, 0.95)
	Dunia.batu_pijakan(self, Vector3(POS_PUNCAK_BUKIT.x, 0, POS_PUNCAK_BUKIT.z), POS_PUNCAK_BUKIT.y, 1.8)
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
	_tu_a_golo = _buat_npc("Tu'a Golo", {"pos_dunia": Vector3(-1.3, Y_ATAS, 1.1), "songke": "songke_kuning", "baju": Color("1b1818")})
	_tu_a_golo.model.rotation.y = PI - 0.3
	var daftar: Array = DATA.data["keluarga"]
	for i in daftar.size():
		var d: Dictionary = DATA_KELUARGA[i]
		var n := _buat_npc(str(daftar[i]["nama"]), d)
		if d.get("keliling", false):
			# Ema Gabriel tak pernah berhenti menyusuri pematang terluar
			for k in 24:
				n.titik_patroli.append(_di_pematang(-45.0 + k * 15.0, JARI_LUAR))
			n.lama_diam_min = 0.1
			n.lama_diam_maks = 0.4
			n.kecepatan = 1.6
		_keluarga.append(n)
	var pengecoh: Array = DATA.data["pengecoh"]
	for i in pengecoh.size():
		var n := _buat_npc(str(pengecoh[i]["nama"]), DATA_PENGECOH[i])
		n.set_meta("pengecoh", i)


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
	_panel_undangan = Gaya.panel_songke(Vector2(454, 44), Vector2(178, 168))
	_panel_undangan.visible = false
	_ui.add_child(_panel_undangan)
	var judul := Gaya.label("Undangan Reke Lodok", 9, Gaya.KUNING)
	judul.position = Vector2(10, 6)
	_panel_undangan.add_child(judul)
	_label_undangan = RichTextLabel.new()
	_label_undangan.bbcode_enabled = true
	_label_undangan.position = Vector2(10, 22)
	_label_undangan.size = Vector2(162, 142)
	_label_undangan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_undangan.add_theme_font_size_override("normal_font_size", 7)
	_panel_undangan.add_child(_label_undangan)
	_tirai = ColorRect.new()
	_tirai.color = Color(0.08, 0.06, 0.06)
	_tirai.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tirai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tirai.modulate.a = 0.0
	_ui.add_child(_tirai)
	GameState.state_berubah.connect(_saat_state_berubah)


func _saat_state_berubah(_lama: int, baru: int) -> void:
	if not is_instance_valid(_ui):
		return
	var tampak: bool = baru != GameState.State.DIALOG and baru != GameState.State.MINIGAME
	_panel_undangan.visible = tampak and tahap == Tahap.UNDANG
	_label_waktu.visible = tampak and _waktu_berjalan


func _perbarui_undangan() -> void:
	var daftar: Array = DATA.data["keluarga"]
	var teks: String = ""
	for i in daftar.size():
		var tanda: String = "[color=#7fd47f][x][/color]" if _diundang[i] else "[color=#e8b430][  ][/color]"
		var ciri: String = str(daftar[i]["ciri"])
		teks += "%s %s\n" % [tanda, ("[color=#9a948a]%s[/color]" % ciri) if _diundang[i] else ciri]
	_label_undangan.text = teks


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
	match tahap:
		Tahap.SAMBUT:
			GameState.atur_tujuan("Temui Tu'a Teno di lodok, titik pusat lingko. Susuri pematang dari jalan masuk.")
		Tahap.UNDANG:
			GameState.atur_tujuan("Undang lima kepala keluarga ke reke lodok (lihat ciri-cirinya di kanan atas).")
			_perbarui_undangan()
		Tahap.REKE:
			GameState.atur_tujuan("Kembali ke Tu'a Teno di lodok untuk reke lodok.")
		Tahap.AIR:
			GameState.atur_tujuan("Pergi ke wae teku di utara lingko dan alirkan airnya.")
		Tahap.BAGI:
			GameState.atur_tujuan("Kembali ke Tu'a Teno di lodok untuk membagi lingko dengan moso.")
		Tahap.BUKIT:
			GameState.atur_tujuan("Naik ke bukit batu di barat daya dan pandang lingko dari atas.")
		Tahap.SELESAI:
			GameState.atur_tujuan("Pulang ke kampung untuk merayakan Penti.")
	_saat_state_berubah(GameState.state, GameState.state)


func _pembuka() -> void:
	if tahap == Tahap.SAMBUT and GameState.sedang(GameState.State.BERMAIN):
		DialogManager.mulai_baris("lingko_pembuka", _baris("Nggohak", _dialog()["pembuka"]))


## Baris dialog dari daftar teks (atau satu teks), semuanya diucapkan oleh `nama`.
func _baris(nama: String, isi: Variant) -> Array:
	var daftar: Array = isi if isi is Array else [isi]
	var baris: Array = []
	for teks: String in daftar:
		baris.append({"nama": nama, "teks": teks})
	return baris


func _beri_kartu(id: String, lanjut: Callable) -> void:
	GameState.kumpulkan_kartu(id)
	DialogManager.tampilkan_kartu(id, lanjut)


# ------------------------------------------------------------------ percakapan

func _bicara(npc: NpcKampung) -> void:
	if npc == _tu_a_teno:
		_bicara_tu_a_teno()
	elif npc == _tu_a_golo:
		DialogManager.mulai_baris("tua_golo", _baris("Tu'a Golo", _dialog()["tua_golo"]))
	elif npc.has_meta("pengecoh"):
		_bicara_pengecoh(npc)
	else:
		_bicara_keluarga(_keluarga.find(npc))


func _bicara_tu_a_teno() -> void:
	var d: Dictionary = _dialog()
	match tahap:
		Tahap.SAMBUT:
			var baris: Array = _baris("Tu'a Teno", d["sambutan"])
			if GameState.mode_sulit:
				baris.append_array(_baris("Tu'a Teno", d["sambutan_sulit"]))
			DialogManager.mulai_baris("sambutan", baris, _setelah_sambutan)
		Tahap.UNDANG:
			DialogManager.mulai_baris("menunggu_undangan", _baris("Tu'a Teno", d["menunggu_undangan"]))
		Tahap.REKE:
			_mulai_reke_lodok()
		Tahap.AIR:
			DialogManager.mulai_baris("menunggu_air", _baris("Tu'a Teno", d["menunggu_air"]))
		Tahap.BAGI:
			DialogManager.mulai_baris("mulai_bagi", _baris("Tu'a Teno", d["mulai_bagi"]), _mulai_bagi)
		Tahap.BUKIT:
			DialogManager.mulai_baris("menunggu_bukit", _baris("Tu'a Teno", d["menunggu_bukit"]))
		_:
			DialogManager.mulai_baris("tua_teno_selesai", _baris("Tu'a Teno", d["menunggu_bukit"]))


func _setelah_sambutan() -> void:
	_beri_kartu("lingko", func() -> void:
		_atur_tahap(Tahap.UNDANG)
		if GameState.mode_sulit:
			_waktu_berjalan = true
			_saat_state_berubah(GameState.state, GameState.state))


func _bicara_keluarga(i: int) -> void:
	if i < 0:
		return
	var data: Dictionary = DATA.data["keluarga"][i]
	var nama: String = str(data["nama"])
	if tahap == Tahap.SAMBUT:
		DialogManager.mulai_baris("belum", _baris(nama, _dialog()["belum_waktunya"]))
	elif _diundang[i]:
		DialogManager.mulai_baris("sudah_diundang", _baris(nama, DATA.data["sudah_diundang"]))
	elif tahap == Tahap.UNDANG:
		var baris: Array = _baris("Nggohak", _dialog()["ajak"])
		baris.append_array(_baris(nama, data["undang"]))
		DialogManager.mulai_baris("undang", baris, _setelah_undang.bind(i))


func _setelah_undang(i: int) -> void:
	_diundang[i] = true
	AudioManager.putar_sfx("ambil")
	_perbarui_undangan()
	if not _diundang.has(false):
		_atur_tahap(Tahap.REKE)
		DialogManager.mulai_baris("semua_diundang", _baris("Nggohak", _dialog()["semua_diundang"]))


func _bicara_pengecoh(npc: NpcKampung) -> void:
	var data: Dictionary = DATA.data["pengecoh"][int(npc.get_meta("pengecoh"))]
	if tahap != Tahap.UNDANG:
		DialogManager.mulai_baris("pengecoh_sapa", _baris(npc.nama, _dialog()["sapa_warga"]))
		return
	var baris: Array = _baris("Nggohak", _dialog()["ajak"])
	var teks: String = str(DATA.data["pengecoh_sulit"]) if GameState.mode_sulit else str(data["petunjuk"])
	baris.append_array(_baris(npc.nama, teks))
	DialogManager.mulai_baris("pengecoh", baris)
	if GameState.mode_sulit and not npc.has_meta("sudah_ditanya"):
		_tampilkan_denda(DENDA_SALAH_ORANG)  # denda hanya sekali per pengecoh
	npc.set_meta("sudah_ditanya", true)


# ------------------------------------------------------------------ reke lodok

## Layar meredup, para kepala keluarga dan tetua duduk melingkar (lonto leok) di lodok,
## lalu Tu'a Teno memimpin musyawarah.
func _mulai_reke_lodok() -> void:
	if not GameState.ubah_state(GameState.State.MINIGAME):
		return
	var tw := create_tween()
	tw.tween_property(_tirai, "modulate:a", 1.0, 0.5)
	tw.tween_callback(_atur_lonto_leok)
	tw.tween_property(_tirai, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		GameState.ubah_state(GameState.State.BERMAIN)
		DialogManager.mulai_baris("reke_lodok", _baris("Tu'a Teno", _dialog()["reke_lodok"]), _setelah_reke))


func _atur_lonto_leok() -> void:
	var peserta: Array[NpcKampung] = [_tu_a_teno, _tu_a_golo]
	peserta.append_array(_keluarga)
	for i in peserta.size():
		var n: NpcKampung = peserta[i]
		n.titik_patroli.clear()
		var a: float = PI / 2.0 + TAU * i / peserta.size() + 0.35
		n.global_position = Vector3(cos(a) * 1.85, Y_ATAS, sin(a) * 1.85)
		n.model.rotation.y = atan2(n.global_position.x, n.global_position.z)  # menghadap haju teno
		n.model.mode = "idle"
	# Pemain ikut duduk dalam lingkaran, di sisi selatan lodok
	pemain.global_position = Vector3(0, Y_ATAS + 0.1, JARI_LODOK - 0.3)
	pemain.velocity = Vector3.ZERO
	pemain.model.rotation.y = 0.0
	_titik_aman = pemain.global_position


func _setelah_reke() -> void:
	_beri_kartu("reke_lodok", _atur_tahap.bind(Tahap.AIR))


# ------------------------------------------------------------------ wae teku

func _interaksi_wae_teku(_p: Pemain) -> void:
	var d: Dictionary = _dialog()
	if tahap == Tahap.AIR:
		DialogManager.mulai_baris("buka_saluran", _baris("Nggohak", d["buka_saluran"]), _mulai_saluran)
	elif tahap > Tahap.AIR:
		DialogManager.mulai_baris("wae_teku_selesai", _baris("Nggohak", d["wae_teku_selesai"]))
	else:
		DialogManager.mulai_baris("lihat_wae_teku", _baris("Nggohak", d["lihat_wae_teku"]))


func _mulai_saluran() -> void:
	var s: SaluranAir = SALURAN.new()
	s.selesai.connect(_hasil_saluran)
	add_child(s)


func _hasil_saluran(berhasil: bool) -> void:
	var d: Dictionary = _dialog()
	if not berhasil:
		DialogManager.mulai_baris("air_gagal", _baris("Nggohak", d["air_gagal"]))
		return
	_alirkan_air()
	DialogManager.mulai_baris("air_berhasil", _baris("Nggohak", d["air_berhasil"]), func() -> void:
		_beri_kartu("wae_teku", _atur_tahap.bind(Tahap.BAGI)))


## Visual: saluran dan petak sawah berubah dari kering menjadi berair.
func _alirkan_air() -> void:
	var m_air := Dunia.mat(Color("5fa8d3"))
	m_air.roughness = 0.15
	_saluran.material_override = m_air
	_petak.material_override = DuniaLingko.mat_berair()
	AudioManager.putar_sfx("berhasil")


# ------------------------------------------------------------------ membagi lingko

func _mulai_bagi() -> void:
	var b: BagiLingko = BAGI.new()
	b.siapkan(DATA.data["ronde"])
	b.selesai.connect(_hasil_bagi)
	add_child(b)


func _hasil_bagi(berhasil: bool) -> void:
	var d: Dictionary = _dialog()
	if not berhasil:
		DialogManager.mulai_baris("bagi_gagal", _baris("Tu'a Teno", d["bagi_gagal"]))
		return
	_tampilkan_juring_terbagi()
	DialogManager.mulai_baris("bagi_berhasil", _baris("Tu'a Teno", d["bagi_berhasil"]), func() -> void:
		_beri_kartu("moso", _atur_tahap.bind(Tahap.BUKIT)))


## Garis moso hasil pembagian lingko terakhir ditancapkan di sawah: petak tampak seperti jaring laba-laba.
func _tampilkan_juring_terbagi() -> void:
	var semua_ronde: Array = DATA.data["ronde"]
	var ronde: Dictionary = semua_ronde[semua_ronde.size() - 1]
	var bagian: int = int(ronde["bagian"])
	var batas: Array = []
	var jumlah: int = 0
	for t: Variant in ronde["target"]:
		batas.append(-PI / 2.0 + TAU * jumlah / bagian)
		jumlah += int(t)
	DuniaLingko.juring_terbagi(self, JARI_LODOK - 0.1, JARI_TEPI, batas)
	_petak.visible = false


# ------------------------------------------------------------------ bukit batu

func _interaksi_bukit(_p: Pemain) -> void:
	if tahap != Tahap.BUKIT:
		DialogManager.mulai_baris("bukit_belum", _baris("Nggohak", _dialog()["bukit_belum"]))
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
	if di_sawah:
		if _jeda_jatuh <= 0.0:
			_jatuh_ke_lumpur()
	elif pemain.is_on_floor() and _pijakan_aman(p):
		_titik_aman = p


## Titik aman bila tanah di sekeliling kaki pemain juga padat (bukan di tepi pematang).
func _pijakan_aman(p: Vector3) -> bool:
	var ruang := get_world_3d().direct_space_state
	for geser: Vector3 in [Vector3(0.35, 0, 0), Vector3(-0.35, 0, 0), Vector3(0, 0, 0.35), Vector3(0, 0, -0.35)]:
		var q := PhysicsRayQueryParameters3D.create(p + geser + Vector3(0, 0.5, 0), p + geser + Vector3(0, -0.4, 0), Dunia.LAPISAN_DUNIA)
		q.exclude = [pemain.get_rid()]
		if ruang.intersect_ray(q).is_empty():
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
