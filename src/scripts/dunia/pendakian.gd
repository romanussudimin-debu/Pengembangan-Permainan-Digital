extends Node3D
## Level 1, pembuka: MENDAKI KE WAE REBO (platformer, ±1,5-2 menit) setelah opening, sebelum kampung.
## Jalur hutan menuju utara: sungai dengan batu pijakan, akar pohon melintang, titian di atas jurang,
## tanjakan batu, lalu sungai kedua di dataran tinggi. Tiga titik cek (bendera songke).
## Pengecoh yang adil:
##   - batu RETAK: mirip batu biasa tetapi lebih gelap dengan garis retakan; tenggelam bila diinjak sebentar.
##   - cabang jalan BUNTU: jalur utama ditandai tiang bambu berkain merah, cabang buntu tidak.
## Jatuh ke sungai/jurang = -1 nyawa lalu kembali ke titik aman. Nyawa habis = ulang dari titik cek.

const ADEGAN_PEMAIN: PackedScene = preload("res://scenes/pemain.tscn")
const ADEGAN_KAMPUNG: String = "res://scenes/kampung.tscn"
const DATA: JSON = preload("res://data/rantai_teka_teki.json")
const TITIK_MUNCUL := Vector3(0, 0.3, 27)
const DETIK_RETAK: float = 0.35
## Batu pijakan: [x, z, puncak_y, retak?]
const BATU: Array = [
	[0.0, 13.0, 0.3, false], [-1.6, 10.5, 0.3, false], [1.6, 10.5, 0.3, true], [-0.6, 8.0, 0.3, false],
	[2.4, 8.0, 0.3, false], [0.8, 5.5, 0.3, false],
	[-1.8, -46.0, 2.7, false], [1.8, -46.0, 2.7, true], [-0.9, -48.5, 2.7, false], [1.5, -48.5, 2.7, true],
	[0.8, -51.0, 2.7, false], [-2.2, -51.0, 2.7, true],
]
const TITIK_CEK: Array[Vector3] = [Vector3(0, 0, 25), Vector3(0, 0, -1), Vector3(0, 2.4, -38)]

var pemain: Pemain
var kamera: KameraIkut
var _titik_aman: Vector3 = TITIK_MUNCUL
var _titik_cek: Vector3 = TITIK_MUNCUL
var _batu_retak: Array[Dictionary] = []  ## {badan, mesh, asal, waktu, tenggelam}
var _jeda_jatuh: float = 0.0
var _sudah_retak: bool = false
var _tiba: bool = false


func _ready() -> void:
	GameState.level = 1
	_bangun_dunia()
	_munculkan_pemain()
	add_child(preload("res://scripts/ui/hud.gd").new())
	AudioManager.putar_musik("kampung")
	GameState.ubah_state(GameState.State.BERMAIN)
	GameState.atur_tujuan(_teks("tujuan"))
	Nyawa.atur_tantangan("Mendaki ke Wae Rebo", _ulang_dari_titik_cek)
	get_tree().create_timer(0.8, false).timeout.connect(
			func() -> void: DialogManager.gelembung(pemain, [_teks("pembuka")], "Nggohak", 3.6))


func _teks(id: String) -> String:
	return str(DATA.data["pendakian"][id])


# ------------------------------------------------------------------ dunia

func _tanah(pusat: Vector3, ukuran: Vector2, warna: Color = Color.WHITE) -> void:
	var kotak := BoxMesh.new()
	kotak.size = Vector3(ukuran.x, 3.0, ukuran.y)
	Dunia.mesh(self, kotak, pusat + Vector3(0, -1.5, 0), Dunia.mat(warna, Dunia.TEX_RUMPUT, Vector3(ukuran.x / 2.0, ukuran.y / 2.0, 1)))
	var bentuk := BoxShape3D.new()
	bentuk.size = kotak.size
	Dunia.badan_statis(self, bentuk, pusat + Vector3(0, -1.5, 0))


