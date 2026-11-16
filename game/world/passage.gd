extends Area3D

const SELF := preload("res://game/world/passage.gd")
const QUEST := preload("res://game/world/quest_state.gd")
const FADE := preload("res://game/world/door_fade.gd")

var _used := false


static func place(parent: Node, at: Vector3, target_scene: String, node_name: String, sign_text: String, locked_until_delivery := false) -> Area3D:
	var area := SELF.new() as Area3D
	area.name = node_name
	area.position = at
	area.set_meta("target_scene", target_scene)
	if locked_until_delivery:
		area.set_meta("locked_until_delivery", true)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 2.4, 1.4)
	shape.shape = box
	area.add_child(shape)
	_add_frame(area)
	var sign := Label3D.new()
	sign.name = "Sign"
	sign.text = sign_text
	sign.position = Vector3(0.0, 1.15, 0.0)
	sign.font_size = 48
	sign.pixel_size = 0.004
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = Color(0.95, 0.86, 0.62)
	sign.outline_size = 8
	sign.outline_modulate = Color(0, 0, 0, 0.85)
	area.add_child(sign)
	parent.add_child(area)
	return area


static func _add_frame(area: Area3D) -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.24, 0.16, 0.1)
	wood.roughness = 0.78
	for side in [-1.0, 1.0]:
		var jamb := MeshInstance3D.new()
		var post := BoxMesh.new()
		post.size = Vector3(0.16, 2.5, 0.28)
		jamb.mesh = post
		jamb.position = Vector3(side * 0.9, 0.15, 0.0)
		jamb.material_override = wood
		area.add_child(jamb)
	var lintel := MeshInstance3D.new()
	var beam := BoxMesh.new()
	beam.size = Vector3(1.96, 0.18, 0.28)
	lintel.mesh = beam
	lintel.position = Vector3(0.0, 1.35, 0.0)
	lintel.material_override = wood
	area.add_child(lintel)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _used or body == null or body.name != "Player":
		return
	var target := str(get_meta("target_scene", ""))
	if target.is_empty():
		return
	if bool(get_meta("locked_until_delivery", false)) and not QUEST.delivered:
		return
	var fade := FADE.new()
	fade.name = "DoorFade"
	if not fade.claim(target):
		fade.free()
		return
	_used = true
	get_tree().root.add_child(fade)
