class_name BossBandit
extends BossBase
## BOS Level 1: Ketua Perampok Songke.
##  - Lempar jaring (marah: 3 jaring menyebar)
##  - Sabetan berputar (lingkaran merah di sekitarnya) bila pemain dekat
##  - Memanggil 2 Perampok Pemukul (jeda panjang; maks. 4 antek hidup)
## Fase marah: lebih cepat, jaring tiga, jeda serangan lebih singkat.

const MINION: EnemyData = preload("res://data/combat/enemies/l1/perampok_pemukul.tres")
const NET_SHOT: String = "net"


func _choose_attack() -> String:
	if _minion_cd <= 0.0 and _minions_alive() < 4:
		return "summon"
	if target and _flat_distance(target.global_position) < 3.2:
		return "swing"
	return "nets"


func _minions_alive() -> int:
	var n: int = 0
	for e: Node3D in CombatManager.enemies:
		if e != self and is_instance_valid(e) and e.get("data") == MINION:
			n += 1
	return n


func _run_attack(kind: String, t: float, delta: float) -> bool:
	_move(Vector3.ZERO, delta)
	match kind:
		"summon":
			if t < 0.05:
				_anim_windup(0.6)
				Efek.teks(get_parent(), global_position + Vector3(0, 3.6, 0), "Anak buah, serbu!", Color("ff8a60"))
			if t >= 0.6 and not _attack_done:
				_attack_done = true
				_minion_cd = 16.0
				summon(MINION, 2)
				_anim_strike()
			return t >= 1.0
		"swing":
			if t < 0.05:
				Telegraph.circle(get_parent(), global_position, 3.0, 0.8)
				_anim_windup(0.8)
			if t >= 0.8 and not _attack_done:
				_attack_done = true
				_anim_strike()
				area_hit(global_position, 3.0, damage * 1.3, 7.0)
				Efek.cincin(get_parent(), global_position, 3.0, Color(1, 0.7, 0.3, 0.9))
			return t >= 1.2
		_:
			face_target(delta)
			if t < 0.05:
				_anim_windup(0.7)
			if t >= 0.7 and not _attack_done:
				_attack_done = true
				_anim_strike()
				var spread: Array[float] = [0.0]
				if enraged:
					spread = [-0.35, 0.0, 0.35]
				var from: Vector3 = global_position + Vector3(0, 1.6, 0)
				var to: Vector3 = target.global_position + Vector3(0, CombatConst.COMBAT_HEIGHT, 0)
				for a: float in spread:
					var dir: Vector3 = (to - from).rotated(Vector3.UP, a)
					var p := Projectile.spawn(get_parent(), from, dir, 12.0, damage * 0.5, CombatConst.TEAM_ENEMIES,
							self, 18.0, NET_SHOT)
					p.skill = hit_effect
				AudioManager.putar_sfx("cambuk")
			return t >= 1.1
