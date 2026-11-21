extends Node
## Uji otomatis alur Level 1 (dijalankan headless):
##   godot --headless --path . res://tests/uji_alur.tscn
## Memeriksa: gerak pemain, serangan pemain, serangan buta, transisi ke bos,
## pola Hantaman Bumi, kondisi MENANG, dan kondisi KALAH.

const LEVEL := preload("res://scenes/level/level_1.tscn")

var _gagal: int = 0


func _ready() -> void:
	await _uji_menang()
	await _uji_kalah()
	print("\n==== HASIL: %s (%d gagal) ====" % ["LULUS" if _gagal == 0 else "GAGAL", _gagal])
	get_tree().quit(1 if _gagal > 0 else 0)


func _cek(kondisi: bool, pesan: String) -> void:
	print(("[OK]   " if kondisi else "[GAGAL] ") + pesan)
	if not kondisi:
		_gagal += 1


func _tunggu(detik: float) -> void:
	await get_tree().create_timer(detik, true, true).timeout


func _uji_menang() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	await _tunggu(0.3)
	var pemain := get_tree().get_first_node_in_group("pemain") as Pemain
	_cek(GameManager.state == GameManager.State.BERTARUNG, "state awal BERTARUNG")
	_cek(GameManager.musuh_tersisa == 6, "jumlah buta awal = 6 (didapat %d)" % GameManager.musuh_tersisa)

	# Gerak maju (W) -> pemain bergerak ke -Z.
	var z0 := pemain.global_position.z
	Input.action_press("maju")
	await _tunggu(0.5)
	Input.action_release("maju")
	_cek(pemain.global_position.z < z0 - 1.0, "WASD: pemain bergerak maju (dz=%.2f)" % (pemain.global_position.z - z0))
	_cek(pemain.is_on_floor(), "pemain berdiri di lantai (collision tanah)")

	# Lompat.
	Input.action_press("lompat")
	await _tunggu(0.15)
	Input.action_release("lompat")
	_cek(pemain.global_position.y > 0.3, "Spasi: pemain melompat (y=%.2f)" % pemain.global_position.y)
	await _tunggu(1.0)

	# Serangan pemain mengenai buta di depannya.
	var buta := get_tree().get_nodes_in_group("buta")[0] as Buta
	buta.global_position = pemain.global_position + (-pemain.model.global_basis.z) * 1.6
	await _tunggu(0.1)
	var hp_awal := buta.komponen_hp.hp
	pemain._minta_serang = true
	await _tunggu(0.5)
	_cek(buta.komponen_hp.hp < hp_awal, "klik kiri: serangan mengenai buta (HP %d -> %d)" % [hp_awal, buta.komponen_hp.hp])

	# Buta menyerang balik.
	await _tunggu(3.0)
	_cek(pemain.komponen_hp.hp < pemain.hp_maks, "buta mengejar & menyerang pemain (HP pemain %d)" % pemain.komponen_hp.hp)

	# Kalahkan semua buta.
	pemain.komponen_hp.inisialisasi(9999)
	for b: Node in get_tree().get_nodes_in_group("buta"):
		(b as Buta).terima_serangan(9999, Vector3.FORWARD)
	await _tunggu(0.2)
	_cek(GameManager.musuh_tersisa == 0, "semua buta kalah, sisa = 0")
	_cek(GameManager.state == GameManager.State.BOS, "state berganti ke BOS")
	await _tunggu(2.5)
	var bos := get_tree().get_first_node_in_group("bos") as BosRaksasa
	_cek(bos != null, "bos Ditya Kalamurka muncul")
	if bos == null:
		level.queue_free()
		return
	# Bos kebal selama animasi muncul.
	var hp_bos := bos.komponen_hp.hp
	bos.terima_serangan(50, Vector3.FORWARD)
	_cek(bos.komponen_hp.hp == hp_bos, "bos kebal saat bangkit dari tanah")
	await _tunggu(bos.waktu_muncul)

	# Dekatkan pemain agar bos melakukan Hantaman Bumi.
	pemain.global_position = bos.global_position + Vector3(0, 0, 4.0)
	var hp_p := pemain.komponen_hp.hp
	await _tunggu(0.3)
	_cek(bos.state == BosRaksasa.State.ANCANG_HANTAM, "bos ancang-ancang Hantaman Bumi (penanda tampil: %s)" % bos.penanda_hantam.visible)
	await _tunggu(bos.waktu_ancang + 0.3)
	_cek(pemain.komponen_hp.hp < hp_p, "Hantaman Bumi mengenai pemain (HP %d -> %d)" % [hp_p, pemain.komponen_hp.hp])

	# Kalahkan bos.
	bos.terima_serangan(99999, Vector3.FORWARD)
	await _tunggu(0.2)
	_cek(GameManager.state == GameManager.State.MENANG, "bos kalah -> state MENANG")
	var hud := level.get_node("HUD") as Hud
	_cek(hud.get_node("%LayarAkhir").visible and hud.get_node("%JudulAkhir").text == "MENANG!", "HUD menampilkan teks MENANG")
	level.queue_free()
	await _tunggu(0.2)


func _uji_kalah() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	await _tunggu(0.3)
	_cek(GameManager.state == GameManager.State.BERTARUNG and GameManager.musuh_tersisa == 6, "level baru: state di-reset")
	var pemain := get_tree().get_first_node_in_group("pemain") as Pemain
	for i in 20:
		pemain.terima_serangan(20, Vector3.BACK)
		await _tunggu(pemain.waktu_kebal + 0.05)
		if pemain.state == Pemain.State.MATI:
			break
	_cek(pemain.state == Pemain.State.MATI, "HP pemain habis -> pemain MATI")
	_cek(GameManager.state == GameManager.State.KALAH, "state KALAH")
	var hud := level.get_node("HUD") as Hud
	_cek(hud.get_node("%JudulAkhir").text == "KALAH", "HUD menampilkan teks KALAH + petunjuk R")
	level.queue_free()
