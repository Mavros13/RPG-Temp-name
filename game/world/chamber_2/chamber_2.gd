extends Node3D

const TILE := 2.0
const TILES_X := 5
const TILES_Z := 4
const ROOM_X := TILE * float(TILES_X)
const ROOM_Z := TILE * float(TILES_Z)
const PLINTH := 0.07
const WALL_THICKNESS := 0.5
const WALL_HEIGHT := 3.2
const DOOR_CENTER_X := 5.0
const DOOR_WIDTH := 2.0

const FLOOR_SCENE := preload("res://assets/world/first_room/stone_floor_tile.glb")
const WALL_SCENE := preload("res://assets/world/first_room/wall_segment.glb")
const BRAZIER_SCENE := preload("res://assets/world/first_room/brazier.glb")
const PASSAGE := preload("res://game/world/passage.gd")
const HUD_SCENE := preload("res://game/ui/hud_3d/hud_3d.tscn")
const DARK_BRAZIERS := preload("res://game/world/chamber_2/dark_braziers.gd")

func _ready() -> void:
	DisplayServer.window_set_title("APEX DREAMFORGE")
	_setup_lighting()
	_build_bounds()
	_build_floor()
	_build_walls()
	_place_braziers()
	_place_dark_braziers()
	_place_passage()


func _setup_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.032, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.58)
	env.ambient_light_energy = 0.26
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	$WorldEnvironment.environment = env

	var fill := $FillLight as DirectionalLight3D
	fill.rotation_degrees = Vector3(-48.0, -36.0, 0.0)
	fill.light_color = Color(0.9, 0.93, 1.0)
	fill.light_energy = 0.2
	fill.shadow_enabled = true


func _build_bounds() -> void:
	var body := $Bounds as StaticBody3D
	_add_box(body, Vector3(ROOM_X, 0.4, ROOM_Z), Vector3(ROOM_X * 0.5, -0.2, ROOM_Z * 0.5))
	var reach := WALL_THICKNESS * 0.5
	var along_x := ROOM_X + 0.8
	var along_z := ROOM_Z + 0.8
	var mid_x := ROOM_X * 0.5
	var mid_z := ROOM_Z * 0.5
	var height := WALL_HEIGHT * 0.5
	_add_south_opening(body, height, PLINTH - reach, ROOM_X)
	_add_box(body, Vector3(along_x, WALL_HEIGHT, WALL_THICKNESS), Vector3(mid_x, height, ROOM_Z - PLINTH + reach))
	_add_box(body, Vector3(WALL_THICKNESS, WALL_HEIGHT, along_z), Vector3(PLINTH - reach, height, mid_z))
	_add_box(body, Vector3(WALL_THICKNESS, WALL_HEIGHT, along_z), Vector3(ROOM_X - PLINTH + reach, height, mid_z))


func _add_south_opening(body: StaticBody3D, height: float, south_z: float, room_span: float) -> void:
	var overhang := 0.4
	var left := DOOR_CENTER_X - DOOR_WIDTH * 0.5
	var right := DOOR_CENTER_X + DOOR_WIDTH * 0.5
	_add_x_span(body, -overhang, left, height, south_z)
	_add_x_span(body, right, room_span + overhang, height, south_z)
	_add_box(body, Vector3(DOOR_WIDTH - 0.15, 0.4, 1.8), Vector3(DOOR_CENTER_X, -0.2, 0.2))


func _add_x_span(body: StaticBody3D, x0: float, x1: float, height: float, z: float) -> void:
	_add_box(body, Vector3(x1 - x0, WALL_HEIGHT, WALL_THICKNESS), Vector3((x0 + x1) * 0.5, height, z))


func _place_passage() -> void:
	PASSAGE.place(self, Vector3(DOOR_CENTER_X, 1.1, 0.35), "res://game/world/room_3d/room_3d.tscn", "ReturnDoor", "Back to the room")


func _add_box(body: StaticBody3D, size: Vector3, box_position: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = box_position
	body.add_child(shape)


func _build_floor() -> void:
	var parent := $Visuals/Floor
	for x in TILES_X:
		for z in TILES_Z:
			var tile := FLOOR_SCENE.instantiate()
			tile.position = Vector3((float(x) + 0.5) * TILE, 0.0, (float(z) + 0.5) * TILE)
			parent.add_child(tile)


func _build_walls() -> void:
	var parent := $Visuals/Walls
	for x in TILES_X:
		var center_x := (float(x) + 0.5) * TILE
		if absf(center_x - DOOR_CENTER_X) > 0.01:
			_add_wall(parent, Vector3(center_x, 0.0, 0.0), 0.0)
		_add_wall(parent, Vector3(center_x, 0.0, ROOM_Z), PI)
	for z in TILES_Z:
		var center_z := (float(z) + 0.5) * TILE
		_add_wall(parent, Vector3(0.0, 0.0, center_z), PI * 0.5)
		_add_wall(parent, Vector3(ROOM_X, 0.0, center_z), -PI * 0.5)


func _add_wall(parent: Node, wall_position: Vector3, yaw: float) -> void:
	var wall := WALL_SCENE.instantiate()
	wall.position = wall_position
	wall.rotation.y = yaw
	parent.add_child(wall)


func _place_braziers() -> void:
	for at in [Vector3(1.8, 0.0, 1.6), Vector3(8.2, 0.0, 1.6), Vector3(1.8, 0.0, 6.4), Vector3(8.2, 0.0, 6.4)]:
		var brazier := BRAZIER_SCENE.instantiate()
		brazier.position = at
		$Visuals/Braziers.add_child(brazier)


func _place_dark_braziers() -> void:
	var hud := HUD_SCENE.instantiate()
	hud.name = "Hud3D"
	add_child(hud)
	var root := Node3D.new()
	root.name = "DarkBraziers"
	$Visuals.add_child(root)
	var reader := DARK_BRAZIERS.new()
	reader.name = "DarkBrazierReader"
	add_child(reader)
	reader.bind(root, hud)
