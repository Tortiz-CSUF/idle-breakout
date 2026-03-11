extends Node2D

var text: String = "+1"
var lifetime: float = 0.8
var age: float = 0.0
var drift := Vector2(randf_range(-20, 20), -40)

func _process(delta):
	age += delta
	position += drift * delta
	queue_redraw()
	if age >= lifetime:
		queue_free()

func _draw():
	var alpha = 1.0 - (age / lifetime)
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(-15, 0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.15, 0.5, 0.1, alpha))
