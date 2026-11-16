extends Node

const PACK := preload("res://game/world/inventory_state.gd")
const SWING := preload("res://game/audio/swing.wav")
const RANGE := 1.7
const COOLDOWN := 0.45

var _cooldown := 0.0
var _queued := false
var _swing: AudioStreamPlayer3D

signal swing_played


func _ready() -> void:
	_bind_attack()
	_setup_swing()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"attack"):
		_queued = true


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if Input.is_action_just_pressed(&"attack"):
		_queued = true
	if not _queued or _cooldown > 0.0:
		return
	_queued = false
	_cooldown = COOLDOWN
	var player := get_parent() as Node3D
	if player == null or player.has_meta("defeated"):
		return
	_swing.play()
	swing_played.emit()
	var raider := _nearest_raider(player.global_position)
	if raider != null and raider.has_method("take_hit"):
		raider.call("take_hit", PACK.attack())


func _nearest_raider(origin: Vector3) -> Node:
	var best: Node = null
	var best_dist := RANGE
	for node in get_tree().get_nodes_in_group("raiders"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var flat := (node as Node3D).global_position - origin
		flat.y = 0.0
		var dist := flat.length()
		if dist <= best_dist:
			best = node
			best_dist = dist
	return best


func _bind_attack() -> void:
	if not InputMap.has_action(&"attack"):
		InputMap.add_action(&"attack", 0.2)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	if not InputMap.action_has_event(&"attack", click):
		InputMap.action_add_event(&"attack", click)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	if not InputMap.action_has_event(&"attack", key):
		InputMap.action_add_event(&"attack", key)


func _setup_swing() -> void:
	_swing = AudioStreamPlayer3D.new()
	_swing.name = "Swing"
	_swing.stream = SWING
	_swing.volume_db = -5.0
	_swing.unit_size = 4.0
	var host := get_parent()
	if host == null:
		add_child(_swing)
	else:
		host.add_child(_swing)
