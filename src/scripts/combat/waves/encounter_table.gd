class_name EncounterTable
## Tabel gelombang per level (Normal, 1 pemain) — satu tempat untuk diseimbangkan.
## Jenis musuh baru diperkenalkan bertahap dari gelombang ke gelombang; gelombang ke-4 = bos.

const R := "res://data/combat/enemies/"

## level -> daftar gelombang: [judul, [[path musuh, jumlah], ...], path bos atau ""]
const TABLE: Dictionary = {
	1: [
		["Perampok datang dari hutan!", [["l1/perampok_pemukul", 3], ["l1/perampok_ketapel", 2]], ""],
		["Mereka membawa jaring dan kera!", [["l1/perampok_pemukul", 2], ["l1/perampok_jaring", 2], ["l1/kera_pencuri", 2]], ""],
		["Serangan dari semak!", [["l1/perampok_perisai", 2], ["l1/perampok_ketapel", 2], ["l1/ular_hijau", 2], ["l1/lebah_hutan", 2]], ""],
		["Ketua Perampok Songke", [], "boss/ketua_perampok"],
	],
	2: [
		["Hama menyerbu sawah!", [["l2/tikus_sawah", 6], ["l2/babi_hutan_kecil", 2]], ""],
		["Pencuri padi beraksi!", [["l2/pipit_perusak", 3], ["l2/pencuri_padi", 2], ["l2/ular_sawah", 2]], ""],
		["Lingko diserang dari segala arah!", [["l2/perampok_pembakar", 2], ["l2/kerbau_mengamuk", 1], ["l2/babi_hutan_kecil", 2],
				["l2/tikus_sawah", 4]], ""],
		["Babi Hutan Raksasa", [], "boss/babi_hutan_raksasa"],
	],
	3: [
		["Bahaya di pesisir!", [["l3/komodo_muda", 2], ["l3/kepiting_bakau", 2], ["l3/penyelundup_pencuri", 1]], ""],
		["Senja tiba: kalong dan penyelundup!", [["l3/kawanan_kalong", 3], ["l3/penyelundup_pemanah", 2], ["l3/monyet_ekor_panjang", 2]], ""],
		["Kepungan terakhir!", [["l3/ubur_ubur", 2], ["l3/komodo_muda", 2], ["l3/penyelundup_pemanah", 1], ["l3/kepiting_bakau", 1],
				["l3/kawanan_kalong", 2]], ""],
		["Komodo Raksasa", [], "boss/komodo_raksasa"],
	],
}


static func build(level: int) -> EncounterData:
	var enc := EncounterData.new()
	enc.level = level
	for w: Array in TABLE.get(level, TABLE[1]):
		var wave := WaveData.new()
		wave.title = str(w[0])
		var counts: Array[int] = []
		for entry: Array in w[1]:
			wave.enemies.append(load(R + str(entry[0]) + ".tres") as EnemyData)
			counts.append(int(entry[1]))
		wave.counts = PackedInt32Array(counts)
		if str(w[2]) != "":
			wave.boss = load(R + str(w[2]) + ".tres") as EnemyData
		enc.waves.append(wave)
	return enc
