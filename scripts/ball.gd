extends Node2D

var ball_type: String = "basic"
var velocity: Vector2 = Vector2.ZERO
var radius: float = 6.0
var damage: int = 1
var speed: float = 200.0
var color: Color = Color.WHITE

var bounds: Rect2 = Rect2(0, 0, 880, 720)
var _hit_cooldown: float = 0.0

var brick_grid: Node2D = null
var _sniper_targeting: bool = false



signal hit_brick(ball, brick)
# new signal for wall. emit added to _bounce_walls() after sniper check
signal hit_wall(ball)

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
	
	if _hit_cooldown > 0:
		_hit_cooldown -= delta
	position += velocity * delta
	_bounce_walls()

func _bounce_walls():
	var bounced = false
	
	if position.x - radius < bounds.position.x:
		position.x = bounds.position.x + radius
		velocity.x = abs(velocity.x)
		bounced = true
	elif position.x + radius > bounds.end.x:
		position.x = bounds.end.x - radius
		velocity.x = -abs(velocity.x)
		bounced = true
	if position.y - radius < bounds.position.y:
		position.y = bounds.position.y + radius
		velocity.y = abs(velocity.y)
		bounced = true
	elif position.y + radius > bounds.end.y:
		position.y = bounds.end.y - radius
		velocity.y = -abs(velocity.y)
		bounced = true
		
	if bounced and ball_type == "sniper" and brick_grid:
		_sniper_target_closest()
		
		if bounced and ball_type == "scatter":
			emit_signal("hit_wall", self)
		
func _sniper_target_closest():
	var bricks = brick_grid.get_bricks()
	if bricks.is_empty():
		return
	var closest: Node2D = null
	var closest_dist := INF
	for b in bricks:
		if is_instance_valid(b):
			var dist = global_position.distance_to(b.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = b
	if closest:
		var direction = (closest.global_position - global_position).normalized()
		velocity = direction * speed
		_sniper_targeting = true


func check_brick_collision(brick: Node2D) -> bool:
	if _hit_cooldown > 0:
		return false

	var brick_rect = brick.get_rect()
	var expanded = brick_rect.grow(radius)
	if not expanded.has_point(global_position):
		return false
		
	# cannon penetrates through bricks it can destroy
	if ball_type == "cannon" and damage >= brick.hp:
		_hit_cooldown = 0.05
		emit_signal("hit_brick", self, brick)
		return true
		
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
