extends Node3D

const TILE := 2.0
const TILES := 3
const ROOM := TILE * float(TILES)
const PLINTH := 0.07
const WALL_THICKNESS := 0.5
const WALL_HEIGHT := 3.2
const DOOR_CENTER_X := 3.0
const DOOR_WIDTH := 2.0

const FLOOR_SCENE := preload("res://assets/world/first_room/stone_floor_tile.glb")
const WALL_SCENE := preload("res://assets/world/first_room/wall_segment.glb")
const PASSAGE := preload("res://game/world/passage.gd")
const INSCRIPTION := preload("res://game/world/alcove/inscription.gd")
const HUD := preload("res://game/ui/hud_3d/hud_3d.gd")


func _ready() -> void:
	DisplayServer.window_set_title("APEX DREAMFORGE")
	_setup_lighting()
	_build_bounds()
	_build_floor()
	_build_walls()
	_place_passage()
	_place_inscription()
	_show_controls()


func _setup_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.032, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.5, 0.42)
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	$WorldEnvironment.environment = env

	var fill := $FillLight as DirectionalLight3D
	fill.rotation_degrees = Vector3(-50.0, 20.0, 0.0)
	fill.light_color = Color(1.0, 0.93, 0.82)
	fill.light_energy = 0.35
	fill.shadow_enabled = true


func _build_bounds() -> void:
	var body := $Bounds as StaticBody3D
	_add_box(body, Vector3(ROOM, 0.4, ROOM), Vector3(ROOM * 0.5, -0.2, ROOM * 0.5))
	var reach := WALL_THICKNESS * 0.5
	var height := WALL_HEIGHT * 0.5
	var mid := ROOM * 0.5
	var along := ROOM + 0.8
	_add_south_opening(body, height, PLINTH - reach)
	_add_box(body, Vector3(along, WALL_HEIGHT, WALL_THICKNESS), Vector3(mid, height, ROOM - PLINTH + reach))
	_add_box(body, Vector3(WALL_THICKNESS, WALL_HEIGHT, along), Vector3(PLINTH - reach, height, mid))
	_add_box(body, Vector3(WALL_THICKNESS, WALL_HEIGHT, along), Vector3(ROOM - PLINTH + reach, height, mid))


func _add_south_opening(body: StaticBody3D, height: float, south_z: float) -> void:
	var overhang := 0.4
	var left := DOOR_CENTER_X - DOOR_WIDTH * 0.5
	var right := DOOR_CENTER_X + DOOR_WIDTH * 0.5
	_add_x_span(body, -overhang, left, height, south_z)
	_add_x_span(body, right, ROOM + overhang, height, south_z)


func _add_x_span(body: StaticBody3D, x0: float, x1: float, height: float, z: float) -> void:
	_add_box(body, Vector3(x1 - x0, WALL_HEIGHT, WALL_THICKNESS), Vector3((x0 + x1) * 0.5, height, z))


func _add_box(body: StaticBody3D, size: Vector3, box_position: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = box_position
	body.add_child(shape)


func _build_floor() -> void:
	var parent := $Visuals/Floor
	for x in TILES:
		for z in TILES:
			var tile := FLOOR_SCENE.instantiate()
			tile.position = Vector3((float(x) + 0.5) * TILE, 0.0, (float(z) + 0.5) * TILE)
			parent.add_child(tile)


func _build_walls() -> void:
	var parent := $Visuals/Walls
	for x in TILES:
		var center_x := (float(x) + 0.5) * TILE
		if absf(center_x - DOOR_CENTER_X) > 0.01:
			_add_wall(parent, Vector3(center_x, 0.0, 0.0), 0.0)
		_add_wall(parent, Vector3(center_x, 0.0, ROOM), PI)
	for z in TILES:
		var center_z := (float(z) + 0.5) * TILE
		_add_wall(parent, Vector3(0.0, 0.0, center_z), PI * 0.5)
		_add_wall(parent, Vector3(ROOM, 0.0, center_z), -PI * 0.5)


func _add_wall(parent: Node, wall_position: Vector3, yaw: float) -> void:
	var wall := WALL_SCENE.instantiate()
	wall.position = wall_position
	wall.rotation.y = yaw
	parent.add_child(wall)


func _place_passage() -> void:
	PASSAGE.place(self, Vector3(DOOR_CENTER_X, 1.1, 0.35), "res://game/world/chamber_2/chamber_2.tscn", "ChamberReturn", "Back to the chamber")


func _show_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ControlsLayer"
	layer.layer = 10
	add_child(layer)
	var line := HUD._make_controls_line()
	layer.add_child(line)
	var save_line := HUD._make_save_line()
	layer.add_child(save_line)
	_refresh_controls_line.call_deferred(line, save_line)


func _refresh_controls_line(line: Label, save_line: Label) -> void:
	line.text = HUD.controls_text()
	save_line.text = HUD.save_line_text()


func _place_inscription() -> void:
	var note := INSCRIPTION.new()
	note.name = "Inscription"
	add_child(note)
