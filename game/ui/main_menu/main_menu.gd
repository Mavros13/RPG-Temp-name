extends Control

const LIT_ROOM := "res://game/world/room_3d/room_3d.tscn"
const SAVE := preload("res://game/world/room_save.gd")
const QUEST := preload("res://game/world/quest_state.gd")
const PACK := preload("res://game/world/inventory_state.gd")


func _ready() -> void:
	DisplayServer.window_set_title("APEX DREAMFORGE")
	%Play.pressed.connect(_play)
	%Continue.pressed.connect(_continue)
	%Quit.pressed.connect(_quit)
	%Continue.visible = SAVE.exists()


func _play() -> void:
	SAVE.apply_on_enter = false
	SAVE.reset_raiders()
	QUEST.restore([], false, false, false, false)
	PACK.has_potion = true
	get_tree().change_scene_to_file(LIT_ROOM)


func _continue() -> void:
	if not SAVE.exists():
		return
	SAVE.apply_on_enter = true
	SAVE.reset_raiders()
	get_tree().change_scene_to_file(LIT_ROOM)


func _quit() -> void:
	get_tree().quit()
