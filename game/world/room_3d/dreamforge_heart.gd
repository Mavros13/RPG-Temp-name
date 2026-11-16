extends Node3D

const QUEST := preload("res://game/world/quest_state.gd")
const REACH := 1.7

var _hud: Node
var _material: StandardMaterial3D


func setup(hud: Node) -> void:
	_hud = hud
	_build_marker()
	var player := _player()
	if player != null:
		sync_coal(player)
	if QUEST.delivered:
		_answer()
		_show_answer()


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"mark"):
		_try_deliver()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mark"):
		_try_deliver()


func _try_deliver() -> void:
	if not QUEST.carrying_coal:
		return
	var player := _player()
	if player == null:
		return
	var flat: Vector3 = global_position - player.global_position
	flat.y = 0.0
	if flat.length() > REACH:
		return
	if not QUEST.deliver_coal():
		return
	sync_coal(player)
	_answer()
	_show_answer()


func _show_answer() -> void:
	if _hud != null and _hud.has_method("show_heart_answer"):
		_hud.call("show_heart_answer")


func _player() -> Node3D:
	var grouped := get_tree().get_first_node_in_group("player") as Node3D
	if grouped != null:
		return grouped
	var room := get_parent()
	if room == null:
		return null
	return room.get_node_or_null("Player") as Node3D


func _build_marker() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.62, 0.08, 0.08)
	_material.emission_enabled = true
	_material.emission = Color(1.0, 0.24, 0.1)
	_material.emission_energy_multiplier = 0.7
	_material.roughness = 0.42
	var lobe := SphereMesh.new()
	lobe.radius = 0.09
	lobe.height = 0.18
	_add_mesh(lobe, Vector3(-0.055, 0.24, 0.0))
	_add_mesh(lobe, Vector3(0.055, 0.24, 0.0))
	var point := BoxMesh.new()
	point.size = Vector3(0.15, 0.15, 0.12)
	var tip := _add_mesh(point, Vector3(0.0, 0.13, 0.0))
	tip.rotation_degrees = Vector3(0.0, 0.0, 45.0)


func _add_mesh(mesh: Mesh, at: Vector3) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position = at
	view.material_override = _material
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	return view


func _answer() -> void:
	set_meta("answered", true)
	if _material != null:
		_material.emission = Color(1.0, 0.72, 0.38)
		_material.emission_energy_multiplier = 2.2


static func sync_coal(player: Node3D) -> void:
	if player == null:
		return
	var existing := player.get_node_or_null("CarriedCoal")
	if QUEST.carrying_coal:
		if existing != null:
			return
		var coal := MeshInstance3D.new()
		coal.name = "CarriedCoal"
		var mesh := SphereMesh.new()
		mesh.radius = 0.06
		mesh.height = 0.12
		coal.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.08, 0.05, 0.04)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.28, 0.05)
		mat.emission_energy_multiplier = 0.55
		coal.material_override = mat
		coal.position = Vector3(0.2, 1.0, 0.22)
		coal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		player.add_child(coal)
		return
	if existing != null:
		existing.queue_free()
