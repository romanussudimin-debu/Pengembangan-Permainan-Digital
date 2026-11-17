class_name EnemyRoster
## Daftar jenis musuh per level cerita (7 per level; bos ditambah di Tahap 5).
## Urutan = urutan perkenalan dari gelombang ke gelombang.

const LEVEL_1: Array[EnemyData] = [
	preload("res://data/combat/enemies/l1/perampok_pemukul.tres"),
	preload("res://data/combat/enemies/l1/perampok_ketapel.tres"),
	preload("res://data/combat/enemies/l1/perampok_jaring.tres"),
	preload("res://data/combat/enemies/l1/kera_pencuri.tres"),
	preload("res://data/combat/enemies/l1/perampok_perisai.tres"),
	preload("res://data/combat/enemies/l1/ular_hijau.tres"),
	preload("res://data/combat/enemies/l1/lebah_hutan.tres"),
]
const LEVEL_2: Array[EnemyData] = [
	preload("res://data/combat/enemies/l2/tikus_sawah.tres"),
	preload("res://data/combat/enemies/l2/babi_hutan_kecil.tres"),
	preload("res://data/combat/enemies/l2/pipit_perusak.tres"),
	preload("res://data/combat/enemies/l2/pencuri_padi.tres"),
	preload("res://data/combat/enemies/l2/ular_sawah.tres"),
	preload("res://data/combat/enemies/l2/perampok_pembakar.tres"),
	preload("res://data/combat/enemies/l2/kerbau_mengamuk.tres"),
]
const LEVEL_3: Array[EnemyData] = [
	preload("res://data/combat/enemies/l3/komodo_muda.tres"),
	preload("res://data/combat/enemies/l3/kepiting_bakau.tres"),
	preload("res://data/combat/enemies/l3/penyelundup_pencuri.tres"),
	preload("res://data/combat/enemies/l3/kawanan_kalong.tres"),
	preload("res://data/combat/enemies/l3/penyelundup_pemanah.tres"),
	preload("res://data/combat/enemies/l3/ubur_ubur.tres"),
	preload("res://data/combat/enemies/l3/monyet_ekor_panjang.tres"),
]


static func for_level(level: int) -> Array[EnemyData]:
	match level:
		2:
			return LEVEL_2
		3:
			return LEVEL_3
	return LEVEL_1
