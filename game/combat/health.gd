extends Node

const CONNECT := preload("res://game/audio/connect.wav")

signal damaged(amount: int, remaining: int)
signal healed(amount: int, remaining: int)
signal depleted

@export var max_health := 8
var health := 8
var _connect: AudioStreamPlayer3D


func _ready() -> void:
	health = max_health
	_connect = AudioStreamPlayer3D.new()
	_connect.name = "Connect"
	_connect.stream = CONNECT
	_connect.volume_db = -4.0
	_connect.unit_size = 4.0
	var host := get_parent()
	if host == null:
		add_child(_connect)
	else:
		host.add_child(_connect)


func hurt(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = maxi(health - amount, 0)
	_connect.play()
	damaged.emit(amount, health)
	if health > 0:
		return
	var body := get_parent()
	if body != null and body.is_in_group("player"):
		body.set_meta("defeated", true)
	depleted.emit()


func heal(amount: int) -> void:
	if amount <= 0 or health >= max_health:
		return
	var gained := mini(amount, max_health - health)
	health += gained
	var body := get_parent()
	if health > 0 and body != null and body.has_meta("defeated"):
		body.remove_meta("defeated")
	healed.emit(gained, health)


func restore(amount: int) -> void:
	health = clampi(amount, 0, max_health)
	var body := get_parent()
	if body == null:
		return
	if health > 0 and body.has_meta("defeated"):
		body.remove_meta("defeated")
	elif health <= 0 and body.is_in_group("player"):
		body.set_meta("defeated", true)
