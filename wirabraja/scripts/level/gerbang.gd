@tool
extends StaticBody3D
## Gerbang keraton bergaya paduraksa (gapura beratap), terinspirasi gerbang-gerbang
## (kori) Keraton Surakarta. Pintu tertutup — bos muncul di depannya.

@export var lebar_total: float = 10.0:
	set(v):
		lebar_total = v
		_bangun_ulang()
@export var tinggi: float = 6.0:
	set(v):
		tinggi = v
		_bangun_ulang()


func _ready() -> void:
	_bangun()


func _bangun_ulang() -> void:
	if is_inside_tree():
		_bangun()


func _bangun() -> void:
	Pembangun.hapus_anak(self)
	var tebal := 2.0
	var lebar_pilar := 3.0
	var lebar_pintu := lebar_total - lebar_pilar * 2.0
	var xp := (lebar_total - lebar_pilar) * 0.5
	for s: float in [-1.0, 1.0]:
		# Pilar tembok gading dengan pelipit marun & emas.
		Pembangun.kotak(self, Vector3(lebar_pilar, tinggi - 1.0, tebal), Vector3(s * xp, (tinggi - 1.0) * 0.5, 0), PaletJawa.GADING)
		Pembangun.kotak(self, Vector3(lebar_pilar + 0.2, 0.5, tebal + 0.2), Vector3(s * xp, 0.25, 0), PaletJawa.MARUN, false)
		Pembangun.kotak(self, Vector3(lebar_pilar + 0.1, 0.15, tebal + 0.1), Vector3(s * xp, tinggi - 1.6, 0), PaletJawa.EMAS, false, true)
		# Panel hias marun di muka pilar.
		Pembangun.kotak(self, Vector3(1.6, 2.6, 0.06), Vector3(s * xp, 2.6, tebal * 0.5 + 0.03), PaletJawa.MARUN, false)
		Pembangun.kotak(self, Vector3(1.2, 2.2, 0.07), Vector3(s * xp, 2.6, tebal * 0.5 + 0.05), PaletJawa.EMAS, false, true)
	# Ambang atas.
	Pembangun.kotak(self, Vector3(lebar_total, 1.2, tebal), Vector3(0, tinggi - 0.4, 0), PaletJawa.GADING)
	Pembangun.kotak(self, Vector3(lebar_total + 0.2, 0.15, tebal + 0.2), Vector3(0, tinggi + 0.25, 0), PaletJawa.MARUN, false)
	# Daun pintu kayu marun berpaku emas (tertutup).
	for s: float in [-1.0, 1.0]:
		var xd := s * lebar_pintu * 0.25
		Pembangun.kotak(self, Vector3(lebar_pintu * 0.5 - 0.05, tinggi - 1.6, 0.25), Vector3(xd, (tinggi - 1.6) * 0.5, 0), PaletJawa.MARUN)
		for i in 3:
			for j in 2:
				Pembangun.bola(self, 0.07, Vector3(xd + (j - 0.5) * 0.9, 1.0 + i * 1.2, 0.15), PaletJawa.EMAS, true)
	# Atap tajug dan mustaka.
	Pembangun.limas(self, Vector2(lebar_total + 1.0, tebal + 1.6), Vector2(2.0, 0.6), 2.0,
			Vector3(0, tinggi + 0.32 + 1.0, 0), PaletJawa.GENTENG)
	Pembangun.bola(self, 0.3, Vector3(0, tinggi + 2.55, 0), PaletJawa.EMAS, true)
