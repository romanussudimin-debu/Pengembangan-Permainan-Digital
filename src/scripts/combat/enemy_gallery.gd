extends Node3D
## Galeri roster musuh (Tahap 4). Jalankan scenes/combat/enemy_gallery.tscn dengan F6.
## Tombol 1 / 2 / 3: tampilkan 7 jenis musuh Level 1 (Wae Rebo) / 2 (Lingko Lodok) / 3 (Labuan Bajo).
## Tombol 0: hapus semua musuh. Lapak & respawn berfungsi seperti di arena uji.

@export var level: int = 1

var pemain: Pemain
var kamera: KameraIkut
var _label: Label


func _ready() -> void:
	Dunia.lingkungan(self)
	Dunia.tanah(self, 80.0)
	var lantai := BoxShape3D.new()
	lantai.size = Vector3(80, 1, 80)
	Dunia.badan_statis(self, lantai, Vector3(0, -0.5, 0))
	Dunia.batas_dunia(self, 34.0)
	for p: Vector3 in [Vector3(-14, 0, -12), Vector3(14, 0, -14), Vector3(-18, 0, 6), Vector3(18, 0, 4)]:
		Dunia.pohon(self, p, 1.2)
	var cp := Checkpoint.new()
	cp.position = Vector3(0, 0, 12)
	add_child(cp)
	pemain = preload("res://scenes/pemain.tscn").instantiate()
	add_child(pemain)
	pemain.global_position = Vector3(0, 0.3, 14)
	kamera = KameraIkut.new()
	kamera.target = pemain
	add_child(kamera)
	kamera.current = true
	add_child(CombatHud.new())
	var ui := CanvasLayer.new()
	add_child(ui)
	_label = Gaya.label("", 10, Gaya.KUNING)
	_label.position = Vector2(10, 8)
	ui.add_child(_label)
	GameState.ubah_state(GameState.State.BERMAIN)
	CombatManager.set_active(true)
	show_level(level)


func show_level(n: int) -> void:
	level = n
	clear_enemies()
	var roster: Array[EnemyData] = EnemyRoster.for_level(n)
	var names: PackedStringArray = []
	for i in roster.size():
		var a: float = lerpf(-1.1, 1.1, float(i) / maxf(roster.size() - 1, 1))
		var pos := Vector3(sin(a) * 11.0, 0.1, -cos(a) * 11.0)
		EnemyBase.spawn(self, roster[i], pos)
		names.append("%d. %s" % [i + 1, roster[i].display_name])
	_label.text = "Galeri musuh Level %d  (tombol 1/2/3 ganti level, 0 hapus)\n%s" % [n, "\n".join(names)]


func clear_enemies() -> void:
	for e: Node3D in CombatManager.enemies.duplicate():
		e.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_1:
				show_level(1)
			KEY_2:
				show_level(2)
			KEY_3:
				show_level(3)
			KEY_0:
				clear_enemies()


func _exit_tree() -> void:
	CombatManager.set_active(false)
