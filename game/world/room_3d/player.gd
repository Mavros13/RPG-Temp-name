extends CharacterBody3D

const SPEED := 3.6
const SPRINT_SPEED := 6.4
const ACCELERATION := 12.0
const DECELERATION := 18.0
const TURN_RATE := 14.0
const JUMP_VELOCITY := 4.8

const MODEL_SCENE := preload("res://assets/characters/player/player_adventurer.glb")

const CAMERA_BACK := 3.15
const CAMERA_HEIGHT := 2.55
const CAMERA_LOOK_HEIGHT := 1.2
const CAMERA_YAW_SHARPNESS := 6.0
const CAMERA_ARM_SHARPNESS := 8.0
const CAMERA_PROBE_RADIUS := 0.18

@onready var model: Node3D = $Model
@onready var camera: Camera3D = $Camera3D

var _facing_yaw := 0.0
var _camera_yaw := 0.0
var _camera_arm := 0.0
var _move_yaw := 0.0
var _latched_input := Vector2.ZERO
var _camera_sphere: SphereShape3D


func _ready() -> void:
	_ensure_move_actions()
	var visual := MODEL_SCENE.instantiate()
	model.add_child(visual)
	_setup_body()
	_camera_sphere = SphereShape3D.new()
	_camera_sphere.radius = CAMERA_PROBE_RADIUS
	camera.current = true
	camera.fov = 58.0
	_facing_yaw = model.rotation.y
	_camera_yaw = _facing_yaw
	_move_yaw = _facing_yaw
	_camera_arm = _ideal_arm_length()
	_place_camera(0.0)


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
	_bind_action("sprint", [KEY_SHIFT])
	_bind_action("jump", [KEY_CTRL])


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
	var direction := _wish_direction(input_dir)
	var top_speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED
	var target := Vector3.ZERO
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
		target = direction * top_speed
		_facing_yaw = rotate_toward(_facing_yaw, atan2(direction.x, direction.z), TURN_RATE * delta)
	model.rotation.y = _facing_yaw
	var rate := ACCELERATION if target.length_squared() > 0.0 else DECELERATION
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
		else:
			velocity.y = 0.0
	else:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	move_and_slide()


func _process(delta: float) -> void:
	_place_camera(delta)


# Held keys keep the heading they had when the chord changed, so the body
# walks a straight line while the chase camera eases in behind the new facing.
func _wish_direction(input_dir: Vector2) -> Vector3:
	if input_dir.length_squared() <= 0.0001:
		_latched_input = Vector2.ZERO
		return Vector3.ZERO
	if _latched_input.distance_squared_to(input_dir) > 0.0001:
		_move_yaw = _camera_yaw
		_latched_input = input_dir
	var forward := Vector3(sin(_move_yaw), 0.0, cos(_move_yaw))
	var right := forward.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = Vector3(1.0, 0.0, 0.0)
	else:
		right = right.normalized()
	return right * input_dir.x + forward * (-input_dir.y)


func _ideal_offset(yaw: float) -> Vector3:
	var behind := Vector3(-sin(yaw), 0.0, -cos(yaw))
	return behind * CAMERA_BACK + Vector3(0.0, CAMERA_HEIGHT, 0.0)


func _ideal_arm_length() -> float:
	var pivot := Vector3(0.0, CAMERA_LOOK_HEIGHT, 0.0)
	return _ideal_offset(_camera_yaw).distance_to(pivot)


func _place_camera(delta: float) -> void:
	if delta > 0.0:
		var yaw_blend := 1.0 - exp(-CAMERA_YAW_SHARPNESS * delta)
		_camera_yaw = lerp_angle(_camera_yaw, _facing_yaw, yaw_blend)
	var pivot := global_position + Vector3(0.0, CAMERA_LOOK_HEIGHT, 0.0)
	var desired := global_position + _ideal_offset(_camera_yaw)
	var allowed := _camera_clearance(pivot, desired)
	if delta <= 0.0 or allowed < _camera_arm:
		_camera_arm = allowed
	else:
		var arm_blend := 1.0 - exp(-CAMERA_ARM_SHARPNESS * delta)
		_camera_arm = lerpf(_camera_arm, allowed, arm_blend)
	var aim := desired - pivot
	var aim_len := aim.length()
	if aim_len < 0.001:
		return
	camera.global_position = pivot + aim * (_camera_arm / aim_len)
	var look_target := global_position + Vector3(0.0, CAMERA_LOOK_HEIGHT, 0.0)
	if camera.global_position.distance_squared_to(look_target) > 0.01:
		camera.look_at(look_target, Vector3.UP)


func _camera_clearance(pivot: Vector3, desired: Vector3) -> float:
	var motion := desired - pivot
	var length := motion.length()
	if length < 0.001 or _camera_sphere == null:
		return length
	var world := get_world_3d()
	if world == null:
		return length
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _camera_sphere
	params.transform = Transform3D(Basis(), pivot)
	params.motion = motion
	params.exclude = [get_rid()]
	params.collision_mask = 1
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var fraction := world.direct_space_state.cast_motion(params)
	var safe := clampf(float(fraction[0]), 0.0, 1.0)
	var allowed := length * safe
	if safe < 0.999:
		allowed = maxf(allowed - 0.06, 0.0)
	return minf(allowed, length)
