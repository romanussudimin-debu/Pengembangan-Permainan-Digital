class_name KomponenHP
extends Node
## Komponen nyawa (HP) yang dapat dipasang pada pemain, buta, maupun bos.
## Pemilik memanggil inisialisasi() di _ready() dengan nilai hp_maks miliknya.

signal hp_berubah(hp: int, hp_maks: int)
signal terkena(jumlah: int)
signal habis

var hp_maks: int = 100
var hp: int = 100
var mati: bool = false


func inisialisasi(nilai_maks: int) -> void:
	hp_maks = maxi(nilai_maks, 1)
	hp = hp_maks
	mati = false
	hp_berubah.emit(hp, hp_maks)


## Mengurangi HP. Mengembalikan true bila serangan benar-benar mengenai.
func kurangi(jumlah: int) -> bool:
	if mati or jumlah <= 0:
		return false
	hp = maxi(hp - jumlah, 0)
	hp_berubah.emit(hp, hp_maks)
	terkena.emit(jumlah)
	if hp == 0:
		mati = true
		habis.emit()
	return true


func pulihkan(jumlah: int) -> void:
	if mati:
		return
	hp = mini(hp + jumlah, hp_maks)
	hp_berubah.emit(hp, hp_maks)


func rasio() -> float:
	return float(hp) / float(hp_maks)
