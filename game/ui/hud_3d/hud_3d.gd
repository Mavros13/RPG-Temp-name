extends CanvasLayer

## Attack and defense stay on this sheet. Health follows the player's combat health.
const QUEST := preload("res://game/world/quest_state.gd")
const PACK := preload("res://game/world/inventory_state.gd")

@onready var health_value: Label = %HealthValue
@onready var attack_value: Label = %AttackValue
@onready var defense_value: Label = %DefenseValue
@onready var unmarked_row: HBoxContainer = %UnmarkedRow
@onready var unmarked_name: Label = %UnmarkedName
@onready var unmarked_value: Label = %UnmarkedValue
@onready var objective: Label = %Objective
@onready var inventory: PanelContainer = %Inventory
@onready var inventory_items: VBoxContainer = %InventoryItems

var _health: Node
var _listed_coal := false
var _listed_potion := false


func _ready() -> void:
	attack_value.text = str(PACK.attack())
	defense_value.text = str(PACK.defense())
	_bind_inventory()
	_bind_drink()
	inventory.visible = false
	_sync_inventory(true)
	set_process(not _bind_health())


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"inventory"):
		inventory.visible = not inventory.visible
		_sync_inventory(true)
	if Input.is_action_just_pressed(&"drink"):
		_drink_potion()
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
	if not InputMap.has_action(&"drink"):
		InputMap.add_action(&"drink", 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_1
	if not InputMap.action_has_event(&"drink", event):
		InputMap.action_add_event(&"drink", event)


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
