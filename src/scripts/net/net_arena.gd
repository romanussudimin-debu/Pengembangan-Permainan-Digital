extends Node3D
## Arena LAN untuk CO-OP (2-4 pemain melawan gelombang + bos level pilihan) dan PvP ARENA
## (1v1 / 2v2 / bebas, slot kosong diisi bot, 10 eliminasi atau skor tertinggi setelah 5 menit).
## Model jaringan: HOST adalah otoritas. Host menjalankan fisika semua karakter (input pemain lain
## datang lewat NetworkInput), AI musuh, dan damage, lalu mengirim snapshot 20x/detik. Klien hanya
## mengirim input dan menampilkan hasil (karakter "boneka" + efek yang ditiru dari siaran host).

const PEMAIN: PackedScene = preload("res://scenes/pemain.tscn")
const RULES: PvpRules = preload("res://data/combat/pvp_rules.tres")
const SNAP_INTERVAL: float = 0.05
const INPUT_INTERVAL: float = 1.0 / 30.0

var mode: String = "coop"
var option: Dictionary = {}
var is_host: bool = true
var local_player: Pemain
var kamera: KameraIkut
var scores: Dictionary = {}  ## nama node pemain -> eliminasi (PvP)
var time_left: float = 0.0
var ended: bool = false
var _snap_t: float = 0.0
var _input_t: float = 0.0
var _waves: WaveManager
var _ui: CanvasLayer
var _score_label: Label
var _end_panel: Control


func _ready() -> void:
	mode = NetworkManager.mode
	option = NetworkManager.option
	is_host = not NetworkManager.is_online() or NetworkManager.is_host()
	var level: int = int(option.get("level", 1))
	var theme: String = ArenaBuilder.theme_for_level(level) if mode == "coop" else str(option.get("arena", "wae_rebo"))
	ArenaBuilder.build(self, theme)
	GameState.level = level if mode == "coop" else 0
	CombatManager.reset_session()
	CombatManager.pvp = mode == "pvp"
	CombatManager.respawn_override = RULES.respawn_time if mode == "pvp" else 0.0
	GameState.ubah_state(GameState.State.BERMAIN)
	_spawn_all_players()
	kamera = KameraIkut.new()
	kamera.target = local_player
	add_child(kamera)
	kamera.current = true
	add_child(CombatHud.new())
	_build_ui()
	CombatManager.set_active(true)
	NetworkManager.left.connect(_on_left)
	if is_host:
		_connect_host_signals()
		if mode == "pvp":
			time_left = RULES.match_time
		else:
			_run_coop(level)
	AudioManager.putar_musik("caci" if mode == "pvp" else "kampung")


func _exit_tree() -> void:
	CombatManager.set_active(false)
	CombatManager.pvp = false
	CombatManager.respawn_override = 0.0
	CombatManager.set_boss(null)


# ------------------------------------------------------------------ pemain

## Urutan slot sama di semua perangkat (diurutkan menurut peer id), lalu bot pengisi slot PvP.
func _spawn_all_players() -> void:
	var ids: Array = NetworkManager.players.keys() if NetworkManager.is_online() else [1]
	ids.sort()
	var my_id: int = NetworkManager.my_id()
	var slot: int = 0
	var format: String = str(option.get("format", "1v1"))
	for id: int in ids:
		var team: int = CombatConst.TEAM_PLAYERS if mode == "coop" else PvpRules.team_for(format, slot)
		var nama: String = NetworkManager.player_name(id) if NetworkManager.is_online() else PlayerProfile.player_name
		var kind: String = "local" if id == my_id else ("remote" if is_host else "puppet")
		_spawn_player("P_%d" % id, id, nama, team, slot, kind)
		slot += 1
	if mode == "pvp":
		var bot_i: int = 0
		while slot < PvpRules.slots(format):
			_spawn_player("B_%d" % bot_i, 1000 + bot_i, RULES.bot_names[bot_i % RULES.bot_names.size()],
					PvpRules.team_for(format, slot), slot, "bot" if is_host else "puppet")
			slot += 1
			bot_i += 1


