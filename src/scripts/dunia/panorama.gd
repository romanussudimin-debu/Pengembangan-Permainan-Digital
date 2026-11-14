class_name Panorama
extends RefCounted
## Panorama Manggarai untuk opening dan menu utama: semua tema game dalam satu dunia visual.
##   - Kampung Wae Rebo (7 Mbaru Niang, compang, penari Penti, pemain caci) di pusat
##   - Lingko lodok (sawah jaring laba-laba) di barat
##   - Pantai, komodo, dan lontar di timur
##   - Laut Taman Nasional Komodo dengan kapal pinisi dan pulau-pulau
## Hanya visual (tanpa pemain); kamera digerakkan oleh skrip opening/menu lewat daftar SHOT.

const PUSAT_LINGKO := Vector3(-46, 0, 4)
const PUSAT_KOMODO := Vector3(31, 0, 3)

## Bidikan kamera: posisi awal/akhir, titik pandang awal/akhir, judul & keterangan, durasi (detik).
const SHOT: Array = [
	{"dari": Vector3(0, 32, 64), "ke": Vector3(0, 15, 34), "lihat_dari": Vector3(0, 2, 0), "lihat_ke": Vector3(0, 3, 0),
		"judul": "Selamat Datang di Manggarai", "ket": "Flores, Nusa Tenggara Timur", "durasi": 5.0},
	{"dari": Vector3(15, 3.5, 15), "ke": Vector3(-7, 4.5, 19), "lihat_dari": Vector3(0, 4, -2), "lihat_ke": Vector3(0, 4, -2),
		"judul": "Mbaru Niang", "ket": "Rumah adat kerucut di Kampung Wae Rebo", "durasi": 4.5},
	{"dari": Vector3(6, 2.6, 11), "ke": Vector3(-5, 2.8, 10), "lihat_dari": Vector3(0, 1.6, 4), "lihat_ke": Vector3(0, 1.6, 4),
		"judul": "Penti & Caci", "ket": "Tahun baru adat, gong, gendang, dan tarian", "durasi": 4.5},
	{"dari": Vector3(-46, 36, 34), "ke": Vector3(-46, 28, 20), "lihat_dari": Vector3(-46, 0, 4), "lihat_ke": Vector3(-46, 0, 2),
		"judul": "Lingko Lodok", "ket": "Sawah adat berbentuk jaring laba-laba", "durasi": 4.5},
	{"dari": Vector3(23, 2.4, 11), "ke": Vector3(25.5, 2.0, 7), "lihat_dari": Vector3(31, 0.6, 3), "lihat_ke": Vector3(31, 0.6, 2),
		"judul": "Komodo", "ket": "Kadal terbesar di dunia, penghuni Taman Nasional Komodo", "durasi": 4.5},
	{"dari": Vector3(33, 5, 24), "ke": Vector3(40, 10, 32), "lihat_dari": Vector3(58, 1, -4), "lihat_ke": Vector3(64, 1, -6),
		"judul": "Labuan Bajo", "ket": "Laut biru, pantai merah muda, dan kapal pinisi", "durasi": 4.5},
]
## Bidikan penutup (judul game).
const SHOT_AKHIR: Dictionary = {"dari": Vector3(14, 46, 86), "ke": Vector3(8, 26, 60), "lihat_dari": Vector3(6, 0, 0),
	"lihat_ke": Vector3(4, 0, 0), "judul": "", "ket": "", "durasi": 6.0}


## Membangun panorama di bawah `induk`. Mengembalikan daftar kapal (untuk animasi mengapung).
static func bangun(induk: Node3D) -> Array[Node3D]:
	Dunia.lingkungan(induk)
	DuniaPulau.laut(induk, 420.0)
	# Daratan Flores (barat) dan pantai (timur, berbatasan dengan laut)
	var darat := BoxMesh.new()
	darat.size = Vector3(130, 2, 180)
	Dunia.mesh(induk, darat, Vector3(-39, -1, 0), Dunia.mat(Color.WHITE, Dunia.TEX_RUMPUT, Vector3(65, 90, 1)))
	var pantai := BoxMesh.new()
	pantai.size = Vector3(9, 2, 180)
	Dunia.mesh(induk, pantai, Vector3(30.5, -1.08, 0), Dunia.mat(DuniaPulau.WARNA_PASIR, Dunia.TEX_TANAH, Vector3(4, 80, 1)))
	var pantai_pink := BoxMesh.new()
	pantai_pink.size = Vector3(9.2, 2, 22)
	Dunia.mesh(induk, pantai_pink, Vector3(30.5, -1.06, -22), Dunia.mat(DuniaPulau.WARNA_PASIR_PINK, Dunia.TEX_TANAH, Vector3(4, 10, 1)))
	_kampung(induk)
	_lingko(induk)
	_pesisir(induk)
	var kapal: Array[Node3D] = _laut(induk)
	_alam(induk)
	return kapal


