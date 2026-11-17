class_name SkillData
extends Resource
## Data satu skill panah (disimpan sebagai .tres di data/combat/skills/).
## Jarak dalam meter (game 3D; 48 px pada rancangan 2D ~ 1,5 m).

@export var id: String = "fire_arrow"
@export var display_name: String = "Panah Api"
@export var key_hint: String = "Q"
@export_enum("fire_arrow", "arrow_rain", "wind_arrow", "ultimate") var kind: String = "fire_arrow"
@export var color: Color = Color("ff8a30")
@export_group("Biaya")
@export var cooldown: float = 6.0
@export var energy_cost: float = 20.0
@export_group("Efek")
@export var damage: float = 40.0
@export var radius: float = 1.5
@export var projectile_speed: float = 22.0
@export var cast_range: float = 14.0
@export var ticks: int = 1  ## jumlah pukulan (Hujan Panah)
@export var tick_interval: float = 0.3
@export var burn_dps: float = 0.0
@export var burn_duration: float = 0.0
@export var slow_factor: float = 1.0  ## 0,5 = kecepatan jadi separuh
@export var slow_duration: float = 0.0
@export var knockback: float = 0.0
@export var invulnerable_time: float = 0.0
@export var pvp_multiplier: float = 0.7  ## pengali damage saat mengenai pemain lain (PvP)
@export var shake: float = 0.2
