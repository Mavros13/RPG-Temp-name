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
const SURFACE_SHADER := preload("res://game/world/room_3d/materials/room_surface.gdshader")
const FIRE_SHADER := preload("res://game/world/room_3d/materials/room_fire.gdshader")

var _materials: Dictionary = {}

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
	env.background_color = Color(0.015, 0.012, 0.01)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.46, 0.32)
	env.ambient_light_energy = 0.05
	env.ambient_light_sky_contribution = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_strength = 0.65
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.85
	env.glow_hdr_scale = 1.6
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	$WorldEnvironment.environment = env

	# One orthogonal cascade covers this 8 m room. 2048 is set on the
	# project so the shadow map stays small enough for a laptop.
	var key := $KeyLight as DirectionalLight3D
	key.rotation_degrees = Vector3(-62.0, 168.0, 0.0)
	key.light_color = Color(1.0, 0.9, 0.76)
	key.light_energy = 0.4
	key.light_specular = 0.45
	key.light_indirect_energy = 0.25
	key.shadow_enabled = true
	key.shadow_bias = 0.03
	key.shadow_normal_bias = 1.15
	key.shadow_blur = 0.6
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 16.0
	key.directional_shadow_fade_start = 0.88
	key.light_angular_distance = 0.0

	var probe := ReflectionProbe.new()
	probe.name = "RoomProbe"
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.45
	probe.interior = true
	probe.box_projection = true
	probe.size = Vector3(10.0, 5.0, 10.0)
	probe.position = Vector3(ROOM_SIZE * 0.5, 1.8, ROOM_SIZE * 0.5)
	add_child(probe)


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
			_dress_tree(tile)
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
	_dress_tree(wall)
	parent.add_child(wall)


func _place_braziers() -> void:
	for at in [Vector3(1.8, 0.0, 4.4), Vector3(6.2, 0.0, 4.4)]:
		var brazier := BRAZIER_SCENE.instantiate()
		brazier.position = at
		_dress_tree(brazier)
		_tune_fire_light(brazier)
		$Visuals/Braziers.add_child(brazier)


func _tune_fire_light(brazier: Node) -> void:
	var light := _find_omni(brazier)
	if light == null:
		light = OmniLight3D.new()
		light.name = "FireLight"
		light.position = Vector3(0.0, 1.12, 0.0)
		brazier.add_child(light)
	light.light_color = Color(1.0, 0.46, 0.12)
	light.light_energy = 2.55
	light.light_specular = 0.7
	light.light_indirect_energy = 0.35
	light.omni_range = 5.8
	light.omni_attenuation = 1.8
	# Two fires would each render six shadow faces. The key light is the shadow caster.
	light.shadow_enabled = false


func _find_omni(node: Node) -> OmniLight3D:
	if node is OmniLight3D:
		return node
	for child in node.get_children():
		var found := _find_omni(child)
		if found != null:
			return found
	return null


func _dress_tree(root: Node) -> void:
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child in node.get_children():
			pending.append(child)
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		if String(mesh_instance.name).to_lower().contains("flame"):
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in mesh_instance.mesh.get_surface_count():
			var dressed := _surface_material(mesh_instance.get_active_material(surface))
			mesh_instance.set_surface_override_material(surface, dressed)


func _surface_material(existing: Material) -> Material:
	var albedo := Color(0.18, 0.15, 0.12)
	var rough := 0.92
	var metal := 0.0
	var emission := Color(0, 0, 0)
	var emission_energy := 0.0
	var unshaded := false
	var label := ""
	var std := existing as StandardMaterial3D
	if std != null:
		albedo = std.albedo_color
		rough = std.roughness
		metal = std.metallic
		if std.emission_enabled:
			emission = std.emission
			emission_energy = std.emission_energy_multiplier
		unshaded = std.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
		label = std.resource_name.to_lower()
	var kind := _material_kind(label, albedo, rough, metal, emission_energy, unshaded)
	var key := "%s|%s|%.3f|%.3f|%.3f" % [kind, albedo.to_html(false), rough, metal, emission_energy]
	if _materials.has(key):
		return _materials[key]
	var built := _build_material(kind, albedo, rough, metal, emission, emission_energy)
	_materials[key] = built
	return built


func _material_kind(label: String, albedo: Color, rough: float, metal: float, emission_energy: float, unshaded: bool) -> String:
	if "flame" in label or (unshaded and albedo.r > 0.55 and metal < 0.2):
		return "fire"
	if "ember" in label or "coal" in label or emission_energy > 0.05:
		return "ember"
	if "iron" in label or metal >= 0.5:
		return "metal"
	if "mortar" in label or (rough >= 0.97 and albedo.get_luminance() < 0.08):
		return "mortar"
	return "stone"


func _build_material(kind: String, albedo: Color, rough: float, metal: float, emission: Color, emission_energy: float) -> ShaderMaterial:
	if kind == "fire":
		var fire := ShaderMaterial.new()
		fire.shader = FIRE_SHADER
		var core := albedo.g > 0.75
		fire.set_shader_parameter("albedo", albedo)
		fire.set_shader_parameter("energy", 2.15 if core else 1.35)
		fire.set_shader_parameter("flicker", 0.14 if core else 0.22)
		return fire

	var grain := 0.26
	var grain_scale := 2.6
	var normal_strength := 0.4
	var ao_strength := 0.2
	var flicker := 0.0
	if kind == "mortar":
		grain = 0.08
		grain_scale = 7.5
		normal_strength = 0.12
		ao_strength = 0.05
		rough = maxf(rough, 0.96)
		metal = 0.0
	elif kind == "metal":
		albedo = Color(albedo.r * 1.04, albedo.g * 0.9, albedo.b * 0.78)
		rough = clampf(rough, 0.42, 0.62)
		metal = 1.0
		grain = 0.1
		grain_scale = 11.0
		normal_strength = 0.18
		ao_strength = 0.06
	elif kind == "ember":
		grain = 0.16
		grain_scale = 5.0
		normal_strength = 0.2
		ao_strength = 0.12
		metal = 0.0
		emission_energy = maxf(emission_energy * 1.25, 0.45)
		flicker = 0.26 if emission_energy > 1.5 else 0.06
		if emission.get_luminance() < 0.001:
			emission = Color(1.0, 0.22, 0.04)

	var mat := ShaderMaterial.new()
	mat.shader = SURFACE_SHADER
	mat.set_shader_parameter("albedo", albedo)
	mat.set_shader_parameter("roughness_base", rough)
	mat.set_shader_parameter("metallic", metal)
	mat.set_shader_parameter("grain", grain)
	mat.set_shader_parameter("grain_scale", grain_scale)
	mat.set_shader_parameter("normal_strength", normal_strength)
	mat.set_shader_parameter("ao_strength", ao_strength)
	mat.set_shader_parameter("emission_color", Vector3(emission.r, emission.g, emission.b))
	mat.set_shader_parameter("emission_energy", emission_energy)
	mat.set_shader_parameter("flicker", flicker)
	return mat


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
