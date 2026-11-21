@tool
extends StaticBody3D
## Pagar tembok keliling alun-alun: tembok rendah gading, tiang marun bertopi emas,
## dan dinding tak terlihat setinggi `tinggi_tabrakan` agar pemain tidak keluar arena.
## Sisi utara diberi celah selebar `celah_utara` untuk gerbang keraton.

@export var ukuran: Vector2 = Vector2(64, 64):
	set(v):
		ukuran = v
		_bangun_ulang()
@export var celah_utara: float = 10.0:
	set(v):
		celah_utara = v
		_bangun_ulang()
@export var jarak_tiang: float = 4.0
@export var tinggi_tembok: float = 1.0
@export var tinggi_tabrakan: float = 5.0


func _ready() -> void:
	_bangun()


func _bangun_ulang() -> void:
	if is_inside_tree():
		_bangun()


func _bangun() -> void:
	Pembangun.hapus_anak(self)
	var hx := ukuran.x * 0.5
	var hz := ukuran.y * 0.5
	var c := celah_utara * 0.5
	# Segmen: [titik awal, titik akhir] pada bidang XZ.
	var segmen: Array = [
		[Vector2(-hx, hz), Vector2(hx, hz)],      # selatan
		[Vector2(-hx, -hz), Vector2(-hx, hz)],    # barat
		[Vector2(hx, -hz), Vector2(hx, hz)],      # timur
		[Vector2(-hx, -hz), Vector2(-c, -hz)],    # utara kiri
		[Vector2(c, -hz), Vector2(hx, -hz)],      # utara kanan
	]
	for s: Array in segmen:
		_segmen(s[0], s[1])


func _segmen(a: Vector2, b: Vector2) -> void:
	var tengah := (a + b) * 0.5
	var panjang := a.distance_to(b)
	var sepanjang_x := absf(b.x - a.x) > absf(b.y - a.y)
	var ukuran_tembok := Vector3(panjang, tinggi_tembok, 0.4) if sepanjang_x else Vector3(0.4, tinggi_tembok, panjang)
	Pembangun.kotak(self, ukuran_tembok, Vector3(tengah.x, tinggi_tembok * 0.5, tengah.y), PaletJawa.GADING, false)
	var ukuran_lis := ukuran_tembok + Vector3(0.1, -tinggi_tembok + 0.12, 0.1)
	Pembangun.kotak(self, ukuran_lis, Vector3(tengah.x, tinggi_tembok + 0.06, tengah.y), PaletJawa.MARUN, false)
	# Dinding tak terlihat (collision saja).
	var cs := CollisionShape3D.new()
	var bentuk := BoxShape3D.new()
	bentuk.size = Vector3(ukuran_tembok.x, tinggi_tabrakan, ukuran_tembok.z + 0.2)
	cs.shape = bentuk
	cs.position = Vector3(tengah.x, tinggi_tabrakan * 0.5, tengah.y)
	add_child(cs)
	# Tiang-tiang.
	var jumlah := maxi(int(panjang / jarak_tiang), 1)
	for i in jumlah + 1:
		var p := a.lerp(b, float(i) / float(jumlah))
		Pembangun.kotak(self, Vector3(0.6, tinggi_tembok + 0.5, 0.6), Vector3(p.x, (tinggi_tembok + 0.5) * 0.5, p.y), PaletJawa.MARUN, false)
		Pembangun.kotak(self, Vector3(0.75, 0.15, 0.75), Vector3(p.x, tinggi_tembok + 0.55, p.y), PaletJawa.EMAS, false, true)
