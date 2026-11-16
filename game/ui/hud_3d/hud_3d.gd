extends CanvasLayer

## Placeholder combat stats until a character sheet drives the HUD.
const HEALTH := 20
const ATTACK := 4
const DEFENSE := 2

@onready var health_value: Label = %HealthValue
@onready var attack_value: Label = %AttackValue
@onready var defense_value: Label = %DefenseValue


func _ready() -> void:
	health_value.text = str(HEALTH)
	attack_value.text = str(ATTACK)
	defense_value.text = str(DEFENSE)
