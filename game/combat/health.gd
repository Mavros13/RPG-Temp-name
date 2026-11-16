extends Node

signal damaged(amount: int, remaining: int)
signal depleted

@export var max_health := 8
var health := 8


func _ready() -> void:
	health = max_health


func hurt(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = maxi(health - amount, 0)
	damaged.emit(amount, health)
	if health > 0:
		return
	var body := get_parent()
	if body != null and body.is_in_group("player"):
		body.set_meta("defeated", true)
	depleted.emit()
