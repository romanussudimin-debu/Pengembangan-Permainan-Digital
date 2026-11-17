extends CanvasLayer
## Kontrol layar sentuh untuk ponsel/tablet (APK Android atau browser HP).
## Joystick virtual di kiri (jalan) dan tombol di kanan (lompat, interaksi, jeda).
## Saat BERTEMPUR tombol kanan berganti ala MOBA: TEMBAK besar (bidik otomatis), 3 skill + ultimate
## dengan sapuan cooldown (seret tombol skill untuk membidik manual), dan LOMPAT untuk menghindar.
## Hanya tampil di perangkat sentuh dan hanya saat state BERMAIN; selebihnya
## (dialog, teka-teki, mini-game, menu) cukup diketuk karena sentuhan ditiru sebagai klik mouse.

const PUSAT_JOYSTICK := Vector2(78, 282)
const JARI_JOYSTICK: float = 46.0
const JARI_KENOP: float = 20.0
const ZONA_MATI: float = 0.18
## Tombol: id -> {pusat, jari-jari, label, aksi (Input Map) atau fungsi (sakelar)}.
## Diletakkan agar tidak menutupi panel HUD (kiri atas) dan panel tujuan level (kanan atas).
const TOMBOL: Dictionary = {
	"lompat": {"pusat": Vector2(584, 304), "jari": 32.0, "label": "LOMPAT", "aksi": "lompat"},
	"interaksi": {"pusat": Vector2(510, 280), "jari": 30.0, "label": "BICARA", "aksi": "interaksi"},
	"kartu": {"pusat": Vector2(612, 240), "jari": 18.0, "label": "KARTU", "aksi": "jeda"},
	"jeda": {"pusat": Vector2(612, 24), "jari": 16.0, "label": "II", "aksi": "jeda"},
	"suara": {"pusat": Vector2(24, 108), "jari": 15.0, "label": "SUARA", "fungsi": "suara"},
	"teks": {"pusat": Vector2(24, 146), "jari": 15.0, "label": "TEKS", "fungsi": "teks"},
}

## Tata letak tempur (lingkaran di sekitar tombol TEMBAK). "skill" = indeks skill (seret = bidik manual).
const TOMBOL_TEMPUR: Dictionary = {
	"tembak": {"pusat": Vector2(566, 284), "jari": 34.0, "label": "TEMBAK"},
	"skill_1": {"pusat": Vector2(490, 324), "jari": 20.0, "label": "Q", "aksi": "skill_1", "skill": 0},
	"skill_2": {"pusat": Vector2(494, 264), "jari": 20.0, "label": "E", "aksi": "skill_2", "skill": 1},
	"skill_3": {"pusat": Vector2(530, 216), "jari": 20.0, "label": "R", "aksi": "skill_3", "skill": 2},
	"ultimate": {"pusat": Vector2(596, 206), "jari": 24.0, "label": "ULT", "aksi": "ultimate", "skill": 3},
	"lompat": {"pusat": Vector2(618, 338), "jari": 18.0, "label": "LOMPAT", "aksi": "lompat"},
	"jeda": {"pusat": Vector2(612, 24), "jari": 16.0, "label": "II", "aksi": "jeda"},
}
const JARAK_BIDIK: float = 16.0  ## seret tombol skill sejauh ini = mode bidik manual

