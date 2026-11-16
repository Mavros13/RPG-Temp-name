extends Node

## Stops a footstep while the tree is paused. Rooms without a HUD pause from here.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not InputMap.has_action(&"pause"):
		InputMap.add_action(&"pause", 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	if not InputMap.action_has_event(&"pause", event):
		InputMap.action_add_event(&"pause", event)


func _process(delta: float) -> void:
	var room := _room()
	if room != null and room.get_node_or_null("Hud3D") == null and Input.is_action_just_pressed(&"pause"):
		get_tree().paused = not get_tree().paused
	if not get_tree().paused:
		return
	var steps := get_parent().get_node_or_null("Footsteps") as AudioStreamPlayer3D
	if steps != null:
		steps.stop()
	var body := get_parent()
	if body != null and body.has_method("rest_step_bob"):
		body.rest_step_bob(delta)


func _room() -> Node:
	var player := get_parent()
	if player == null:
		return null
	return player.get_parent()