func _spawn_player(node_name: String, peer: int, nama: String, team: int, slot: int, kind: String) -> void:
	var p: Pemain = PEMAIN.instantiate()
	p.name = node_name
	p.peer_id = peer
	var input: PlayerInput
	match kind:
		"remote":
			input = NetworkInput.new()
		"bot":
			var b := BotInput.new()
			b.skill_level = RULES.bot_skill
			input = b
		_:
			input = KeyboardInput.new()  # lokal; di klien juga dipakai untuk membaca & mengirim input
	input.name = "Input"
	p.add_child(input)
	var team_count: int = PvpRules.team_count(str(option.get("format", "1v1"))) if mode == "pvp" else 1
	p.position = ArenaBuilder.spawn_point(slot, team_count, team - 2 if mode == "pvp" else 0)
	add_child(p)
	p.combat.team = team
	p.combat.hurtbox.team = team
	p.combat.set_player_name(nama)
	CombatManager.respawn_points[p] = p.position
	scores[node_name] = 0
	if kind == "local":
		local_player = p
	if not is_host:
		_make_puppet(p)
	elif mode == "pvp":
		p.combat.health.died.connect(_on_player_died.bind(p))


## Klien: karakter hanya ditampilkan (posisi dari snapshot host), tanpa fisika & tanpa damage lokal.
func _make_puppet(p: Pemain) -> void:
	p.set_physics_process(false)
	p.mesin.set_physics_process(false)
	p.combat.set_physics_process(false)
	p.combat.caster.set_physics_process(false)


# ------------------------------------------------------------------ host: co-op & PvP

func _run_coop(level: int) -> void:
	_waves = WaveManager.new(self)
	add_child(_waves)
	await get_tree().create_timer(2.0, false).timeout
	CombatManager.announce.emit("Co-op: %d pemain" % CombatManager.players.size(), "Bertahan dari 3 gelombang, lalu kalahkan bosnya!")
	await get_tree().create_timer(2.0, false).timeout
	_waves.run_encounter(EncounterTable.build(level))
	await _waves.encounter_finished
	_finish("Kalian menang!", "Semua gelombang dan bos dikalahkan bersama.")


func _on_player_died(killer: Node, victim: Pemain) -> void:
	if ended or not is_instance_valid(victim):
		return
	if killer is Pemain and killer != victim:
		scores[killer.name] = int(scores.get(killer.name, 0)) + 1
		CombatManager.announce.emit("%s mengalahkan %s" % [(killer as Pemain).combat.player_name, victim.combat.player_name], "")
		_send_event("score", {"s": scores})
		if _team_score((killer as Pemain).combat.team) >= RULES.kill_target:
			_finish_pvp()


func _team_score(team: int) -> int:
	var n: int = 0
	for p: Node3D in CombatManager.players:
		if int((p as Pemain).combat.team) == team:
			n += int(scores.get(p.name, 0))
	return n


func _finish_pvp() -> void:
	var best_team: int = -1
	var best: int = -1
	var seri: bool = false
	for p: Node3D in CombatManager.players:
		var t: int = (p as Pemain).combat.team
		var sc: int = _team_score(t)
		if sc > best:
			best = sc
			best_team = t
			seri = false
		elif sc == best and t != best_team:
			seri = true
	var winners: PackedStringArray = []
	for p: Node3D in CombatManager.players:
		if (p as Pemain).combat.team == best_team:
			winners.append((p as Pemain).combat.player_name)
	if seri:
		_finish("Seri!", "Skor sama kuat.")
	else:
		_finish("%s menang!" % " & ".join(winners), "Skor: %d eliminasi" % best)


func _finish(title: String, subtitle: String) -> void:
	if ended:
		return
	ended = true
	var board: Array = _board()
	if NetworkManager.is_online():
		_rpc_game_over.rpc(title, subtitle, board)
	else:
		_rpc_game_over(title, subtitle, board)


func _board() -> Array:
	var rows: Array = []
	for p: Node3D in CombatManager.players:
		var pm: Pemain = p
		rows.append([pm.combat.player_name, int(scores.get(p.name, 0)), pm.combat.team, pm.combat.stats.level])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return rows


func _connect_host_signals() -> void:
	CombatManager.net_event.connect(_send_event)
	CombatManager.announce.connect(func(t: String, s: String) -> void: _send_event("announce", {"t": t, "s": s}))
	CombatManager.boss_changed.connect(func(b: Node3D) -> void: _send_event("boss", {"n": b.name if b else ""}))
	CombatManager.shop_changed.connect(func(v: bool) -> void: _send_event("shop", {"v": v}))
	for p: Node3D in CombatManager.players:
		var pm: Pemain = p
		pm.combat.shot.connect(func(dir: Vector3) -> void: _send_event("pshot", {"n": pm.name, "d": dir}))
		pm.combat.caster.cast.connect(func(i: int) -> void:
			_send_event("pskill", {"n": pm.name, "i": i, "a": pm.combat.aim_dir, "c": pm.combat.caster.last_center}))
	multiplayer.peer_disconnected.connect(func(id: int) -> void:
		var p: Node = get_node_or_null("P_%d" % id)
		if p:
			CombatManager.announce.emit("%s keluar" % (p as Pemain).combat.player_name, "")
			p.queue_free())


