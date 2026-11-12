class_name Dunia
extends RefCounted
## Kumpulan fungsi pembangun dunia 3D low-poly (lingkungan, Mbaru Niang, compang, dst).
## Semua objek dibangun dari mesh primitif + tekstur buatan sendiri.

const TEX_IJUK: Texture2D = preload("res://assets/textures/ijuk.png")
const TEX_RUMPUT: Texture2D = preload("res://assets/textures/rumput.png")
const TEX_TANAH: Texture2D = preload("res://assets/textures/tanah.png")
const TEX_BATU: Texture2D = preload("res://assets/textures/batu.png")
const TEX_KAYU: Texture2D = preload("res://assets/textures/kayu.png")
const TEX_KULIT: Texture2D = preload("res://assets/textures/kulit_kerbau.png")

const LAPISAN_DUNIA: int = 1


static func mat(warna: Color, tekstur: Texture2D = null, skala_uv: Vector3 = Vector3.ONE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = warna
	m.roughness = 0.95
	if tekstur:
		m.albedo_texture = tekstur
		m.uv1_scale = skala_uv
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	return m


static func mesh(induk: Node3D, m: Mesh, posisi: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = posisi
	mi.material_override = material
	induk.add_child(mi)
	return mi


static func badan_statis(induk: Node3D, bentuk: Shape3D, posisi: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = LAPISAN_DUNIA
	b.collision_mask = 0
	b.position = posisi
	var c := CollisionShape3D.new()
	c.shape = bentuk
	b.add_child(c)
	induk.add_child(b)
	return b


static func silinder(r_atas: float, r_bawah: float, tinggi: float, segmen: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_atas
	c.bottom_radius = r_bawah
	c.height = tinggi
	c.radial_segments = segmen
	return c


## Langit cerah dan cahaya matahari dengan bayangan (tanpa kabut agar warna tetap jernih).
static func lingkungan(induk: Node3D) -> void:
	var env := Environment.new()
	var langit := Sky.new()
	var mat_langit := ProceduralSkyMaterial.new()
	mat_langit.sky_top_color = Color("6f9cc4")
	mat_langit.sky_horizon_color = Color("cfdde0")
	mat_langit.ground_horizon_color = Color("a8b8a0")
	mat_langit.ground_bottom_color = Color("4d6a48")
	langit.sky_material = mat_langit
	env.background_mode = Environment.BG_SKY
	env.sky = langit
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	induk.add_child(we)

	var matahari := DirectionalLight3D.new()
	matahari.rotation_degrees = Vector3(-50, -35, 0)
	matahari.light_energy = 1.1
	matahari.light_color = Color("fff1d8")
	matahari.shadow_enabled = true
	matahari.directional_shadow_max_distance = 80.0
	induk.add_child(matahari)


## Tanah datar berumput dengan collision.
static func tanah(induk: Node3D, ukuran: float, posisi: Vector3 = Vector3.ZERO) -> void:
	var kotak := BoxMesh.new()
	kotak.size = Vector3(ukuran, 1.0, ukuran)
	mesh(induk, kotak, posisi + Vector3(0, -0.5, 0), mat(Color.WHITE, TEX_RUMPUT, Vector3(ukuran / 2.0, ukuran / 2.0, 1)))
	var bentuk := BoxShape3D.new()
	bentuk.size = Vector3(ukuran, 1.0, ukuran)
	badan_statis(induk, bentuk, posisi + Vector3(0, -0.5, 0))


## Dinding tak terlihat di tepi dunia.
static func batas_dunia(induk: Node3D, setengah: float) -> void:
	for data: Array in [[Vector3(setengah, 2, 0), Vector3(1, 4, setengah * 2)], [Vector3(-setengah, 2, 0), Vector3(1, 4, setengah * 2)],
			[Vector3(0, 2, setengah), Vector3(setengah * 2, 4, 1)], [Vector3(0, 2, -setengah), Vector3(setengah * 2, 4, 1)]]:
		var bentuk := BoxShape3D.new()
		bentuk.size = data[1]
		badan_statis(induk, bentuk, data[0])


## Mbaru Niang: rumah kerucut beratap ijuk, 5 tingkat, di atas tiang (panggung).
## `menghadap` adalah titik yang dituju pintu (biasanya compang di tengah kampung).
## Bila `bisa_dimasuki`, dinding collision berbentuk cincin dengan celah pintu dan bagian dalam
## (lantai, tungku, tikar) dibuat; atap disembunyikan saat pemain berada di dalam (tampilan potong).
static func mbaru_niang(induk: Node3D, posisi: Vector3, menghadap: Vector3, skala: float = 1.0, bisa_dimasuki: bool = false) -> Node3D:
	var rumah := Node3D.new()
	rumah.position = posisi
	induk.add_child(rumah)
	var arah := menghadap - posisi
	rumah.rotation.y = atan2(-arah.x, -arah.z)  # sisi -Z menghadap titik tujuan
	var r: float = 3.6 * skala
	var t: float = 8.0 * skala
	var m_kayu := mat(Color.WHITE, TEX_KAYU)
	# Tiang panggung
	for i in 8:
		var a: float = TAU * i / 8.0
		mesh(rumah, silinder(0.12, 0.12, 0.8, 6), Vector3(cos(a) * r * 0.8, 0.4, sin(a) * r * 0.8), m_kayu)
	# Atap (dikelompokkan agar bisa disembunyikan saat pemain di dalam)
	var atap := Node3D.new()
	atap.name = "Atap"
	rumah.add_child(atap)
	mesh(atap, silinder(0.08, r, t, 20), Vector3(0, 0.6 + t / 2.0, 0), mat(Color.WHITE, TEX_IJUK, Vector3(6, 3, 1)))
	# Penanda 5 tingkat (lutur, lobo, lentar, lempa rae, hekang kode)
	var m_garis := mat(Color("4a3424"))
	for k in range(1, 5):
		var tinggi_garis: float = 0.6 + t * k / 5.0
		var jari: float = r * (1.0 - k / 5.0) + 0.03
		var cincin := TorusMesh.new()
		cincin.inner_radius = jari - 0.05
		cincin.outer_radius = jari + 0.05
		cincin.rings = 24
		cincin.ring_segments = 4
		mesh(atap, cincin, Vector3(0, tinggi_garis, 0), m_garis)
	mesh(atap, silinder(0.05, 0.15, 0.7 * skala, 6), Vector3(0, 0.6 + t + 0.3, 0), m_kayu)
	var pintu := BoxMesh.new()
	pintu.size = Vector3(0.9, 1.5, 0.2) * skala
	mesh(atap, pintu, Vector3(0, 1.4 * skala, -r * 0.82), mat(Color("1b1414")))
	var tangga := BoxMesh.new()
	tangga.size = Vector3(1.0, 0.15, 0.8) * skala
	mesh(rumah, tangga, Vector3(0, 0.08, -r * 0.95), m_kayu)
	if bisa_dimasuki:
		_dinding_bercelah(rumah, r * 0.85, t)
		_isi_rumah(rumah, r)
		_pemicu_atap(rumah, atap, r * 0.8)
	else:
		var bentuk := CylinderShape3D.new()
		bentuk.radius = r * 0.85
		bentuk.height = t
		badan_statis(rumah, bentuk, Vector3(0, t / 2.0, 0))
	return rumah


## Dinding collision melingkar dari segmen-segmen kotak, dengan celah pintu di sisi -Z.
static func _dinding_bercelah(rumah: Node3D, jari: float, tinggi: float) -> void:
	var jumlah: int = 18
	var panjang: float = TAU * jari / jumlah * 1.15
	for i in jumlah:
		var a: float = TAU * i / jumlah
		if absf(wrapf(a + PI / 2.0, -PI, PI)) < deg_to_rad(25.0):
			continue  # celah pintu (arah -Z lokal)
		var bentuk := BoxShape3D.new()
		bentuk.size = Vector3(panjang, tinggi, 0.3)
		var badan := badan_statis(rumah, bentuk, Vector3(cos(a) * jari, tinggi / 2.0, sin(a) * jari))
		badan.rotation.y = -a - PI / 2.0  # sumbu X kotak menyinggung lingkaran


## Bagian dalam rumah (lutur): lantai kayu, tungku api di tengah, tikar.
static func _isi_rumah(rumah: Node3D, r: float) -> void:
	mesh(rumah, silinder(r * 0.84, r * 0.84, 0.06, 24), Vector3(0, 0.03, 0), mat(Color.WHITE, TEX_KAYU, Vector3(4, 4, 1)))
	var m_batu := mat(Color("6e6a62"), TEX_BATU)
	for i in 3:
		var a: float = TAU * i / 3.0
		var batu := SphereMesh.new()
		batu.radius = 0.16
		batu.height = 0.22
		mesh(rumah, batu, Vector3(cos(a) * 0.3, 0.12, sin(a) * 0.3 - 0.2), m_batu)
	var api := StandardMaterial3D.new()
	api.albedo_color = Color("ff9a3c")
	api.emission_enabled = true
	api.emission = Color("ff7a1c")
	api.emission_energy_multiplier = 2.0
	mesh(rumah, silinder(0.0, 0.16, 0.35, 8), Vector3(0, 0.25, -0.2), api)
	var cahaya := OmniLight3D.new()
	cahaya.light_color = Color("ffb057")
	cahaya.light_energy = 1.4
	cahaya.omni_range = r
	cahaya.position = Vector3(0, 0.8, -0.2)
	rumah.add_child(cahaya)
	var tikar := BoxMesh.new()
	tikar.size = Vector3(1.6, 0.02, 1.0)
	mesh(rumah, tikar, Vector3(0, 0.07, r * 0.4), mat(Color("c8a868")))


## Area di dalam rumah yang menyembunyikan atap saat pemain masuk.
static func _pemicu_atap(rumah: Node3D, atap: Node3D, jari: float) -> void:
	var area := PemicuAtap.new()
	area.atap = atap
	var bentuk := CylinderShape3D.new()
	bentuk.radius = jari
	bentuk.height = 3.0
	var c := CollisionShape3D.new()
	c.shape = bentuk
	c.position = Vector3(0, 1.5, 0)
	area.add_child(c)
	rumah.add_child(area)


## Alat tenun sederhana: rangka kayu rendah dengan kain songke yang sedang ditenun.
static func alat_tenun(induk: Node3D, posisi: Vector3, rotasi_y: float, tekstur: Texture2D) -> void:
	var g := Node3D.new()
	g.position = posisi
	g.rotation.y = rotasi_y
	induk.add_child(g)
	var m_kayu := mat(Color.WHITE, TEX_KAYU)
	for x: float in [-0.6, 0.6]:
		for z: float in [-0.5, 0.5]:
			mesh(g, silinder(0.04, 0.04, 0.6, 6), Vector3(x, 0.3, z), m_kayu)
	for z: float in [-0.5, 0.5]:
		var balok := BoxMesh.new()
		balok.size = Vector3(1.3, 0.06, 0.06)
		mesh(g, balok, Vector3(0, 0.6, z), m_kayu)
	var kain := BoxMesh.new()
	kain.size = Vector3(1.0, 0.02, 0.9)
	var mi := mesh(g, kain, Vector3(0, 0.62, 0), mat(Color.WHITE, tekstur, Vector3(2, 2, 1)))
	mi.rotation.x = -0.15


## Kain songke yang dijemur pada rangka kayu (penanda rumah).
static func jemuran_songke(induk: Node3D, posisi: Vector3, rotasi_y: float, tekstur: Texture2D) -> void:
	var g := Node3D.new()
	g.position = posisi
	g.rotation.y = rotasi_y
	induk.add_child(g)
	var m_kayu := mat(Color.WHITE, TEX_KAYU)
	for x: float in [-0.9, 0.9]:
		mesh(g, silinder(0.05, 0.05, 1.8, 6), Vector3(x, 0.9, 0), m_kayu)
	var balok := BoxMesh.new()
	balok.size = Vector3(2.0, 0.08, 0.08)
	mesh(g, balok, Vector3(0, 1.75, 0), m_kayu)
	var kain := BoxMesh.new()
	kain.size = Vector3(1.5, 1.1, 0.03)
	mesh(g, kain, Vector3(0, 1.15, 0), mat(Color.WHITE, tekstur, Vector3(2, 2, 1)))


## Tumpukan kayu bakar (penanda rumah).
static func kayu_bakar(induk: Node3D, posisi: Vector3, rotasi_y: float) -> void:
	var g := Node3D.new()
	g.position = posisi
	g.rotation.y = rotasi_y
	induk.add_child(g)
	var m_kayu := mat(Color("6a4428"))
	var baris: Array = [[-0.3, 0.12], [0.0, 0.12], [0.3, 0.12], [-0.15, 0.36], [0.15, 0.36], [0.0, 0.6]]
	for posisi_kayu: Array in baris:
		var batang := mesh(g, silinder(0.12, 0.12, 1.2, 8), Vector3(posisi_kayu[0], posisi_kayu[1], 0), m_kayu)
		batang.rotation.x = PI / 2.0


## Compang: altar batu berundak di tengah kampung (natas).
static func compang(induk: Node3D, posisi: Vector3) -> Node3D:
	var c := Node3D.new()
	c.position = posisi
	induk.add_child(c)
	var m_batu := mat(Color.WHITE, TEX_BATU, Vector3(3, 1, 1))
	mesh(c, silinder(2.4, 2.7, 0.6, 18), Vector3(0, 0.3, 0), m_batu)
	mesh(c, silinder(1.6, 1.9, 0.5, 16), Vector3(0, 0.85, 0), m_batu)
	# Batu tegak di tengah
	var batu := SphereMesh.new()
	batu.radius = 0.5
	batu.height = 1.3
	mesh(c, batu, Vector3(0, 1.5, 0), mat(Color("8a857c"), TEX_BATU))
	# Batu-batu kecil mengelilingi
	for i in 14:
		var a: float = TAU * i / 14.0
		var b := SphereMesh.new()
		b.radius = 0.3
		b.height = 0.4
		mesh(c, b, Vector3(cos(a) * 2.6, 0.55, sin(a) * 2.6), mat(Color("77736b"), TEX_BATU))
	var bentuk := CylinderShape3D.new()
	bentuk.radius = 2.7
	bentuk.height = 2.0
	badan_statis(c, bentuk, Vector3(0, 1.0, 0))
	return c


## Batu pijakan (platform) untuk menjangkau kartu budaya.
static func batu_pijakan(induk: Node3D, posisi: Vector3, tinggi: float, jari: float = 1.1) -> void:
	mesh(induk, silinder(jari, jari * 1.15, tinggi, 10), posisi + Vector3(0, tinggi / 2.0, 0), mat(Color.WHITE, TEX_BATU, Vector3(2, 1, 1)))
	var bentuk := CylinderShape3D.new()
	bentuk.radius = jari
	bentuk.height = tinggi
	badan_statis(induk, bentuk, posisi + Vector3(0, tinggi / 2.0, 0))


static func pohon(induk: Node3D, posisi: Vector3, skala: float = 1.0) -> void:
	mesh(induk, silinder(0.15 * skala, 0.25 * skala, 2.2 * skala, 6), posisi + Vector3(0, 1.1 * skala, 0), mat(Color("5a3a22")))
	var daun := SphereMesh.new()
	daun.radius = 1.4 * skala
	daun.height = 2.4 * skala
	daun.radial_segments = 8
	daun.rings = 4
	mesh(induk, daun, posisi + Vector3(0, 3.0 * skala, 0), mat(Color("2f6b3a")))
	var bentuk := CylinderShape3D.new()
	bentuk.radius = 0.3 * skala
	bentuk.height = 2.2 * skala
	badan_statis(induk, bentuk, posisi + Vector3(0, 1.1 * skala, 0))


## Bukit di kejauhan (tanpa collision).
static func bukit(induk: Node3D, posisi: Vector3, jari: float, tinggi: float) -> void:
	var b := SphereMesh.new()
	b.radius = jari
	b.height = tinggi * 2.0
	b.radial_segments = 12
	b.rings = 6
	mesh(induk, b, posisi, mat(Color("3f7048")))


## Gong tergantung pada rangka kayu dan gendang di sampingnya.
static func gong_gendang(induk: Node3D, posisi: Vector3) -> void:
	var g := Node3D.new()
	g.position = posisi
	induk.add_child(g)
	var m_kayu := mat(Color.WHITE, TEX_KAYU)
	for x: float in [-0.8, 0.8]:
		mesh(g, silinder(0.07, 0.07, 1.8, 6), Vector3(x, 0.9, 0), m_kayu)
	var balok := BoxMesh.new()
	balok.size = Vector3(1.9, 0.12, 0.12)
	mesh(g, balok, Vector3(0, 1.8, 0), m_kayu)
	var gong := mesh(g, silinder(0.45, 0.45, 0.08, 20), Vector3(0, 1.2, 0), mat(Color("b8892c")))
	gong.rotation.x = PI / 2.0
	var benjol := mesh(g, silinder(0.12, 0.15, 0.08, 12), Vector3(0, 1.2, -0.06), mat(Color("d4a640")))
	benjol.rotation.x = PI / 2.0
	var gendang := mesh(g, silinder(0.3, 0.25, 0.9, 14), Vector3(1.5, 0.45, 0), m_kayu)
	gendang.rotation.z = 0.2
	mesh(g, silinder(0.31, 0.31, 0.03, 14), Vector3(1.59, 0.9, 0), mat(Color.WHITE, TEX_KULIT))
	var bentuk := BoxShape3D.new()
	bentuk.size = Vector3(2.4, 1.8, 0.6)
	badan_statis(g, bentuk, Vector3(0.3, 0.9, 0))


## Papan penunjuk dengan tulisan 3D.
static func papan(induk: Node3D, posisi: Vector3, teks: String) -> void:
	var m_kayu := mat(Color.WHITE, TEX_KAYU)
	mesh(induk, silinder(0.08, 0.08, 1.6, 6), posisi + Vector3(0, 0.8, 0), m_kayu)
	var p := BoxMesh.new()
	p.size = Vector3(1.8, 0.6, 0.1)
	mesh(induk, p, posisi + Vector3(0, 1.5, 0), m_kayu)
	var l := Label3D.new()
	l.text = teks
	l.font_size = 48
	l.pixel_size = 0.006
	l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = posisi + Vector3(0, 1.55, 0.1)
	induk.add_child(l)


## Lingkaran arena caci dari tanah, dikelilingi batu.
static func arena(induk: Node3D, posisi: Vector3, jari: float) -> void:
	mesh(induk, silinder(jari, jari, 0.06, 32), posisi + Vector3(0, 0.03, 0), mat(Color.WHITE, TEX_TANAH, Vector3(6, 6, 1)))
	for i in 20:
		var a: float = TAU * i / 20.0
		var b := SphereMesh.new()
		b.radius = 0.35
		b.height = 0.45
		mesh(induk, b, posisi + Vector3(cos(a) * (jari + 0.4), 0.15, sin(a) * (jari + 0.4)), mat(Color("77736b"), TEX_BATU))


## Label nama mengambang di atas karakter.
static func label_nama(induk: Node3D, teks: String, tinggi: float = 2.3) -> Label3D:
	var l := Label3D.new()
	l.text = teks
	l.font_size = 40
	l.pixel_size = 0.006
	l.outline_size = 10
	l.modulate = Color("e8b430")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	l.position = Vector3(0, tinggi, 0)
	induk.add_child(l)
	return l
