extends Node

## Stops a raider step while the tree is paused, and drops it on resume.

var _held := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var steps := get_parent().get_node_or_null("RaiderSteps") as AudioStreamPlayer3D
	if steps == null:
		return
	if get_tree().paused:
		steps.stop()
		_held = true
		return
	if not _held:
		return
	_held = false
	steps.stop()
