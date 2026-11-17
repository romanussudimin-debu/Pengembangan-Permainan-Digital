class_name EnemyData
extends Resource
## Data satu jenis musuh (disimpan sebagai .tres di data/combat/enemies/).
## Stat dasar untuk kesulitan Normal & 1 pemain; pengali kesulitan/co-op diterapkan saat spawn.

@export var id: String = "perampok_pemukul"
@export var display_name: String = "Perampok Pemukul"
@export_group("Tampilan")
@export_enum("bandit", "komodo") var model_kind: String = "bandit"
@export var body_color: Color = Color("3a3030")  ## baju
@export var accent_color: Color = Color("6a1a1a")  ## ikat kepala/selempang
@export var scale: float = 1.0
@export_group("Stat")
@export var max_hp: float = 60.0
@export var move_speed: float = 2.6
@export var damage: float = 12.0
@export var detect_range: float = 18.0
@export var knockback_resist: float = 0.0  ## 0 = mudah terdorong, 1 = tidak terdorong
@export_group("Serangan")
@export_enum("melee", "ranged") var attack_type: String = "melee"
@export var attack_range: float = 1.6
@export var attack_windup: float = 0.55  ## ancang-ancang (isyarat untuk menghindar)
@export var attack_cooldown: float = 1.4
@export var projectile_speed: float = 14.0
@export var projectile_kind: String = "stone"
@export var keep_distance: float = 0.0  ## > 0 = menjaga jarak dari pemain (penembak)
@export_group("Hadiah")
@export var coins: int = 3
@export var xp: int = 10
