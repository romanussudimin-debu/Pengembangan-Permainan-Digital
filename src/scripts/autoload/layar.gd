extends CanvasLayer
## Pengaturan tampilan untuk HP & tablet (APK Android dan browser HP):
## - Layar penuh otomatis saat layar disentuh (browser hanya mengizinkannya TEPAT di dalam
##   penanganan sentuhan, jadi di web dipasang pendengar JavaScript sendiri), lalu orientasi
##   dikunci ke landscape. Bila dipasang sebagai aplikasi (PWA), game sudah layar penuh.
## - Bila perangkat dipegang tegak (potret), muncul petunjuk untuk memutar ke landscape.

## Pendengar sentuhan di halaman web: meminta layar penuh + kunci landscape selama
## window.jejakPentiPenuh bernilai true (diatur dari GDScript lewat layar_penuh()).
const JS_LAYAR_PENUH: String = """
(function () {
	if (window.jejakPentiLayar) { return; }
	window.jejakPentiLayar = true;
	var hp = /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent);
	window.jejakPentiPenuh = hp;
	function minta() {
		if (!window.jejakPentiPenuh || document.fullscreenElement || document.webkitFullscreenElement) { return; }
		var el = document.documentElement;
		var req = el.requestFullscreen || el.webkitRequestFullscreen;
		if (!req) { return; }
		try {
			var hasil = req.call(el, { navigationUI: 'hide' });
			if (hasil && hasil.then) {
				hasil.then(function () {
					if (screen.orientation && screen.orientation.lock) { screen.orientation.lock('landscape').catch(function () {}); }
				}).catch(function () {});
			}
		} catch (e) {}
	}
	document.addEventListener('touchend', minta, { passive: true });
	document.addEventListener('click', minta);
})();
"""

var seluler: bool = false
var _sudah_penuh: bool = false
var _tirai: Control
var _waktu: float = 0.0


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	seluler = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	if OS.has_feature("web"):
		JavaScriptBridge.eval(JS_LAYAR_PENUH, true)
	_bangun_tirai()
	get_tree().root.size_changed.connect(_cek_arah)
	_cek_arah()


func _bangun_tirai() -> void:
	_tirai = Control.new()
	_tirai.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tirai.mouse_filter = Control.MOUSE_FILTER_STOP
	_tirai.visible = false
	add_child(_tirai)
	var gelap := ColorRect.new()
	gelap.color = Color(0.06, 0.05, 0.05, 0.96)
	gelap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tirai.add_child(gelap)
	var ikon := Control.new()
	ikon.set_anchors_preset(Control.PRESET_FULL_RECT)
	ikon.draw.connect(_gambar_ikon.bind(ikon))
	_tirai.add_child(ikon)
	var teks := Gaya.label("Putar perangkatmu ke posisi LANDSCAPE\nuntuk bermain Jejak Penti", 14, Gaya.KUNING)
	teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teks.position = Vector2(0, 236)
	teks.size = Vector2(640, 60)
	_tirai.add_child(teks)


## Ikon HP yang berputar dari tegak ke mendatar.
func _gambar_ikon(c: Control) -> void:
	var sudut: float = -PI / 2.0 * clampf(fmod(_waktu, 2.4) / 1.2, 0.0, 1.0)
	c.draw_set_transform(Vector2(320, 150), sudut, Vector2.ONE)
	c.draw_rect(Rect2(-30, -52, 60, 104), Gaya.PUTIH, false, 4.0)
	c.draw_rect(Rect2(-24, -42, 48, 80), Color(Gaya.MERAH, 0.6))
	c.draw_circle(Vector2(0, 45), 3.0, Gaya.PUTIH)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _process(delta: float) -> void:
	if _tirai.visible:
		_waktu += delta
		_tirai.get_child(1).queue_redraw()


func _cek_arah() -> void:
	var ukuran: Vector2i = DisplayServer.window_get_size()
	_tirai.visible = seluler and ukuran.y > ukuran.x


func _input(event: InputEvent) -> void:
	# APK Android: layar penuh pada sentuhan pertama (di web ditangani pendengar JavaScript)
	if seluler and not OS.has_feature("web") and not _sudah_penuh and event is InputEventScreenTouch and event.is_pressed():
		_sudah_penuh = true
		layar_penuh(true)


## Masuk/keluar layar penuh. Di web: keluar langsung, masuk pada sentuhan/klik berikutnya
## (aturan browser), dan pilihan ini diingat oleh pendengar JavaScript.
func layar_penuh(aktif: bool) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.jejakPentiPenuh = %s;" % ("true" if aktif else "false"), true)
		if not aktif:
			JavaScriptBridge.eval("if (document.fullscreenElement && document.exitFullscreen) { document.exitFullscreen(); }", true)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if aktif else DisplayServer.WINDOW_MODE_WINDOWED)


func sedang_penuh() -> bool:
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("!!(document.fullscreenElement || document.webkitFullscreenElement)", true))
	var m: int = DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
