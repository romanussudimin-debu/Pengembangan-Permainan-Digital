extends Node
## Alat bantu dokumentasi: mengambil tangkapan layar Level 1 dari beberapa sudut.
## Jalankan (butuh tampilan/GPU):  godot --path . res://tests/tangkap_layar.tscn -- <folder_keluaran>

const LEVEL := preload("res://scenes/level/level_1.tscn")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var keluar := args[0] if args.size() > 0 else "user://"
	var level := LEVEL.instantiate()
	add_child(level)
	await _tunggu(1.5)
	await _simpan(keluar + "/ss_awal.png")
	var pemain := get_tree().get_first_node_in_group("pemain") as Pemain
	# Dekat dengan buta.
	pemain.global_position = Vector3(0, 0, 14)
	await _tunggu(1.2)
	await _simpan(keluar + "/ss_buta.png")
	# Kamera umum dari atas.
	var kam := Camera3D.new()
	add_child(kam)
	kam.global_position = Vector3(30, 32, 40)
	kam.look_at(Vector3(0, 0, -6))
	kam.current = true
	await _tunggu(0.3)
	await _simpan(keluar + "/ss_arena.png")
	kam.current = false
	pemain.get_node("KameraRig/SpringArm3D/Camera3D").current = true
	# Bos.
	pemain.komponen_hp.inisialisasi(9999)
	for b: Node in get_tree().get_nodes_in_group("buta"):
		(b as Buta).terima_serangan(9999, Vector3.FORWARD)
	pemain.global_position = Vector3(0, 0, 1)
	await _tunggu(4.5)
	await _simpan(keluar + "/ss_bos.png")
	var bos := get_tree().get_first_node_in_group("bos") as BosRaksasa
	pemain.global_position = bos.global_position + Vector3(0, 0, 4.5)
	await _tunggu(0.9)
	await _simpan(keluar + "/ss_hantam.png")
	bos.terima_serangan(99999, Vector3.FORWARD)
	await _tunggu(1.5)
	await _simpan(keluar + "/ss_menang.png")
	get_tree().quit()


func _tunggu(d: float) -> void:
	await get_tree().create_timer(d).timeout


func _simpan(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("disimpan: ", path)