# ------------------------------------------------------------------ per frame

func _physics_process(delta: float) -> void:
	if not NetworkManager.is_online():
		_tick_pvp_timer(delta)
		return
	if is_host:
		_tick_pvp_timer(delta)
		_snap_t += delta
		if _snap_t >= SNAP_INTERVAL:
			_snap_t = 0.0
			_rpc_snapshot.rpc(_build_snapshot())
	else:
		_send_input(delta)


func _tick_pvp_timer(delta: float) -> void:
	if mode != "pvp" or ended or not is_host:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		_finish_pvp()


func _process(delta: float) -> void:
	if not is_host:
		_interpolate(delta)
	_update_score_label()


# ------------------------------------------------------------------ klien: kirim input

func _send_input(delta: float) -> void:
	if local_player == null or not is_instance_valid(local_player) or ended:
		return
	var inp: PlayerInput = local_player.input
	inp.update_input(local_player, delta)
	if inp.jump_pressed:
		_rpc_input_event.rpc_id(1, "jump", 0)
	for i in 4:
		if inp.skill_pressed[i]:
			_rpc_input_event.rpc_id(1, "skill", i)
	_input_t += delta
	if _input_t >= INPUT_INTERVAL:
		_input_t = 0.0
		_rpc_input.rpc_id(1, Vector2(inp.move_dir.x, inp.move_dir.z), inp.aim_point, inp.has_aim_point, inp.auto_aim,
				inp.shoot_held, inp.jump_held)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_input(move: Vector2, aim: Vector3, has_aim: bool, auto: bool, shoot: bool, jump_hold: bool) -> void:
	var p: Node = get_node_or_null("P_%d" % multiplayer.get_remote_sender_id())
	if p and (p as Pemain).input is NetworkInput:
		((p as Pemain).input as NetworkInput).apply_state(move, aim, has_aim, auto, shoot, jump_hold)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_input_event(kind: String, index: int) -> void:
	var p: Node = get_node_or_null("P_%d" % multiplayer.get_remote_sender_id())
	if p and (p as Pemain).input is NetworkInput:
		((p as Pemain).input as NetworkInput).push_event(kind, index)


