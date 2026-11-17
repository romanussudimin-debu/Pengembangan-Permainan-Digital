class_name StoryCombat
extends Node
## Menyisipkan pertempuran ke level cerita: gelombang ke-i dijalankan di sela tugas cerita,
## lalu cerita berlanjut (callback). Gelombang yang sudah dimenangkan tidak diulang selama
## sesi level yang sama (CombatManager.story_waves_done). Setelah gelombang: jeda Lapak Songke.
## Tempur menunggu dialog/kartu tertutup dulu agar tidak bertabrakan dengan cerita.

const SHOP_BREAK: float = 25.0

var level: int = 1
var encounter: EncounterData
var manager: WaveManager
var world: Node3D
var hud: CombatHud
var busy: bool = false


func _init(target_world: Node3D = null, story_level: int = 1, forbidden: Array[Vector4] = []) -> void:
	world = target_world
	level = story_level
	encounter = EncounterTable.build(story_level)
	manager = WaveManager.new(target_world)
	manager.forbidden_zones = forbidden


func _ready() -> void:
	add_child(manager)
	hud = CombatHud.new()
	add_child(hud)


func is_done(index: int) -> bool:
	return CombatManager.story_waves_done.has("%d:%d" % [level, index])


## Jalankan gelombang `index` (0..2 biasa, 3 = bos) lalu panggil `on_done`.
func run(index: int, on_done: Callable = Callable()) -> void:
	while busy and is_inside_tree():
		await get_tree().create_timer(0.25, false).timeout  # tunggu gelombang lain selesai dulu
	if not is_inside_tree():
		return
	if index >= encounter.waves.size() or is_done(index):
		if on_done.is_valid():
			on_done.call_deferred()
		return
	busy = true
	while is_inside_tree() and (not GameState.sedang(GameState.State.BERMAIN) or DialogManager.aktif):
		await get_tree().create_timer(0.25, false).timeout
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.6, false).timeout
	manager.start_wave(encounter.waves[index], index, encounter.waves.size() - 1)
	await manager.wave_cleared
	CombatManager.story_waves_done["%d:%d" % [level, index]] = true
	CombatManager.set_active(false)
	busy = false
	Analitik.catat("gelombang_menang", {"gelombang": index + 1})
	if index < encounter.waves.size() - 1:
		_shop_break()
	if on_done.is_valid():
		on_done.call()


func _shop_break() -> void:
	CombatManager.set_shop_available(true)
	var t: float = SHOP_BREAK
	while t > 0.0 and is_inside_tree() and not CombatManager.active:
		CombatManager.break_time_left = t
		await get_tree().create_timer(0.5, false).timeout
		if GameState.sedang(GameState.State.BERMAIN):
			t -= 0.5
	CombatManager.break_time_left = 0.0
	CombatManager.set_shop_available(false)
