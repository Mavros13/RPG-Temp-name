class_name InventoryData
extends Resource

## A list of item resources. Storage only: no equipment slots and no combat.

@export var items: Array[ItemData] = []


func add_item(item: ItemData) -> void:
	items.append(item)


func remove_item(item: ItemData) -> bool:
	var index := items.find(item)
	if index < 0:
		return false
	items.remove_at(index)
	return true
