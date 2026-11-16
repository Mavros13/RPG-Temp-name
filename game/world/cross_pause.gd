extends Node

## Stops a doorway sound if pause starts, and does not play it again.


var _silenced := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _silenced or not get_tree().paused:
		return
	var cross := get_parent().get_node_or_null("DoorCross") as AudioStreamPlayer
	if cross != null:
		cross.stop()
	_silenced = true
