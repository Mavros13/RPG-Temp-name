extends CanvasLayer

## Attack and defense stay on this sheet. Health follows the player's combat health.
const ATTACK := 4
const DEFENSE := 2

@onready var health_value: Label = %HealthValue
@onready var attack_value: Label = %AttackValue
@onready var defense_value: Label = %DefenseValue
@onready var unmarked_value: Label = %UnmarkedValue

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
	unmarked_value.text = str(count)