## Tebing di sisi jalur (dinding alami) dengan pohon di atasnya.
func _tebing(pusat: Vector3, ukuran: Vector2) -> void:
	var tinggi: float = pusat.y + 8.0
	var kotak := BoxMesh.new()
	kotak.size = Vector3(ukuran.x, tinggi, ukuran.y)
	var tengah := Vector3(pusat.x, pusat.y - tinggi / 2.0, pusat.z)
	Dunia.mesh(self, kotak, tengah, Dunia.mat(Color("6a5a44"), Dunia.TEX_BATU, Vector3(ukuran.x / 3.0, tinggi / 3.0, 1)))
	var atas := BoxMesh.new()
	atas.size = Vector3(ukuran.x, 0.05, ukuran.y)
	Dunia.mesh(self, atas, pusat + Vector3(0, 0.02, 0), Dunia.mat(Color.WHITE, Dunia.TEX_RUMPUT, Vector3(ukuran.x / 2.0, ukuran.y / 2.0, 1)))
	var bentuk := BoxShape3D.new()
	bentuk.size = kotak.size
	Dunia.badan_statis(self, bentuk, tengah)
	var acak := RandomNumberGenerator.new()
	acak.seed = int(pusat.z * 10.0 + pusat.x)
	for i in maxi(int(ukuran.y / 4.0), 1):
		var x: float = pusat.x + signf(pusat.x) * acak.randf_range(-4.0, 6.0)
		var z: float = pusat.z + acak.randf_range(-ukuran.y / 2.0 + 1.0, ukuran.y / 2.0 - 1.0)
		Dunia.pohon(self, Vector3(x, pusat.y, z), acak.randf_range(0.9, 1.4))


func _air(pusat: Vector3, ukuran: Vector2) -> void:
	var bidang := PlaneMesh.new()
	bidang.size = ukuran
	var m := Dunia.mat(Color(0.25, 0.55, 0.7, 0.85))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	Dunia.mesh(self, bidang, pusat, m)
	var dasar := PlaneMesh.new()
	dasar.size = ukuran
	Dunia.mesh(self, dasar, pusat + Vector3(0, -3, 0), Dunia.mat(Color("2a3a3a")))


