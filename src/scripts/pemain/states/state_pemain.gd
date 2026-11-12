class_name StatePemain
extends StateDasar
## Dasar semua state pemain; menyediakan akses bertipe ke Pemain.

var pemain: Pemain:
	get:
		return pemilik as Pemain
