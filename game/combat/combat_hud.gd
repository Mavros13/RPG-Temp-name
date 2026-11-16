extends CanvasLayer

const NEAR_RANGE := 3.0

var _label: Label
var _flash: ColorRect
var _bound: Node


func _ready() -> void:
	_flash = ColorRect.new()
	_flash.color = Color(0.55, 0.02, 0.01, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_label = Label.new()
	_label.position = Vector2(28, 22)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.96, 0.91, 0.82))
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.012, 0.9))
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _process(delta: float) -> void:
	_fade(delta)
	var player := get_tree().get_first_node_in_group("player") as Node
	var raider := get_tree().get_first_node_in_group("raiders") as Node
	var player_hp := 0
	var player_max := 0
	if player != null:
		var stats := player.get_node_or_null("CombatHealth")
		if stats != null:
			player_hp = int(stats.get("health"))
			player_max = int(stats.get("max_health"))
			_bind_flash(stats)
	var raider_text := ""
	var raider_hp := _nearby_health(player, raider)
	if raider_hp >= 0:
		raider_text = "    Raider %d" % raider_hp
	var down := ""
	if player != null and player.has_meta("defeated"):
		down = "  down"
	_label.text = "You %d/%d%s%s" % [player_hp, player_max, down, raider_text]


func _nearby_health(player: Node, raider: Node) -> int:
	if player == null or raider == null or not is_instance_valid(raider):
		return -1
	if float(raider.get("_fall")) >= 0.0:
		return -1
	var stats := raider.get_node_or_null("CombatHealth")
	if stats == null:
		return -1
	var health := int(stats.get("health"))
	if health <= 0:
		return -1
	var origin := player as Node3D
	var body := raider as Node3D
	if origin == null or body == null:
		return -1
	var flat := body.global_position - origin.global_position
	flat.y = 0.0
	if flat.length() > NEAR_RANGE:
		return -1
	return health


func _bind_flash(stats: Node) -> void:
	if _bound == stats:
		return
	if stats.has_signal("damaged"):
		stats.connect("damaged", Callable(self, "_on_player_damaged"))
	_bound = stats


func _on_player_damaged(_amount: int, _remaining: int) -> void:
	_flash.color = Color(0.55, 0.02, 0.01, 0.42)


func _fade(delta: float) -> void:
	var color := _flash.color
	if color.a <= 0.0:
		return
	color.a = maxf(color.a - delta * 1.5, 0.0)
	_flash.color = color