func _bangun_dunia() -> void:
	Dunia.lingkungan(self)
	Dunia.batas_dunia(self, 85.0)  # jalur membentang dari z +30 sampai -72
	var dasar := PlaneMesh.new()  # lembah jauh di bawah (visual)
	dasar.size = Vector2(300, 300)
	Dunia.mesh(self, dasar, Vector3(0, -8, 0), Dunia.mat(Color("2f5a34")))
	# Bagian jalur (ngarai): [z_awal, z_akhir, puncak_y, jenis] - jenis "tanah", "sungai", "jurang"
	var segmen: Array = [
		[30.0, 16.0, 0.0, "tanah"], [16.0, 4.0, 0.0, "sungai"], [4.0, -10.0, 0.0, "tanah"],
		[-10.0, -22.0, 0.0, "jurang"], [-22.0, -34.0, 0.0, "tanah"], [-34.0, -44.0, 2.4, "tanah"],
		[-44.0, -54.0, 2.4, "sungai"], [-54.0, -72.0, 2.4, "tanah"],
	]
	for sg: Array in segmen:
		var z0: float = sg[0]
		var z1: float = sg[1]
		var y: float = sg[2]
		var panjang: float = z0 - z1
		var tengah: float = (z0 + z1) / 2.0
		match str(sg[3]):
			"tanah":
				_tanah(Vector3(0, y, tengah), Vector2(12, panjang))
			"sungai":
				_air(Vector3(0, y - 0.6, tengah), Vector2(12, panjang))
		# Tebing berpohon di kedua sisi; tebing kanan segmen tepi sungai diberi celah (cabang buntu)
		_tebing(Vector3(-14, y + 4.0, tengah), Vector2(16, panjang))
		if is_equal_approx(z0, 4.0):
			_tebing(Vector3(14, y + 4.0, 1.45), Vector2(16, 5.1))  # z -1,1 .. 4
			_tebing(Vector3(14, y + 4.0, -6.45), Vector2(16, 7.1))  # z -10 .. -2,9
		else:
			_tebing(Vector3(14, y + 4.0, tengah), Vector2(16, panjang))
	for b: Array in BATU:
		_batu_pijakan(Vector3(b[0], 0, b[1]), b[2], b[3])
	# Akar pohon melintang (harus dilompati)
	for z: float in [1.0, -5.5]:
		var akar := Dunia.mesh(self, Dunia.silinder(0.32, 0.32, 7.0, 8), Vector3(0, 0.3, z), Dunia.mat(Color("5a3a22")))
		akar.rotation.z = PI / 2.0
		var bentuk := CylinderShape3D.new()
		bentuk.radius = 0.32
		bentuk.height = 7.0
		var badan := Dunia.badan_statis(self, bentuk, Vector3(0, 0.3, z))
		badan.rotation.z = PI / 2.0
	# Cabang jalan buntu ke timur (pengecoh): berakhir di tepi jurang, tanpa tiang penanda
	var cabang := BoxMesh.new()
	cabang.size = Vector3(9, 3, 1.4)
	Dunia.mesh(self, cabang, Vector3(9.5, -1.5, -2), Dunia.mat(Color.WHITE, Dunia.TEX_TANAH, Vector3(4, 1, 1)))
	var b_cabang := BoxShape3D.new()
	b_cabang.size = cabang.size
	Dunia.badan_statis(self, b_cabang, Vector3(9.5, -1.5, -2))
	_pemicu(Vector3(13.2, 0, -2), 1.5, func() -> void: DialogManager.gelembung(pemain, [_teks("buntu")], "Nggohak", 3.6))
	# Titian kayu sempit di atas jurang
	var titian := BoxMesh.new()
	titian.size = Vector3(0.8, 0.35, 12.4)
	Dunia.mesh(self, titian, Vector3(0, -0.175, -16), Dunia.mat(Color.WHITE, Dunia.TEX_KAYU, Vector3(1, 6, 1)))
	var b_titian := BoxShape3D.new()
	b_titian.size = titian.size
	Dunia.badan_statis(self, b_titian, Vector3(0, -0.175, -16))
	for x: float in [-0.6, 0.6]:
		var tali := Dunia.mesh(self, Dunia.silinder(0.03, 0.03, 12.4, 4), Vector3(x, 0.8, -16), Dunia.mat(Color("c8a868")))
		tali.rotation.x = PI / 2.0
	_pemicu(Vector3(0, 0, -9.2), 1.6, func() -> void: DialogManager.gelembung(pemain, [_teks("titian")], "Nggohak", 3.6))
	# Tanjakan batu ke dataran tinggi
	for data: Array in [[Vector3(2.5, 0, -31.0), 0.8], [Vector3(2.5, 0, -33.4), 1.6]]:
		Dunia.batu_pijakan(self, data[0], data[1], 1.2)
	# Tiang bambu berkain merah menandai jalur utama
	for p: Vector3 in [Vector3(-3.6, 0, 18), Vector3(3.6, 0, 18), Vector3(-3.6, 0, 2), Vector3(-3.6, 0, -8.5),
			Vector3(3.6, 0, -24), Vector3(-3.6, 2.4, -36), Vector3(3.6, 2.4, -42), Vector3(-3.6, 2.4, -56)]:
		_tiang_penanda(p)
	for i in TITIK_CEK.size():
		_bendera_cek(TITIK_CEK[i])
	# Gerbang kampung dan pemicu akhir
	var m_kayu := Dunia.mat(Color.WHITE, Dunia.TEX_KAYU)
	for x: float in [-2.2, 2.2]:
		Dunia.mesh(self, Dunia.silinder(0.15, 0.18, 3.4, 8), Vector3(x, 2.4 + 1.7, -64), m_kayu)
	var palang := BoxMesh.new()
	palang.size = Vector3(5.2, 0.3, 0.3)
	Dunia.mesh(self, palang, Vector3(0, 2.4 + 3.3, -64), m_kayu)
	Dunia.papan(self, Vector3(3.5, 2.4, -62), "Wae Rebo")
	_pemicu(Vector3(0, 2.4, -66), 2.5, _sampai)
	# Rumah-rumah kerucut di kejauhan dan hutan
	for i in 3:
		Dunia.mbaru_niang(self, Vector3(-8.0 + i * 8.0, 2.4, -82), Vector3(0, 2.4, -60), 1.0)
	var acak := RandomNumberGenerator.new()
	acak.seed = 9
	for i in 9:
		var a: float = PI + PI * i / 8.0
		Dunia.bukit(self, Vector3(cos(a) * 70, -6, sin(a) * 70 - 20), acak.randf_range(18, 28), acak.randf_range(18, 34))
	var kopi := PenambahNyawa.new()
	kopi.jenis = "kopi"
	kopi.position = Vector3(-3.0, 0, -7.0)
	add_child(kopi)


