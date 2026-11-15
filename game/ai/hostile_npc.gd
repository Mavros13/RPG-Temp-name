extends CharacterBody3D

## Hostile NPC with health. Idles until a body in the "player" group overlaps Detection, then chases it.

enum State { IDLE, CHASE }

@export var max_health: int = 30
@export var speed: float = 3.0

var health: int = 0
var state: State = State.IDLE
var _target: Node3D

@onready var _detection: Area3D = $Detection


func _ready() -> void:
	health = max_health


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = maxi(health - amount, 0)
	if health == 0:
		queue_free()


func _physics_process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or not _detection.overlaps_body(_target):
		_target = _find_player()
	if _target == null:
		state = State.IDLE
		velocity = Vector3.ZERO
		return
	state = State.CHASE
	var offset := _target.global_position - global_position
	if offset.length_squared() <= 0.25:
		velocity = Vector3.ZERO
		return
	velocity = offset.normalized() * speed
	move_and_slide()


func _find_player() -> Node3D:
	for body in _detection.get_overlapping_bodies():
		if body != self and body.is_in_group("player"):
			return body
	return null
