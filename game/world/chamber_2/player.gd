extends CharacterBody3D

const SPEED := 3.6
const MODEL_SCENE := preload("res://assets/characters/player/player_adventurer.glb")
const CAMERA_OFFSET := Vector3(0.0, 2.55, -3.15)
const CAMERA_LOOK_HEIGHT := 1.2
const ROOM_MIN_X := 0.45
const ROOM_MAX_X := 9.55
const ROOM_MIN_Z := 0.45
const ROOM_MAX_Z := 7.55

@onready var model: Node3D = $Model
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	_ensure_move_actions()
	var visual := MODEL_SCENE.instantiate()
	model.add_child(visual)
	_setup_body()
	camera.current = true
	camera.fov = 58.0
	_place_camera()


func _setup_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.7
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.85, 0.0)
	add_child(shape)


func _ensure_move_actions() -> void:
	_bind_action("move_forward", [KEY_W, KEY_UP])
	_bind_action("move_back", [KEY_S, KEY_DOWN])
	_bind_action("move_left", [KEY_A, KEY_LEFT])
	_bind_action("move_right", [KEY_D, KEY_RIGHT])


func _bind_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := _camera_relative(input_dir)
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
		model.rotation.y = atan2(direction.x, direction.z)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	move_and_slide()


func _process(_delta: float) -> void:
	_place_camera()


func _camera_relative(input_dir: Vector2) -> Vector3:
	# Heading comes from the chase offset, not the clamped camera, so a wall
	# that pulls the camera inside the player does not reverse the keys.
	var forward := Vector3(-CAMERA_OFFSET.x, 0.0, -CAMERA_OFFSET.z)
	if forward.length_squared() < 0.0001:
		forward = Vector3(0.0, 0.0, 1.0)
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = Vector3(1.0, 0.0, 0.0)
	right = right.normalized()
	return right * input_dir.x + forward * (-input_dir.y)


func _place_camera() -> void:
	var desired := global_position + CAMERA_OFFSET
	desired.x = clampf(desired.x, ROOM_MIN_X, ROOM_MAX_X)
	desired.z = clampf(desired.z, ROOM_MIN_Z, ROOM_MAX_Z)
	var flat := Vector2(desired.x - global_position.x, desired.z - global_position.z)
	if flat.length() < 0.75:
		var push := Vector2(0.0, -1.0) if flat.length() < 0.001 else flat.normalized()
		push *= 0.75
		desired.x = clampf(global_position.x + push.x, ROOM_MIN_X, ROOM_MAX_X)
		desired.z = clampf(global_position.z + push.y, ROOM_MIN_Z, ROOM_MAX_Z)
	camera.global_position = desired
	var look_target := global_position + Vector3(0.0, CAMERA_LOOK_HEIGHT, 0.0)
	if camera.global_position.distance_squared_to(look_target) > 0.04:
		camera.look_at(look_target, Vector3.UP)