func _batu_pijakan(pos: Vector3, puncak: float, retak: bool) -> void:
	var tinggi: float = puncak + 3.0
	var pusat := Vector3(pos.x, puncak - tinggi / 2.0, pos.z)
	var warna: Color = Color("8f8a82") if retak else Color("a29d94")
	var mi := Dunia.mesh(self, Dunia.silinder(0.85, 0.95, tinggi, 10), pusat, Dunia.mat(warna, Dunia.TEX_BATU, Vector3(2, 1, 1)))
	var bentuk := CylinderShape3D.new()
	bentuk.radius = 0.85
	bentuk.height = tinggi
	var badan := Dunia.badan_statis(self, bentuk, pusat)
	if retak:
		# Garis retakan halus di permukaan atas (tanda pengecoh yang adil)
		var m_retak := Dunia.mat(Color("2a2622"))
		for k in 3:
			var garis := BoxMesh.new()
			garis.size = Vector3(0.9 - k * 0.2, 0.02, 0.05)
			var g := Dunia.mesh(mi, garis, Vector3(0.1 * k - 0.1, tinggi / 2.0 + 0.01, 0.15 * k - 0.15), m_retak)
			g.rotation.y = 0.6 + k * 0.9
		badan.set_meta("retak", true)
		_batu_retak.append({"badan": badan, "mesh": mi, "asal": pusat, "waktu": 0.0, "tenggelam": false})


func _tiang_penanda(p: Vector3) -> void:
	Dunia.mesh(self, Dunia.silinder(0.06, 0.07, 1.8, 6), p + Vector3(0, 0.9, 0), Dunia.mat(Color("b8a050")))
	var kain := BoxMesh.new()
	kain.size = Vector3(0.04, 0.3, 0.4)
	Dunia.mesh(self, kain, p + Vector3(0, 1.6, 0.2), Dunia.mat(Gaya.MERAH))


func _bendera_cek(p: Vector3) -> void:
	Dunia.mesh(self, Dunia.silinder(0.07, 0.08, 2.6, 6), p + Vector3(-3.0, 1.3, 0), Dunia.mat(Color.WHITE, Dunia.TEX_KAYU))
	var kain := BoxMesh.new()
	kain.size = Vector3(0.9, 0.55, 0.04)
	Dunia.mesh(self, kain, p + Vector3(-2.5, 2.3, 0), Dunia.mat(Color.WHITE, preload("res://assets/textures/songke_merah.png")))
	_pemicu(p, 3.0, func() -> void:
		if _titik_cek.distance_to(p) > 1.0:
			_titik_cek = p + Vector3(0, 0.3, 0)
			AudioManager.putar_sfx("ambil", 0.1))


func _pemicu(pos: Vector3, jari: float, aksi: Callable) -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = pos
	var c := CollisionShape3D.new()
	var bola := SphereShape3D.new()
	bola.radius = jari
	c.shape = bola
	c.position = Vector3(0, 1, 0)
	area.add_child(c)
	add_child(area)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body is Pemain:
			aksi.call())


func _munculkan_pemain() -> void:
	pemain = ADEGAN_PEMAIN.instantiate()
	add_child(pemain)
	pemain.global_position = TITIK_MUNCUL
	pemain.model.rotation.y = 0.0
	kamera = KameraIkut.new()
	kamera.target = pemain
	add_child(kamera)
	kamera.current = true


# ------------------------------------------------------------------ per frame

