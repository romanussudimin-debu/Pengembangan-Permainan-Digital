class_name DuniaLingko
extends RefCounted
## Pembangun dunia Level 2 (Lingko Lodok): pematang melingkar & menjari, lodok dengan haju teno,
## petak sawah berbentuk juring (jaring laba-laba), pondok, wae teku, dan bukit batu.
## Semua dari mesh primitif + tekstur buatan sendiri (lihat tools/generate_textures.py).
## Sudut memakai konvensi posisi = (cos a, 0, sin a) * r: a = -90° utara (-Z), 0° timur (+X),
## 90° selatan (+Z, arah kamera), 180° barat. Sudut yang bertambah = searah jarum jam dilihat dari atas.

const TEX_SAWAH: Texture2D = preload("res://assets/textures/sawah.png")
const TINGGI_PEMATANG: float = 0.7  ## puncak pematang & lodok (permukaan tanah = 0)
const TINGGI_AIR: float = 0.36  ## permukaan petak sawah (visual saja; di bawahnya lumpur)
const LEBAR_PEMATANG: float = 0.9


static func _mat_pematang() -> StandardMaterial3D:
	return Dunia.mat(Color("8a6a44"), Dunia.TEX_TANAH)


static func _mat_rumput_pematang() -> StandardMaterial3D:
	return Dunia.mat(Color("a4b06a"), Dunia.TEX_RUMPUT, Vector3(0.5, 0.5, 1))


## Satu ruas pematang (kotak tanah + rumput di atasnya) dengan collision.
static func _ruas(induk: Node3D, pusat: Vector3, panjang: float, rotasi_y: float, m_tanah: Material, m_rumput: Material) -> void:
	var kotak := BoxMesh.new()
	kotak.size = Vector3(panjang, TINGGI_PEMATANG, LEBAR_PEMATANG)
	var mi := Dunia.mesh(induk, kotak, pusat + Vector3(0, TINGGI_PEMATANG / 2.0, 0), m_tanah)
	mi.rotation.y = rotasi_y
	var atas := BoxMesh.new()
	atas.size = Vector3(panjang, 0.04, LEBAR_PEMATANG + 0.02)
	var mr := Dunia.mesh(induk, atas, pusat + Vector3(0, TINGGI_PEMATANG + 0.01, 0), m_rumput)
	mr.rotation.y = rotasi_y
	var bentuk := BoxShape3D.new()
	bentuk.size = kotak.size
	var b := Dunia.badan_statis(induk, bentuk, pusat + Vector3(0, TINGGI_PEMATANG / 2.0, 0))
	b.rotation.y = rotasi_y


## Pematang melingkar berjari-jari `jari`. `celah` = daftar sudut (derajat) tempat pematang putus
## selebar `lebar_celah` meter (pemain harus melompat).
static func pematang_lingkar(induk: Node3D, jari: float, celah: Array = [], lebar_celah: float = 1.5) -> void:
	var m_tanah := _mat_pematang()
	var m_rumput := _mat_rumput_pematang()
	var jumlah: int = maxi(int(ceil(TAU * jari / 0.9)), 12)
	var panjang: float = TAU * jari / jumlah * 1.08
	for i in jumlah:
		var a: float = TAU * i / jumlah
		var putus: bool = false
		for c: float in celah:
			if absf(wrapf(a - deg_to_rad(c), -PI, PI)) * jari < lebar_celah / 2.0:
				putus = true
		if putus:
			continue
		_ruas(induk, Vector3(cos(a), 0, sin(a)) * jari, panjang, -a - PI / 2.0, m_tanah, m_rumput)


