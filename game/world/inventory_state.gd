extends RefCounted

## Minor potions. Scene changes keep these, the same way quest progress does.
const POTION := "Minor Potion"
const POTION_HEAL := 8
const BASE_ATTACK := 4
const SWORD_BONUS := 3
const BASE_DEFENSE := 2
const VEST_BONUS := 2
const CONTACT_POWER := 6

static var has_potion
static var sword_equipped: bool
static var vest_equipped: bool


static func _static_init() -> void:
	has_potion = true
	sword_equipped = true
	vest_equipped = true


static func potion_count() -> int:
	if has_potion is bool:
		return 1 if has_potion else 0
	return int(has_potion)


static func grant_potion() -> void:
	has_potion = potion_count() + 1


static func attack() -> int:
	if sword_equipped:
		return BASE_ATTACK + SWORD_BONUS
	return BASE_ATTACK


static func defense() -> int:
	if vest_equipped:
		return BASE_DEFENSE + VEST_BONUS
	return BASE_DEFENSE


static func contact_damage() -> int:
	return maxi(CONTACT_POWER - defense(), 1)
