class_name StateDasar
extends Node
## Kelas dasar satu state. Turunannya mengisi fungsi yang diperlukan saja.

var mesin: StateMachine
var pemilik: Node


func masuk(_data: Dictionary) -> void:
	pass


func keluar() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
