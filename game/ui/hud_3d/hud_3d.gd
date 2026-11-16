extends CanvasLayer

## Attack and defense stay on this sheet. Health follows the player's combat health.
const QUEST := preload("res://game/world/quest_state.gd")
const PACK := preload("res://game/world/inventory_state.gd")
const SAVE := preload("res://game/world/room_save.gd")
const LIT_ROOM := "res://game/world/room_3d/room_3d.tscn"
const MAIN_MENU := "res://game/ui/main_menu/main_menu.tscn"
const LIT_START := Vector3(4.0, 0.08, 3.2)
const FALL_TIME := 1.6

static var announce_fall := false

@onready var health_value: Label = %HealthValue
@onready var attack_value: Label = %AttackValue
@onready var defense_value: Label = %DefenseValue
@onready var unmarked_row: HBoxContainer = %UnmarkedRow
@onready var unmarked_name: Label = %UnmarkedName
@onready var unmarked_value: Label = %UnmarkedValue
@onready var objective: Label = %Objective
@onready var inventory: PanelContainer = %Inventory
@onready var inventory_items: VBoxContainer = %InventoryItems
@onready var pause_bar: HBoxContainer = %PauseBar
@onready var menu_button: Button = %Menu
@onready var fall_label: Label = %Fallen

var _health: Node
var _listed_coal := false
var _listed_potion := false
var _room_paused := false
var _quieted: Array[AudioStreamPlayer3D] = []
var _fall_left := 0.0


func _ready() -> void:
	attack_value.text = str(PACK.attack())
	defense_value.text = str(PACK.defense())
	_bind_inventory()
	_bind_drink()
	_bind_save_keys()
	_bind_pause()
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory.visible = false
	pause_bar.visible = false
	menu_button.pressed.connect(_open_menu)
	fall_label.visible = false
	if announce_fall:
		announce_fall = false
		_show_fall()
	_sync_inventory(true)
	set_process(not _bind_health())
	if SAVE.take_apply():
		_load_room()


func _physics_process(delta: float) -> void:
	if _fall_left > 0.0:
		_fall_left = maxf(_fall_left - delta, 0.0)
		if _fall_left == 0.0:
			fall_label.visible = false
	if Input.is_action_just_pressed(&"inventory"):
		inventory.visible = not inventory.visible
		_sync_inventory(true)
	if Input.is_action_just_pressed(&"drink"):
		_drink_potion()
	if Input.is_action_just_pressed(&"quick_save"):
		_save_room()
	if Input.is_action_just_pressed(&"quick_load"):
		_load_room()
	if Input.is_action_just_pressed(&"pause"):
		_toggle_pause()
	elif inventory.visible:
		_sync_inventory(false)


func _process(_delta: float) -> void:
	if _bind_health():
		set_process(false)


func _bind_health() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	var stats := player.get_node_or_null("CombatHealth")
	if stats == null:
		return false
	_health = stats
	_show_health(int(stats.get("health")))
	if stats.has_signal("damaged") and not stats.damaged.is_connected(_on_damaged):
		stats.damaged.connect(_on_damaged)
	if stats.has_signal("healed") and not stats.healed.is_connected(_on_healed):
		stats.healed.connect(_on_healed)
	return true


func _on_damaged(_amount: int, remaining: int) -> void:
	_show_health(remaining)
	if remaining <= 0:
		_respawn()


func _respawn() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	var stats := player.get_node_or_null("CombatHealth") if player != null else _health
	var maximum := 8
	if stats != null:
		maximum = int(stats.get("max_health"))
		if stats.has_method("restore"):
			stats.call("restore", maximum)
	_show_health(maximum)
	var here := get_tree().current_scene
	if here != null and here.scene_file_path == LIT_ROOM:
		if player != null:
			player.velocity = Vector3.ZERO
			player.global_position = LIT_START
		_show_fall()
		return
	announce_fall = true
	get_tree().call_deferred("change_scene_to_file", LIT_ROOM)


func _show_fall() -> void:
	fall_label.visible = true
	_fall_left = FALL_TIME


func _on_healed(_amount: int, remaining: int) -> void:
	_show_health(remaining)


func _show_health(amount: int) -> void:
	health_value.text = str(amount)


func set_unmarked(count: int) -> void:
	if QUEST.delivered:
		_show_objective(QUEST.HEART_ANSWER)
		return
	if count > 0:
		_show_count("Unmarked", count)
		return
	if QUEST.all_names_read():
		_show_objective(QUEST.COAL_OBJECTIVE)
	elif not QUEST.names_read.is_empty():
		_show_count("Unread", QUEST.unread_count())
	else:
		_show_objective(QUEST.READ_OBJECTIVE)


