class_name PvpRules
extends Resource
## Aturan PvP Arena LAN (data/combat/pvp_rules.tres).

@export var kill_target: int = 10  ## menang dengan eliminasi ini lebih dulu
@export var match_time: float = 300.0  ## atau skor tertinggi setelah 5 menit
@export var respawn_time: float = 3.0
@export var arrow_damage_mult: float = 0.6  ## panah biasa antar-pemain (skill memakai pvp_multiplier masing-masing)
@export var bot_names: PackedStringArray = PackedStringArray(["Bot Mbureng", "Bot Mbodol", "Bot Ndereng", "Bot Lawir"])
@export var bot_skill: float = 0.65  ## 0..1 akurasi bot


## Jumlah slot per format; slot kosong diisi bot.
static func slots(format: String) -> int:
	return 2 if format == "1v1" else 4


## Tim untuk slot ke-i: 1v1 & bebas = tiap slot tim sendiri; 2v2 = dua tim.
static func team_for(format: String, slot: int) -> int:
	if format == "2v2":
		return 2 + (slot % 2)
	return 2 + slot


static func team_count(format: String) -> int:
	return 2 if format != "bebas" else 4
