class_name ShopItem
extends Resource
## Satu barang di toko "Lapak Songke" (data/combat/shop/*.tres).
## Harga naik per tingkat: base_price + price_step x tingkat yang sudah dibeli.

@export var id: String = "mata_panah"
@export var display_name: String = "Mata Panah Besi"
@export_multiline var description: String = "Damage panah +15%"
@export_enum("damage", "fire_rate", "max_hp", "energy_regen", "cooldown", "move_speed", "heal") var stat: String = "damage"
@export var value_per_rank: float = 0.15
@export var max_rank: int = 3  ## 0 = bisa dibeli berulang (barang habis pakai)
@export var base_price: int = 10
@export var price_step: int = 8
@export var color: Color = Color("e8b430")


func price(rank: int) -> int:
	return base_price + price_step * rank
