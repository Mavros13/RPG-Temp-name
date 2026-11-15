extends Node2D

func _draw() -> void:
	var line_color := Color(0.27, 0.26, 0.32)
	var x := -640.0
	while x <= 640.0:
		draw_line(Vector2(x, -400.0), Vector2(x, 400.0), line_color, 2.0)
		x += 160.0
	var y := -320.0
	while y <= 320.0:
		draw_line(Vector2(-680.0, y), Vector2(680.0, y), line_color, 2.0)
		y += 160.0
