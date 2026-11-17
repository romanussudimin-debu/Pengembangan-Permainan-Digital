extends Node3D
## Arena uji tempur (Tahap 1). Jalankan scenes/combat/combat_test.tscn dengan F6.
## Isi: lapangan rumput, 1 checkpoint, perampok pemukul & ketapel yang muncul lagi setelah semuanya kalah.

const PEMUKUL: EnemyData = preload("res://data/combat/enemies/l1/perampok_pemukul.tres")
const KETAPEL: EnemyData = preload("res://data/combat/enemies/l1/perampok_ketapel.tres")

var pemain: Pemain
var kamera: KameraIkut
var _shop_dipakai: bool = false


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
	GameState.state_berubah.connect(func(lama: int, _baru: int) -> void:
		if lama == GameState.State.MINIGAME:
			_shop_dipakai = true)
	GameState.ubah_state(GameState.State.BERMAIN)
	CombatManager.set_active(true)
	spawn_wave()


func spawn_wave() -> void:
	var titik: Array[Vector3] = [Vector3(-4, 0.2, -1), Vector3(4, 0.2, -1), Vector3(0, 0.2, -7)]
	for i in titik.size():
		var e: EnemyBase = EnemyBase.spawn(self, KETAPEL if i == 2 else PEMUKUL, titik[i])
		e.defeated.connect(_on_enemy_defeated)


## Gelombang habis: jeda dengan Lapak Songke (maks. 20 detik atau sampai toko ditutup), lalu gelombang baru.
## (WaveManager lengkap di Tahap 5.)
func _on_enemy_defeated(_e: EnemyBase) -> void:
	await get_tree().create_timer(1.0).timeout
	if CombatManager.alive_enemies() > 0 or CombatManager.shop_available:
		return
	Efek.teks(self, pemain.global_position + Vector3(0, 3, 0), "Gelombang selesai! [B] Lapak Songke")
	CombatManager.set_shop_available(true)
	var sisa: float = 20.0
	while sisa > 0.0 and is_inside_tree():
		await get_tree().create_timer(0.5, false).timeout
		if GameState.sedang(GameState.State.BERMAIN):
			sisa -= 0.5
		if _shop_dipakai and GameState.sedang(GameState.State.BERMAIN):
			break
	_shop_dipakai = false
	CombatManager.set_shop_available(false)
	Efek.teks(self, pemain.global_position + Vector3(0, 3, 0), "Gelombang baru!")
	spawn_wave()


func _exit_tree() -> void:
	CombatManager.set_active(false)
