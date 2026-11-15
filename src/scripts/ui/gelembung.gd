class_name Gelembung
extends Node3D
## Gelembung teks di atas kepala tokoh untuk obrolan ringan: pemain tetap bisa bergerak
## (state game tidak berubah). Beberapa baris ditampilkan bergantian; gelembung lalu hilang.
## Panel dialog penuh (DialogManager.mulai_baris) hanya dipakai untuk momen cerita penting.

const DETIK_PER_KATA: float = 0.32
const DETIK_MIN: float = 2.2

var _baris: Array[String] = []
var _indeks: int = 0
var _sisa: float = 0.0
var _label: Label3D
var _latar: MeshInstance3D


## Menampilkan `baris` di atas `target` (mengganti gelembung lama milik target bila ada).
static func pada(target: Node3D, baris: Array, tinggi: float = 3.4) -> Gelembung:
	var lama: Node = target.get_node_or_null("Gelembung")
	var g: Gelembung = lama as Gelembung
	if g == null:
		g = Gelembung.new()
		g.name = "Gelembung"
		target.add_child(g)
	g.position = Vector3(0, tinggi, 0)
	g._mulai(baris)
	return g


func _ready() -> void:
	_latar = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.6, 0.6)
	_latar.mesh = quad
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.06, 0.06, 0.78)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = true
	m.render_priority = 1
	_latar.material_override = m
	add_child(_latar)
	_label = Label3D.new()
	_label.font_size = 34
	_label.pixel_size = 0.005
	_label.outline_size = 8
	_label.modulate = Color("f4ecd8")
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.render_priority = 2
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.width = 480.0
	add_child(_label)


func _mulai(baris: Array) -> void:
	_baris.clear()
	for b: Variant in baris:
		_baris.append(str(b))
	_indeks = 0
	_tampilkan()


func _tampilkan() -> void:
	if _indeks >= _baris.size():
		queue_free()
		return
	if _label == null:
		await ready
	var teks: String = _baris[_indeks]
	_label.text = teks
	var baris_teks: int = maxi(1, ceili(teks.length() / 34.0))
	(_latar.mesh as QuadMesh).size = Vector2(2.6, 0.18 + baris_teks * 0.2)
	_sisa = maxf(DETIK_MIN, teks.split(" ").size() * DETIK_PER_KATA)
	scale = Vector3.ONE * 0.6
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_sisa -= delta
	if _sisa <= 0.0:
		_indeks += 1
		_tampilkan()
