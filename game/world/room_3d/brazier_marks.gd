extends Node

const MARK_RANGE := 1.7
const FIRE_SHADER := "res://game/world/room_3d/materials/room_fire.gdshader"
const SURFACE_SHADER := "res://game/world/room_3d/materials/room_surface.gdshader"

signal marks_changed(unmarked: int)

var unmarked := 0
var _braziers: Array[Node3D] = []


func bind(parent: Node) -> void:
	_bind_mark()
	for child in parent.get_children():
		if child is Node3D:
			_braziers.append(child)
	unmarked = _braziers.size()


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"mark"):
		_try_mark()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mark"):
		_try_mark()


func _try_mark() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		var room := get_parent()
		if room != null:
			player = room.get_node_or_null("Player") as Node3D
	if player == null:
		return
	var best: Node3D = null
	var best_dist := MARK_RANGE
	for brazier in _braziers:
		if not is_instance_valid(brazier) or brazier.has_meta("marked"):
			continue
		var flat: Vector3 = brazier.global_position - player.global_position
		flat.y = 0.0
		var dist := flat.length()
		if dist <= best_dist:
			best = brazier
			best_dist = dist
	if best == null:
		return
	_mark(best)


func _mark(brazier: Node3D) -> void:
	brazier.set_meta("marked", true)
	_dim_light(brazier)
	_dim_meshes(brazier)
	_add_mark(brazier)
	unmarked = maxi(unmarked - 1, 0)
	marks_changed.emit(unmarked)


func _dim_light(brazier: Node) -> void:
	var light := _find_omni(brazier)
	if light == null:
		return
	light.light_energy = 0.22
	light.light_color = Color(0.42, 0.24, 0.12)
	light.omni_range = 1.6


func _dim_meshes(node: Node) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		for surface in mesh_instance.get_surface_override_material_count():
			var mat := mesh_instance.get_surface_override_material(surface) as ShaderMaterial
			if mat == null or mat.shader == null:
				continue
			var path := mat.shader.resource_path
			var copy := mat.duplicate() as ShaderMaterial
			if path == FIRE_SHADER:
				copy.set_shader_parameter("energy", 0.12)
				copy.set_shader_parameter("flicker", 0.02)
				mesh_instance.set_surface_override_material(surface, copy)
			elif path == SURFACE_SHADER:
				var glow := float(mat.get_shader_parameter("emission_energy"))
				if glow > 0.05:
					copy.set_shader_parameter("emission_energy", glow * 0.12)
					copy.set_shader_parameter("flicker", 0.0)
					mesh_instance.set_surface_override_material(surface, copy)
	for child in node.get_children():
		_dim_meshes(child)


func _add_mark(brazier: Node3D) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "Mark"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.42
	mesh.bottom_radius = 0.42
	mesh.height = 0.03
	mesh.radial_segments = 20
	ring.mesh = mesh
	var chalk := StandardMaterial3D.new()
	chalk.albedo_color = Color(0.86, 0.72, 0.38)
	chalk.emission_enabled = true
	chalk.emission = Color(0.7, 0.5, 0.18)
	chalk.emission_energy_multiplier = 0.4
	ring.material_override = chalk
	ring.position = Vector3(0.0, 0.04, 0.0)
	brazier.add_child(ring)


func _find_omni(node: Node) -> OmniLight3D:
	if node is OmniLight3D:
		return node
	for child in node.get_children():
		var found := _find_omni(child)
		if found != null:
			return found
	return null


func _bind_mark() -> void:
	if not InputMap.has_action(&"mark"):
		InputMap.add_action(&"mark", 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F
	if not InputMap.action_has_event(&"mark", event):
		InputMap.action_add_event(&"mark", event)
