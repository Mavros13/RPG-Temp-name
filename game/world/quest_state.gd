extends RefCounted

## Quest progress shared across the doorway. Scene changes keep these values.
const DARK_NAMES: Array[String] = ["Ildra", "Soren"]
const READ_OBJECTIVE := "Read the mark on every brazier that stayed dark and bring those names back."
const COAL_OBJECTIVE := "Take a coal from a brazier that still answers and carry it to the Dreamforge heart."
const HEART_ANSWER := "The heart answers."

static var lit_marked: Array[int]
static var names_read: Array[String]
static var carrying_coal: bool
static var delivered: bool


static func _static_init() -> void:
	lit_marked = []
	names_read = []
	carrying_coal = false
	delivered = false


static func both_lit_marked() -> bool:
	return lit_marked.size() >= 2


static func is_lit_marked(index: int) -> bool:
	return lit_marked.has(index)


static func mark_lit(index: int) -> void:
	if index < 0 or lit_marked.has(index):
		return
	lit_marked.append(index)


static func try_read(mark_name: String) -> bool:
	if not both_lit_marked():
		return false
	if mark_name.is_empty() or names_read.has(mark_name):
		return false
	names_read.append(mark_name)
	return true


static func unread_count() -> int:
	return DARK_NAMES.size() - names_read.size()


static func all_names_read() -> bool:
	return names_read.size() >= DARK_NAMES.size()


static func take_coal() -> bool:
	if not all_names_read() or carrying_coal or delivered:
		return false
	carrying_coal = true
	return true


static func deliver_coal() -> bool:
	if not carrying_coal or delivered:
		return false
	delivered = true
	carrying_coal = false
	return true