## Pematang lurus menjari dari lodok ke tepi pada sudut `sudut` (derajat).
## `potongan` = daftar [r_awal, r_akhir]; jarak di antara potongan adalah bagian yang putus.
static func pematang_jari(induk: Node3D, sudut: float, potongan: Array) -> void:
	var m_tanah := _mat_pematang()
	var m_rumput := _mat_rumput_pematang()
	var a: float = deg_to_rad(sudut)
	var arah := Vector3(cos(a), 0, sin(a))
	for p: Array in potongan:
		var r0: float = p[0]
		var r1: float = p[1]
		_ruas(induk, arah * (r0 + r1) / 2.0, r1 - r0, -a, m_tanah, m_rumput)


## Mesh juring (cincin terpotong) datar pada ketinggian `y`, dari sudut a0 ke a1 (radian).
static func mesh_juring(r0: float, r1: float, a0: float, a1: float, y: float, skala_uv: float = 0.25) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var langkah: int = maxi(int(ceil(absf(a1 - a0) / deg_to_rad(4.0))), 2)
	for i in langkah:
		var t0: float = lerpf(a0, a1, float(i) / langkah)
		var t1: float = lerpf(a0, a1, float(i + 1) / langkah)
		var titik: Array[Vector3] = [
			Vector3(cos(t0) * r0, y, sin(t0) * r0), Vector3(cos(t0) * r1, y, sin(t0) * r1),
			Vector3(cos(t1) * r1, y, sin(t1) * r1), Vector3(cos(t1) * r0, y, sin(t1) * r0),
		]
		for indeks: int in [0, 1, 2, 0, 2, 3]:  # urutan searah jarum jam dilihat dari atas (sisi depan Godot)
			var v: Vector3 = titik[indeks]
			st.set_uv(Vector2(v.x, v.z) * skala_uv)
			st.add_vertex(v)
	return st.commit()


