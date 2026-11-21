@tool
extends StaticBody3D
## Pendopo bergaya joglo (terinspirasi Pagelaran Sasana Sumewa di sisi utara
## Alun-Alun Lor Keraton Surakarta). Dibangun dari bentuk dasar saat _ready,
## sehingga ukurannya dapat disetel lewat Inspector. Untuk mengganti dengan model
## asli: hapus skrip ini lalu tambahkan model .glb sebagai anak node ini.

@export var panjang: float = 18.0:
	set(v):
		panjang = v
		_bangun_ulang()
@export var lebar: float = 11.0:
	set(v):
		lebar = v
		_bangun_ulang()
@export var tinggi_tiang: float = 3.4:
	set(v):
		tinggi_tiang = v
		_bangun_ulang()
@export var jumlah_tiang_sisi_panjang: int = 7:
	set(v):
		jumlah_tiang_sisi_panjang = maxi(v, 2)
		_bangun_ulang()


func _ready() -> void:
	_bangun()


func _bangun_ulang() -> void:
	if is_inside_tree():
		_bangun()


func _bangun() -> void:
	Pembangun.hapus_anak(self)
	var batu := Color(0.62, 0.58, 0.52)
	# Lantai (tanpa collision agar pemain bisa naik tanpa tangga).
	Pembangun.kotak(self, Vector3(panjang, 0.15, lebar), Vector3(0, 0.075, 0), batu, false)

	# Tiang tepi (saka emper).
	var hx := panjang * 0.5 - 0.5
	var hz := lebar * 0.5 - 0.5
	var titik: Array[Vector2] = []
	for i in jumlah_tiang_sisi_panjang:
		var x := lerpf(-hx, hx, float(i) / float(jumlah_tiang_sisi_panjang - 1))
		titik.append(Vector2(x, -hz))
		titik.append(Vector2(x, hz))
	for z: float in [-hz / 3.0, hz / 3.0]:
		titik.append(Vector2(-hx, z))
		titik.append(Vector2(hx, z))
	for p: Vector2 in titik:
		_tiang(Vector3(p.x, 0, p.y), tinggi_tiang, 0.2)

	# Empat saka guru di tengah, lebih tinggi.
	var tinggi_guru := tinggi_tiang + 1.6
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_tiang(Vector3(sx * 2.4, 0, sz * 1.7), tinggi_guru, 0.28)

	# Balok blandar keliling di atas tiang tepi.
	var yb := tinggi_tiang + 0.12
	Pembangun.kotak(self, Vector3(panjang - 0.6, 0.25, 0.3), Vector3(0, yb, -hz), PaletJawa.SOGAN_TUA, false)
	Pembangun.kotak(self, Vector3(panjang - 0.6, 0.25, 0.3), Vector3(0, yb, hz), PaletJawa.SOGAN_TUA, false)
	Pembangun.kotak(self, Vector3(0.3, 0.25, lebar - 0.6), Vector3(-hx, yb, 0), PaletJawa.SOGAN_TUA, false)
	Pembangun.kotak(self, Vector3(0.3, 0.25, lebar - 0.6), Vector3(hx, yb, 0), PaletJawa.SOGAN_TUA, false)
	# Lis emas (tumpang sari disederhanakan).
	Pembangun.kotak(self, Vector3(panjang - 0.4, 0.08, 0.34), Vector3(0, yb + 0.16, -hz), PaletJawa.EMAS, false, true)
	Pembangun.kotak(self, Vector3(panjang - 0.4, 0.08, 0.34), Vector3(0, yb + 0.16, hz), PaletJawa.EMAS, false, true)

	# Atap emper (landai) dan atap brunjung (curam) khas joglo.
	var y_emper := tinggi_tiang + 0.25
	Pembangun.limas(self, Vector2(panjang + 2.2, lebar + 2.2), Vector2(6.4, 4.4), 1.5,
			Vector3(0, y_emper + 0.75, 0), PaletJawa.GENTENG)
	Pembangun.limas(self, Vector2(6.6, 4.6), Vector2(1.6, 1.1), 2.6,
			Vector3(0, y_emper + 1.5 + 1.3, 0), PaletJawa.GENTENG)
	# Mustaka (hiasan puncak) berwarna emas.
	Pembangun.bola(self, 0.35, Vector3(0, y_emper + 1.5 + 2.6 + 0.25, 0), PaletJawa.EMAS, true)


func _tiang(alas: Vector3, tinggi: float, radius: float) -> void:
	# Umpak (alas batu), tiang marun, dan cincin emas di atas.
	Pembangun.kotak(self, Vector3(radius * 3.0, 0.3, radius * 3.0), alas + Vector3(0, 0.15, 0),
			Color(0.5, 0.47, 0.43), false)
	Pembangun.silinder(self, radius, tinggi, alas + Vector3(0, tinggi * 0.5, 0), PaletJawa.MARUN)
	Pembangun.silinder(self, radius * 1.25, 0.18, alas + Vector3(0, tinggi - 0.3, 0), PaletJawa.EMAS, false, true)
	Pembangun.silinder(self, radius * 1.25, 0.18, alas + Vector3(0, 0.45, 0), PaletJawa.EMAS, false, true)
