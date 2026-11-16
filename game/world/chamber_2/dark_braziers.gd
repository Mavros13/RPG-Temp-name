extends Node

const QUEST := preload("res://game/world/quest_state.gd")
const BRAZIER_SCENE := preload("res://assets/world/first_room/brazier.glb")
const MARK_RANGE := 1.7

var _braziers: Array[Node3D] = []
var _hud: Node


func bind(parent: Node3D, hud: Node) -> void:
	_bind_mark()
	_hud = hud
	for index in QUEST.DARK_NAMES.size():
		var mark_name: String = QUEST.DARK_NAMES[index]
		var brazier := BRAZIER_SCENE.instantiate() as Node3D
		brazier.name = mark_name
		brazier.position = _spot(index)
		brazier.set_meta("mark_name", mark_name)
		brazier.set_meta("dark", true)
		parent.add_child(brazier)
		_darken(brazier)
		if QUEST.names_read.has(mark_name):
			brazier.set_meta("read", true)
			_show_name(brazier, mark_name)
		_braziers.append(brazier)
	_refresh_hud()


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"mark"):
		_try_read()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mark"):
		_try_read()


func _try_read() -> void:
	if not QUEST.both_lit_marked():
		return
	var player := _player()
	if player == null:
		return
	var best: Node3D = null
	var best_dist := MARK_RANGE
	for brazier in _braziers:
		if not is_instance_valid(brazier) or brazier.has_meta("read"):
			continue
		var flat: Vector3 = brazier.global_position - player.global_position
		flat.y = 0.0
		var dist := flat.length()
		if dist <= best_dist:
			best = brazier
			best_dist = dist
	if best == null:
		return
	var mark_name := str(best.get_meta("mark_name"))
	if not QUEST.try_read(mark_name):
		return
	best.set_meta("read", true)
	_show_name(best, mark_name)
	_refresh_hud()


func _refresh_hud() -> void:
	if _hud == null:
		return
	if not QUEST.both_lit_marked():
		if _hud.has_method("clear_quest"):
			_hud.call("clear_quest")
		return
	if _hud.has_method("show_unread"):
		_hud.call("show_unread", QUEST.unread_count())


func _player() -> Node3D:
	var grouped := get_tree().get_first_node_in_group("player") as Node3D
	if grouped != null:
		return grouped
	var room := get_parent()
	if room == null:
		return null
	return room.get_node_or_null("Player") as Node3D


func _spot(index: int) -> Vector3:
	if index == 0:
		return Vector3(3.4, 0.0, 5.2)
	return Vector3(6.6, 0.0, 5.2)


func _show_name(brazier: Node3D, mark_name: String) -> void:
	if brazier.get_node_or_null("ReadName") != null:
		return
	var label := Label3D.new()
	label.name = "ReadName"
	label.text = mark_name
	label.position = Vector3(0.0, 1.55, 0.0)
	label.font_size = 56
	label.modulate = Color(0.93, 0.84, 0.55)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	brazier.add_child(label)


func _darken(node: Node) -> void:
	var light := node as OmniLight3D
	if light != null:
		light.light_energy = 0.0
		light.omni_range = 0.4
		light.light_color = Color(0.12, 0.1, 0.08)
	var mesh := node as MeshInstance3D
	if mesh != null and mesh.mesh != null:
		for surface in mesh.mesh.get_surface_count():
			var standard := mesh.get_active_material(surface) as StandardMaterial3D
			if standard == null:
				continue
			var dim := standard.duplicate() as StandardMaterial3D
			dim.emission_enabled = false
			dim.albedo_color = dim.albedo_color.darkened(0.72)
			mesh.set_surface_override_material(surface, dim)
	for child in node.get_children():
		_darken(child)


func _bind_mark() -> void:
	if not InputMap.has_action(&"mark"):
		InputMap.add_action(&"mark", 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F
	if not InputMap.action_has_event(&"mark", event):
		InputMap.action_add_event(&"mark", event)
