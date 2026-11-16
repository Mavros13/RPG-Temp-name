extends CharacterBody3D

const SPEED := 2.4
const CONTACT_RANGE := 1.05
const CONTACT_DAMAGE := 1
const CONTACT_COOLDOWN := 0.8
const MAX_HEALTH := 4
const PLAYER_MAX_HEALTH := 8

const HEALTH := preload("res://game/combat/health.gd")
const ATTACK := preload("res://game/combat/player_attack.gd")
const HUD := preload("res://game/combat/combat_hud.gd")

var _health: Node
var _player: CharacterBody3D
var _gravity := 9.8
var _contact_wait := 0.0
var _stagger := 0.0
var _knock := Vector3.ZERO


func _ready() -> void:
	add_to_group("raiders")
	collision_layer = 1
	collision_mask = 1
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	_player = get_parent().get_node("Player") as CharacterBody3D
	_player.add_to_group("player")
	_health = _attach(self, "CombatHealth", MAX_HEALTH)
	_health.connect("depleted", Callable(self, "queue_free"))
	_attach(_player, "CombatHealth", PLAYER_MAX_HEALTH)
	_attach(_player, "PlayerAttack", -1)
	var room := get_parent()
	if room.get_node_or_null("CombatHud") == null:
		var hud := HUD.new()
		hud.name = "CombatHud"
		room.add_child.call_deferred(hud)


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


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or current_health() <= 0:
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
	if _player.has_meta("defeated") or _stagger > 0.0 or _contact_wait > 0.0:
		return
	var flat := _player.global_position - global_position
	flat.y = 0.0
	if flat.length() > CONTACT_RANGE:
		return
	var stats := _player.get_node_or_null("CombatHealth")
	if stats != null and stats.has_method("hurt"):
		stats.call("hurt", CONTACT_DAMAGE)
		_contact_wait = CONTACT_COOLDOWN


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
