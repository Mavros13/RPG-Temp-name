extends RefCounted

## Local room save. F5 writes it and F9 reads it back.
const QUEST := preload("res://game/world/quest_state.gd")
const PACK := preload("res://game/world/inventory_state.gd")
const NOTE := preload("res://game/world/alcove/inscription.gd")
const PATH := "user://room_save.cfg"

static var apply_on_enter := false


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func write(health: int) -> bool:
	var file := ConfigFile.new()
	file.set_value("room", "health", health)
	var potions := clampi(PACK.potion_count(), 0, 2)
	file.set_value("room", "potion_count", potions)
	file.set_value("room", "has_potion", potions > 0)
	file.set_value("room", "carrying_coal", QUEST.carrying_coal)
	file.set_value("room", "lit_marked", QUEST.lit_marked.size())
	file.set_value("room", "marked_indices", _indices_text(QUEST.lit_marked))
	file.set_value("room", "ildra_read", QUEST.names_read.has("Ildra"))
	file.set_value("room", "soren_read", QUEST.names_read.has("Soren"))
	file.set_value("room", "heart_answered", QUEST.delivered)
	file.set_value("room", "alcove_line_read", NOTE.read)
	return file.save(PATH) == OK


static func take_apply() -> bool:
	var armed := apply_on_enter
	apply_on_enter = false
	return armed and exists()


static func read() -> Dictionary:
	if not exists():
		return {}
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return {}
	var marked := _indices_from(file)
	var potions := _potion_count(file)
	return {
		"health": int(file.get_value("room", "health", 0)),
		"potion_count": potions,
		"has_potion": potions > 0,
		"carrying_coal": bool(file.get_value("room", "carrying_coal", false)),
		"lit_marked": marked.size(),
		"marked": marked,
		"ildra_read": bool(file.get_value("room", "ildra_read", false)),
		"soren_read": bool(file.get_value("room", "soren_read", false)),
		"heart_answered": bool(file.get_value("room", "heart_answered", false)),
		"alcove_line_read": bool(file.get_value("room", "alcove_line_read", false)),
	}


static func _potion_count(file: ConfigFile) -> int:
	if file.has_section_key("room", "potion_count"):
		return clampi(int(file.get_value("room", "potion_count")), 0, 2)
	var legacy = file.get_value("room", "has_potion", 1)
	if legacy is bool:
		return 1 if legacy else 0
	return clampi(int(legacy), 0, 2)


static func _indices_text(indices: Array) -> String:
	var parts := PackedStringArray()
	for index in indices:
		parts.append(str(int(index)))
	return ",".join(parts)


static func _indices_from(file: ConfigFile) -> Array:
	var text := str(file.get_value("room", "marked_indices", ""))
	var marked: Array = []
	if not text.is_empty():
		for part in text.split(",", false):
			marked.append(int(part))
		return marked
	var count := int(file.get_value("room", "lit_marked", 0))
	for index in count:
		marked.append(index)
	return marked
