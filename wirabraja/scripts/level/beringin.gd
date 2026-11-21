@tool
extends StaticBody3D
## Pohon beringin. Dengan `pakai_pagar` = true menjadi "ringin kurung"
## (beringin berpagar) seperti sepasang beringin di tengah alun-alun keraton.

@export var pakai_pagar: bool = true:
	set(v):
		pakai_pagar = v
		_bangun_ulang()
@export var skala_tajuk: float = 1.0:
	set(v):
		skala_tajuk = v
		_bangun_ulang()
@export var sisi_pagar: float = 5.0


func _ready() -> void:
	_bangun()


func _bangun_ulang() -> void:
	if is_inside_tree():
		_bangun()


func _bangun() -> void:
	Pembangun.hapus_anak(self)
	var k := skala_tajuk
	Pembangun.silinder(self, 0.7 * k, 5.0 * k, Vector3(0, 2.5 * k, 0), PaletJawa.SOGAN_TUA, true, false, 0.45 * k)
	# Tajuk rimbun dari beberapa bola.
	var tajuk := [
		[Vector3(0, 6.2, 0), 3.4], [Vector3(2.2, 5.6, 0.8), 2.4], [Vector3(-2.1, 5.7, -0.6), 2.5],
		[Vector3(0.6, 5.5, 2.1), 2.3], [Vector3(-0.7, 5.4, -2.2), 2.3], [Vector3(0.2, 7.6, 0.2), 2.2],
	]
	var i := 0
	for t: Array in tajuk:
		var warna := PaletJawa.HIJAU if i % 2 == 0 else PaletJawa.HIJAU_TUA
		Pembangun.bola(self, (t[1] as float) * k, (t[0] as Vector3) * k, warna)
		i += 1
	# Akar gantung (sulur) tipis.
	for j in 8:
		var sudut := TAU * float(j) / 8.0
		var p := Vector3(cos(sudut), 0, sin(sudut)) * 2.0 * k
		Pembangun.silinder(self, 0.06, 3.2 * k, p + Vector3(0, 3.6 * k, 0), PaletJawa.SOGAN, false)
	if pakai_pagar:
		_pagar_kurung()


func _pagar_kurung() -> void:
	var h := sisi_pagar * 0.5
	var tinggi := 1.1
	for sisi: int in 4:
		var horisontal := sisi < 2
		var tanda := -1.0 if sisi % 2 == 0 else 1.0
		var pos := Vector3(0, 0, tanda * h) if horisontal else Vector3(tanda * h, 0, 0)
		var ukuran_rel := Vector3(sisi_pagar, 0.12, 0.12) if horisontal else Vector3(0.12, 0.12, sisi_pagar)
		Pembangun.kotak(self, ukuran_rel, pos + Vector3(0, tinggi, 0), PaletJawa.GADING, false)
		Pembangun.kotak(self, ukuran_rel, pos + Vector3(0, tinggi * 0.5, 0), PaletJawa.GADING, false)
		# Collision pagar.
		var bentuk_col := Vector3(sisi_pagar, tinggi + 0.2, 0.3) if horisontal else Vector3(0.3, tinggi + 0.2, sisi_pagar)
		var cs := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = bentuk_col
		cs.shape = b
		cs.position = pos + Vector3(0, (tinggi + 0.2) * 0.5, 0)
		add_child(cs)
		for n in 5:
			var t := lerpf(-h, h, float(n) / 4.0)
			var p := Vector3(t, 0, pos.z) if horisontal else Vector3(pos.x, 0, t)
			Pembangun.kotak(self, Vector3(0.18, tinggi + 0.25, 0.18), p + Vector3(0, (tinggi + 0.25) * 0.5, 0), PaletJawa.MARUN, false)
			Pembangun.bola(self, 0.12, p + Vector3(0, tinggi + 0.3, 0), PaletJawa.EMAS, true)
