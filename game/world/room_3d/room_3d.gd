extends Node3D

const TILE := 2.0
const TILES := 4
const ROOM_SIZE := TILE * float(TILES)
const PLINTH := 0.07
const WALL_THICKNESS := 0.5
const WALL_HEIGHT := 3.2

const FLOOR_SCENE := preload("res://assets/world/first_room/stone_floor_tile.glb")
const WALL_SCENE := preload("res://assets/world/first_room/wall_segment.glb")
const BRAZIER_SCENE := preload("res://assets/world/first_room/brazier.glb")
const HOSTILE_SCENE := preload("res://assets/characters/hostile_npc/hostile_npc.gltf")

func _ready() -> void:
	DisplayServer.window_set_title("APEX DREAMFORGE")
	_setup_lighting()
	_build_bounds()
	_build_floor()
	_build_walls()
	_place_braziers()
	_place_hostile()


func _setup_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.03, 0.028)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.48, 0.4)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	$WorldEnvironment.environment = env

	var fill := $FillLight as DirectionalLight3D
	fill.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
	fill.light_color = Color(1.0, 0.93, 0.84)
	fill.light_energy = 0.22
	fill.shadow_enabled = true


func _build_bounds() -> void:
	var body := $Bounds as StaticBody3D
	_add_box(body, Vector3(ROOM_SIZE, 0.4, ROOM_SIZE), Vector3(ROOM_SIZE * 0.5, -0.2, ROOM_SIZE * 0.5))
	var reach := WALL_THICKNESS * 0.5
	var along := ROOM_SIZE + 0.8
	var mid := ROOM_SIZE * 0.5
	var height := WALL_HEIGHT * 0.5
	_add_box(body, Vector3(along, WALL_HEIGHT, WALL_THICKNESS), Vector3(mid, height, PLINTH - reach))
	_add_box(body, Vector3(along, WALL_HEIGHT, WALL_THICKNESS), Vector3(mid, height, ROOM_SIZE - PLINTH + reach))
	_add_box(body, Vector3(WALL_THICKNESS, WALL_HEIGHT, along), Vector3(PLINTH - reach, height, mid))
	_add_box(body, Vector3(WALL_THICKNESS, WALL_HEIGHT, along), Vector3(ROOM_SIZE - PLINTH + reach, height, mid))


func _add_box(body: StaticBody3D, size: Vector3, position: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = position
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
	for i in TILES:
		var center := (float(i) + 0.5) * TILE
		_add_wall(parent, Vector3(center, 0.0, 0.0), 0.0)
		_add_wall(parent, Vector3(center, 0.0, ROOM_SIZE), PI)
		_add_wall(parent, Vector3(0.0, 0.0, center), PI * 0.5)
		_add_wall(parent, Vector3(ROOM_SIZE, 0.0, center), -PI * 0.5)


func _add_wall(parent: Node, wall_position: Vector3, yaw: float) -> void:
	var wall := WALL_SCENE.instantiate()
	wall.position = wall_position
	wall.rotation.y = yaw
	parent.add_child(wall)


func _place_braziers() -> void:
	for at in [Vector3(1.8, 0.0, 4.4), Vector3(6.2, 0.0, 4.4)]:
		var brazier := BRAZIER_SCENE.instantiate()
		brazier.position = at
		$Visuals/Braziers.add_child(brazier)


func _place_hostile() -> void:
	var visual := HOSTILE_SCENE.instantiate()
	visual.rotation.y = PI
	var body := $Hostile as Node3D
	body.add_child(visual)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.85, 0.0)
	body.add_child(shape)
