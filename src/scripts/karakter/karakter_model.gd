class_name KarakterModel
extends Node3D
## Model karakter low-poly yang dibangun dari mesh primitif + animasi prosedural.
## Menerapkan prinsip animasi: anticipation, follow-through, squash & stretch,
## ease in/out, timing, dan secondary action (napas, ayunan lengan).
## Arah depan model = -Z.

signal momen_pukul  ## dipancarkan saat cambuk mencapai titik pukul

@export var tekstur_songke: Texture2D = preload("res://assets/textures/songke_merah.png")
@export var warna_baju: Color = Color("e8e2d2")
@export var warna_ikat: Color = Color("b02a2a")
@export var telanjang_dada: bool = false
@export var pakai_panggal: bool = false
@export var bawa_senjata: bool = false
@export var skala_tubuh: float = 1.0
@export var perempuan: bool = false  ## rambut bersanggul, sarung songke panjang
@export var bawa_nampan: bool = false  ## membawa nampan berisi cangkir kopi

const KULIT := Color("8d552e")
const RAMBUT := Color("1a1414")

## "idle", "jalan", "udara", "menari", "siaga"
var mode: String = "idle"
var kecepatan_jalan: float = 0.0  # 0..1, mengatur tempo ayunan kaki

var _akar: Node3D
var _badan: Node3D
var _lengan_kiri: Node3D
var _lengan_kanan: Node3D
var _kaki_kiri: Node3D
var _kaki_kanan: Node3D
var _larik: Node3D
var _nggiling: Node3D
var _nampan: Node3D
var _fase: float = 0.0
var _waktu: float = 0.0
var _aksi_aktif: bool = false
var _tween_aksi: Tween


func _ready() -> void:
	_bangun()


# ---------------------------------------------------------------- pembangunan

func _mat(warna: Color, tekstur: Texture2D = null) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = warna
	if tekstur:
		m.albedo_texture = tekstur
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.roughness = 0.9
	return m


