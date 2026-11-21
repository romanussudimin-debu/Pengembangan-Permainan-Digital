class_name BosRaksasa
extends CharacterBody3D
## Ditya Kalamurka — bos raksasa Level 1 (v1.1: tiga pola serangan + dua fase).
##
## Pola serangan:
##   1. HANTAMAN BUMI   : pemain dekat -> lengan terangkat, lingkaran merah membesar,
##                        lalu tanah dihantam (lolos dengan keluar lingkaran atau melompat).
##   2. SERBUAN LURUS   : pemain jauh -> garis merah di tanah, lalu bos menyeruduk lurus.
##                        Bila menabrak pagar/bangunan, bos terhuyung lama (celah emas).
##   3. PANGGIL BALA    : bos meraung dan memanggil buta kecil yang jatuh dari langit.
##
## Fase 2 (HP < 50%): bos MURKA — kulit memerah, lebih cepat, ancang-ancang lebih
## singkat, Hantaman Bumi lebih luas dan dua kali berturut-turut, memanggil lebih banyak buta.
##
## State: MUNCUL -> MENGEJAR -> (ANCANG_HANTAM -> HANTAM) | (ANCANG_SERBU -> SERBU -> TERHUYUNG?)
##        | MEMANGGIL -> PULIH -> MENGEJAR ...   BERUBAH_FASE (sekali)   MATI

signal hp_berubah(hp: int, hp_maks: int)
signal fase_berubah(fase: int)
signal kalah

enum State { MUNCUL, MENGEJAR, ANCANG_HANTAM, HANTAM, ANCANG_SERBU, SERBU, TERHUYUNG,
		MEMANGGIL, PULIH, BERUBAH_FASE, MATI }

@export var nama_tampilan: String = "Ditya Kalamurka"

@export_group("Nyawa & Fase")
@export var hp_maks: int = 650
## Fase 2 dimulai saat rasio HP di bawah nilai ini.
@export_range(0.1, 0.9) var ambang_fase_2: float = 0.5
@export var lama_berubah_fase: float = 1.8

@export_group("Gerak")
@export var kecepatan: float = 2.4
@export var kecepatan_putar: float = 3.0
@export var waktu_muncul: float = 1.8
@export var jeda_antar_serangan: float = 0.8
## Pengali kecepatan & kecepatan ancang-ancang saat fase 2.
@export var pengali_fase_2: float = 1.35

@export_group("Pola 1: Hantaman Bumi")
@export var jarak_pemicu_hantam: float = 5.5
@export var radius_hantaman: float = 6.5
@export var damage_hantaman: int = 30
@export var waktu_ancang_hantam: float = 1.2
@export var kekuatan_dorong_hantam: float = 11.0
@export var tinggi_lolos_lompat: float = 0.5

@export_group("Pola 2: Serbuan Lurus")
@export var jarak_min_serbu: float = 9.0
@export var jeda_serbu: float = 7.0
@export var waktu_ancang_serbu: float = 1.0
@export var kecepatan_serbu: float = 15.0
@export var durasi_serbu_maks: float = 1.5
@export var damage_serbu: int = 25
@export var jarak_kena_serbu: float = 2.4
@export var lama_terhuyung_tabrak: float = 2.2

@export_group("Pola 3: Panggil Bala")
@export var scene_buta_kecil: PackedScene
@export var jeda_panggil: float = 15.0
@export var jeda_panggil_awal: float = 6.0
@export var waktu_ancang_panggil: float = 1.1
@export var jumlah_panggil: int = 2
@export var jumlah_panggil_fase_2: int = 3
@export var maks_panggilan_hidup: int = 4

@export_group("Pulih")
@export var waktu_pulih: float = 1.5

@onready var model: Node3D = $Model
@onready var komponen_hp: KomponenHP = $KomponenHP
@onready var penanda_hantam: MeshInstance3D = $PenandaHantam
@onready var penanda_serbu: Node3D = $PenandaSerbu
@onready var _lengan_kanan: Node3D = get_node_or_null("Model/LenganKanan")
@onready var _lengan_kiri: Node3D = get_node_or_null("Model/LenganKiri")
@onready var _kaki_kanan: Node3D = get_node_or_null("Model/KakiKanan")
@onready var _kaki_kiri: Node3D = get_node_or_null("Model/KakiKiri")

