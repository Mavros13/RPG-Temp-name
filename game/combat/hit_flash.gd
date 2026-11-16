extends Node

const FLASH_TIME := 0.15

var flashing := false
var _left := 0.0
var _bound := false
var _material: StandardMaterial3D
var _meshes: Array[MeshInstance3D] = []
var _previous: Array[Material] = []


func _ready() -> void:
	_bind()


func _process(delta: float) -> void:
	if not _bound:
		_bind()
	if not flashing:
		return
	_left = maxf(_left - delta, 0.0)
	if _left > 0.000001:
		return
	_left = 0.0
	flashing = false
	_restore()


func _bind() -> void:
	var body := get_parent()
	if body == null:
		return
	var stats := body.get_node_or_null("CombatHealth")
	if stats == null or not stats.has_signal("damaged"):
		return
	if not stats.damaged.is_connected(_on_damaged):
		stats.damaged.connect(_on_damaged)
	_collect(body.get_node_or_null("Model"))
	_bound = true


func _on_damaged(_amount: int, _remaining: int) -> void:
	if _meshes.is_empty():
		var body := get_parent()
		if body != null:
			_collect(body.get_node_or_null("Model"))
	if not flashing:
		_apply()
	flashing = true
	_left = FLASH_TIME


func _collect(node: Node) -> void:
	if node == null:
		return
	_meshes.clear()
	_gather(node)


func _gather(node: Node) -> void:
	var mesh := node as MeshInstance3D
	if mesh != null:
		_meshes.append(mesh)
	for child in node.get_children():
		_gather(child)


func _apply() -> void:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color(1.0, 0.82, 0.72)
		_material.emission_enabled = true
		_material.emission = Color(1.0, 0.32, 0.18)
		_material.emission_energy_multiplier = 3.0
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_previous.clear()
	for mesh in _meshes:
		_previous.append(mesh.material_override)
		mesh.material_override = _material


func _restore() -> void:
	for index in _meshes.size():
		if index >= _previous.size():
			break
		_meshes[index].material_override = _previous[index]
	_previous.clear()
