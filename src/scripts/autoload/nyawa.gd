extends CanvasLayer
## SISTEM NYAWA (semua level): 5 nyawa (Normal) / 3 nyawa (Sulit), diisi penuh saat level dimulai.
## -1 nyawa saat salah pilih pengecoh, jatuh, salah jawab, atau gagal tantangan:
## suara gagal + layar berkedip merah + kamera bergetar; ikon hati di HUD pecah (hud.gd).
## Nyawa habis = hanya TANTANGAN YANG SEDANG DIMAINKAN yang diulang (bukan level):
## panel "Nyawa habis, coba lagi" + tombol Ulangi, nyawa diisi penuh kembali.
## Level/mini-game mendaftarkan tantangan aktif lewat atur_tantangan(nama, cara_mengulang).

signal berubah(sisa: int, selisih: int)
signal habis(tantangan: String)
signal tantangan_berubah(nama: String)  ## (Prestasi)
signal dikurangi(penyebab: String, tantangan: String)  ## didengar Analitik

var sisa: int = 5
var hilang_di_level: int = 0  ## jumlah nyawa yang hilang sejak level dimulai (untuk bintang/analytics)
var pengecoh_di_level: int = 0  ## salah pilih orang/benda pengecoh sejak level dimulai (Analitik)
var diulang_di_level: int = 0  ## tantangan yang diulang karena nyawa habis sejak level dimulai (Analitik)
var _tantangan: String = ""
var _ulang: Callable = Callable()
var _kilat: ColorRect
var _panel: Control
var _label_tantangan: Label
var _tombol_ulangi: Button


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_kilat = ColorRect.new()
	_kilat.color = Color(0.85, 0.05, 0.05)
	_kilat.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kilat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kilat.modulate.a = 0.0
	add_child(_kilat)
	_bangun_panel()
	GameState.level_dimulai.connect(_reset_hitungan_level)


func maks() -> int:
	return 3 if GameState.mode_sulit else 5


## Dipanggil saat level (atau destinasi Level 3) dimulai.
func isi_penuh(level_baru: bool = true) -> void:
	sisa = maks()
	if level_baru:
		hilang_di_level = 0
	berubah.emit(sisa, 0)


## Mendaftarkan tantangan yang sedang dimainkan dan cara mengulangnya bila nyawa habis.
func atur_tantangan(nama: String, cara_mengulang: Callable = Callable()) -> void:
	_tantangan = nama
	_ulang = cara_mengulang
	tantangan_berubah.emit(nama)


func tantangan_aktif() -> String:
	return _tantangan


## -1 nyawa. `penyebab` dicatat (misalnya "jatuh", "salah jawab", "pengecoh").
## `pengecoh` = true bila nyawa hilang karena salah memilih orang/benda pengecoh (dihitung Analitik).
func kurangi(penyebab: String, pengecoh: bool = false) -> void:
	if _panel.visible or sisa <= 0:
		return
	sisa -= 1
	hilang_di_level += 1
	if pengecoh:
		pengecoh_di_level += 1
	dikurangi.emit(penyebab, _tantangan)
	berubah.emit(sisa, -1)
	AudioManager.putar_sfx("salah")
	_teks_di_pemain("-1", Color("ff5a4a"))
	get_tree().call_group("kamera_ikut", "guncang", 0.45)
	_kilat.modulate.a = 0.45
	create_tween().tween_property(_kilat, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_OUT)
	if penyebab != "":
		print_verbose("Nyawa -1 (%s) di tantangan '%s'" % [penyebab, _tantangan])
	if sisa <= 0:
		_tampilkan_habis()


## +1 nyawa (penambah nyawa di dunia). Mengembalikan false bila nyawa sudah penuh.
func tambah() -> bool:
	if sisa >= maks():
		return false
	sisa += 1
	berubah.emit(sisa, 1)
	AudioManager.putar_sfx("ambil")
	_teks_di_pemain("+1", Color("6ad07a"))
	return true


func sedang_habis() -> bool:
	return _panel.visible


# ------------------------------------------------------------------ panel nyawa habis

func _bangun_panel() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	add_child(_panel)
	var gelap := ColorRect.new()
	gelap.color = Color(0.1, 0.02, 0.02, 0.78)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(gelap)
	var kotak := Gaya.panel_songke(Vector2(170, 92), Vector2(300, 170))
	_panel.add_child(kotak)
	var hati := Control.new()
	hati.position = Vector2(0, 0)
	hati.size = Vector2(300, 60)
	hati.draw.connect(func() -> void: GambarHati.gambar(hati, Vector2(150, 34), 16.0, false, true))
	kotak.add_child(hati)
	var judul := Gaya.label("Nyawa habis, coba lagi!", 16, Gaya.KUNING)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.size = Vector2(300, 24)
	judul.position = Vector2(0, 62)
	kotak.add_child(judul)
	_label_tantangan = Gaya.label("", 9, Gaya.PUTIH)
	_label_tantangan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_tantangan.size = Vector2(300, 16)
	_label_tantangan.position = Vector2(0, 90)
	kotak.add_child(_label_tantangan)
	_tombol_ulangi = Gaya.tombol("Ulangi")
	_tombol_ulangi.custom_minimum_size = Vector2(150, 30)
	_tombol_ulangi.position = Vector2(75, 120)
	_tombol_ulangi.pressed.connect(_ulangi)
	kotak.add_child(_tombol_ulangi)


func _tampilkan_habis() -> void:
	_label_tantangan.text = ("Tantangan: %s (nyawa diisi penuh lagi)" % _tantangan) if _tantangan != "" else "Nyawa diisi penuh lagi"
	_panel.visible = true
	get_tree().paused = true
	habis.emit(_tantangan)
	_tombol_ulangi.call_deferred("grab_focus")


func _ulangi() -> void:
	diulang_di_level += 1
	_panel.visible = false
	get_tree().paused = false
	isi_penuh(false)
	if DialogManager.aktif:
		DialogManager.tutup_paksa()
	if _ulang.is_valid():
		_ulang.call()


## Penghitung analitik direset hanya saat level benar-benar dimulai (bukan saat tantangan/level diulang).
func _reset_hitungan_level(_n: int) -> void:
	pengecoh_di_level = 0
	diulang_di_level = 0


## Teks melayang di atas kepala pemain (bila ada pemain di scene aktif).
func _teks_di_pemain(isi: String, warna: Color) -> void:
	var adegan: Node = get_tree().current_scene
	var p: Variant = adegan.get("pemain") if adegan else null
	if p is Node3D and is_instance_valid(p) and (p as Node3D).is_inside_tree():
		Efek.teks(adegan, (p as Node3D).global_position + Vector3(0, 2.4, 0), isi, warna)
