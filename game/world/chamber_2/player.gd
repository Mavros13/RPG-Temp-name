extends CharacterBody3D

const SPEED := 3.6
const TURN_RATE := 14.0
const MODEL_SCENE := preload("res://assets/characters/player/player_adventurer.glb")
const CAMERA_OFFSET := Vector3(0.0, 2.55, -3.15)
const CAMERA_LOOK_HEIGHT := 1.2
const ROOM_MIN_X := 0.45
const ROOM_MAX_X := 9.55
const ROOM_MIN_Z := 0.45
const ROOM_MAX_Z := 7.55
const MOUSE_SENS := 0.0028
const LOOK_BLEND := 0.42
const WALK_BOB_RATE := 9.5
const BOB_HEIGHT := 0.06
const LEAN_ANGLE := 0.16
const POSE_SHARPNESS := 12.0
const GAIT_EPSILON := 0.22
const FOOTSTEP := preload("res://game/audio/footstep.wav")
const WALK_STEP := 0.46

@onready var model: Node3D = $Model
@onready var camera: Camera3D = $Camera3D

var _aim_yaw := 0.0
var _yaw := 0.0
var _look := true
var _facing_yaw := 0.0
var _bob_phase := 0.0
var _bob_height := 0.0
var _lean_pitch := 0.0
var _lean_roll := 0.0
var _steps: AudioStreamPlayer3D
var _step_time := 0.0

signal footstep_played

func _ready() -> void:
	_ensure_move_actions()
	var visual := MODEL_SCENE.instantiate()
	model.add_child(visual)
	_setup_body()
	camera.current = true
	camera.fov = 58.0
	_place_camera()
	_setup_footsteps()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
		_facing_yaw = rotate_toward(_facing_yaw, atan2(direction.x, direction.z), TURN_RATE * delta)
		model.rotation.y = _facing_yaw
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
	_apply_gait(delta)
	_update_footsteps(delta)


func _apply_gait(delta: float) -> void:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var speed := flat.length()
	var moving := speed > GAIT_EPSILON
	var target_height := 0.0
	var target_pitch := 0.0
	var target_roll := 0.0
	if moving:
		_bob_phase += WALK_BOB_RATE * delta
		target_height = sin(_bob_phase) * BOB_HEIGHT
		var forward := Vector3(sin(_facing_yaw), 0.0, cos(_facing_yaw))
		var right := forward.cross(Vector3.UP)
		if right.length_squared() > 0.0001:
			right = right.normalized()
		else:
			right = Vector3.RIGHT
		var wish := flat / speed
		target_pitch = -wish.dot(forward) * LEAN_ANGLE
		target_roll = wish.dot(right) * LEAN_ANGLE
	else:
		_bob_phase = 0.0
	var blend := 1.0 - exp(-POSE_SHARPNESS * delta)
	_bob_height = lerpf(_bob_height, target_height, blend)
	_lean_pitch = lerpf(_lean_pitch, target_pitch, blend)
	_lean_roll = lerpf(_lean_roll, target_roll, blend)
	if not moving and absf(_bob_height) < 0.001:
		_bob_height = 0.0
		_lean_pitch = 0.0
		_lean_roll = 0.0
	model.position.y = _bob_height
	model.rotation.x = _lean_pitch
	model.rotation.y = _facing_yaw
	model.rotation.z = _lean_roll


func _setup_footsteps() -> void:
	_steps = AudioStreamPlayer3D.new()
	_steps.name = "Footsteps"
	_steps.stream = FOOTSTEP
	_steps.volume_db = -8.0
	_steps.unit_size = 4.0
	add_child(_steps)


func _update_footsteps(delta: float) -> void:
	var speed := Vector3(velocity.x, 0.0, velocity.z).length()
	if not is_on_floor():
		_step_time = 0.0
		_steps.stop()
		return
	if speed <= GAIT_EPSILON:
		_step_time = 0.0
		return
	_step_time += delta
	if _step_time < WALK_STEP:
		return
	_step_time = 0.0
	_steps.play()
	footstep_played.emit()


func set_mouse_look(enabled: bool) -> void:
	_look = enabled
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if not _look or not (event is InputEventMouseMotion):
		return
	var motion := event as InputEventMouseMotion
	_aim_yaw -= motion.relative.x * MOUSE_SENS


func _process(_delta: float) -> void:
	_yaw = lerp_angle(_yaw, _aim_yaw, LOOK_BLEND)
	_place_camera()


func _camera_relative(input_dir: Vector2) -> Vector3:
	# Heading comes from the orbit, not the clamped camera, so a wall
	# that pulls the camera inside the player does not reverse the keys.
	var offset := CAMERA_OFFSET.rotated(Vector3.UP, _aim_yaw)
	var forward := Vector3(-offset.x, 0.0, -offset.z)
	if forward.length_squared() < 0.0001:
		forward = Vector3(0.0, 0.0, 1.0)
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = Vector3(1.0, 0.0, 0.0)
	right = right.normalized()
	return right * input_dir.x + forward * (-input_dir.y)


func _orbit_offset() -> Vector3:
	return CAMERA_OFFSET.rotated(Vector3.UP, _yaw)


func _place_camera() -> void:
	var desired := global_position + _orbit_offset()
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
