class_name ArenaBuilder
## Arena bertema untuk mode LAN (co-op gelombang & PvP), dibangun dari builder dunia yang ada:
##   "wae_rebo"    - lapangan rumput dikelilingi Mbaru Niang (tanpa compang: tempat sakral bukan arena)
##   "lingko"      - sawah jaring laba-laba dengan pematang melingkar & pondok
##   "labuan_bajo" - pantai pasir, pohon lontar, perahu, laut di sekeliling
## Batu-batu besar menjadi tempat berlindung. Mengembalikan titik muncul (spawn) per sisi.

const HALF: float = 24.0


static func theme_for_level(level: int) -> String:
	return ["wae_rebo", "lingko", "labuan_bajo"][clampi(level, 1, 3) - 1]


static func build(root: Node3D, theme: String) -> void:
	Dunia.lingkungan(root)
	var lantai := BoxShape3D.new()
	lantai.size = Vector3(HALF * 2.4, 1, HALF * 2.4)
	Dunia.badan_statis(root, lantai, Vector3(0, -0.5, 0))
	Dunia.batas_dunia(root, HALF)
	match theme:
		"lingko":
			_lingko(root)
		"labuan_bajo":
			_labuan_bajo(root)
		_:
			_wae_rebo(root)
	# Batu perlindungan (sama di semua arena, simetris agar adil di PvP)
	for p: Vector3 in [Vector3(-7, 0, -3), Vector3(7, 0, 3), Vector3(-3, 0, 8), Vector3(3, 0, -8), Vector3(-12, 0, 10),
			Vector3(12, 0, -10)]:
		_rock(root, p)


static func _wae_rebo(root: Node3D) -> void:
	Dunia.tanah(root, HALF * 2.4)
	for i in 7:
		var a: float = TAU * i / 7.0 + 0.3
		Dunia.mbaru_niang(root, Vector3(cos(a), 0, sin(a)) * (HALF + 4.0), Vector3.ZERO, 0.9)
	for i in 10:
		var a2: float = TAU * i / 10.0
		Dunia.pohon(root, Vector3(cos(a2), 0, sin(a2)) * (HALF - 3.0), 1.1)


static func _lingko(root: Node3D) -> void:
	Dunia.tanah(root, HALF * 2.4)
	for r: float in [6.0, 12.0, 18.0]:
		DuniaLingko.petak_sawah(root, r - 5.6, r - 0.4)
		DuniaLingko.pematang_lingkar(root, r)
	for k in 8:
		DuniaLingko.pematang_jari(root, 360.0 * k / 8.0, [[0.8, 18.0]])
	DuniaLingko.pondok(root, Vector3(-HALF + 4, 0, HALF - 4), 0.6)


static func _labuan_bajo(root: Node3D) -> void:
	DuniaPulau.laut(root, 160.0)
	DuniaPulau.daratan(root, Vector3.ZERO, HALF + 2.0, DuniaPulau.WARNA_PASIR)
	for i in 9:
		var a: float = TAU * i / 9.0
		DuniaPulau.lontar(root, Vector3(cos(a), 0, sin(a)) * (HALF - 3.0), 1.0)
	DuniaPulau.kapal(root, Vector3(0, 0, HALF + 6.0), 0.0)
	DuniaPulau.kapal(root, Vector3(HALF + 6.0, 0, -6.0), PI / 2.0, Color("d8e8f0"))


## Titik muncul: co-op berkumpul di tengah; PvP tiap tim di sisi berlawanan.
static func spawn_point(slot: int, team_count: int, team: int) -> Vector3:
	if team_count <= 1:
		var a: float = TAU * slot / 4.0
		return Vector3(cos(a) * 2.0, 0.3, sin(a) * 2.0 + 4.0)
	var sudut: float = TAU * team / maxf(team_count, 2) + PI / 2.0
	var base := Vector3(cos(sudut), 0, sin(sudut)) * (HALF - 6.0)
	return base + Vector3(randf_range(-2, 2), 0.3, randf_range(-2, 2))


## Batu besar abu-abu (tempat berlindung dari panah).
static func _rock(root: Node3D, p: Vector3) -> void:
	var b := SphereMesh.new()
	b.radius = 1.3
	b.height = 2.0
	b.radial_segments = 9
	b.rings = 5
	var mi := Dunia.mesh(root, b, p + Vector3(0, 0.7, 0), Dunia.mat(Color("7a756c"), Dunia.TEX_BATU))
	mi.scale = Vector3(1.0, 0.8, 0.9)
	mi.rotation.y = p.x
	var bentuk := CylinderShape3D.new()
	bentuk.radius = 1.15
	bentuk.height = 1.7
	Dunia.badan_statis(root, bentuk, p + Vector3(0, 0.85, 0))

