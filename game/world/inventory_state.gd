extends RefCounted

## One minor potion. Scene changes keep this, the same way quest progress does.
const POTION := "Minor Potion"
const POTION_HEAL := 8
const BASE_ATTACK := 4
const SWORD_BONUS := 3

static var has_potion: bool
static var sword_equipped: bool


static func _static_init() -> void:
	has_potion = true
	sword_equipped = true


static func attack() -> int:
	if sword_equipped:
		return BASE_ATTACK + SWORD_BONUS
	return BASE_ATTACK