static func _kampung(induk: Node3D) -> void:
	Dunia.compang(induk, Vector3.ZERO)
	for i in 7:
		var a: float = deg_to_rad(-90.0 + 360.0 * i / 7.0)
		Dunia.mbaru_niang(induk, Vector3(cos(a), 0, sin(a)) * 13.0, Vector3.ZERO, 1.25 if i == 0 else 1.0)
	Dunia.gong_gendang(induk, Vector3(-5, 0, -4))
	var songke: Array[String] = ["songke_merah", "songke_biru", "songke_hijau", "songke_kuning"]
	for i in 8:
		var a: float = TAU * i / 8.0
		var m := KarakterModel.new()
		m.tekstur_songke = load("res://assets/textures/%s.png" % songke[i % songke.size()])
		m.warna_baju = Color("1b1818") if i % 2 == 0 else Color("e8e2d2")
		m.perempuan = i % 3 == 0
		m.position = Vector3(cos(a), 0, sin(a)) * 6.0
		induk.add_child(m)
		m.rotation.y = atan2(m.position.x, m.position.z)
		m.mode = "menari"
	for i in 2:
		var c := KarakterModel.new()
		c.tekstur_songke = load("res://assets/textures/%s.png" % ["songke_biru", "songke_kuning"][i])
		c.telanjang_dada = true
		c.pakai_panggal = true
		c.bawa_senjata = true
		c.position = Vector3(-1.3 + i * 2.6, 0, 4.0)
		induk.add_child(c)
		c.rotation.y = -PI / 2.0 if i == 0 else PI / 2.0
		c.mode = "siaga"
	# Nggohak menyambut di depan kampung
	var n := KarakterModel.new()
	n.tekstur_songke = preload("res://assets/textures/songke_nggohak.png")
	n.telanjang_dada = true
	n.sarung_panjang = true
	n.ikat_songke = true
	n.rambut_gimbal = true
	n.berotot = true
	n.position = Vector3(3.0, 0, 9.5)
	induk.add_child(n)
	n.rotation.y = 0.3
	for data: Array in [[Vector3(5, 0, 12), Color("f1ede4")], [Vector3(5.6, 0, 12.6), Color("9a4a22")], [Vector3(-6, 0, 10), Color("1e1a1a")]]:
		var ayam := Hewan.new()
		ayam.jenis = "ayam"
		ayam.position = data[0]
		ayam.warna_utama = data[1]
		ayam.jari_jelajah = 1.5
		induk.add_child(ayam)


static func _lingko(induk: Node3D) -> void:
	var l := Node3D.new()
	l.position = PUSAT_LINGKO
	induk.add_child(l)
	var batas: Array = []
	var jumlah: int = 0
	for t: int in [6, 4, 3, 3, 2, 2, 2, 2]:
		batas.append(-PI / 2.0 + TAU * jumlah / 24.0)
		jumlah += t
	DuniaLingko.juring_terbagi(l, 2.5, 16.45, batas)
	DuniaLingko.lodok(l, 2.6)
	DuniaLingko.pematang_lingkar(l, 5.5)
	DuniaLingko.pematang_lingkar(l, 10.5)
	DuniaLingko.pematang_lingkar(l, 16.0)
	for a: float in [90.0, -90.0, 0.0, 180.0]:
		DuniaLingko.pematang_jari(l, a, [[2.4, 16.0]])


