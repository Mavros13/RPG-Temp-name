extends StaticBody3D

const SPEAKER_NAME := "Keeper Alden"
const LINE := "The braziers that still answer are the ones you mark."
const TALK_RANGE := 2.0
const ROOM_CENTER := Vector3(4.0, 0.0, 4.0)

var _dialogue: CanvasLayer
var _continue: Button
var _prompt: Label3D
var _open := false
var _held_player: CharacterBody3D


func _ready() -> void:
	_ensure_marker()
	_build_figure()
	_build_collision()
	_build_dialogue()
	_bind_talk()
	_face_room()
	_keep_window_title()


func _process(_delta: float) -> void:
	if _prompt:
		_prompt.visible = not _open and _in_range()


func _unhandled_input(event: InputEvent) -> void:
	if _open or not event.is_action_pressed(&"talk") or not _in_range():
		return
	_open_dialogue()
	get_viewport().set_input_as_handled()


func _ensure_marker() -> void:
	if get_node_or_null("Marker") == null:
		var marker := Marker3D.new()
		marker.name = "Marker"
		add_child(marker)


func _keep_window_title() -> void:
	# Godot 4.7 appends " (DEBUG)" when the main window refreshes its title
	# during startup, after the room scene sets it. Apply the name again once
	# that pass has finished.
	await get_tree().process_frame
	DisplayServer.window_set_title("APEX DREAMFORGE")


func _face_room() -> void:
	var flat := ROOM_CENTER - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		return
	rotation.y = atan2(flat.x, flat.z)


func _bind_talk() -> void:
	if not InputMap.has_action(&"talk"):
		InputMap.add_action(&"talk", 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	if not InputMap.action_has_event(&"talk", event):
		InputMap.action_add_event(&"talk", event)


func _player() -> CharacterBody3D:
	var room := get_parent()
	if room == null:
		return null
	return room.get_node_or_null("Player") as CharacterBody3D


func _in_range() -> bool:
	var player := _player()
	if player == null:
		return false
	var offset := player.global_position - global_position
	offset.y = 0.0
	return offset.length() <= TALK_RANGE


func _open_dialogue() -> void:
	if _open:
		return
	_open = true
	_dialogue.visible = true
	_continue.grab_focus()
	var player := _player()
	if player:
		player.velocity = Vector3.ZERO
		player.set_physics_process(false)
		_held_player = player


func _close_dialogue() -> void:
	_open = false
	if _dialogue:
		_dialogue.visible = false
	if _continue and _continue.has_focus():
		_continue.release_focus()
	if _held_player:
		_held_player.set_physics_process(true)
		_held_player = null


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.65
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.85, 0.0)
	add_child(shape)


func _build_figure() -> void:
	var robe := _mat(Color(0.1, 0.11, 0.15), 0.84, 0.02)
	var hood := _mat(Color(0.06, 0.065, 0.08), 0.72, 0.04)
	var gold := _mat(Color(0.72, 0.54, 0.24), 0.38, 0.72)
	var wood := _mat(Color(0.27, 0.17, 0.1), 0.74, 0.0)
	var flame := _mat(Color(1.0, 0.64, 0.24), 0.45, 0.0)
	flame.emission_enabled = true
	flame.emission = Color(1.0, 0.55, 0.18)
	flame.emission_energy_multiplier = 2.0

	var figure := Node3D.new()
	figure.name = "Figure"
	add_child(figure)

	_mesh(figure, _cylinder(0.62, 0.62, 0.018), Vector3(0.0, 0.012, 0.0), gold)
	_mesh(figure, _cylinder(0.36, 0.2, 1.22), Vector3(0.0, 0.64, 0.0), robe)
	_mesh(figure, _cylinder(0.38, 0.38, 0.045), Vector3(0.0, 0.08, 0.0), gold)
	_mesh(figure, _sphere(0.16), Vector3(0.0, 1.4, 0.0), hood)
	_mesh(figure, _box(Vector3(0.035, 0.86, 0.02)), Vector3(0.0, 0.72, 0.2), gold)
	_mesh(figure, _cylinder(0.025, 0.025, 1.35), Vector3(0.34, 0.72, 0.12), wood)
	_mesh(figure, _sphere(0.07), Vector3(0.34, 1.42, 0.16), flame)

	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.34, 1.42, 0.16)
	lamp.light_color = Color(1.0, 0.7, 0.38)
	lamp.light_energy = 0.45
	lamp.omni_range = 3.2
	lamp.shadow_enabled = false
	figure.add_child(lamp)

	var name_label := Label3D.new()
	name_label.name = "Name"
	name_label.text = SPEAKER_NAME
	name_label.font = ThemeDB.fallback_font
	name_label.font_size = 42
	name_label.pixel_size = 0.0032
	name_label.position = Vector3(0.0, 1.82, 0.0)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.modulate = Color(0.95, 0.84, 0.55)
	name_label.outline_size = 10
	name_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	figure.add_child(name_label)

	_prompt = Label3D.new()
	_prompt.name = "Prompt"
	_prompt.text = "Press E"
	_prompt.font = ThemeDB.fallback_font
	_prompt.font_size = 32
	_prompt.pixel_size = 0.003
	_prompt.position = Vector3(0.0, 2.08, 0.0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.modulate = Color(0.96, 0.9, 0.74)
	_prompt.outline_size = 8
	_prompt.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	figure.add_child(_prompt)


func _build_dialogue() -> void:
	_dialogue = CanvasLayer.new()
	_dialogue.name = "Dialogue"
	_dialogue.layer = 20
	_dialogue.visible = false
	add_child(_dialogue)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue.add_child(root)

	var panel := PanelContainer.new()
	panel.name = "Box"
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 36.0
	panel.offset_top = -168.0
	panel.offset_right = -36.0
	panel.offset_bottom = -24.0
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var speaker := Label.new()
	speaker.name = "Speaker"
	speaker.text = SPEAKER_NAME
	speaker.add_theme_font_size_override("font_size", 22)
	speaker.add_theme_color_override("font_color", Color(0.9, 0.75, 0.42))
	box.add_child(speaker)

	var rule := ColorRect.new()
	rule.color = Color(0.62, 0.46, 0.22)
	rule.custom_minimum_size = Vector2(0, 1)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(rule)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)

	var line := Label.new()
	line.name = "Line"
	line.text = LINE
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_theme_font_size_override("font_size", 18)
	line.add_theme_color_override("font_color", Color(0.9, 0.89, 0.85))
	row.add_child(line)

	_continue = Button.new()
	_continue.name = "Continue"
	_continue.text = "Continue"
	_continue.custom_minimum_size = Vector2(128, 36)
	_continue.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_continue(_continue)
	_continue.pressed.connect(_close_dialogue)
	row.add_child(_continue)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.04, 0.036, 0.97)
	style.border_color = Color(0.75, 0.56, 0.28)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 22
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style


func _style_continue(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.84, 0.66, 0.36)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.92, 0.76, 0.46)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.7, 0.52, 0.26)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	var ink := Color(0.14, 0.1, 0.05)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_focus_color", ink)
	button.add_theme_font_size_override("font_size", 16)


func _mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)


func _cylinder(bottom_radius: float, top_radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom_radius
	mesh.top_radius = top_radius
	mesh.height = height
	mesh.radial_segments = 18
	return mesh


func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return mesh


func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh
