class_name DuniaPulau
extends RefCounted
## Pembangun dunia Level 3 (Taman Nasional Komodo) yang dapat dipakai ulang di setiap destinasi:
## laut, daratan pasir/sabana, dermaga, kapal wisata, pohon lontar, karang, gedung pelabuhan.
## Semua dari mesh primitif. Permukaan laut di Y_LAUT; deknya kapal di Y_DEK.

const Y_LAUT: float = -0.3
const Y_DEK: float = 0.7
const WARNA_PASIR := Color("e8d8a8")
const WARNA_PASIR_PINK := Color("f0c2bc")
const WARNA_SABANA := Color("b8a860")


static func mat_laut() -> StandardMaterial3D:
	var m := Dunia.mat(Color(0.18, 0.55, 0.72, 0.82))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.metallic_specular = 0.9
	return m


## Permukaan laut (visual) dan dasar laut gelap di kejauhan.
static func laut(induk: Node3D, ukuran: float = 240.0) -> void:
	var permukaan := PlaneMesh.new()
	permukaan.size = Vector2(ukuran, ukuran)
	Dunia.mesh(induk, permukaan, Vector3(0, Y_LAUT, 0), mat_laut())
	var dasar := PlaneMesh.new()
	dasar.size = Vector2(ukuran, ukuran)
	Dunia.mesh(induk, dasar, Vector3(0, -6.0, 0), Dunia.mat(Color("1d4a5c")))


## Dasar laut dangkal yang dapat dipijak (air dangkal, teluk snorkeling).
static func dasar_dangkal(induk: Node3D, pusat: Vector3, jari: float, warna: Color = Color("d8c89a")) -> void:
	Dunia.mesh(induk, Dunia.silinder(jari, jari, 1.0, 40), pusat + Vector3(0, -0.5, 0), Dunia.mat(warna, Dunia.TEX_TANAH, Vector3(6, 6, 1)))
	var bentuk := CylinderShape3D.new()
	bentuk.radius = jari
	bentuk.height = 1.0
	Dunia.badan_statis(induk, bentuk, pusat + Vector3(0, -0.5, 0))


## Daratan bundar (pasir/sabana) yang puncaknya di `pusat.y`, menjorok ke bawah laut.
static func daratan(induk: Node3D, pusat: Vector3, jari: float, warna: Color, tekstur: Texture2D = Dunia.TEX_TANAH) -> StaticBody3D:
	var tinggi: float = pusat.y + 3.0
	var dasar_y: float = pusat.y - tinggi / 2.0
	Dunia.mesh(induk, Dunia.silinder(jari, jari * 1.08, tinggi, 36), Vector3(pusat.x, dasar_y, pusat.z),
			Dunia.mat(warna, tekstur, Vector3(jari / 2.0, jari / 4.0, 1)))
	Dunia.mesh(induk, Dunia.silinder(jari, jari, 0.02, 36), Vector3(pusat.x, pusat.y + 0.005, pusat.z),
			Dunia.mat(warna, tekstur, Vector3(jari / 2.0, jari / 2.0, 1)))
	var bentuk := CylinderShape3D.new()
	bentuk.radius = jari
	bentuk.height = tinggi
	return Dunia.badan_statis(induk, bentuk, Vector3(pusat.x, dasar_y, pusat.z))


## Daratan kotak (kawasan pelabuhan kota).
static func daratan_kotak(induk: Node3D, pusat: Vector3, ukuran: Vector2, warna: Color) -> void:
	var kotak := BoxMesh.new()
	kotak.size = Vector3(ukuran.x, 3.0, ukuran.y)
	Dunia.mesh(induk, kotak, pusat + Vector3(0, -1.5, 0), Dunia.mat(warna, Dunia.TEX_BATU, Vector3(ukuran.x / 3.0, ukuran.y / 3.0, 1)))
	var bentuk := BoxShape3D.new()
	bentuk.size = kotak.size
	Dunia.badan_statis(induk, bentuk, pusat + Vector3(0, -1.5, 0))


