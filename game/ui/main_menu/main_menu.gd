extends Control

const LIT_ROOM := "res://game/world/room_3d/room_3d.tscn"


func _ready() -> void:
	DisplayServer.window_set_title("APEX DREAMFORGE")
	%Play.pressed.connect(_play)
	%Quit.pressed.connect(_quit)


func _play() -> void:
	get_tree().change_scene_to_file(LIT_ROOM)


func _quit() -> void:
	get_tree().quit()