static func _pesisir(induk: Node3D) -> void:
	for z: float in [-40.0, -30.0, -12.0, 12.0, 20.0, 30.0, 42.0]:
		DuniaPulau.lontar(induk, Vector3(28.0 + fmod(absf(z), 3.0), -0.05, z), 1.0 + fmod(absf(z), 0.4))
	var k := Komodo.new()
	k.titik_a = PUSAT_KOMODO + Vector3(0, -0.05, 4)
	k.titik_b = PUSAT_KOMODO + Vector3(0, -0.05, -3)
	k.kecepatan = 0.7
	k.selalu_bergerak = true
	induk.add_child(k)
	var k2 := Komodo.new()
	k2.titik_a = PUSAT_KOMODO + Vector3(-1.5, -0.05, 9)
	k2.titik_b = PUSAT_KOMODO + Vector3(-1.0, -0.05, 14)
	k2.kecepatan = 0.5
	k2.selalu_bergerak = true
	induk.add_child(k2)
	DuniaPulau.dermaga(induk, Vector3(34, 0.0, -8), Vector3(46, 0.0, -8))


static func _laut(induk: Node3D) -> Array[Node3D]:
	var kapal: Array[Node3D] = []
	kapal.append(DuniaPulau.kapal(induk, Vector3(44, 0, 0), 0.5))
	kapal.append(DuniaPulau.kapal(induk, Vector3(58, 0, -18), -0.7, Color("d8e8f0")))
	kapal.append(DuniaPulau.kapal(induk, Vector3(49, 0, -10), 1.57, Color("f4e0c0")))
	# Pulau-pulau Taman Nasional Komodo di kejauhan: pulau berbukit dan pulau berpantai merah muda
	DuniaPulau.daratan(induk, Vector3(82, 0, -12), 15.0, DuniaPulau.WARNA_PASIR)
	for data: Array in [[Vector3(84, 0, -14), 11.0, 4.0], [Vector3(82, 0, -18), 7.5, 8.0], [Vector3(88, 0, -10), 5.0, 11.0]]:
		Dunia.mesh(induk, Dunia.silinder(data[1] * 0.7, data[1], data[2], 14), data[0] + Vector3(0, data[2] / 2.0, 0),
				Dunia.mat(DuniaPulau.WARNA_SABANA, Dunia.TEX_RUMPUT, Vector3(4, 2, 1)))
	DuniaPulau.daratan(induk, Vector3(70, 0, 26), 9.0, DuniaPulau.WARNA_PASIR_PINK)
	Dunia.bukit(induk, Vector3(72, -2, 22), 7, 7)
	for p: Vector3 in [Vector3(66, 0, 30), Vector3(76, 0, -2)]:
		DuniaPulau.lontar(induk, p)
	for i in 6:
		var a: float = -PI / 2.0 + PI * i / 5.0
		Dunia.bukit(induk, Vector3(140 + cos(a) * 30, -6, sin(a) * 80), 22, 18)
	return kapal


static func _alam(induk: Node3D) -> void:
	var acak := RandomNumberGenerator.new()
	acak.seed = 21
	for i in 70:
		var p := Vector3(acak.randf_range(-100, 24), 0, acak.randf_range(-80, 70))
		if p.distance_to(Vector3.ZERO) > 20.0 and p.distance_to(PUSAT_LINGKO) > 20.0 and p.distance_to(Vector3(0, 0, 40)) > 14.0:
			Dunia.pohon(induk, p, acak.randf_range(0.8, 1.5))
	# Pegunungan Wae Rebo di belakang kampung
	for i in 10:
		var x: float = -110.0 + i * 16.0
		Dunia.bukit(induk, Vector3(x, -4, -78 - acak.randf_range(0, 12)), acak.randf_range(18, 26), acak.randf_range(16, 30))


## Kapal mengapung naik-turun dan sedikit bergoyang.
static func animasi_kapal(kapal: Array[Node3D], waktu: float) -> void:
	for i in kapal.size():
		var k: Node3D = kapal[i]
		k.position.y = DuniaPulau.Y_LAUT + sin(waktu * 1.3 + i) * 0.12
		k.rotation.z = sin(waktu * 0.9 + i * 2.0) * 0.03


## Posisi & titik pandang kamera pada bidikan `shot` di waktu relatif t (0..1), dengan ease in/out.
static func pose(shot: Dictionary, t: float) -> Array:
	var e: float = ease(clampf(t, 0.0, 1.0), -1.8)
	var pos: Vector3 = (shot["dari"] as Vector3).lerp(shot["ke"], e)
	var lihat: Vector3 = (shot["lihat_dari"] as Vector3).lerp(shot["lihat_ke"], e)
	return [pos, lihat]