func show_unread(count: int) -> void:
	if QUEST.delivered:
		_show_objective(QUEST.HEART_ANSWER)
		return
	if count > 0:
		_show_count("Unread", count)
		return
	_show_objective(QUEST.COAL_OBJECTIVE)


func show_heart_answer() -> void:
	_show_objective(QUEST.HEART_ANSWER)


func clear_quest() -> void:
	unmarked_row.visible = false
	objective.visible = false


func _show_count(title: String, count: int) -> void:
	unmarked_name.text = title
	unmarked_value.text = str(count)
	unmarked_row.visible = true
	objective.visible = false


func _bind_inventory() -> void:
	if not InputMap.has_action(&"inventory"):
		InputMap.add_action(&"inventory", 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_I
	if not InputMap.action_has_event(&"inventory", event):
		InputMap.action_add_event(&"inventory", event)


func _bind_drink() -> void:
	_bind_key(&"drink", KEY_1)


func _bind_save_keys() -> void:
	_bind_key(&"quick_save", KEY_F5)
	_bind_key(&"quick_load", KEY_F9)


func _bind_pause() -> void:
	_bind_key(&"pause", KEY_ESCAPE)


func _toggle_pause() -> void:
	_room_paused = not _room_paused
	if _room_paused:
		_quiet_loops()
		get_tree().paused = true
	else:
		get_tree().paused = false
		_restore_loops()
	pause_bar.visible = _room_paused


func _open_menu() -> void:
	_room_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)


func _quiet_loops() -> void:
	_quieted.clear()
	_collect_loops(get_tree().root)


func _collect_loops(node: Node) -> void:
	for child in node.get_children():
		var player := child as AudioStreamPlayer3D
		if player != null and (player.name == "FireCrackle" or player.name == "Footsteps"):
			if player.playing and not player.stream_paused:
				player.stream_paused = true
				_quieted.append(player)
		_collect_loops(child)


func _restore_loops() -> void:
	for player in _quieted:
		if is_instance_valid(player):
			player.stream_paused = false
	_quieted.clear()


func _bind_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _save_room() -> void:
	SAVE.write(_current_health())


func _load_room() -> void:
	var data := SAVE.read()
	if data.is_empty():
		return
	PACK.has_potion = bool(data["has_potion"])
	QUEST.restore(
		data["marked"],
		bool(data["ildra_read"]),
		bool(data["soren_read"]),
		bool(data["carrying_coal"]),
		bool(data["heart_answered"])
	)
	var stats := _player_stats()
	var amount := int(data["health"])
	if stats != null and stats.has_method("restore"):
		stats.call("restore", amount)
		amount = int(stats.get("health"))
	_show_health(amount)
	_sync_inventory(true)
	_show_saved_quest()


func _current_health() -> int:
	var stats := _player_stats()
	if stats != null:
		return int(stats.get("health"))
	return int(health_value.text)


func _player_stats() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	return player.get_node_or_null("CombatHealth")


func _show_saved_quest() -> void:
	if QUEST.delivered:
		show_heart_answer()
		return
	if not QUEST.names_read.is_empty() or QUEST.all_names_read():
		show_unread(QUEST.unread_count())
		return
	if QUEST.both_lit_marked():
		set_unmarked(0)
		return
	set_unmarked(maxi(2 - QUEST.lit_marked.size(), 0))


func _drink_potion() -> void:
	if not PACK.has_potion:
		return
	PACK.has_potion = false
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var stats := player.get_node_or_null("CombatHealth")
		if stats != null and stats.has_method("heal"):
			stats.call("heal", PACK.POTION_HEAL)
	_sync_inventory(true)


func _sync_inventory(force: bool) -> void:
	var carrying := QUEST.carrying_coal
	var potion := PACK.has_potion
	if (
		not force
		and inventory_items.get_child_count() > 0
		and _listed_coal == carrying
		and _listed_potion == potion
	):
		return
	_listed_coal = carrying
	_listed_potion = potion
	for child in inventory_items.get_children():
		inventory_items.remove_child(child)
		child.free()
	for gear in ["Rusty Sword", "Leather Vest"]:
		_add_inventory_line(gear, gear)
	if potion:
		_add_inventory_line(PACK.POTION, PACK.POTION)
	if carrying:
		_add_inventory_line("Coal", "Coal")


func _add_inventory_line(item_name: String, label_text: String) -> void:
	var line := Label.new()
	line.name = item_name
	line.text = label_text
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_color_override("font_color", Color(0.93, 0.84, 0.55))
	inventory_items.add_child(line)


func _show_objective(text: String) -> void:
	unmarked_row.visible = false
	objective.visible = true
	objective.text = text
	var panel := $Panel as Control
	panel.offset_right = 640.0
	panel.offset_bottom = 220.0
