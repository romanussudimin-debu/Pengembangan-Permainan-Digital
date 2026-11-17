class_name EnemyData
extends Resource
## Data satu jenis musuh (disimpan sebagai .tres di data/combat/enemies/l1..l3/).
## Stat dasar untuk kesulitan Normal & 1 pemain; pengali kesulitan/co-op diterapkan saat spawn.
## `behavior` memilih kelas turunan EnemyBase (lihat EnemyBase.create).

@export var id: String = "perampok_pemukul"
@export var display_name: String = "Perampok Pemukul"
@export_multiline var hint: String = ""  ## kiat singkat untuk pemain (ditampilkan saat jenis baru muncul)
@export_group("Tampilan")
@export_enum("bandit", "komodo", "bird", "monkey", "snake", "bees", "boar", "rat", "bat", "crab", "jellyfish",
		"buffalo") var model_kind: String = "bandit"
@export var body_color: Color = Color("3a3030")  ## baju / warna tubuh hewan
@export var accent_color: Color = Color("6a1a1a")  ## ikat kepala / kaki / corak
@export var scale: float = 1.0
@export var bar_height: float = 2.7
@export_group("Perilaku")
@export_enum("basic", "charger", "thief", "shield", "flyer", "ambush", "boss_bandit", "boss_boar", "boss_komodo")
var behavior: String = "basic"
@export var max_hp: float = 60.0
@export var move_speed: float = 2.6
@export var damage: float = 12.0
@export var detect_range: float = 18.0
@export var knockback_resist: float = 0.0  ## 0 = mudah terdorong, 1 = tidak terdorong
@export var keep_distance: float = 0.0  ## > 0 = menjaga jarak dari pemain (penembak)
@export var strafe_after_attack: bool = false  ## bergeser ke samping setelah menembak (berlindung)
@export_group("Serangan")
@export_enum("melee", "ranged", "pulse") var attack_type: String = "melee"
@export var attack_range: float = 1.6
@export var attack_windup: float = 0.55  ## ancang-ancang (isyarat untuk menghindar)
@export var attack_cooldown: float = 1.4
@export var projectile_speed: float = 14.0
@export_enum("stone", "arrow", "net", "torch", "venom") var projectile_kind: String = "stone"
@export_group("Efek serangan")
@export var hit_poison_dps: float = 0.0
@export var hit_poison_duration: float = 0.0
@export var hit_slow_factor: float = 1.0  ## jaring: 0,5 = setengah kecepatan
@export var hit_slow_duration: float = 0.0
@export var hit_knockback: float = 0.0  ## positif = mendorong, negatif = menarik ke arah musuh
@export var fire_zone_radius: float = 0.0  ## > 0 = proyektil meninggalkan area api
@export var fire_zone_dps: float = 8.0
@export var fire_zone_duration: float = 4.0
@export_group("Khusus")
@export var steal_coins: int = 0  ## pencuri: jumlah koin yang dicuri
@export var steal_label: String = "koin"  ## nama barang curian di teks (koin / padi / kain songke)
@export var flee_time: float = 6.0  ## lama kabur sebelum lolos membawa curian
@export var front_block: float = 1.0  ## pengali damage dari depan (perisai); 1 = tanpa perisai
@export var shell_reduction: float = 1.0  ## pengali damage di luar jendela lemah (cangkang kepiting)
@export var fly_height: float = 0.0
@export var zigzag: float = 0.0  ## amplitudo gerak zig-zag (m)
@export var swoop: bool = false  ## terbang tinggi (tak terjangkau) lalu menukik saat menyerang
@export var charge_speed: float = 0.0  ## seruduk: kecepatan lari lurus
@export var charge_distance: float = 0.0
@export var ambush_range: float = 0.0  ## > 0 = bersembunyi sampai pemain sedekat ini
@export_enum("none", "bush", "water") var hide_in: String = "none"
@export_group("Hadiah")
@export var coins: int = 3
@export var xp: int = 10
