class_name CombatConst
## Konstanta sistem tempur di satu tempat: lapisan fisika, tim, dan pengali kesulitan.
## (Stat musuh/skill/gelombang disimpan sebagai Resource .tres di data/combat/.)

# Lapisan fisika (bit). Lapisan 1 = dunia (Dunia.LAPISAN_DUNIA), 2 = badan pemain, 4 = area Interaktif.
const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMY: int = 8
const LAYER_HURTBOX: int = 16

# Tim: serangan hanya mengenai tim lain. Di PvP setiap pemain/regu memakai tim sendiri (>= 2).
const TEAM_PLAYERS: int = 0
const TEAM_ENEMIES: int = 1

## Pengali kesulitan (tabel GDD). aim_assist: 1 = kuat, 0,5 = sedang, 0 = mati.
const DIFFICULTY: Dictionary = {
	"mudah": {"enemy_hp": 0.7, "enemy_damage": 0.6, "respawn": 3.0, "aim_assist": 1.0},
	"normal": {"enemy_hp": 1.0, "enemy_damage": 1.0, "respawn": 5.0, "aim_assist": 0.5},
	"sulit": {"enemy_hp": 1.4, "enemy_damage": 1.3, "respawn": 8.0, "aim_assist": 0.0},
}

# Panah dasar pemain
const PLAYER_MAX_HP: float = 120.0
const ARROW_DAMAGE: float = 22.0
const ARROW_SPEED: float = 26.0
const ARROW_RANGE: float = 18.0
const FIRE_INTERVAL: float = 0.42
const AIM_ASSIST_RANGE: float = 16.0
const AIM_ASSIST_ANGLE: float = 0.45  ## radian; bantuan "kuat" menarik bidikan dalam sudut ini
const INVULNERABLE_AFTER_RESPAWN: float = 2.0
const COMBAT_HEIGHT: float = 1.25  ## tinggi badan (titik bidik & asal panah)
