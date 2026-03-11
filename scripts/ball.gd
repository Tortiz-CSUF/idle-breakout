extends Node2D

var ball_type: String = "basic"
var velocity: Vector2 = Vector2.ZERO
var radius: float = 6.0
var damage: int = 1
var speed: float = 200.0
var color: Color = Color.WHITE

var bounds: Rect2 = Rect2(0, 0, 880, 720)
var _hit_cooldown: float = 0.0

# TODO: add fields here for special ball behaviors (sniper target, fragment lifetime, etc)

signal hit_brick(ball, brick)

func _ready():
	_init_velocity()

func setup(type: String, play_bounds: Rect2):
	ball_type = type
	bounds = play_bounds
	radius = GameData.get_ball_radius(type)
	damage = GameData.get_ball_damage(type)
	speed = GameData.get_ball_speed(type)
	color = GameData.get_ball_color(type)
	velocity = velocity.normalized() * speed

func _init_velocity():
	var angle = randf_range(-PI * 0.8, -PI * 0.2)
	velocity = Vector2.from_angle(angle) * speed

func _process(delta):
	# TODO: add per-type movement logic here (sniper steering, fragment expiry, etc)
	if _hit_cooldown > 0:
		_hit_cooldown -= delta
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

func check_brick_collision(brick: Node2D) -> bool:
	if _hit_cooldown > 0:
		return false

	var brick_rect = brick.get_rect()
	var expanded = brick_rect.grow(radius)
	if not expanded.has_point(global_position):
		return false

	# figure out which side we hit for bounce
	var brick_center = brick_rect.get_center()
	var diff = global_position - brick_center

	if abs(diff.x) / brick_rect.size.x > abs(diff.y) / brick_rect.size.y:
		velocity.x = -velocity.x
		# push out horizontally past the brick edge
		if diff.x > 0:
			position.x = brick_rect.end.x + radius + 1.0
		else:
			position.x = brick_rect.position.x - radius - 1.0
	else:
		velocity.y = -velocity.y
		# push out vertically past the brick edge
		if diff.y > 0:
			position.y = brick_rect.end.y + radius + 1.0
		else:
			position.y = brick_rect.position.y - radius - 1.0

	_hit_cooldown = 0.05

	emit_signal("hit_brick", self, brick)
	return true

func _draw():
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.25, Color(1, 1, 1, 0.4))