var state: State = State.MUNCUL
var fase: int = 1
var _gravitasi: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _waktu_state: float = 0.0
var _target: Pemain
var _fase_langkah: float = 0.0
var _bahan_penanda: StandardMaterial3D
var _sisa_jeda_serangan: float = 0.0
var _sisa_jeda_serbu: float = 3.0
var _sisa_jeda_panggil: float = 0.0
var _arah_serbu: Vector3 = Vector3.FORWARD
var _serbu_mengenai: bool = false
var _sisa_hantam_beruntun: int = 0
var _panggilan: Array[Node] = []
var _mask_asli: int = 0


func _ready() -> void:
	add_to_group("bos")
	add_to_group("musuh")
	komponen_hp.hp_berubah.connect(func(h: int, m: int) -> void: hp_berubah.emit(h, m))
	komponen_hp.habis.connect(_saat_mati)
	komponen_hp.inisialisasi(hp_maks)
	model.rotation.y += rotation.y
	rotation.y = 0.0
	_mask_asli = collision_mask
	_sisa_jeda_panggil = jeda_panggil_awal
	penanda_hantam.visible = false
	penanda_serbu.visible = false
	_bahan_penanda = penanda_hantam.get_active_material(0) as StandardMaterial3D
	# Bahan kulit & mata diduplikasi agar perubahan warna fase 2 tidak menular
	# ke instance bos berikutnya (setelah level diulang).
	_duplikasi_bahan(model)
	AudioManager.putar_sfx("bos_raung")
	model.position.y = -6.0
	var t := create_tween()
	t.tween_property(model, "position:y", 0.0, waktu_muncul).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravitasi * delta
	_waktu_state += delta
	_sisa_jeda_serangan = maxf(_sisa_jeda_serangan - delta, 0.0)
	_sisa_jeda_serbu = maxf(_sisa_jeda_serbu - delta, 0.0)
	_sisa_jeda_panggil = maxf(_sisa_jeda_panggil - delta, 0.0)
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("pemain") as Pemain
	var bermain := GameManager.sedang_bermain() and _target != null \
			and _target.state != Pemain.State.MATI

	match state:
		State.MUNCUL:
			_rem(delta)
			if _waktu_state >= waktu_muncul:
				_ganti_state(State.MENGEJAR)
		State.MENGEJAR:
			if not bermain:
				_rem(delta)
			else:
				_pilih_tindakan(delta)
		State.ANCANG_HANTAM:
			_rem(delta)
			var k := clampf(_waktu_state / _waktu(waktu_ancang_hantam), 0.0, 1.0)
			penanda_hantam.scale = Vector3(lerpf(0.2, 1.0, k), 1.0, lerpf(0.2, 1.0, k))
			if _bahan_penanda:
				_bahan_penanda.albedo_color.a = 0.25 + 0.35 * absf(sin(_waktu_state * 12.0))
			if _waktu_state >= _waktu(waktu_ancang_hantam):
				_hantam()
		State.HANTAM:
			_rem(delta)
			if _waktu_state >= 0.3:
				if _sisa_hantam_beruntun > 0 and bermain:
					_sisa_hantam_beruntun -= 1
					_mulai_ancang_hantam(0.55)
				else:
					_ganti_state(State.PULIH)
		State.ANCANG_SERBU:
			_rem(delta)
			# Membidik selama 70% waktu ancang-ancang, lalu arah dikunci.
			if _waktu_state < _waktu(waktu_ancang_serbu) * 0.7:
				_arah_serbu = _arah_ke_target()
				_hadap_ke(_arah_serbu, delta * 3.0)
			penanda_serbu.rotation.y = atan2(-_arah_serbu.x, -_arah_serbu.z)
			if _waktu_state >= _waktu(waktu_ancang_serbu):
				_mulai_serbu()
		State.SERBU:
			_proses_serbu()
		State.TERHUYUNG:
			_rem(delta)
			if _waktu_state >= lama_terhuyung_tabrak:
				model.rotation.z = 0.0
				_ganti_state(State.MENGEJAR)
		State.MEMANGGIL:
			_rem(delta)
			if _waktu_state >= _waktu(waktu_ancang_panggil):
				_panggil_bala()
				_ganti_state(State.PULIH)
		State.PULIH:
			_rem(delta)
			if _waktu_state >= waktu_pulih:
				_sisa_jeda_serangan = jeda_antar_serangan
				_ganti_state(State.MENGEJAR)
		State.BERUBAH_FASE:
			_rem(delta)
			if _waktu_state >= lama_berubah_fase:
				_ganti_state(State.MENGEJAR)
		State.MATI:
			_rem(delta)

	move_and_slide()
	_animasi_langkah(delta)


