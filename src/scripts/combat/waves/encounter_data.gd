class_name EncounterData
extends Resource
## Rangkaian pertempuran satu level cerita: 3 gelombang makin sulit lalu bos.
## Di level cerita setiap gelombang dipicu terpisah di sela tugas cerita (lihat CombatEncounterHost).

@export var level: int = 1
@export var waves: Array[WaveData] = []
@export var break_time: float = 15.0  ## jeda Lapak Songke antar-gelombang (bila beberapa gelombang beruntun)
