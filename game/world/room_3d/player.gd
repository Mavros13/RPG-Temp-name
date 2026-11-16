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
const CAMERA_ARM_SHARPNESS := 8.0
const LOOK_BLEND := 0.42
const CAMERA_PROBE_RADIUS := 0.18
const MOUSE_SENS := 0.0028
const PITCH_MIN := -0.2
const PITCH_MAX := 1.15
const WALK_BOB_RATE := 9.5
const SPRINT_BOB_RATE := 16.0
const BOB_HEIGHT := 0.06
const SPRINT_BOB_HEIGHT := 0.08
const LEAN_ANGLE := 0.16
const POSE_SHARPNESS := 12.0
const GAIT_EPSILON := 0.22
const FOOTSTEP := preload("res://game/audio/footstep.wav")
const LAND := preload("res://game/audio/land.wav")
const WALK_STEP := 0.46
const SPRINT_STEP := 0.28
const SETTLE_TIME := 0.16
const SETTLE_DIP := 0.07

@onready var model: Node3D = $Model
@onready var camera: Camera3D = $Camera3D

var _facing_yaw := 0.0
var _aim_yaw := 0.0
var _aim_pitch := 0.0
var _camera_yaw := 0.0
var _camera_pitch := 0.0
var _orbit_distance := 1.0
var _camera_arm := 0.0
var _look := true
var _camera_sphere: SphereShape3D
var _bob_phase := 0.0
var _bob_height := 0.0
var _lean_pitch := 0.0
var _lean_roll := 0.0
var _steps: AudioStreamPlayer3D
var _land: AudioStreamPlayer3D
var _step_time := 0.0
var _pending_jump := false
var _air_from_jump := false
var _settle := 0.0

signal footstep_played


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
	_aim_yaw = _facing_yaw
	var raise := CAMERA_HEIGHT - CAMERA_LOOK_HEIGHT
	_orbit_distance = Vector2(CAMERA_BACK, raise).length()
	_camera_pitch = atan2(raise, CAMERA_BACK)
	_aim_pitch = _camera_pitch
	_camera_arm = _orbit_distance
	_place_camera(0.0)
	_setup_footsteps()
	_arm_step_pause()
	_setup_land()
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
	if has_meta("defeated"):
		input_dir = Vector2.ZERO
	var direction := _wish_direction(input_dir)
	var top_speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED
	var swing := _swing_cap()
	if swing >= 0.0:
		top_speed = swing
	var target := Vector3.ZERO
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
		target = direction * top_speed
		_facing_yaw = rotate_toward(_facing_yaw, atan2(direction.x, direction.z), TURN_RATE * delta)
	model.rotation.y = _facing_yaw
	var rate := ACCELERATION if target.length_squared() > 0.0 else DECELERATION
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, rate * delta)
	if swing >= 0.0 and horizontal.length() > swing:
		horizontal = horizontal.normalized() * swing
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	var started_jump := false
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			started_jump = true
		else:
			velocity.y = 0.0
	else:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	move_and_slide()
	_track_landing(started_jump)
	_apply_gait(delta, Input.is_action_pressed("sprint"))
	_update_footsteps(delta, Input.is_action_pressed("sprint"))


func _apply_gait(delta: float, sprinting: bool) -> void:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var speed := flat.length()
	var moving := speed > GAIT_EPSILON
	var target_height := 0.0
	var target_pitch := 0.0
	var target_roll := 0.0
	if moving:
		var fast := sprinting and speed > SPEED * 0.85
		var rate := SPRINT_BOB_RATE if fast else WALK_BOB_RATE
		var amplitude := SPRINT_BOB_HEIGHT if fast else BOB_HEIGHT
		_bob_phase += rate * delta
		target_height = sin(_bob_phase) * amplitude
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
	model.position.y = _bob_height + _landing_dip(delta)
	model.rotation.x = _lean_pitch
	model.rotation.y = _facing_yaw
	model.rotation.z = _lean_roll


func _track_landing(started_jump: bool) -> void:
	var grounded := is_on_floor()
	if started_jump:
		_pending_jump = true
	if not grounded and _pending_jump:
		_pending_jump = false
		_air_from_jump = true
	elif grounded and _pending_jump and not started_jump:
		_pending_jump = false
	if grounded and _air_from_jump:
		_air_from_jump = false
		_play_land()


func _play_land() -> void:
	_settle = SETTLE_TIME
	if _land != null:
		_land.play()


func _landing_dip(delta: float) -> float:
	if _settle <= 0.0:
		return 0.0
	_settle = maxf(_settle - delta, 0.0)
	var along := 1.0 - (_settle / SETTLE_TIME)
	return -sin(along * PI) * SETTLE_DIP


func _setup_land() -> void:
	_land = AudioStreamPlayer3D.new()
	_land.name = "Land"
	_land.stream = LAND
	_land.volume_db = -10.0
	_land.unit_size = 4.0
	add_child(_land)


func _arm_step_pause() -> void:
	var watch := Node.new()
	watch.name = "StepPause"
	watch.process_mode = Node.PROCESS_MODE_ALWAYS
	watch.set_script(preload("res://game/world/step_pause.gd"))
	add_child(watch)


func _setup_footsteps() -> void:
	_steps = AudioStreamPlayer3D.new()
	_steps.name = "Footsteps"
	_steps.stream = FOOTSTEP
	_steps.volume_db = -8.0
	_steps.unit_size = 4.0
	add_child(_steps)


func _update_footsteps(delta: float, sprinting: bool) -> void:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var speed := flat.length()
	if not is_on_floor():
		_step_time = 0.0
		_steps.stop()
		return
	if speed <= GAIT_EPSILON:
		_step_time = 0.0
		return
	_step_time += delta
	var interval := SPRINT_STEP if sprinting and speed > SPEED * 0.85 else WALK_STEP
	if _step_time < interval:
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
	_aim_pitch = clampf(_aim_pitch + motion.relative.y * MOUSE_SENS, PITCH_MIN, PITCH_MAX)


func _process(delta: float) -> void:
	_ease_look(delta)
	_place_camera(delta)


func _ease_look(_delta: float) -> void:
	_camera_yaw = lerp_angle(_camera_yaw, _aim_yaw, LOOK_BLEND)
	_camera_pitch = lerpf(_camera_pitch, _aim_pitch, LOOK_BLEND)


func _swing_cap() -> float:
	var attack := get_node_or_null("PlayerAttack")
	if attack == null or not attack.has_method(&"is_swinging"):
		return -1.0
	if not attack.is_swinging():
		return -1.0
	return float(attack.swing_speed())


func _wish_direction(input_dir: Vector2) -> Vector3:
	if input_dir.length_squared() <= 0.0001:
		return Vector3.ZERO
	var forward := Vector3(sin(_aim_yaw), 0.0, cos(_aim_yaw))
	var right := forward.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = Vector3(1.0, 0.0, 0.0)
	else:
		right = right.normalized()
	return right * input_dir.x + forward * (-input_dir.y)


func _orbit_offset() -> Vector3:
	var horizontal := cos(_camera_pitch) * _orbit_distance
	var height := sin(_camera_pitch) * _orbit_distance
	return Vector3(-sin(_camera_yaw) * horizontal, height, -cos(_camera_yaw) * horizontal)


func _place_camera(delta: float) -> void:
	var pivot := global_position + Vector3(0.0, CAMERA_LOOK_HEIGHT, 0.0)
	var desired := pivot + _orbit_offset()
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
