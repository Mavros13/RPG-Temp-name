extends CharacterBody3D

const SPEED := 2.4
const CONTACT_RANGE := 1.05
const CONTACT_COOLDOWN := 0.8
const CONTACT_TELL := 0.33
const TELL_LEAN := -0.42
const FALL_TIME := 0.55
const FALL_TIP := 1.25
const FALL_DROP := 0.42
const STEP_GAP := 0.74
const STEP_EPSILON := 0.22
const MAX_HEALTH := 14
const PLAYER_MAX_HEALTH := 8

const HEALTH := preload("res://game/combat/health.gd")
const ATTACK := preload("res://game/combat/player_attack.gd")
const FLASH := preload("res://game/combat/hit_flash.gd")
const RAIDER_FLASH := preload("res://game/combat/raider_flash.gd")
const HUD := preload("res://game/combat/combat_hud.gd")
const PACK := preload("res://game/world/inventory_state.gd")
const SAVE := preload("res://game/world/room_save.gd")
const STEP := preload("res://game/audio/raider_step.wav")

var _health: Node
var _player: CharacterBody3D
var _gravity := 9.8
var _contact_wait := 0.0
var _tell := -1.0
var _pose := 0.0
var _stagger := 0.0
var _knock := Vector3.ZERO
var _fall := -1.0
var _steps: AudioStreamPlayer3D
var _step_time := 0.0


func _ready() -> void:
	var room := get_parent()
	var staying_down := room != null and SAVE.is_down(str(room.scene_file_path))
	if staying_down:
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		add_to_group("raiders")
	collision_layer = 1
	collision_mask = 1
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	_player = room.get_node("Player") as CharacterBody3D
	_player.add_to_group("player")
	_attach(_player, "CombatHealth", PLAYER_MAX_HEALTH)
	_attach(_player, "PlayerAttack", -1)
	_attach_flash(_player)
	if room.get_node_or_null("CombatHud") == null:
		var hud := HUD.new()
		hud.name = "CombatHud"
		room.add_child.call_deferred(hud)
	if staying_down:
		queue_free()
		return
	_health = _attach(self, "CombatHealth", MAX_HEALTH)
	_health.connect("depleted", Callable(self, "_begin_fall"))
	_attach_raider_flash()
	_setup_steps()


func current_health() -> int:
	if _health == null:
		return 0
	return int(_health.get("health"))


func take_hit(amount: int) -> void:
	if _health == null or current_health() <= 0:
		return
	_stagger = 0.16
	if _player != null:
		var away := global_position - _player.global_position
		away.y = 0.0
		if away.length_squared() > 0.0001:
			_knock = away.normalized() * 1.6
	_health.call("hurt", amount)


func _begin_fall() -> void:
	if _fall >= 0.0:
		return
	var room := get_parent()
	if room != null:
		SAVE.remember_defeat(str(room.scene_file_path))
	_fall = FALL_TIME
	_tell = -1.0
	_stagger = 0.0
	_knock = Vector3.ZERO
	velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _fall >= 0.0 or current_health() <= 0:
		_update_fall(delta)
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	if distance > 0.05:
		_face(to_player / distance)
	_contact_wait = maxf(_contact_wait - delta, 0.0)
	if _stagger > 0.0:
		_stagger = maxf(_stagger - delta, 0.0)
		velocity.x = _knock.x
		velocity.z = _knock.z
	elif _player.has_meta("defeated") or distance <= CONTACT_RANGE:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var direction := to_player / distance
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()
	_update_touch(delta)
	_apply_pose(delta)
	_update_steps(delta)


func _setup_steps() -> void:
	_steps = AudioStreamPlayer3D.new()
	_steps.name = "RaiderSteps"
	_steps.stream = STEP
	_steps.volume_db = -16.0
	_steps.unit_size = 4.0
	add_child(_steps)


func _update_steps(delta: float) -> void:
	if _steps == null or _fall >= 0.0 or _tell >= 0.0 or _stagger > 0.0 or not is_on_floor():
		_step_time = 0.0
		return
	var speed := Vector3(velocity.x, 0.0, velocity.z).length()
	if speed <= STEP_EPSILON:
		_step_time = 0.0
		return
	_step_time += delta
	if _step_time < STEP_GAP:
		return
	_step_time = 0.0
	_steps.play()


func _update_fall(delta: float) -> void:
	if _fall < 0.0:
		_fall = FALL_TIME
	velocity.x = 0.0
	velocity.z = 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()
	var visual := _visual()
	if visual != null:
		var along := 1.0 - clampf(_fall / FALL_TIME, 0.0, 1.0)
		visual.rotation.x = FALL_TIP * along
		visual.position.y = -FALL_DROP * along
	_fall = maxf(_fall - delta, 0.0)
	if _fall <= 0.0:
		queue_free()


func _update_touch(delta: float) -> void:
	if _player.has_meta("defeated"):
		_tell = -1.0
		return
	var flat := _player.global_position - global_position
	flat.y = 0.0
	var in_range := flat.length() <= CONTACT_RANGE
	if not in_range:
		_tell = -1.0
		return
	if _contact_wait > 0.0:
		return
	if _tell < 0.0:
		_tell = CONTACT_TELL
		return
	_tell = maxf(_tell - delta, 0.0)
	if _tell > 0.0 or _stagger > 0.0:
		return
	_tell = -1.0
	_pose = 0.0
	var stats := _player.get_node_or_null("CombatHealth")
	if stats != null and stats.has_method("hurt"):
		stats.call("hurt", PACK.contact_damage())
		_contact_wait = CONTACT_COOLDOWN


func _apply_pose(delta: float) -> void:
	var visual := _visual()
	if visual == null:
		return
	if _tell >= 0.0:
		var along := 1.0 - clampf(_tell / CONTACT_TELL, 0.0, 1.0)
		_pose = TELL_LEAN * along
	else:
		var blend := 1.0 - exp(-8.0 * delta)
		_pose = lerpf(_pose, 0.0, blend)
		if absf(_pose) < 0.01:
			_pose = 0.0
	visual.rotation.x = _pose


func _face(direction: Vector3) -> void:
	var visual := _visual()
	if visual == null:
		return
	visual.rotation.y = atan2(direction.x, direction.z)


func _visual() -> Node3D:
	for child in get_children():
		if child is CollisionShape3D:
			continue
		if child is Node3D and child.name != "CombatHealth":
			return child
	return null


func _attach_flash(player: Node) -> void:
	if player.get_node_or_null("HitFlash") != null:
		return
	var flash := FLASH.new()
	flash.name = "HitFlash"
	player.add_child(flash)


func _attach_raider_flash() -> void:
	if get_node_or_null("RaiderFlash") != null:
		return
	var flash := RAIDER_FLASH.new()
	flash.name = "RaiderFlash"
	add_child(flash)


func _attach(host: Node, node_name: String, max_health: int) -> Node:
	var existing := host.get_node_or_null(node_name)
	if existing != null:
		return existing
	var node: Node
	if node_name == "PlayerAttack":
		node = ATTACK.new()
	else:
		node = HEALTH.new()
		node.set("max_health", max_health)
	node.name = node_name
	host.add_child(node)
	return node
