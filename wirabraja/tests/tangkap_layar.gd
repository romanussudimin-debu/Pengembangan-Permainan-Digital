extends Node
## Alat bantu dokumentasi: mengambil tangkapan layar narasi dan Level 1.
## Jalankan (butuh tampilan/GPU):  godot --path . res://tests/tangkap_layar.tscn -- <folder_keluaran>

const LEVEL := preload("res://scenes/level/level_1.tscn")
const NARASI := preload("res://scenes/ui/narasi_pembuka.tscn")

var _keluar: String = "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_keluar = args[0] if args.size() > 0 else "user://"
	# Narasi pembuka.
	var n := NARASI.instantiate()
	n.pindah_otomatis = false
	add_child(n)
	await _tunggu(2.6)
	await _simpan("ss_narasi_kayon.png")
	await _tunggu(2.4)
	n._lanjut()
	await _tunggu(0.1)
	n._lanjut()
	await _tunggu(0.6)
	n._lanjut()
	await _tunggu(0.1)
	await _simpan("ss_narasi.png")
	n.queue_free()
	await _tunggu(0.2)

	var level := LEVEL.instantiate()
	add_child(level)
	await _tunggu(1.5)
	await _simpan("ss_awal.png")
	var pemain := get_tree().get_first_node_in_group("pemain") as Pemain
	pemain.komponen_hp.inisialisasi(99999)
	# Pameran varian: susun keempat jenis buta berjajar di depan pemain.
	for b: Node in get_tree().get_nodes_in_group("buta"):
		b.queue_free()
	await _tunggu(0.1)
	var jenis := ["buta", "buta_kilat", "buta_gempal", "buta_pelempar"]
	for i in jenis.size():
		var bt := (load("res://scenes/enemies/%s.tscn" % jenis[i]) as PackedScene).instantiate() as Buta
		level.add_child(bt)
		bt.global_position = Vector3(-6.0 + i * 4.0, 0, 8)
		bt.model.rotation.y = PI
		bt.set_physics_process(false)
	pemain.global_position = Vector3(0, 0, 18)
	await _tunggu(0.6)
	await _simpan("ss_varian.png")
	for b: Node in get_tree().get_nodes_in_group("buta"):
		b.queue_free()
	await _tunggu(0.2)
	# Gelombang dimajukan sampai bos.
	GameManager.musuh_tersisa = 1
	GameManager.lapor_buta_kalah()
	pemain.global_position = Vector3(0, 0, 4)
	await _tunggu(4.5)
	var bos := get_tree().get_first_node_in_group("bos") as BosRaksasa
	bos._sisa_jeda_panggil = 99.0
	bos._sisa_jeda_serbu = 0.0
	pemain.global_position = bos.global_position + Vector3(3, 0, 13.0)
	await _tunggu(0.75)
	await _simpan("ss_serbu.png")
	await _tunggu(3.5)
	bos._sisa_jeda_panggil = 0.0
	bos._sisa_jeda_serbu = 99.0
	bos._sisa_jeda_serangan = 0.0
	pemain.global_position = bos.global_position + Vector3(0, 0, 7.5)
	await _tunggu(2.2)
	await _simpan("ss_panggil.png")
	bos.terima_serangan(bos.komponen_hp.hp - int(bos.komponen_hp.hp_maks * 0.45), Vector3.FORWARD)
	await _tunggu(1.4)
	await _simpan("ss_murka.png")
	await _tunggu(1.0)
	pemain.global_position = bos.global_position + Vector3(0, 0, 4.5)
	bos._sisa_jeda_serangan = 0.0
	await _tunggu(0.6)
	await _simpan("ss_hantam.png")
	bos.terima_serangan(99999, Vector3.FORWARD)
	await _tunggu(1.6)
	await _simpan("ss_menang.png")
	AudioManager.hentikan_semua()
	await _tunggu(0.2)
	get_tree().quit()


func _tunggu(d: float) -> void:
	await get_tree().create_timer(d).timeout


func _simpan(nama: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_keluar + "/" + nama)
	print("disimpan: ", nama)
