class_name ItemData
extends Resource

## A named starter item and the core-stat modifiers it carries.

enum Kind {
	WEAPON,
	ARMOR,
	CONSUMABLE,
}

@export var item_name: String = ""
@export var kind: Kind = Kind.WEAPON
@export var modifiers: CoreStats


func _init() -> void:
	if modifiers == null:
		modifiers = CoreStats.new()
