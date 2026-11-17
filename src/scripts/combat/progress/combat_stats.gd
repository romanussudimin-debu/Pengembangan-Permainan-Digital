class_name CombatStats
extends RefCounted
## Progres tempur satu pemain selama satu level cerita: level tempur (maks. 10), XP, koin,
## dan tingkat upgrade dari Lapak Songke. Disimpan di CombatManager (bukan di node pemain)
## agar bertahan saat pindah scene dan siap dimiliki banyak pemain (kunci = peer id).

signal xp_changed(xp: int, needed: int, level: int)
signal leveled_up(level: int)
signal coins_changed(coins: int)
signal upgrades_changed

const MAX_LEVEL: int = 10
const HP_PER_LEVEL: float = 8.0
const DAMAGE_PER_LEVEL: float = 0.05
const LEVEL_UP_HEAL: float = 0.3

var level: int = 1
var xp: int = 0  ## XP menuju level berikutnya
var total_xp: int = 0
var coins: int = 0
var coins_earned: int = 0
var ranks: Dictionary = {}  ## id barang -> tingkat yang dibeli


static func xp_needed(lv: int) -> int:
	return 20 + 15 * (lv - 1)


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	total_xp += amount
	if level >= MAX_LEVEL:
		xp_changed.emit(xp, xp_needed(level), level)
		return
	xp += amount
	while level < MAX_LEVEL and xp >= xp_needed(level):
		xp -= xp_needed(level)
		level += 1
		leveled_up.emit(level)
	if level >= MAX_LEVEL:
		xp = 0
	xp_changed.emit(xp, xp_needed(level), level)


func add_coins(amount: int) -> void:
	coins += amount
	if amount > 0:
		coins_earned += amount
	coins_changed.emit(coins)


func rank(item_id: String) -> int:
	return int(ranks.get(item_id, 0))


## Coba beli; mengembalikan "" bila berhasil, atau alasan gagal.
func buy(item: ShopItem) -> String:
	var r: int = rank(item.id)
	if item.max_rank > 0 and r >= item.max_rank:
		return "Sudah maksimal"
	var p: int = item.price(r)
	if coins < p:
		return "Koin kurang"
	coins -= p
	if item.max_rank > 0:
		ranks[item.id] = r + 1
	coins_changed.emit(coins)
	upgrades_changed.emit()
	return ""


func _sum(stat_name: String) -> float:
	var total: float = 0.0
	for item: ShopItem in CombatManager.SHOP_ITEMS:
		if item.stat == stat_name:
			total += item.value_per_rank * rank(item.id)
	return total


# ------------------------------------------------------------------ stat akhir

func damage_multiplier() -> float:
	return (1.0 + DAMAGE_PER_LEVEL * (level - 1)) * (1.0 + _sum("damage"))


func fire_interval_multiplier() -> float:
	return 1.0 / (1.0 + _sum("fire_rate"))


func max_hp() -> float:
	return CombatConst.PLAYER_MAX_HP + HP_PER_LEVEL * (level - 1) + _sum("max_hp")


func energy_regen_multiplier() -> float:
	return 1.0 + _sum("energy_regen")


func cooldown_multiplier() -> float:
	return maxf(1.0 - _sum("cooldown"), 0.5)


func move_speed_multiplier() -> float:
	return 1.0 + _sum("move_speed")
