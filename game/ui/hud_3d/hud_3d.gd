extends CanvasLayer

## Attack and defense stay on this sheet. Health follows the player's combat health.
const QUEST := preload("res://game/world/quest_state.gd")
const ATTACK := 4
const DEFENSE := 2

@onready var health_value: Label = %HealthValue
@onready var attack_value: Label = %AttackValue
@onready var defense_value: Label = %DefenseValue
@onready var unmarked_row: HBoxContainer = %UnmarkedRow
@onready var unmarked_name: Label = %UnmarkedName
@onready var unmarked_value: Label = %UnmarkedValue
@onready var objective: Label = %Objective

var _health: Node


func _ready() -> void:
	attack_value.text = str(ATTACK)
	defense_value.text = str(DEFENSE)
	set_process(not _bind_health())


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
	return true


func _on_damaged(_amount: int, remaining: int) -> void:
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


func _show_objective(text: String) -> void:
	unmarked_row.visible = false
	objective.visible = true
	objective.text = text
	var panel := $Panel as Control
	panel.offset_right = 640.0
	panel.offset_bottom = 220.0
