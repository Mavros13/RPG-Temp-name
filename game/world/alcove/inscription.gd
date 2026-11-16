extends Node

const LINE := "The forge kept your name."

static var read := false

var _open := false
var _layer: CanvasLayer
var _line: Label


func _ready() -> void:
	_bind_read()
	_build_line()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_read_key(event):
		return
	if _open:
		_hide()
	else:
		_show()
	get_viewport().set_input_as_handled()


func _bind_read() -> void:
	if not InputMap.has_action(&"mark"):
		InputMap.add_action(&"mark", 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F
	if not InputMap.action_has_event(&"mark", event):
		InputMap.action_add_event(&"mark", event)


func _is_read_key(event: InputEvent) -> bool:
	if event.is_action_pressed(&"mark"):
		return true
	var key := event as InputEventKey
	return key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F


func _show() -> void:
	read = true
	_open = true
	_layer.visible = true


func _hide() -> void:
	_open = false
	_layer.visible = false


func _build_line() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "LineLayer"
	_layer.layer = 20
	_layer.visible = false
	add_child(_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 36.0
	panel.offset_top = -148.0
	panel.offset_right = -36.0
	panel.offset_bottom = -28.0
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)

	_line = Label.new()
	_line.name = "Line"
	_line.text = LINE
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_line.add_theme_font_size_override("font_size", 22)
	_line.add_theme_color_override("font_color", Color(0.93, 0.88, 0.78))
	row.add_child(_line)

	var continue_button := Button.new()
	continue_button.name = "Continue"
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(128, 36)
	continue_button.pressed.connect(_hide)
	row.add_child(continue_button)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.04, 0.96)
	style.border_color = Color(0.75, 0.58, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
