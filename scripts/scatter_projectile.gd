extends Node2D

# Mini projectile spawned by scatter ball on wall bounce
var velocity: Vector2 = Vector2.ZERO
var radius: float = 3.0
var damage: int = 1
var color: Color = Color(0.3, 1.0, 0.4, 0.8)
var bounds: Rect2 = Rect2(0, 0, 880, 720)
var lifetime: float = 5.0 

func _ready():
	add_to_group("scatter_projectiles")

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= delta:
		queue_free()
		return
	position += velocity * delta
	_bounce_walls()


func _bounce_walls():
	if position.x - radius < bounds.position.x:
		position.x = bounds.position.x + radius
		velocity.x = abs(velocity.x)
	elif position.x + radius > bounds.end.x:
		position.x = bounds.end.x - radius
		velocity.x = -abs(velocity.x)
	if position.y - radius < bounds.position.y:
		position.y = bounds.position.y + radius
		velocity.y = abs(velocity.y)
	elif position.y + radius > bounds.end.y:
		position.y = bounds.end.y - radius
		velocity.y = -abs(velocity.y)
		

# return true on hit. Caller handles damage and removal 
func check_brick_collision(brick: Node2D) -> bool:
	var brick_rect = brick.get_rect()
	var expanded = brick_rect.grow(radius)
	return expanded.has_point(global_position)
	
func _draw():
	draw_circle(Vector2.ZERO, radius, color)
