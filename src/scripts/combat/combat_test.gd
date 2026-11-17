extends Node3D
## Arena uji tempur (Tahap 1). Jalankan scenes/combat/combat_test.tscn dengan F6.
## Isi: lapangan rumput, 1 checkpoint, perampok pemukul & ketapel yang muncul lagi setelah semuanya kalah.

const PEMUKUL: EnemyData = preload("res://data/combat/enemies/perampok_pemukul.tres")
const KETAPEL: EnemyData = preload("res://data/combat/enemies/perampok_ketapel.tres")

var pemain: Pemain
var kamera: KameraIkut


func _ready() -> void:
	Dunia.lingkungan(self)
	Dunia.tanah(self, 70.0)
	var lantai := BoxShape3D.new()
	lantai.size = Vector3(70, 1, 70)
	Dunia.badan_statis(self, lantai, Vector3(0, -0.5, 0))
	Dunia.batas_dunia(self, 30.0)
	for p: Vector3 in [Vector3(-8, 0, -6), Vector3(9, 0, -10), Vector3(-12, 0, 8), Vector3(6, 0, 12)]:
		Dunia.pohon(self, p, 1.0)
	var cp := Checkpoint.new()
	cp.position = Vector3(0, 0, 8)
	add_child(cp)
	pemain = preload("res://scenes/pemain.tscn").instantiate()
	add_child(pemain)
	pemain.global_position = Vector3(0, 0.3, 10)
	kamera = KameraIkut.new()
	kamera.target = pemain
	add_child(kamera)
	kamera.current = true
	add_child(CombatHud.new())
	GameState.ubah_state(GameState.State.BERMAIN)
	CombatManager.set_active(true)
	spawn_wave()


func spawn_wave() -> void:
	var titik: Array[Vector3] = [Vector3(-4, 0.2, -1), Vector3(4, 0.2, -1), Vector3(0, 0.2, -7)]
	for i in titik.size():
		var e := EnemyBase.new()
		e.data = KETAPEL if i == 2 else PEMUKUL
		add_child(e)
		e.global_position = titik[i]
		e.home = titik[i]
		e.defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated(_e: EnemyBase) -> void:
	await get_tree().create_timer(1.0).timeout
	if CombatManager.alive_enemies() == 0:
		Efek.teks(self, pemain.global_position + Vector3(0, 3, 0), "Gelombang baru!")
		spawn_wave()


func _exit_tree() -> void:
	CombatManager.set_active(false)