## Dipanggil hitbox pemain. Bos tidak terpental (super armor).
func terima_serangan(jumlah: int, _arah_dorong: Vector3, _kekuatan: float = 0.0) -> void:
	if state == State.MUNCUL or state == State.MATI or state == State.BERUBAH_FASE:
		return
	if not komponen_hp.kurangi(jumlah):
		return
	EfekVisual.kilat_kena(model)
	AudioManager.putar_sfx("pukul", global_position)
	if fase == 1 and not komponen_hp.mati and komponen_hp.rasio() < ambang_fase_2:
		_masuk_fase_2()


# ---------------------------------------------------------------- pemilihan pola

func _pilih_tindakan(delta: float) -> void:
	var arah := _arah_ke_target()
	var jarak := _jarak_datar_ke_target()
	_hadap_ke(arah, delta)
	if _sisa_jeda_serangan <= 0.0:
		if jarak <= jarak_pemicu_hantam:
			_mulai_ancang_hantam(_waktu(waktu_ancang_hantam))
			_sisa_hantam_beruntun = 1 if fase == 2 else 0
			return
		if _sisa_jeda_panggil <= 0.0 and _jumlah_panggilan_hidup() < maks_panggilan_hidup \
				and scene_buta_kecil != null:
			_mulai_panggil()
			return
		if _sisa_jeda_serbu <= 0.0 and jarak >= jarak_min_serbu:
			_mulai_ancang_serbu()
			return
	var laju := kecepatan * (pengali_fase_2 if fase == 2 else 1.0)
	velocity.x = arah.x * laju
	velocity.z = arah.z * laju


# ---------------------------------------------------------------- pola 1: hantaman bumi

func _mulai_ancang_hantam(durasi: float) -> void:
	_ganti_state(State.ANCANG_HANTAM)
	# Sisa waktu ancang-ancang diatur lewat _waktu_state agar hantaman beruntun lebih cepat.
	_waktu_state = _waktu(waktu_ancang_hantam) - durasi
	var r := _radius_hantam()
	penanda_hantam.visible = true
	penanda_hantam.scale = Vector3(0.2, 1.0, 0.2)
	(penanda_hantam.mesh as CylinderMesh).top_radius = r
	(penanda_hantam.mesh as CylinderMesh).bottom_radius = r
	_angkat_lengan(3.1, durasi * 0.7)


func _hantam() -> void:
	_ganti_state(State.HANTAM)
	penanda_hantam.visible = false
	_hantamkan_lengan()
	var r := _radius_hantam()
	AudioManager.putar_sfx("bos_hantam", global_position)
	EfekVisual.gelombang_debu(get_parent(), global_position, r, Color(0.72, 0.6, 0.42, 0.8))
	if _target:
		_target.kamera_rig.guncang(0.25, 0.4)
		var d := _target.global_position - global_position
		var tinggi := d.y
		d.y = 0.0
		var di_udara := _target.sedang_di_udara() and tinggi >= tinggi_lolos_lompat
		if d.length() <= r and not di_udara:
			_target.terima_serangan(damage_hantaman, d.normalized(), kekuatan_dorong_hantam)


func _radius_hantam() -> float:
	return radius_hantaman * (1.25 if fase == 2 else 1.0)


# ---------------------------------------------------------------- pola 2: serbuan lurus

func _mulai_ancang_serbu() -> void:
	_ganti_state(State.ANCANG_SERBU)
	_arah_serbu = _arah_ke_target()
	penanda_serbu.visible = true
	AudioManager.putar_sfx("bos_raung", global_position)
	# Badan condong ke depan sebagai tanda akan menyeruduk.
	var t := create_tween()
	t.tween_property(model, "rotation:x", deg_to_rad(18.0), _waktu(waktu_ancang_serbu) * 0.8)


func _mulai_serbu() -> void:
	_ganti_state(State.SERBU)
	penanda_serbu.visible = false
	_serbu_mengenai = false
	# Selama menyeruduk, bos menembus pemain (kena dihitung dari jarak), hanya tertahan dunia.
	collision_mask = 1


