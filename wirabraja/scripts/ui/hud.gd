class_name Hud
extends CanvasLayer
## HUD minimal: HP pemain, jumlah buta tersisa, bar HP bos, pesan menang/kalah.

const WARNA_EMAS := Color(0.95, 0.78, 0.32)
const WARNA_MARUN := Color(0.55, 0.1, 0.12)

@onready var _bar_hp: ProgressBar = %BarHP
@onready var _label_hp: Label = %LabelHP
@onready var _label_musuh: Label = %LabelMusuh
@onready var _panel_bos: Control = %PanelBos
@onready var _nama_bos: Label = %NamaBos
@onready var _bar_bos: ProgressBar = %BarBos
@onready var _pengumuman: Label = %Pengumuman
@onready var _layar_akhir: Control = %LayarAkhir
@onready var _judul_akhir: Label = %JudulAkhir
@onready var _sub_akhir: Label = %SubAkhir

var _tween_pengumuman: Tween
var _gelombang: int = 1
var _total_gelombang: int = 1


func _ready() -> void:
	_gaya_bar(_bar_hp, Color(0.75, 0.12, 0.12))
	_gaya_bar(_bar_bos, Color(0.45, 0.05, 0.3))
	_panel_bos.visible = false
	_layar_akhir.visible = false
	_pengumuman.modulate.a = 0.0
	GameManager.jumlah_musuh_berubah.connect(_saat_musuh_berubah)
	GameManager.state_berubah.connect(_saat_state_berubah)
	GameManager.bos_muncul.connect(_saat_bos_muncul)
	# Sambungkan ke pemain (dicari lewat grup agar HUD tidak bergantung pada path).
	await get_tree().process_frame
	var pemain := get_tree().get_first_node_in_group("pemain") as Pemain
	if pemain:
		pemain.hp_berubah.connect(_saat_hp_berubah)
		_saat_hp_berubah(pemain.komponen_hp.hp, pemain.komponen_hp.hp_maks)
	_saat_musuh_berubah(GameManager.musuh_tersisa)


func tampilkan_pengumuman(teks: String, durasi: float = 3.0) -> void:
	_pengumuman.text = teks
	if _tween_pengumuman and _tween_pengumuman.is_valid():
		_tween_pengumuman.kill()
	_tween_pengumuman = create_tween()
	_tween_pengumuman.tween_property(_pengumuman, "modulate:a", 1.0, 0.25)
	_tween_pengumuman.tween_interval(durasi)
	_tween_pengumuman.tween_property(_pengumuman, "modulate:a", 0.0, 0.6)


func atur_gelombang(ke: int, total: int) -> void:
	_gelombang = ke
	_total_gelombang = total
	_saat_musuh_berubah(GameManager.musuh_tersisa)


func _saat_hp_berubah(hp: int, hp_maks: int) -> void:
	_bar_hp.max_value = hp_maks
	_bar_hp.value = hp
	_label_hp.text = "HP %d / %d" % [hp, hp_maks]


func _saat_musuh_berubah(sisa: int) -> void:
	if GameManager.state == GameManager.State.BERTARUNG:
		_label_musuh.text = "Gelombang %d/%d  ·  Buta tersisa: %d" % [_gelombang, _total_gelombang, sisa]
	elif GameManager.state == GameManager.State.BOS:
		_label_musuh.text = "Kalahkan sang raksasa!"


func _saat_bos_muncul(bos: Node) -> void:
	var b := bos as BosRaksasa
	if b == null:
		return
	_panel_bos.visible = true
	_nama_bos.text = b.nama_tampilan
	_bar_bos.max_value = b.komponen_hp.hp_maks
	_bar_bos.value = b.komponen_hp.hp
	b.hp_berubah.connect(func(h: int, m: int) -> void:
		_bar_bos.max_value = m
		_bar_bos.value = h
	)
	b.fase_berubah.connect(_saat_fase_bos_berubah)
	tampilkan_pengumuman("Ditya Kalamurka: Hantaman Bumi, Serbuan Lurus, Panggil Bala!")


func _saat_fase_bos_berubah(fase: int) -> void:
	if fase == 2:
		_nama_bos.text = "Ditya Kalamurka  —  MURKA!"
		_gaya_bar(_bar_bos, Color(0.85, 0.12, 0.08))
		tampilkan_pengumuman("Ditya Kalamurka murka! Serangannya makin cepat dan ganas!")


func _saat_state_berubah(state_baru: GameManager.State) -> void:
	match state_baru:
		GameManager.State.BOS:
			_label_musuh.text = "Kalahkan sang raksasa!"
		GameManager.State.MENANG:
			_panel_bos.visible = false
			_tampilkan_layar_akhir("MENANG!", "Alun-alun keraton kembali tenteram.\nTekan R untuk mengulang", WARNA_EMAS)
		GameManager.State.KALAH:
			_tampilkan_layar_akhir("KALAH", "Raden Wirabraja gugur di medan laga.\nTekan R untuk mengulang", Color(0.9, 0.25, 0.2))


func _tampilkan_layar_akhir(judul: String, sub: String, warna: Color) -> void:
	_judul_akhir.text = judul
	_judul_akhir.add_theme_color_override("font_color", warna)
	_sub_akhir.text = sub
	_layar_akhir.visible = true
	_layar_akhir.modulate.a = 0.0
	create_tween().tween_property(_layar_akhir, "modulate:a", 1.0, 0.8)


func _gaya_bar(bar: ProgressBar, warna_isi: Color) -> void:
	var latar := StyleBoxFlat.new()
	latar.bg_color = Color(0.08, 0.05, 0.03, 0.8)
	latar.border_color = WARNA_EMAS
	latar.set_border_width_all(2)
	latar.set_corner_radius_all(4)
	var isi := StyleBoxFlat.new()
	isi.bg_color = warna_isi
	isi.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", latar)
	bar.add_theme_stylebox_override("fill", isi)
	bar.show_percentage = false