var tembak_ditekan: bool = false  ## dibaca KeyboardInput (tombol TEMBAK sentuh)
var aim_override: Vector2 = Vector2.ZERO  ## arah bidik manual dari seret skill (layar; y+ = ke bawah)
var aim_override_until: int = 0  ## ms; bidik manual berlaku sampai waktu ini
var aktif_di_perangkat: bool = false
var _jari_joystick: int = -1  ## indeks sentuhan yang memegang joystick (-1 = tidak ada)
var _kenop := Vector2.ZERO  ## posisi kenop relatif pusat
var _jari_tombol: Dictionary = {}  ## indeks sentuhan -> nama aksi
var _kanvas: Node2D
var _seret_awal: Dictionary = {}  ## indeks sentuhan -> posisi awal (tombol skill)
var _seret_kini: Dictionary = {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	aktif_di_perangkat = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") \
		or OS.has_feature("web_android") or OS.has_feature("web_ios")
	_kanvas = Node2D.new()
	add_child(_kanvas)
	_kanvas.draw.connect(_gambar)
	GameState.state_berubah.connect(_saat_state_berubah)
	CombatManager.combat_changed.connect(func(_a: bool) -> void:
		_lepas_semua()
		_kanvas.queue_redraw())
	_atur_tampil()


func _tombol() -> Dictionary:
	return TOMBOL_TEMPUR if CombatManager.active else TOMBOL


func _process(_delta: float) -> void:
	if visible and CombatManager.active:
		_kanvas.queue_redraw()  # sapuan cooldown skill


func _saat_state_berubah(_lama: int, _baru: int) -> void:
	_atur_tampil()


func _atur_tampil() -> void:
	var tampil: bool = aktif_di_perangkat and GameState.sedang(GameState.State.BERMAIN)
	if not tampil:
		_lepas_semua()
	visible = tampil
	_kanvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var sentuh: InputEventScreenTouch = _kanvas.make_input_local(event)
		if sentuh.pressed:
			_mulai_sentuh(sentuh.index, sentuh.position)
		else:
			_akhiri_sentuh(sentuh.index)
	elif event is InputEventScreenDrag:
		var geser: InputEventScreenDrag = _kanvas.make_input_local(event)
		if geser.index == _jari_joystick:
			_gerak_joystick(geser.position)
		elif _seret_awal.has(geser.index):
			_seret_kini[geser.index] = geser.position
			_kanvas.queue_redraw()


func _mulai_sentuh(indeks: int, pos: Vector2) -> void:
	var daftar: Dictionary = _tombol()
	for id: String in daftar:
		var t: Dictionary = daftar[id]
		if pos.distance_to(t["pusat"]) <= float(t["jari"]) + 8.0:
			_jari_tombol[indeks] = id
			if t.has("fungsi"):
				_jalankan_sakelar(str(t["fungsi"]))
			elif id == "tembak":
				tembak_ditekan = true
			elif t.has("skill"):
				_seret_awal[indeks] = pos  # skill dilepas saat jari diangkat (bisa diseret untuk membidik)
				_seret_kini[indeks] = pos
			else:
				_kirim_aksi(str(t["aksi"]), true)
			_kanvas.queue_redraw()
			get_viewport().set_input_as_handled()
			return
	# Joystick "mengambang": sentuhan di separuh kiri layar mana pun menggerakkan tokoh.
	if _jari_joystick == -1 and pos.x < 320.0 and pos.y > 90.0:
		_jari_joystick = indeks
		_gerak_joystick(pos)
		get_viewport().set_input_as_handled()


func _akhiri_sentuh(indeks: int) -> void:
	if indeks == _jari_joystick:
		_jari_joystick = -1
		_kenop = Vector2.ZERO
		_terapkan_arah()
	elif _jari_tombol.has(indeks):
		var id: String = _jari_tombol[indeks]
		var t: Dictionary = _tombol().get(id, {})
		if id == "tembak":
			tembak_ditekan = false
		elif t.has("skill"):
			var seret: Vector2 = Vector2(_seret_kini.get(indeks, Vector2.ZERO)) - Vector2(_seret_awal.get(indeks, Vector2.ZERO))
			if seret.length() > JARAK_BIDIK:
				aim_override = seret.normalized()
				aim_override_until = Time.get_ticks_msec() + 250
			_kirim_aksi(str(t["aksi"]), true)
			get_tree().create_timer(0.06).timeout.connect(_kirim_aksi.bind(str(t["aksi"]), false))
			_seret_awal.erase(indeks)
			_seret_kini.erase(indeks)
		elif t.has("aksi"):
			_kirim_aksi(str(t["aksi"]), false)
		_jari_tombol.erase(indeks)
	_kanvas.queue_redraw()


func _gerak_joystick(pos: Vector2) -> void:
	_kenop = (pos - PUSAT_JOYSTICK).limit_length(JARI_JOYSTICK)
	_terapkan_arah()
	_kanvas.queue_redraw()


## Kekuatan aksi analog dibaca Input.get_vector() di Pemain.arah_input().
func _terapkan_arah() -> void:
	var v: Vector2 = _kenop / JARI_JOYSTICK
	if v.length() < ZONA_MATI:
		v = Vector2.ZERO
	_atur_sumbu("kiri", -v.x)
	_atur_sumbu("kanan", v.x)
	_atur_sumbu("maju", -v.y)
	_atur_sumbu("mundur", v.y)


func _atur_sumbu(aksi: String, kekuatan: float) -> void:
	if kekuatan > 0.0:
		Input.action_press(aksi, clampf(kekuatan, 0.0, 1.0))
	else:
		Input.action_release(aksi)


## Mengirim InputEventAction supaya _unhandled_input (Pemain, MenuJeda) ikut menerimanya.
func _kirim_aksi(aksi: String, ditekan: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = aksi
	ev.pressed = ditekan
	ev.strength = 1.0 if ditekan else 0.0
	Input.parse_input_event(ev)


## Tombol sakelar: bisukan suara, atau tampilkan/sembunyikan teks dialog.
func _jalankan_sakelar(fungsi: String) -> void:
	match fungsi:
		"suara":
			AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
		"teks":
			DialogManager.tampilkan_teks = not DialogManager.tampilkan_teks


func _label_tombol(id: String) -> String:
	if id == "suara" and AudioServer.is_bus_mute(0):
		return "BISU"
	return str(_tombol()[id]["label"])


func _lepas_semua() -> void:
	for indeks: int in _jari_tombol:
		for daftar: Dictionary in [TOMBOL, TOMBOL_TEMPUR]:
			var t: Dictionary = daftar.get(_jari_tombol[indeks], {})
			if t.has("aksi") and not t.has("skill"):
				_kirim_aksi(str(t["aksi"]), false)
	_jari_tombol.clear()
	_seret_awal.clear()
	_seret_kini.clear()
	tembak_ditekan = false
	_jari_joystick = -1
	_kenop = Vector2.ZERO
	for aksi: String in ["kiri", "kanan", "maju", "mundur"]:
		Input.action_release(aksi)


func _gambar() -> void:
	if not visible:
		return
	var putih := Color(1, 1, 1, 0.35)
	_kanvas.draw_circle(PUSAT_JOYSTICK, JARI_JOYSTICK, Color(0, 0, 0, 0.3))
	_kanvas.draw_arc(PUSAT_JOYSTICK, JARI_JOYSTICK, 0.0, TAU, 40, putih, 2.0)
	_kanvas.draw_circle(PUSAT_JOYSTICK + _kenop, JARI_KENOP, Color(Gaya.KUNING, 0.6))
	var ditekan: Array = _jari_tombol.values()
	var daftar: Dictionary = _tombol()
	var caster: SkillCaster = _caster_lokal() if CombatManager.active else null
	for id: String in daftar:
		var t: Dictionary = daftar[id]
		var pusat: Vector2 = t["pusat"]
		var jari: float = t["jari"]
		var menyala: bool = ditekan.has(id) or (id == "teks" and DialogManager.tampilkan_teks)
		_kanvas.draw_circle(pusat, jari, Color(Gaya.MERAH, 0.8) if menyala else Color(0, 0, 0, 0.45))
		# Cincin bermotif songke: kuning di luar, merah di dalam
		_kanvas.draw_arc(pusat, jari, 0.0, TAU, 32, Color(Gaya.KUNING, 0.9), 2.0)
		_kanvas.draw_arc(pusat, jari - 3.0, 0.0, TAU, 32, Color(Gaya.MERAH, 0.7), 1.0)
		var label: String = _label_tombol(id)
		var ukuran: int = 9 if jari > 20.0 else 7
		if t.has("skill"):
			ukuran = 12  # huruf skill besar agar mudah dikenali
		var lebar: float = ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
		_kanvas.draw_string(ThemeDB.fallback_font, pusat + Vector2(-lebar / 2.0, ukuran * 0.35), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, Gaya.PUTIH)
		if caster and t.has("skill"):
			_gambar_cooldown(pusat, jari, caster, int(t["skill"]))
	# Garis bidik saat menyeret tombol skill
	for indeks: int in _seret_awal:
		var awal: Vector2 = _seret_awal[indeks]
		var kini: Vector2 = _seret_kini.get(indeks, awal)
		if kini.distance_to(awal) > JARAK_BIDIK:
			var arah: Vector2 = (kini - awal).normalized()
			_kanvas.draw_line(awal, awal + arah * 70.0, Color(Gaya.KUNING, 0.9), 3.0)
			_kanvas.draw_circle(awal + arah * 70.0, 6.0, Color(Gaya.MERAH, 0.9))


## Sapuan gelap melingkar = sisa cooldown; redup bila energi kurang.
func _gambar_cooldown(pusat: Vector2, jari: float, caster: SkillCaster, i: int) -> void:
	var cd: float = caster.cooldown_ratio(i)
	if cd > 0.0:
		var poly := PackedVector2Array([pusat])
		for k in 25:
			var a: float = -PI / 2.0 + TAU * cd * k / 24.0
			poly.append(pusat + Vector2(cos(a), sin(a)) * jari)
		if poly.size() >= 3:
			_kanvas.draw_colored_polygon(poly, Color(0, 0, 0, 0.6))
	elif caster.energy < caster.skills[i].energy_cost:
		_kanvas.draw_circle(pusat, jari, Color(0, 0, 0.2, 0.5))


func _caster_lokal() -> SkillCaster:
	for p: Node3D in CombatManager.players:
		if p is Pemain and (p as Pemain).input is KeyboardInput:
			return (p as Pemain).combat.caster
	return null