## Dermaga kayu lurus dari `a` ke `b` (puncak papan di a.y) dengan tiang-tiang.
static func dermaga(induk: Node3D, a: Vector3, b: Vector3, lebar: float = 2.4) -> void:
	var delta: Vector3 = Vector3(b.x - a.x, 0, b.z - a.z)
	var papan := BoxMesh.new()
	papan.size = Vector3(lebar, 0.2, delta.length())
	var pusat: Vector3 = (a + Vector3(b.x, a.y, b.z)) / 2.0 + Vector3(0, -0.1, 0)
	var rot: float = atan2(-delta.x, -delta.z)
	var mi := Dunia.mesh(induk, papan, pusat, Dunia.mat(Color("a07850"), Dunia.TEX_KAYU, Vector3(2, 8, 1)))
	mi.rotation.y = rot
	var bentuk := BoxShape3D.new()
	bentuk.size = papan.size
	var badan := Dunia.badan_statis(induk, bentuk, pusat)
	badan.rotation.y = rot
	var m_tiang := Dunia.mat(Color("5a3a22"))
	var jumlah: int = maxi(int(delta.length() / 3.0), 1)
	for i in jumlah + 1:
		var t: float = float(i) / jumlah
		var titik: Vector3 = a.lerp(Vector3(b.x, a.y, b.z), t)
		var samping := Vector3(-delta.z, 0, delta.x).normalized() * (lebar / 2.0 - 0.1)
		for s: float in [-1.0, 1.0]:
			Dunia.mesh(induk, Dunia.silinder(0.1, 0.1, 2.4, 6), titik + samping * s + Vector3(0, -1.2, 0), m_tiang)


## Kapal wisata kayu bergaya pinisi: lambung, dek (dapat dipijak, puncak di Y_DEK), kabin, tiang & layar.
## Sumbu panjang kapal = Z lokal (haluan ke -Z).
static func kapal(induk: Node3D, pusat: Vector3, rotasi_y: float, warna_lambung: Color = Color("f1ede4")) -> Node3D:
	var k := Node3D.new()
	k.position = Vector3(pusat.x, Y_LAUT, pusat.z)
	k.rotation.y = rotasi_y
	induk.add_child(k)
	var m_lambung := Dunia.mat(warna_lambung)
	var m_kayu := Dunia.mat(Color.WHITE, Dunia.TEX_KAYU)
	var lambung := BoxMesh.new()
	lambung.size = Vector3(3.0, 1.4, 7.0)
	Dunia.mesh(k, lambung, Vector3(0, 0.3, 0.5), m_lambung)
	var haluan := Dunia.mesh(k, Dunia.silinder(0.0, 2.1, 1.4, 3), Vector3(0, 0.3, -3.6), m_lambung)
	haluan.rotation = Vector3(0, PI / 6.0, 0)
	haluan.scale = Vector3(1.0, 1.0, 1.1)
	var dek := BoxMesh.new()
	dek.size = Vector3(3.0, 0.08, 8.0)
	Dunia.mesh(k, dek, Vector3(0, Y_DEK - Y_LAUT - 0.04, 0.0), m_kayu)
	var bentuk := BoxShape3D.new()
	bentuk.size = Vector3(3.0, 1.4, 8.4)
	Dunia.badan_statis(k, bentuk, Vector3(0, Y_DEK - Y_LAUT - 0.7, 0.0))
	# Kabin di buritan
	var kabin := BoxMesh.new()
	kabin.size = Vector3(2.4, 1.3, 2.4)
	Dunia.mesh(k, kabin, Vector3(0, Y_DEK - Y_LAUT + 0.65, 2.6), m_kayu)
	var atap := BoxMesh.new()
	atap.size = Vector3(2.7, 0.12, 2.8)
	Dunia.mesh(k, atap, Vector3(0, Y_DEK - Y_LAUT + 1.36, 2.6), Dunia.mat(Color("6a4428")))
	var b_kabin := BoxShape3D.new()
	b_kabin.size = kabin.size
	Dunia.badan_statis(k, b_kabin, Vector3(0, Y_DEK - Y_LAUT + 0.65, 2.6))
	# Tiang dan layar
	Dunia.mesh(k, Dunia.silinder(0.07, 0.09, 5.0, 6), Vector3(0, Y_DEK - Y_LAUT + 2.5, -0.8), m_kayu)
	var layar := Dunia.mesh(k, Dunia.silinder(0.0, 1.5, 3.4, 3), Vector3(0, Y_DEK - Y_LAUT + 3.0, -1.2), Dunia.mat(Color("f4ecd8")))
	layar.scale = Vector3(0.05, 1.0, 1.0)
	return k