## Klien membeli di Lapak Songke: host yang mengurangi koin & menerapkan upgrade.
func request_buy(item_id: String) -> void:
	_rpc_buy.rpc_id(1, item_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_buy(item_id: String) -> void:
	var p: Node = get_node_or_null("P_%d" % multiplayer.get_remote_sender_id())
	if p == null:
		return
	for item: ShopItem in CombatManager.SHOP_ITEMS:
		if item.id == item_id and CombatManager.stats_for(p).buy(item) == "" and item.max_rank == 0:
			(p as Pemain).combat.use_consumable(item)


# ------------------------------------------------------------------ host -> klien: snapshot

func _build_snapshot() -> Dictionary:
	var pl: Dictionary = {}
	for n: Node3D in CombatManager.players:
		var p: Pemain = n
		var c: CombatPlayer = p.combat
		var st: CombatStats = c.stats
		pl[p.name] = [p.global_position, p.model.rotation.y, c.health.hp, c.health.max_hp, c.is_dead, c.respawn_left,
				c.aim_dir, p.velocity.length() > 0.4, c.caster.energy, PackedFloat32Array(c.caster.cooldowns),
				st.level, st.xp, st.coins, st.ranks, c.health.is_invulnerable()]
	var en: Dictionary = {}
	for n: Node3D in CombatManager.enemies:
		var e: EnemyBase = n
		en[e.name] = [e.global_position, e.model.rotation.y, e.health.hp, e.health.max_hp, int(e.state), e.targetable,
				e.model.visible, e.get("enraged") == true]
	return {"p": pl, "e": en, "w": [CombatManager.shop_available, CombatManager.break_time_left, time_left]}


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_snapshot(snap: Dictionary) -> void:
	var w: Array = snap["w"]
	CombatManager.break_time_left = float(w[1])
	time_left = float(w[2])
	for nama: String in snap["p"]:
		var p: Node = get_node_or_null(nama)
		if p is Pemain:
			_apply_player(p as Pemain, snap["p"][nama])
	for nama: String in snap["e"]:
		var e: Node = get_node_or_null(nama)
		if e is EnemyBase:
			_apply_enemy(e as EnemyBase, snap["e"][nama])


func _apply_player(p: Pemain, d: Array) -> void:
	var c: CombatPlayer = p.combat
	p.set_meta("net_pos", d[0])
	p.set_meta("net_rot", d[1])
	var hp: float = d[2]
	if hp < c.health.hp - 0.5 and not c.is_dead:
		Efek.angka_damage(self, p.global_position + Vector3(0, 2.2, 0), c.health.hp - hp)
		Efek.kilat(p.model)
	c.health.max_hp = d[3]
	c.health.hp = hp
	c.health.invulnerable_time = 0.5 if d[14] else 0.0
	c.health.changed.emit(hp, c.health.max_hp)
	if d[4] and not c.is_dead:
		c._on_died(null)
	elif not d[4] and c.is_dead:
		c.respawn()
	c.respawn_left = d[5]
	c.aim_dir = d[6]
	p.model.mode = "jalan" if d[7] else "idle"
	p.model.kecepatan_jalan = 1.0 if d[7] else 0.0
	c.caster.energy = d[8]
	var cds: PackedFloat32Array = d[9]
	for i in mini(cds.size(), 4):
		c.caster.cooldowns[i] = cds[i]
	if p == local_player:
		var st: CombatStats = c.stats
		var lv_lama: int = st.level
		st.level = d[10]
		st.xp = d[11]
		st.coins = d[12]
		st.ranks = d[13]
		if st.level > lv_lama:
			st.leveled_up.emit(st.level)


func _apply_enemy(e: EnemyBase, d: Array) -> void:
	e.set_meta("net_pos", d[0])
	e.set_meta("net_rot", d[1])
	var hp: float = d[2]
	if hp < e.health.hp - 0.5:
		Efek.angka_damage(self, e.global_position + Vector3(0, 2.3 * e.data.scale, 0), e.health.hp - hp)
		Efek.percikan_kena(self, e.global_position + Vector3(0, 1.0, 0))
		Efek.kilat(e.model)
	e.health.max_hp = d[3]
	e.health.hp = hp
	e.health.changed.emit(hp, e.health.max_hp)
	e.apply_remote_state(int(d[4]))
	e.targetable = d[5]
	e.model.visible = d[6]
	if e is BossBase:
		(e as BossBase).enraged = d[7]


func _interpolate(delta: float) -> void:
	var t: float = clampf(delta * 15.0, 0.0, 1.0)
	for n: Node3D in CombatManager.players + CombatManager.enemies:
		if not is_instance_valid(n) or not n.has_meta("net_pos"):
			continue
		var target: Vector3 = n.get_meta("net_pos")
		n.global_position = target if n.global_position.distance_to(target) > 6.0 else n.global_position.lerp(target, t)
		var model: Node3D = n.get("model")
		if model:
			model.rotation.y = lerp_angle(model.rotation.y, float(n.get_meta("net_rot")), t)


# ------------------------------------------------------------------ kejadian (andal)

func _send_event(kind: String, data: Dictionary) -> void:
	if NetworkManager.is_online() and is_host:
		_rpc_event.rpc(kind, data)


@rpc("authority", "call_remote", "reliable")
func _rpc_event(kind: String, d: Dictionary) -> void:
	match kind:
		"enemy":
			if get_node_or_null(str(d["name"])) == null:
				var e: EnemyBase = EnemyBase.create(load(str(d["path"])) as EnemyData)
				e.name = str(d["name"])
				e.position = d["pos"]
				e.from_wave = true
				add_child(e)
				e.set_physics_process(false)
		"enemy_dead":
			var e2: Node = get_node_or_null(str(d["name"]))
			if e2 is EnemyBase and not (e2 as EnemyBase).is_dead:
				(e2 as EnemyBase)._on_died(null)
		"shot":
			Projectile.spawn(self, d["from"], d["dir"], float(d["speed"]), 0.0, CombatConst.TEAM_ENEMIES, null,
					float(d["range"]), str(d["kind"]))
		"hazard":
			HazardZone.spawn(self, d["pos"], float(d["r"]), 0.0, float(d["dur"]), CombatConst.TEAM_ENEMIES, null, d["tint"])
		"telegraph":
			Telegraph.circle(self, d["pos"], float(d["r"]), float(d["dur"]), d["color"])
		"announce":
			CombatManager.announce.emit(str(d["t"]), str(d["s"]))
		"boss":
			CombatManager.set_boss(get_node_or_null(str(d["n"])) as Node3D if str(d["n"]) != "" else null)
		"shop":
			CombatManager.set_shop_available(bool(d["v"]))
		"pshot":
			var p: Node = get_node_or_null(str(d["n"]))
			if p is Pemain:
				var pm: Pemain = p
				pm.combat.aim_dir = d["d"]
				Projectile.spawn(self, pm.global_position + Vector3(0, CombatConst.COMBAT_HEIGHT, 0) + pm.combat.aim_dir * 0.6,
						pm.combat.aim_dir, CombatConst.ARROW_SPEED, 0.0, pm.combat.team, pm, CombatConst.ARROW_RANGE)
				pm.model.lepas_panah()
				AudioManager.putar_sfx("busur", 0.15)
		"pskill":
			var p2: Node = get_node_or_null(str(d["n"]))
			if p2 is Pemain:
				(p2 as Pemain).combat.caster.play_remote(int(d["i"]), d["a"], d["c"])
		"score":
			scores = d["s"]


@rpc("authority", "call_remote", "reliable")
func _rpc_game_over(title: String, subtitle: String, board: Array) -> void:
	ended = true
	CombatManager.set_active(false)
	AudioManager.putar_sfx("gong")
	_show_end(title, subtitle, board)


# ------------------------------------------------------------------ UI arena

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 13
	add_child(_ui)
	_score_label = Gaya.label("", 10, Gaya.PUTIH)
	_score_label.position = Vector2(170, 6)
	_score_label.size = Vector2(300, 60)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_constant_override("outline_size", 5)
	_ui.add_child(_score_label)


func _update_score_label() -> void:
	if _score_label == null:
		return
	if mode != "pvp":
		_score_label.text = ""
		return
	var d: int = int(ceil(time_left))
	var baris: PackedStringArray = ["Waktu %d:%02d  ·  target %d eliminasi" % [d / 60, d % 60, RULES.kill_target]]
	for n: Node3D in CombatManager.players:
		var p: Pemain = n
		baris.append("%s%s: %d" % ["» " if p == local_player else "", p.combat.player_name, int(scores.get(p.name, 0))])
	_score_label.text = "\n".join(baris)


## Layar menang/selesai: judul, papan skor dengan nama pemain, tombol kembali.
func _show_end(title: String, subtitle: String, board: Array) -> void:
	if _end_panel:
		return
	_end_panel = Gaya.panel_songke(Vector2(150, 60), Vector2(340, 240))
	_ui.add_child(_end_panel)
	var j := Gaya.label(title, 18, Gaya.KUNING)
	j.position = Vector2(0, 12)
	j.size = Vector2(340, 26)
	j.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_panel.add_child(j)
	var s := Gaya.label(subtitle, 10, Gaya.PUTIH)
	s.position = Vector2(0, 42)
	s.size = Vector2(340, 18)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_panel.add_child(s)
	for i in board.size():
		var row: Array = board[i]
		var kolom: String = ("%d eliminasi" % int(row[1])) if mode == "pvp" else ("Level tempur %d" % int(row[3]))
		var l := Gaya.label("%d. %s — %s" % [i + 1, str(row[0]), kolom], 11, Gaya.PUTIH)
		l.position = Vector2(30, 70 + i * 20)
		_end_panel.add_child(l)
	var tombol := Gaya.tombol("Kembali ke Lobi" if is_host and NetworkManager.is_online() else "Ke Menu Utama")
	tombol.position = Vector2(80, 190)
	tombol.custom_minimum_size = Vector2(180, 30)
	tombol.pressed.connect(func() -> void:
		if is_host and NetworkManager.is_online():
			NetworkManager.back_to_lobby.rpc()
		else:
			NetworkManager.leave()
			Transisi.pindah_scene("res://scenes/main_menu.tscn"))
	_end_panel.add_child(tombol)
	if not is_host:
		var info := Gaya.label("Menunggu host memulai lagi...", 8, Color("c9c2b0"))
		info.position = Vector2(0, 224)
		info.size = Vector2(340, 14)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_end_panel.add_child(info)


func _on_left(reason: String) -> void:
	if not is_inside_tree():
		return
	CombatManager.announce.emit("Terputus", reason)
	await get_tree().create_timer(2.0).timeout
	Transisi.pindah_scene("res://scenes/main_menu.tscn")
