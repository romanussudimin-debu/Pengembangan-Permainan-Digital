extends Node3D
## Level 1 — Alun-Alun Lor Keraton Kasunanan Surakarta (v1.1).
##
## Musuh dibagi menjadi beberapa GELOMBANG (anak-anak node "Musuh"). Hanya
## gelombang pertama yang aktif di awal; gelombang berikutnya diturunkan dari
## langit setelah gelombang sebelumnya habis. Setelah semua buta kalah,
## bos Ditya Kalamurka bangkit di depan pendopo.
## Level juga mengatur musik: pertempuran -> bos -> sunyi + sfx menang/kalah.

@export var scene_bos: PackedScene
## Jeda (detik) antara buta terakhir kalah dan bos muncul.
@export var jeda_munculnya_bos: float = 2.0
@export var jeda_antar_gelombang: float = 2.0
## Pengumuman untuk tiap gelombang (indeks 0 = gelombang pertama).
@export var pengumuman_gelombang: PackedStringArray = [
	"Gelombang 1: Buta Prajurit dan Buta Kilat menyerbu!",
	"Gelombang 2: awas lemparan batu Buta Pelempar!",
	"Gelombang 3: Buta Gempal datang, pukulannya berat!",
]

@onready var _titik_bos: Marker3D = $TitikMunculBos
@onready var _hud: Hud = $HUD
@onready var _wadah_musuh: Node3D = $Musuh

var _bos_sudah_muncul: bool = false
var _gelombang: Array[Node3D] = []
var _indeks_gelombang: int = 0
var _menunggu_gelombang: bool = false


func _ready() -> void:
	GameManager.state_berubah.connect(_saat_state_berubah)
	GameManager.jumlah_musuh_berubah.connect(_saat_musuh_berubah)
	# Semua buta (semua gelombang) dihitung sebagai target misi.
	var jumlah_buta := 0
	for g: Node in _wadah_musuh.get_children():
		_gelombang.append(g as Node3D)
		for b: Node in g.get_children():
			if b is Buta and (b as Buta).dihitung_misi:
				jumlah_buta += 1
	# Lepaskan gelombang ke-2 dst. dari pohon scene sampai waktunya tiba.
	for i in range(1, _gelombang.size()):
		_wadah_musuh.remove_child(_gelombang[i])
	GameManager.mulai_level(jumlah_buta)
	AudioManager.putar_musik("pertempuran")
	_hud.atur_gelombang(1, _gelombang.size())
	if _gelombang.size() > 0:
		_hud.tampilkan_pengumuman(_teks_gelombang(0))


func _exit_tree() -> void:
	# Gelombang yang belum sempat diturunkan tidak ikut terhapus otomatis.
	for g: Node3D in _gelombang:
		if is_instance_valid(g) and not g.is_inside_tree():
			g.queue_free()


func _saat_musuh_berubah(_sisa: int) -> void:
	if GameManager.state != GameManager.State.BERTARUNG or _menunggu_gelombang:
		return
	if _indeks_gelombang + 1 >= _gelombang.size():
		return
	if _hitung_buta_hidup() == 0:
		_menunggu_gelombang = true
		get_tree().create_timer(jeda_antar_gelombang).timeout.connect(_turunkan_gelombang_berikutnya)


func _turunkan_gelombang_berikutnya() -> void:
	_menunggu_gelombang = false
	if not is_inside_tree() or GameManager.state != GameManager.State.BERTARUNG:
		return
	_indeks_gelombang += 1
	var g := _gelombang[_indeks_gelombang]
	_wadah_musuh.add_child(g)
	# Buta "melompat turun" dari ketinggian dan langsung memburu pemain.
	for b: Node in g.get_children():
		if b is Buta:
			var buta := b as Buta
			buta.global_position += Vector3.UP * 8.0
			buta.jadikan_agresif()
	AudioManager.putar_sfx("gong")
	_hud.atur_gelombang(_indeks_gelombang + 1, _gelombang.size())
	_hud.tampilkan_pengumuman(_teks_gelombang(_indeks_gelombang))


func _saat_state_berubah(state_baru: GameManager.State) -> void:
	match state_baru:
		GameManager.State.BOS:
			if not _bos_sudah_muncul:
				_bos_sudah_muncul = true
				AudioManager.hentikan_musik(1.5)
				_hud.tampilkan_pengumuman("Bumi bergetar... Ditya Kalamurka bangkit!")
				# Koneksi ke timer otomatis putus bila level dimuat ulang sebelum waktunya.
				get_tree().create_timer(jeda_munculnya_bos).timeout.connect(_munculkan_bos)
		GameManager.State.MENANG:
			AudioManager.hentikan_musik(0.5)
			AudioManager.putar_sfx("menang")
		GameManager.State.KALAH:
			AudioManager.hentikan_musik(0.5)
			AudioManager.putar_sfx("kalah")


func _munculkan_bos() -> void:
	if scene_bos == null or not is_inside_tree():
		push_error("Level 1: scene_bos belum diisi.")
		return
	var bos := scene_bos.instantiate() as Node3D
	add_child(bos)
	bos.global_position = _titik_bos.global_position
	AudioManager.putar_musik("bos", 0.5)
	GameManager.lapor_bos_muncul(bos)


func _hitung_buta_hidup() -> int:
	var n := 0
	for m: Node in get_tree().get_nodes_in_group("musuh"):
		if m is Buta and (m as Buta).dihitung_misi:
			n += 1
	return n


func _teks_gelombang(i: int) -> String:
	return pengumuman_gelombang[i] if i < pengumuman_gelombang.size() else "Gelombang %d!" % (i + 1)