func _bagian(induk: Node3D, mesh: Mesh, posisi: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = posisi
	mi.material_override = mat
	induk.add_child(mi)
	return mi


func _pivot(induk: Node3D, posisi: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = posisi
	induk.add_child(p)
	return p


func _kapsul(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 8
	c.rings = 2
	return c


func _bangun() -> void:
	var m_kulit := _mat(KULIT)
	var m_songke := _mat(Color.WHITE, tekstur_songke)
	var m_baju := m_kulit if telanjang_dada else _mat(warna_baju)
	var m_ikat := _mat(warna_ikat)

	_akar = _pivot(self, Vector3.ZERO)
	_akar.scale = Vector3.ONE * skala_tubuh

	# Kaki (pivot di pinggul supaya bisa berayun)
	_kaki_kiri = _pivot(_akar, Vector3(-0.11, 0.85, 0))
	_kaki_kanan = _pivot(_akar, Vector3(0.11, 0.85, 0))
	for k: Node3D in [_kaki_kiri, _kaki_kanan]:
		_bagian(k, _kapsul(0.08, 0.85), Vector3(0, -0.42, 0), m_kulit)

	_badan = _pivot(_akar, Vector3(0, 0.85, 0))
	# Sarung songke (kerucut terpotong); perempuan memakai sarung panjang hingga mata kaki
	var sarung := CylinderMesh.new()
	sarung.top_radius = 0.2
	sarung.bottom_radius = 0.3 if perempuan else 0.26
	sarung.height = 0.85 if perempuan else 0.55
	sarung.radial_segments = 10
	_bagian(_badan, sarung, Vector3(0, -0.27 if perempuan else -0.12, 0), m_songke)
	# Tubuh
	var tubuh := BoxMesh.new()
	tubuh.size = Vector3(0.4, 0.46, 0.24)
	_bagian(_badan, tubuh, Vector3(0, 0.38, 0), m_baju)
	if telanjang_dada:
		var selempang := BoxMesh.new()
		selempang.size = Vector3(0.42, 0.06, 0.26)
		_bagian(_badan, selempang, Vector3(0, 0.18, 0), m_songke)
	# Kepala
	var kepala := SphereMesh.new()
	kepala.radius = 0.15
	kepala.height = 0.32
	kepala.radial_segments = 10
	kepala.rings = 6
	_bagian(_badan, kepala, Vector3(0, 0.8, 0), m_kulit)
	var rambut := SphereMesh.new()
	rambut.radius = 0.155
	rambut.height = 0.2
	rambut.radial_segments = 10
	rambut.rings = 4
	_bagian(_badan, rambut, Vector3(0, 0.88, 0.02), _mat(RAMBUT))
	for x: float in [-0.055, 0.055]:
		var mata := SphereMesh.new()
		mata.radius = 0.022
		mata.height = 0.044
		_bagian(_badan, mata, Vector3(x, 0.82, -0.135), _mat(RAMBUT))
	if perempuan:
		# Rambut panjang disanggul di belakang kepala
		var sanggul := SphereMesh.new()
		sanggul.radius = 0.09
		sanggul.height = 0.16
		_bagian(_badan, sanggul, Vector3(0, 0.84, 0.16), _mat(RAMBUT))
	else:
		# Ikat kepala songke
		var ikat := TorusMesh.new()
		ikat.inner_radius = 0.14
		ikat.outer_radius = 0.175
		ikat.rings = 12
		ikat.ring_segments = 4
		_bagian(_badan, ikat, Vector3(0, 0.86, 0), m_ikat)
	if pakai_panggal:
		_bangun_panggal(m_songke, m_ikat)

	# Lengan (pivot di bahu)
	_lengan_kiri = _pivot(_badan, Vector3(-0.27, 0.58, 0))
	_lengan_kanan = _pivot(_badan, Vector3(0.27, 0.58, 0))
	for l: Node3D in [_lengan_kiri, _lengan_kanan]:
		_bagian(l, _kapsul(0.065, 0.6), Vector3(0, -0.28, 0), m_kulit)

	_bangun_senjata()
	if bawa_nampan:
		_bangun_nampan()


## Nampan kayu berisi cangkir kopi, dipegang dengan dua tangan di depan badan.
func _bangun_nampan() -> void:
	_nampan = _pivot(_badan, Vector3(0, 0.3, -0.36))
	var papan := BoxMesh.new()
	papan.size = Vector3(0.5, 0.03, 0.3)
	_bagian(_nampan, papan, Vector3.ZERO, _mat(Color("7a5030")))
	var m_cangkir := _mat(Color("f1ede4"))
	var m_kopi := _mat(Color("2a1a10"))
	for x: float in [-0.15, 0.0, 0.15]:
		var cangkir := CylinderMesh.new()
		cangkir.top_radius = 0.045
		cangkir.bottom_radius = 0.035
		cangkir.height = 0.08
		cangkir.radial_segments = 8
		_bagian(_nampan, cangkir, Vector3(x, 0.055, 0), m_cangkir)
		var isi := CylinderMesh.new()
		isi.top_radius = 0.038
		isi.bottom_radius = 0.038
		isi.height = 0.01
		isi.radial_segments = 8
		_bagian(_nampan, isi, Vector3(x, 0.095, 0), m_kopi)


func _bangun_panggal(m_songke: Material, m_ikat: Material) -> void:
	# Panggal: penutup kepala pemain caci dengan dua ujung menjulang
	var pita := CylinderMesh.new()
	pita.top_radius = 0.17
	pita.bottom_radius = 0.18
	pita.height = 0.12
	_bagian(_badan, pita, Vector3(0, 0.9, 0), m_songke)
	for sisi: float in [-1.0, 1.0]:
		var tanduk := CylinderMesh.new()
		tanduk.top_radius = 0.0
		tanduk.bottom_radius = 0.06
		tanduk.height = 0.35
		var mi := _bagian(_badan, tanduk, Vector3(0.14 * sisi, 1.07, 0), m_ikat)
		mi.rotation = Vector3(0, 0, -0.6 * sisi)


func _bangun_senjata() -> void:
	# Larik (cambuk) di tangan kanan
	_larik = _pivot(_lengan_kanan, Vector3(0, -0.55, 0))
	var gagang := CylinderMesh.new()
	gagang.top_radius = 0.02
	gagang.bottom_radius = 0.012
	gagang.height = 1.1
	_bagian(_larik, gagang, Vector3(0, -0.5, 0), _mat(Color("5a3a22")))
	# Nggiling (perisai bundar kulit kerbau) di tangan kiri
	_nggiling = _pivot(_lengan_kiri, Vector3(0, -0.5, -0.05))
	var perisai := CylinderMesh.new()
	perisai.top_radius = 0.3
	perisai.bottom_radius = 0.3
	perisai.height = 0.04
	perisai.radial_segments = 16
	var mi := _bagian(_nggiling, perisai, Vector3.ZERO, _mat(Color.WHITE, preload("res://assets/textures/kulit_kerbau.png")))
	mi.rotation = Vector3(PI / 2, 0, 0)
	var tengah := SphereMesh.new()
	tengah.radius = 0.06
	tengah.height = 0.06
	_bagian(_nggiling, tengah, Vector3(0, 0, -0.03), _mat(Color("e8b430")))
	_larik.visible = bawa_senjata
	_nggiling.visible = bawa_senjata


# ---------------------------------------------------------------- animasi loop

func _process(delta: float) -> void:
	_waktu += delta
	if _aksi_aktif:
		return
	match mode:
		"jalan":
			_fase += delta * lerpf(6.0, 11.0, kecepatan_jalan)
			var ayun: float = sin(_fase) * 0.7 * maxf(kecepatan_jalan, 0.3)
			_kaki_kiri.rotation.x = ayun
			_kaki_kanan.rotation.x = -ayun
			_lengan_kiri.rotation.x = -ayun * 0.7
			_lengan_kanan.rotation.x = ayun * 0.7
			_akar.position.y = absf(sin(_fase)) * 0.05
			_badan.rotation.x = 0.08
		"udara":
			_kaki_kiri.rotation.x = lerpf(_kaki_kiri.rotation.x, 0.5, delta * 12.0)
			_kaki_kanan.rotation.x = lerpf(_kaki_kanan.rotation.x, -0.25, delta * 12.0)
			_lengan_kiri.rotation.z = lerpf(_lengan_kiri.rotation.z, -0.8, delta * 10.0)
			_lengan_kanan.rotation.z = lerpf(_lengan_kanan.rotation.z, 0.8, delta * 10.0)
		"menari":
			# Gerak tari sederhana saat perayaan (lengan terentang, badan bergoyang)
			_lengan_kiri.rotation.z = -1.2 + sin(_waktu * 4.0) * 0.3
			_lengan_kanan.rotation.z = 1.2 + sin(_waktu * 4.0 + PI) * 0.3
			_akar.position.y = absf(sin(_waktu * 4.0)) * 0.08
			_badan.rotation.z = sin(_waktu * 2.0) * 0.08
		"siaga":
			# Kuda-kuda caci: perisai di depan, cambuk siap
			_lengan_kiri.rotation.x = lerpf(_lengan_kiri.rotation.x, 0.9, delta * 8.0)
			_lengan_kanan.rotation.x = lerpf(_lengan_kanan.rotation.x, -0.4, delta * 8.0)
			_kaki_kiri.rotation.x = lerpf(_kaki_kiri.rotation.x, -0.25, delta * 8.0)
			_kaki_kanan.rotation.x = lerpf(_kaki_kanan.rotation.x, 0.25, delta * 8.0)
			_akar.position.y = sin(_waktu * 3.0) * 0.02 - 0.03
		_:  # idle: napas (secondary action)
			_kaki_kiri.rotation.x = lerpf(_kaki_kiri.rotation.x, 0.0, delta * 10.0)
			_kaki_kanan.rotation.x = lerpf(_kaki_kanan.rotation.x, 0.0, delta * 10.0)
			_lengan_kiri.rotation.x = lerpf(_lengan_kiri.rotation.x, sin(_waktu * 2.0) * 0.05, delta * 8.0)
			_lengan_kanan.rotation.x = lerpf(_lengan_kanan.rotation.x, -sin(_waktu * 2.0) * 0.05, delta * 8.0)
			_akar.position.y = lerpf(_akar.position.y, 0.0, delta * 10.0)
			_badan.rotation.x = lerpf(_badan.rotation.x, 0.0, delta * 10.0)
			_badan.scale.y = 1.0 + sin(_waktu * 2.2) * 0.015
	if mode != "udara" and mode != "menari":
		_lengan_kiri.rotation.z = lerpf(_lengan_kiri.rotation.z, 0.0, delta * 10.0)
		_lengan_kanan.rotation.z = lerpf(_lengan_kanan.rotation.z, 0.0, delta * 10.0)
	if mode != "menari":
		_badan.rotation.z = lerpf(_badan.rotation.z, 0.0, delta * 10.0)
	if bawa_nampan:
		# Kedua lengan menahan nampan di depan badan (menimpa ayunan lengan)
		_lengan_kiri.rotation.x = lerpf(_lengan_kiri.rotation.x, 1.15, delta * 10.0)
		_lengan_kanan.rotation.x = lerpf(_lengan_kanan.rotation.x, 1.15, delta * 10.0)
		_lengan_kiri.rotation.z = lerpf(_lengan_kiri.rotation.z, -0.25, delta * 10.0)
		_lengan_kanan.rotation.z = lerpf(_lengan_kanan.rotation.z, 0.25, delta * 10.0)
		_badan.rotation.x = 0.0


# ---------------------------------------------------------------- aksi sekali jalan

func _mulai_aksi() -> Tween:
	if _tween_aksi:
		_tween_aksi.kill()
	_aksi_aktif = true
	_tween_aksi = create_tween()
	return _tween_aksi


func _akhiri_aksi() -> void:
	_aksi_aktif = false


## Squash & stretch: dipakai saat melompat (stretch) dan mendarat (squash).
func squash(skala: Vector3, durasi: float = 0.22) -> void:
	_akar.scale = skala * skala_tubuh
	var tw := create_tween()
	tw.tween_property(_akar, "scale", Vector3.ONE * skala_tubuh, durasi).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Serangan cambuk: anticipation -> pukul -> follow-through -> kembali.
## Mengembalikan durasi hingga momen pukul.
func serang(durasi_ancang: float = 0.35) -> float:
	var tw := _mulai_aksi()
	tw.set_parallel(true)
	# Anticipation: tarik cambuk jauh ke belakang, badan condong ke belakang
	tw.tween_property(_lengan_kanan, "rotation:x", -2.6, durasi_ancang).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_badan, "rotation:x", -0.2, durasi_ancang).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	# Pukulan cepat (timing: sangat singkat dibanding antisipasi)
	tw.tween_property(_lengan_kanan, "rotation:x", 1.7, 0.09).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_badan, "rotation:x", 0.25, 0.09)
	tw.tween_callback(func() -> void: momen_pukul.emit())
	# Follow-through: lengan terus bergerak melewati target lalu kembali perlahan
	tw.tween_property(_lengan_kanan, "rotation:x", 0.6, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_larik, "rotation:x", 0.5, 0.1)
	tw.tween_property(_larik, "rotation:x", 0.0, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_badan, "rotation:x", 0.0, 0.3).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(_lengan_kanan, "rotation:x", -0.4, 0.3).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_akhiri_aksi)
	return durasi_ancang + 0.09


