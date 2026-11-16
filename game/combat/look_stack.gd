extends RefCounted

static var _base: Dictionary = {}
static var _order: Dictionary = {}


static func begin(body: Node, token: Node, material: Material, meshes: Array) -> void:
	if body == null:
		return
	var key := body.get_instance_id()
	if not _order.has(key) or (_order[key] as Array).is_empty():
		_order[key] = []
		_base[key] = {
			"meshes": meshes.duplicate(),
			"materials": _snapshot(meshes),
		}
	var stack: Array = _order[key]
	for entry in stack:
		if entry["token"] == token:
			_paint(meshes, material)
			return
	stack.append({"token": token, "material": material, "meshes": meshes})
	_paint(meshes, material)


static func end(body: Node, token: Node) -> void:
	if body == null:
		return
	var key := body.get_instance_id()
	if not _order.has(key):
		return
	var stack: Array = _order[key]
	var removed_top := false
	for index in range(stack.size() - 1, -1, -1):
		if stack[index]["token"] == token:
			removed_top = index == stack.size() - 1
			stack.remove_at(index)
			break
	if stack.is_empty():
		_restore(key)
		return
	if removed_top:
		var top: Dictionary = stack.back()
		_paint(top["meshes"], top["material"])


static func _snapshot(meshes: Array) -> Array:
	var found: Array = []
	for mesh in meshes:
		found.append(mesh.material_override)
	return found


static func _paint(meshes: Array, material: Material) -> void:
	for mesh in meshes:
		if is_instance_valid(mesh):
			mesh.material_override = material


static func _restore(key: int) -> void:
	if not _base.has(key):
		_order.erase(key)
		return
	var saved: Dictionary = _base[key]
	var meshes: Array = saved["meshes"]
	var materials: Array = saved["materials"]
	for index in meshes.size():
		if index >= materials.size():
			break
		if is_instance_valid(meshes[index]):
			meshes[index].material_override = materials[index]
	_base.erase(key)
	_order.erase(key)
