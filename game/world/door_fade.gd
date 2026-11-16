extends Node

## Black veil for a doorway crossing. One fade at a time, kept above the scene change.

const OUT_TIME := 0.18
const IN_TIME := 0.22

static var running := false
static var covered_scene := false

var target := ""
var _phase := 0
var _elapsed := 0.0
var _held := false
var _arrived := false
var _veil: ColorRect


func claim(next_scene: String) -> bool:
	if running or next_scene.is_empty():
		return false
	running = true
	covered_scene = false
	target = next_scene
	return true


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DoorFadeLayer"
	layer.layer = 100
	add_child(layer)

	_veil = ColorRect.new()
	_veil.name = "Veil"
	_veil.color = Color(0.0, 0.0, 0.0, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_veil)
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if _phase == 0:
		_elapsed += delta
		var shown := smoothstep(0.0, 1.0, clampf(_elapsed / OUT_TIME, 0.0, 1.0))
		_veil.color = Color(0.0, 0.0, 0.0, shown)
		if shown < 1.0:
			return
		if not _held:
			_held = true
			return
		covered_scene = true
		_phase = 1
		get_tree().change_scene_to_file(target)
		return
	if _phase == 1:
		var scene := get_tree().current_scene
		if scene == null or scene.scene_file_path != target:
			return
		if not _arrived:
			_arrived = true
			return
		_phase = 2
		_elapsed = 0.0
		return
	_elapsed += delta
	var left := 1.0 - smoothstep(0.0, 1.0, clampf(_elapsed / IN_TIME, 0.0, 1.0))
	_veil.color = Color(0.0, 0.0, 0.0, left)
	if left > 0.0:
		return
	running = false
	queue_free()