func _proses_serbu() -> void:
	var laju := kecepatan_serbu * (pengali_fase_2 if fase == 2 else 1.0)
	velocity.x = _arah_serbu.x * laju
	velocity.z = _arah_serbu.z * laju
	if not _serbu_mengenai and _target and _jarak_datar_ke_target() <= jarak_kena_serbu:
		_serbu_mengenai = true
		var samping := _target.global_position - global_position
		samping.y = 0.0
		_target.terima_serangan(damage_serbu, (_arah_serbu + samping.normalized()).normalized(), 13.0)
	if is_on_wall() and _waktu_state > 0.1:
		_akhiri_serbu(true)
	elif _waktu_state >= durasi_serbu_maks:
		_akhiri_serbu(false)


func _akhiri_serbu(menabrak: bool) -> void:
	collision_mask = _mask_asli
	velocity.x = 0.0
	velocity.z = 0.0
	_sisa_jeda_serbu = jeda_serbu * (0.65 if fase == 2 else 1.0)
	create_tween().tween_property(model, "rotation:x", 0.0, 0.3)
	if menabrak:
		_ganti_state(State.TERHUYUNG)
		AudioManager.putar_sfx("bos_hantam", global_position)
		EfekVisual.gelombang_debu(get_parent(), global_position, 3.0, Color(0.6, 0.55, 0.5, 0.8))
		if _target:
			_target.kamera_rig.guncang(0.2, 0.35)
		# Terhuyung: badan miring ke samping.
		var t := create_tween()
		t.tween_property(model, "rotation:z", deg_to_rad(12.0), 0.25)
		t.tween_property(model, "rotation:z", deg_to_rad(-8.0), 0.6)
		t.tween_property(model, "rotation:z", 0.0, 0.6)
	else:
		_ganti_state(State.PULIH)


# ---------------------------------------------------------------- pola 3: panggil bala

func _mulai_panggil() -> void:
	_ganti_state(State.MEMANGGIL)
	AudioManager.putar_sfx("bos_raung", global_position)
	_angkat_lengan(2.4, _waktu(waktu_ancang_panggil) * 0.6)


func _panggil_bala() -> void:
	_sisa_jeda_panggil = jeda_panggil * (0.75 if fase == 2 else 1.0)
	var jumlah := jumlah_panggil_fase_2 if fase == 2 else jumlah_panggil
	jumlah = mini(jumlah, maks_panggilan_hidup - _jumlah_panggilan_hidup())
	_turunkan_lengan(0.4)
	AudioManager.putar_sfx("gong")
	for i in jumlah:
		var buta := scene_buta_kecil.instantiate() as Buta
		buta.dihitung_misi = false
		get_parent().add_child(buta)
		var sudut := randf() * TAU
		var pos := global_position + Vector3(cos(sudut), 0.0, sin(sudut)) * randf_range(4.5, 7.0)
		pos.x = clampf(pos.x, -29.0, 29.0)
		pos.z = clampf(pos.z, -29.0, 29.0)
		buta.global_position = pos + Vector3.UP * 7.0
		buta.jadikan_agresif()
		_panggilan.append(buta)
		EfekVisual.gelombang_debu(get_parent(), pos, 2.0, Color(0.3, 0.1, 0.1, 0.7))


func _jumlah_panggilan_hidup() -> int:
	_panggilan = _panggilan.filter(func(n: Node) -> bool:
		return is_instance_valid(n) and n.is_in_group("musuh"))
	return _panggilan.size()


# ---------------------------------------------------------------- fase 2

func _masuk_fase_2() -> void:
	fase = 2
	penanda_hantam.visible = false
	penanda_serbu.visible = false
	collision_mask = _mask_asli
	model.rotation = Vector3(0.0, model.rotation.y, 0.0)
	_ganti_state(State.BERUBAH_FASE)
	fase_berubah.emit(2)
	AudioManager.putar_sfx("bos_raung", global_position)
	if _target:
		_target.kamera_rig.guncang(0.3, 1.0)
	_angkat_lengan(2.9, 0.4)
	get_tree().create_timer(lama_berubah_fase * 0.7).timeout.connect(func() -> void:
		if is_instance_valid(self) and state != State.MATI:
			_turunkan_lengan(0.4)
	)
	# Kulit memerah, mata makin menyala, tubuh sedikit membesar.
	_warnai_murka(model)
	create_tween().tween_property(model, "scale", model.scale * 1.08, lama_berubah_fase * 0.6)
	# Jeda pola diringkas agar fase 2 langsung terasa berbeda.
	_sisa_jeda_panggil = minf(_sisa_jeda_panggil, 3.0)
	_sisa_jeda_serbu = minf(_sisa_jeda_serbu, 2.0)


