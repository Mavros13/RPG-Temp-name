extends RefCounted

## One minor potion. Scene changes keep this, the same way quest progress does.
const POTION := "Minor Potion"
const POTION_HEAL := 8

static var has_potion: bool


static func _static_init() -> void:
	has_potion = true