## Petak sawah (seluruh cincin lingko) pada permukaan air; materialnya diganti sesuai tahap.
static func petak_sawah(induk: Node3D, r0: float, r1: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh_juring(r0, r1, 0.0, TAU, TINGGI_AIR)
	mi.material_override = mat_kering()
	induk.add_child(mi)
	return mi


static func mat_kering() -> StandardMaterial3D:
	return Dunia.mat(Color("a07e56"), Dunia.TEX_TANAH, Vector3(1, 1, 1))


static func mat_berair() -> StandardMaterial3D:
	var m := Dunia.mat(Color("8fb0b4"), Dunia.TEX_TANAH, Vector3(1, 1, 1))
	m.roughness = 0.25
	m.metallic_specular = 0.8
	return m


## Juring-juring hasil pembagian (warna hijau padi berbeda tiap keluarga) dan garis moso.
## `batas` = daftar sudut (radian) tempat moso ditancapkan, urut searah jarum jam.
static func juring_terbagi(induk: Node3D, r0: float, r1: float, batas: Array) -> Node3D:
	var akar := Node3D.new()
	akar.name = "JuringTerbagi"
	induk.add_child(akar)
	var hijau: Array[Color] = [Color("c9d46a"), Color("8fbf5a"), Color("a9c86a"), Color("6fae55"), Color("b8cf72"), Color("7fb85e"),
		Color("d2d77a"), Color("9cc462")]
	for i in batas.size():
		var a0: float = batas[i]
		var a1: float = batas[i + 1] if i + 1 < batas.size() else batas[0] + TAU
		var mi := MeshInstance3D.new()
		mi.mesh = mesh_juring(r0, r1, a0, a1, TINGGI_AIR + 0.01)
		mi.material_override = Dunia.mat(hijau[i % hijau.size()], TEX_SAWAH, Vector3.ONE)
		akar.add_child(mi)
	var m_moso := Dunia.mat(Color("5a4026"))
	for a: float in batas:
		var garis := BoxMesh.new()
		garis.size = Vector3(r1 - r0, 0.08, 0.16)
		var g := Dunia.mesh(akar, garis, Vector3(cos(a), 0, sin(a)) * (r0 + r1) / 2.0 + Vector3(0, TINGGI_AIR + 0.04, 0), m_moso)
		g.rotation.y = -a
	return akar


## Lodok: panggung tanah bundar di pusat lingko dengan haju teno (kayu teno) di tengahnya.
static func lodok(induk: Node3D, jari: float) -> void:
	Dunia.mesh(induk, Dunia.silinder(jari, jari + 0.1, TINGGI_PEMATANG, 24), Vector3(0, TINGGI_PEMATANG / 2.0, 0), _mat_pematang())
	Dunia.mesh(induk, Dunia.silinder(jari, jari, 0.04, 24), Vector3(0, TINGGI_PEMATANG + 0.01, 0), _mat_rumput_pematang())
	var bentuk := CylinderShape3D.new()
	bentuk.radius = jari
	bentuk.height = TINGGI_PEMATANG
	Dunia.badan_statis(induk, bentuk, Vector3(0, TINGGI_PEMATANG / 2.0, 0))
	# Haju teno: batang kayu tegak dengan sedikit daun di puncak
	var y0: float = TINGGI_PEMATANG
	Dunia.mesh(induk, Dunia.silinder(0.1, 0.16, 2.4, 8), Vector3(0, y0 + 1.2, 0), Dunia.mat(Color.WHITE, Dunia.TEX_KAYU))
	var daun := SphereMesh.new()
	daun.radius = 0.55
	daun.height = 0.8
	daun.radial_segments = 8
	daun.rings = 4
	Dunia.mesh(induk, daun, Vector3(0, y0 + 2.6, 0), Dunia.mat(Color("3d7a3e")))
	var batang := CylinderShape3D.new()
	batang.radius = 0.2
	batang.height = 2.4
	Dunia.badan_statis(induk, batang, Vector3(0, y0 + 1.2, 0))


## Jalan tanah landai dari permukaan tanah naik ke puncak pematang.
static func tanjakan(induk: Node3D, bawah: Vector3, atas: Vector3, lebar: float = 1.6) -> void:
	var delta: Vector3 = atas - bawah
	var datar := Vector2(delta.x, delta.z)
	var panjang: float = Vector3(delta.x, delta.y, delta.z).length()
	var b := Node3D.new()
	b.position = (bawah + atas) / 2.0
	induk.add_child(b)
	b.rotation.y = atan2(-delta.x, -delta.z)
	var kotak := BoxMesh.new()
	kotak.size = Vector3(lebar, 0.3, panjang)
	var mi := Dunia.mesh(b, kotak, Vector3(0, -0.15, 0), Dunia.mat(Color("9a7a52"), Dunia.TEX_TANAH))
	mi.rotation.x = atan2(delta.y, datar.length())
	var bentuk := BoxShape3D.new()
	bentuk.size = kotak.size
	var badan := Dunia.badan_statis(b, bentuk, Vector3(0, -0.15, 0))
	badan.rotation.x = mi.rotation.x


## Jalan masuk tanah (datar, hanya visual) dari titik a ke titik b.
static func jalan_tanah(induk: Node3D, a: Vector3, b: Vector3, lebar: float = 2.0) -> void:
	var delta: Vector3 = b - a
	var kotak := BoxMesh.new()
	kotak.size = Vector3(lebar, 0.02, delta.length())
	var mi := Dunia.mesh(induk, kotak, (a + b) / 2.0 + Vector3(0, 0.01, 0), Dunia.mat(Color("b08a5c"), Dunia.TEX_TANAH, Vector3(1, 4, 1)))
	mi.rotation.y = atan2(-delta.x, -delta.z)


## Pondok berteduh di atas panggung kayu; atap disembunyikan saat pemain di bawahnya.
static func pondok(induk: Node3D, posisi: Vector3, rotasi_y: float) -> Node3D:
	var g := Node3D.new()
	g.position = posisi
	g.rotation.y = rotasi_y
	induk.add_child(g)
	var m_kayu := Dunia.mat(Color.WHITE, Dunia.TEX_KAYU)
	var lantai := BoxMesh.new()
	lantai.size = Vector3(2.8, TINGGI_PEMATANG, 2.8)
	Dunia.mesh(g, lantai, Vector3(0, TINGGI_PEMATANG / 2.0, 0), m_kayu)
	var bentuk := BoxShape3D.new()
	bentuk.size = lantai.size
	Dunia.badan_statis(g, bentuk, Vector3(0, TINGGI_PEMATANG / 2.0, 0))
	for x: float in [-1.2, 1.2]:
		for z: float in [-1.2, 1.2]:
			Dunia.mesh(g, Dunia.silinder(0.07, 0.07, 3.0, 6), Vector3(x, TINGGI_PEMATANG + 1.5, z), m_kayu)
	var atap := Node3D.new()
	g.add_child(atap)
	var kerucut := Dunia.mesh(atap, Dunia.silinder(0.05, 2.3, 1.5, 4), Vector3(0, TINGGI_PEMATANG + 3.6, 0),
			Dunia.mat(Color.WHITE, Dunia.TEX_IJUK, Vector3(3, 2, 1)))
	kerucut.rotation.y = PI / 4.0
	var area := PemicuAtap.new()
	area.atap = atap
	var c := CollisionShape3D.new()
	var silinder := CylinderShape3D.new()
	silinder.radius = 2.6
	silinder.height = 3.0
	c.shape = silinder
	c.position = Vector3(0, TINGGI_PEMATANG + 1.5, 0)
	area.add_child(c)
	g.add_child(area)
	return g


## Wae teku: kolam mata air berbatu dengan pancuran bambu. Mengembalikan mesh saluran air
## (dari mata air ke lingko) agar warnanya bisa diubah saat air sudah dialirkan.
static func wae_teku(induk: Node3D, posisi: Vector3, ujung_saluran: Vector3) -> MeshInstance3D:
	var g := Node3D.new()
	g.position = posisi
	induk.add_child(g)
	var air := Dunia.mat(Color("5fa8d3"))
	air.roughness = 0.15
	Dunia.mesh(g, Dunia.silinder(1.5, 1.5, 0.06, 20), Vector3(0, 0.08, 0), air)
	for i in 16:
		var a: float = TAU * i / 16.0
		var batu := SphereMesh.new()
		batu.radius = 0.32
		batu.height = 0.42
		Dunia.mesh(g, batu, Vector3(cos(a) * 1.75, 0.14, sin(a) * 1.75), Dunia.mat(Color("77736b"), Dunia.TEX_BATU))
	var bentuk := CylinderShape3D.new()
	bentuk.radius = 1.9
	bentuk.height = 0.6
	Dunia.badan_statis(g, bentuk, Vector3(0, 0.3, 0))
	# Batu besar sumber air dan pancuran bambu
	var batu_besar := SphereMesh.new()
	batu_besar.radius = 1.0
	batu_besar.height = 1.6
	Dunia.mesh(g, batu_besar, Vector3(0, 0.6, -2.4), Dunia.mat(Color("6e6a62"), Dunia.TEX_BATU))
	var bambu := Dunia.mesh(g, Dunia.silinder(0.06, 0.06, 1.4, 8), Vector3(0, 0.95, -1.5), Dunia.mat(Color("b8a050")))
	bambu.rotation.x = deg_to_rad(70.0)
	var pancur := Dunia.mesh(g, Dunia.silinder(0.03, 0.05, 0.75, 6), Vector3(0, 0.55, -0.85), air)
	pancur.rotation.x = 0.0
	# Saluran tanah dari kolam menuju lingko
	var awal: Vector3 = posisi + (ujung_saluran - posisi).normalized() * 1.9
	var delta: Vector3 = ujung_saluran - awal
	var parit := BoxMesh.new()
	parit.size = Vector3(0.5, 0.06, delta.length())
	var saluran := Dunia.mesh(induk, parit, (awal + ujung_saluran) / 2.0 + Vector3(0, 0.04, 0), Dunia.mat(Color("6a4e30")))
	saluran.rotation.y = atan2(-delta.x, -delta.z)
	return saluran