func _physics_process(delta: float) -> void:
	if pemain == null or _tiba:
		return
	_jeda_jatuh = maxf(_jeda_jatuh - delta, 0.0)
	var p: Vector3 = pemain.global_position
	var lantai: Object = _lantai_di_bawah(p)
	_perbarui_batu_retak(delta, lantai)
	if p.y < _titik_aman.y - 2.6 and _jeda_jatuh <= 0.0:
		_jatuh()
	elif pemain.is_on_floor() and _pijakan_aman(p):
		_titik_aman = p


func _lantai_di_bawah(p: Vector3) -> Object:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.3, 0), p + Vector3(0, -0.4, 0), Dunia.LAPISAN_DUNIA)
	q.exclude = [pemain.get_rid()]
	var hasil: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	return hasil.get("collider", null)


## Batu retak tenggelam setelah diinjak sebentar, lalu muncul kembali beberapa detik kemudian.
func _perbarui_batu_retak(delta: float, lantai: Object) -> void:
	for b: Dictionary in _batu_retak:
		if b["tenggelam"]:
			continue
		if lantai == b["badan"] and pemain.is_on_floor():
			b["waktu"] = float(b["waktu"]) + delta
			(b["mesh"] as Node3D).position = (b["asal"] as Vector3) + Vector3(randf_range(-0.04, 0.04), 0, randf_range(-0.04, 0.04))
			if float(b["waktu"]) >= DETIK_RETAK:
				_tenggelamkan(b)
		else:
			b["waktu"] = 0.0


func _tenggelamkan(b: Dictionary) -> void:
	b["tenggelam"] = true
	AudioManager.putar_sfx("terkena", 0.2)
	if not _sudah_retak:
		_sudah_retak = true
		DialogManager.gelembung(pemain, [_teks("retak")], "Nggohak", 3.6)
	var badan: StaticBody3D = b["badan"]
	var mi: Node3D = b["mesh"]
	var asal: Vector3 = b["asal"]
	var tw := create_tween().set_parallel()
	tw.tween_property(mi, "position:y", asal.y - 3.5, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_property(badan, "position:y", asal.y - 3.5, 0.6).set_ease(Tween.EASE_IN)
	tw.chain().tween_interval(3.0)
	tw.chain().tween_callback(func() -> void:
		mi.position = asal
		badan.position = asal
		b["waktu"] = 0.0
		b["tenggelam"] = false)


## Titik aman: tanah padat di sekeliling kaki dan bukan batu retak.
func _pijakan_aman(p: Vector3) -> bool:
	var ruang := get_world_3d().direct_space_state
	for geser: Vector3 in [Vector3(0.3, 0, 0), Vector3(-0.3, 0, 0), Vector3(0, 0, 0.3), Vector3(0, 0, -0.3)]:
		var q := PhysicsRayQueryParameters3D.create(p + geser + Vector3(0, 0.5, 0), p + geser + Vector3(0, -0.4, 0), Dunia.LAPISAN_DUNIA)
		q.exclude = [pemain.get_rid()]
		var hasil: Dictionary = ruang.intersect_ray(q)
		if hasil.is_empty() or (hasil["collider"] as Object).has_meta("retak"):
			return false
	return true


func _jatuh() -> void:
	_jeda_jatuh = 0.8
	Efek.percikan(self, pemain.global_position + Vector3(0, 0.6, 0))
	pemain.velocity = Vector3.ZERO
	pemain.global_position = _titik_aman + Vector3(0, 0.2, 0)
	pemain.model.squash(Vector3(1.2, 0.8, 1.2))
	Nyawa.kurangi("jatuh ke sungai/jurang")


func _ulang_dari_titik_cek() -> void:
	pemain.velocity = Vector3.ZERO
	pemain.global_position = _titik_cek + Vector3(0, 0.3, 0)
	_titik_aman = pemain.global_position


func _sampai() -> void:
	if _tiba:
		return
	_tiba = true
	AudioManager.putar_sfx("gong")
	DialogManager.gelembung(pemain, [_teks("tiba")], "Nggohak", 3.6)
	get_tree().create_timer(1.6, false).timeout.connect(func() -> void: Transisi.pindah_scene(ADEGAN_KAMPUNG))