## Pohon lontar/kelapa: batang miring sedikit dan daun-daun pipih memancar.
static func lontar(induk: Node3D, pos: Vector3, skala: float = 1.0) -> void:
	var tinggi: float = 3.2 * skala
	Dunia.mesh(induk, Dunia.silinder(0.12 * skala, 0.2 * skala, tinggi, 6), pos + Vector3(0, tinggi / 2.0, 0), Dunia.mat(Color("7a5a3a")))
	var m_daun := Dunia.mat(Color("4f8a3c"))
	for i in 7:
		var a: float = TAU * i / 7.0
		var daun := BoxMesh.new()
		daun.size = Vector3(0.35 * skala, 0.04, 1.6 * skala)
		var mi := Dunia.mesh(induk, daun, pos + Vector3(cos(a) * 0.7 * skala, tinggi - 0.1, sin(a) * 0.7 * skala), m_daun)
		mi.rotation = Vector3(0.45, -a + PI / 2.0, 0)
	var bentuk := CylinderShape3D.new()
	bentuk.radius = 0.25 * skala
	bentuk.height = tinggi
	Dunia.badan_statis(induk, bentuk, pos + Vector3(0, tinggi / 2.0, 0))


## Karang warna-warni di dasar laut dangkal (visual; injakan dideteksi oleh skrip pulau).
static func karang(induk: Node3D, pos: Vector3) -> void:
	var warna: Array[Color] = [Color("e0607a"), Color("f0a040"), Color("9a5ad0"), Color("f2e070")]
	for i in 5:
		var a: float = TAU * i / 5.0 + pos.x
		var b := SphereMesh.new()
		b.radius = 0.35
		b.height = 0.5
		b.radial_segments = 8
		b.rings = 4
		Dunia.mesh(induk, b, pos + Vector3(cos(a) * 0.55, 0.15, sin(a) * 0.55), Dunia.mat(warna[i % warna.size()]))
	var cabang := Dunia.mesh(induk, Dunia.silinder(0.04, 0.1, 0.8, 5), pos + Vector3(0, 0.4, 0), Dunia.mat(Color("e86a5a")))
	cabang.rotation.z = 0.3


## Gedung pelabuhan sederhana (kotak + atap pelana).
static func gedung(induk: Node3D, pos: Vector3, ukuran: Vector3, warna: Color) -> void:
	var kotak := BoxMesh.new()
	kotak.size = ukuran
	Dunia.mesh(induk, kotak, pos + Vector3(0, ukuran.y / 2.0, 0), Dunia.mat(warna))
	var atap := Dunia.mesh(induk, Dunia.silinder(0.0, ukuran.x * 0.72, ukuran.z, 3), pos + Vector3(0, ukuran.y + 0.5, 0),
			Dunia.mat(Color("8a3a2a")))
	atap.rotation = Vector3(PI / 2.0, 0, PI / 2.0)
	atap.scale = Vector3(1.0, 1.0, 0.45)
	var bentuk := BoxShape3D.new()
	bentuk.size = ukuran
	Dunia.badan_statis(induk, bentuk, pos + Vector3(0, ukuran.y / 2.0, 0))
