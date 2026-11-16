extends Node

const CONNECT := preload("res://game/audio/connect.wav")
const HURT := preload("res://game/audio/hurt.wav")
const NUMBER := preload("res://game/combat/damage_number.gd")

signal damaged(amount: int, remaining: int)
signal healed(amount: int, remaining: int)
signal depleted

@export var max_health := 8
var health := 8
var _connect: AudioStreamPlayer3D
var _hurt: AudioStreamPlayer3D


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
		if host.is_in_group("player"):
			_setup_hurt(host)


func hurt(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = maxi(health - amount, 0)
	_connect.play()
	if health > 0 and _hurt != null:
		_hurt.play()
	damaged.emit(amount, health)
	_show_damage(amount)
	if health > 0:
		return
	var body := get_parent()
	if body != null and body.is_in_group("player"):
		body.set_meta("defeated", true)
	depleted.emit()


func _setup_hurt(host: Node) -> void:
	_hurt = AudioStreamPlayer3D.new()
	_hurt.name = "Hurt"
	_hurt.stream = HURT
	_hurt.volume_db = -6.0
	_hurt.unit_size = 4.0
	host.add_child(_hurt)


func _show_damage(amount: int) -> void:
	var body := get_parent() as Node3D
	if body == null or amount <= 0:
		return
	var label := NUMBER.new() as Label3D
	label.name = "DamageNumber"
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	label.text = str(amount)
	label.font_size = 56
	label.pixel_size = 0.007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.86, 0.42)
	label.outline_size = 10
	label.outline_modulate = Color(0.05, 0.02, 0.01, 0.9)
	label.position = Vector3(0.0, 1.85, 0.0)
	body.add_child(label)


func heal(amount: int) -> void:
	if amount <= 0 or health >= max_health:
		return
	var gained := mini(amount, max_health - health)
	health += gained
	var body := get_parent()
	if health > 0 and body != null and body.has_meta("defeated"):
		body.remove_meta("defeated")
	healed.emit(gained, health)
	_show_damage(gained)


func restore(amount: int) -> void:
	health = clampi(amount, 0, max_health)
	var body := get_parent()
	if body == null:
		return
	if health > 0 and body.has_meta("defeated"):
		body.remove_meta("defeated")
	elif health <= 0 and body.is_in_group("player"):
		body.set_meta("defeated", true)