func _waktu(dasar: float) -> float:
	## Durasi ancang-ancang menjadi lebih singkat pada fase 2.
	return dasar / pengali_fase_2 if fase == 2 else dasar


func _duplikasi_bahan(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var b := mi.get_surface_override_material(0)
		if b:
			mi.set_surface_override_material(0, b.duplicate())
	for anak: Node in node.get_children():
		_duplikasi_bahan(anak)


func _warnai_murka(node: Node) -> void:
	if node is MeshInstance3D:
		var b := (node as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
		if b:
			if b.resource_name.begins_with("kulit"):
				b.albedo_color = b.albedo_color.lerp(Color(0.55, 0.08, 0.06), 0.6)
			elif b.resource_name.begins_with("mata"):
				b.emission_energy_multiplier = 5.0
	for anak: Node in node.get_children():
		_warnai_murka(anak)


# ---------------------------------------------------------------- mati & utilitas

func _saat_mati() -> void:
	_ganti_state(State.MATI)
	penanda_hantam.visible = false
	penanda_serbu.visible = false
	remove_from_group("musuh")
	collision_layer = 0
	collision_mask = _mask_asli
	kalah.emit()
	AudioManager.putar_sfx("bos_raung", global_position, 0.6)
	# Buta panggilan ikut lenyap saat sang raksasa kalah.
	for b: Node in _panggilan:
		if is_instance_valid(b) and b is Buta and b.is_in_group("musuh"):
			(b as Buta).terima_serangan(9999, Vector3.ZERO, 0.0)
	GameManager.lapor_bos_kalah()
	var t := create_tween()
	t.tween_property(model, "rotation:x", deg_to_rad(-88.0), 1.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _ganti_state(baru: State) -> void:
	state = baru
	_waktu_state = 0.0


func _angkat_lengan(sudut: float, durasi: float) -> void:
	var t := create_tween().set_parallel(true)
	if _lengan_kanan:
		t.tween_property(_lengan_kanan, "rotation:x", sudut, durasi)
	if _lengan_kiri:
		t.tween_property(_lengan_kiri, "rotation:x", sudut, durasi)


func _turunkan_lengan(durasi: float) -> void:
	_angkat_lengan(0.0, durasi)


func _hantamkan_lengan() -> void:
	var t := create_tween().set_parallel(true)
	if _lengan_kanan:
		t.tween_property(_lengan_kanan, "rotation:x", 0.6, 0.12).set_ease(Tween.EASE_IN)
	if _lengan_kiri:
		t.tween_property(_lengan_kiri, "rotation:x", 0.6, 0.12).set_ease(Tween.EASE_IN)
	t.chain().tween_interval(0.5)
	if _lengan_kanan:
		t.chain().tween_property(_lengan_kanan, "rotation:x", 0.0, 0.4)
	if _lengan_kiri:
		t.parallel().tween_property(_lengan_kiri, "rotation:x", 0.0, 0.4)


func _arah_ke_target() -> Vector3:
	if _target == null:
		return -model.global_basis.z
	var arah := _target.global_position - global_position
	arah.y = 0.0
	return arah.normalized() if arah.length_squared() > 0.0001 else -model.global_basis.z


func _jarak_datar_ke_target() -> float:
	if _target == null:
		return INF
	var d := _target.global_position - global_position
	d.y = 0.0
	return d.length()


func _rem(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)


func _hadap_ke(arah: Vector3, delta: float) -> void:
	var sudut := atan2(-arah.x, -arah.z)
	model.rotation.y = lerp_angle(model.rotation.y, sudut, clampf(kecepatan_putar * delta, 0.0, 1.0))


func _animasi_langkah(delta: float) -> void:
	if state != State.MENGEJAR:
		return
	var laju_datar := Vector2(velocity.x, velocity.z).length()
	if laju_datar < 0.2:
		return
	_fase_langkah += delta * laju_datar * 1.6
	var ayun := sin(_fase_langkah) * 0.45
	if _kaki_kanan:
		_kaki_kanan.rotation.x = ayun
	if _kaki_kiri:
		_kaki_kiri.rotation.x = -ayun
	if _lengan_kanan:
		_lengan_kanan.rotation.x = -ayun * 0.6
	if _lengan_kiri:
		_lengan_kiri.rotation.x = ayun * 0.6
