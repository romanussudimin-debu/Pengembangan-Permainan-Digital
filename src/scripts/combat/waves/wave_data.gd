class_name WaveData
extends Resource
## Satu gelombang: daftar jenis musuh dan jumlahnya (Normal, 1 pemain).
## Co-op: jumlah x (1 + 0,5 per pemain tambahan).

@export var title: String = "Gelombang 1"
@export var enemies: Array[EnemyData] = []
@export var counts: PackedInt32Array = PackedInt32Array()
@export var spawn_delay: float = 0.6  ## jeda antar-kemunculan (musuh datang bertahap)
@export var boss: EnemyData  ## diisi pada gelombang bos


func total(player_count: int) -> int:
	var n: int = 0
	for i in counts.size():
		n += scaled_count(i, player_count)
	return n + (1 if boss else 0)


func scaled_count(i: int, player_count: int) -> int:
	return int(ceil(counts[i] * (1.0 + 0.5 * maxi(player_count - 1, 0))))
