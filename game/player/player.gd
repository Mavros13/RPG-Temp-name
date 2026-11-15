extends CharacterBody2D

const SPEED := 240.0

@onready var _facing: Node2D = $Facing

func _ready() -> void:
	$Camera2D.make_current()

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.0:
		velocity = direction * SPEED
		_facing.rotation = direction.angle() + PI * 0.5
	else:
		velocity = Vector2.ZERO
	move_and_slide()
