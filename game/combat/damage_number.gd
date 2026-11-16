extends Label3D

const LIFE := 0.62

var _age := 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	position.y += delta * 0.65
	modulate.a = clampf(1.0 - _age / LIFE, 0.0, 1.0)
	if _age >= LIFE:
		queue_free()
