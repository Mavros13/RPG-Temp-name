extends Node2D

const ROOM_LIMIT_LEFT := -768
const ROOM_LIMIT_TOP := -488
const ROOM_LIMIT_RIGHT := 768
const ROOM_LIMIT_BOTTOM := 488

func _ready() -> void:
	DisplayServer.window_set_title("APEX DREAMFORGE")
	var camera := $Player/Camera2D as Camera2D
	camera.limit_left = ROOM_LIMIT_LEFT
	camera.limit_top = ROOM_LIMIT_TOP
	camera.limit_right = ROOM_LIMIT_RIGHT
	camera.limit_bottom = ROOM_LIMIT_BOTTOM