## Pose ancang-ancang ditahan (dipakai lawan untuk memberi isyarat serangan).
func ancang(durasi: float) -> void:
	var tw := _mulai_aksi()
	tw.tween_property(_lengan_kanan, "rotation:x", -2.6, durasi).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_badan, "rotation:x", -0.2, durasi)


## Lanjutan dari ancang(): pukulan + follow-through.
func lepas_pukulan() -> void:
	var tw := _mulai_aksi()
	tw.tween_property(_lengan_kanan, "rotation:x", 1.7, 0.09).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_badan, "rotation:x", 0.25, 0.09)
	tw.tween_callback(func() -> void: momen_pukul.emit())
	tw.tween_property(_lengan_kanan, "rotation:x", 0.6, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(_badan, "rotation:x", 0.0, 0.3).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(_lengan_kanan, "rotation:x", -0.4, 0.3).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_akhiri_aksi)


## Menangkis dengan nggiling: angkat perisai cepat, tahan, turunkan perlahan.
func tangkis(tahan: float = 0.3) -> void:
	var tw := _mulai_aksi()
	tw.tween_property(_lengan_kiri, "rotation:x", 1.5, 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_badan, "rotation:x", -0.1, 0.07)
	tw.tween_interval(tahan)
	tw.tween_property(_lengan_kiri, "rotation:x", 0.9, 0.2).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(_badan, "rotation:x", 0.0, 0.2)
	tw.tween_callback(_akhiri_aksi)


## Terkena pukulan: terdorong ke belakang + squash, lalu pulih.
func terkena() -> void:
	var tw := _mulai_aksi()
	tw.tween_property(_badan, "rotation:x", -0.45, 0.06).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_akar, "position:z", 0.25, 0.06)
	tw.tween_property(_badan, "rotation:x", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_akar, "position:z", 0.0, 0.35).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_akhiri_aksi)
	squash(Vector3(1.15, 0.85, 1.15), 0.3)


## Membatalkan aksi (misalnya tipuan lawan): lengan kembali ke kuda-kuda.
func batal_aksi() -> void:
	var tw := _mulai_aksi()
	tw.tween_property(_lengan_kanan, "rotation:x", -0.4, 0.25).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(_badan, "rotation:x", 0.0, 0.25)
	tw.tween_callback(_akhiri_aksi)


func tampilkan_senjata(tampil: bool) -> void:
	_larik.visible = tampil
	_nggiling.visible = tampil
