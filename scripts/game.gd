extends Control

@onready var brick_grid: Node2D = $PlayArea/BrickGrid
@onready var ball_container: Node2D = $PlayArea/Balls
@onready var shop: VBoxContainer = $ShopScroll/ShopPanel
@onready var play_area: Panel = $PlayArea

var ball_scene: PackedScene
var play_bounds: Rect2

var save_timer: float = 0.0

func _ready():
	ball_scene = load("res://scenes/ball.tscn")
	GameData.load_game()

	play_bounds = Rect2(0, 0, 880, 720)

	brick_grid.gold_earned.connect(_on_gold_earned)
	brick_grid.level_cleared.connect(_on_level_cleared)
	shop.buy_ball.connect(_on_buy_ball)
	shop.upgrade_speed.connect(_on_upgrade_speed)
	shop.upgrade_power.connect(_on_upgrade_power)
	shop.upgrade_range.connect(_on_upgrade_range)
	shop.delete_ball.connect(_on_delete_ball)
	shop.upgrade_click.connect(_on_upgrade_click)
	shop.prestige_requested.connect(_on_prestige)

	brick_grid.build_level(GameData.current_level)
	_spawn_owned_balls()
	shop.refresh()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = play_area.get_local_mouse_position()
		if Rect2(Vector2.ZERO, play_area.size).has_point(local_pos):
			_handle_click(local_pos)

func _handle_click(pos: Vector2):
	var dmg = GameData.get_click_damage()
	for brick in brick_grid.get_bricks():
		if not is_instance_valid(brick):
			continue
		var bx = brick.position.x
		var by = brick.position.y
		if pos.x >= bx - 26.0 and pos.x <= bx + 26.0 and pos.y >= by - 10.0 and pos.y <= by + 10.0:
			_award_hit_gold(brick, dmg)
			brick.take_damage(dmg)
			return

func _process(delta):
	_check_collisions()

	save_timer += delta
	if save_timer > 30.0:
		save_timer = 0.0
		GameData.save_game()

	shop.refresh()

func _check_collisions():
	var active_bricks = brick_grid.get_bricks()
	for ball in ball_container.get_children():
		for brick in active_bricks:
			if not is_instance_valid(brick):
				continue
			if ball.check_brick_collision(brick):
				_apply_ball_effect(ball, brick)
				break

func _apply_ball_effect(ball, brick):
	# TODO: add special behavior per ball_type here (plasma AOE, sniper targeting, scatter, poison, cannon)
	_award_hit_gold(brick, ball.damage)
	brick.take_damage(ball.damage)

func _award_hit_gold(brick, damage: int):
	var gold = mini(damage, brick.hp)
	GameData.add_gold(gold)

func _on_gold_earned(amount, pos):
	GameData.add_gold(amount)
	_show_gold_popup(amount, pos)

func _show_gold_popup(amount, pos: Vector2):
	var popup = Node2D.new()
	popup.set_script(load("res://scripts/gold_popup.gd"))
	popup.text = "+" + GameData.format_number(amount)
	play_area.add_child(popup)
	popup.position = pos

func _on_level_cleared():
	GameData.current_level += 1
	brick_grid.build_level(GameData.current_level)

func _on_buy_ball(type: String):
	if not GameData.can_buy_ball():
		return
	var cost = GameData.get_ball_cost(type)
	if not GameData.spend_gold(cost):
		return
	GameData.ball_counts[type] += 1
	_spawn_ball(type)
	shop.refresh()

func _on_upgrade_speed(type: String):
	var cost = GameData.get_speed_upgrade_cost(type)
	if not GameData.spend_gold(cost):
		return
	GameData.speed_levels[type] += 1
	for ball in ball_container.get_children():
		if ball.ball_type == type:
			ball.speed = GameData.get_ball_speed(type)
			ball.velocity = ball.velocity.normalized() * ball.speed
	shop.refresh()

func _on_upgrade_power(type: String):
	var cost = GameData.get_power_upgrade_cost(type)
	if not GameData.spend_gold(cost):
		return
	GameData.power_levels[type] += 1
	for ball in ball_container.get_children():
		if ball.ball_type == type:
			ball.damage = GameData.get_ball_damage(type)
	shop.refresh()

func _on_upgrade_range(type: String):
	var cost = GameData.get_range_upgrade_cost(type)
	if not GameData.spend_gold(cost):
		return
	GameData.range_levels[type] += 1
	shop.refresh()

func _on_delete_ball(type: String):
	if GameData.ball_counts[type] <= 0:
		return
	GameData.ball_counts[type] -= 1
	# remove one ball of this type from the field
	for ball in ball_container.get_children():
		if ball.ball_type == type:
			ball.queue_free()
			break
	shop.refresh()

func _on_upgrade_click():
	var cost = GameData.get_click_upgrade_cost()
	if not GameData.spend_gold(cost):
		return
	GameData.click_level += 1
	shop.refresh()

func _on_prestige():
	var cost = GameData.get_prestige_cost()
	if GameData.total_gold_earned < cost:
		return
	GameData.prestige_points += 1
	GameData.prestige_multiplier = 1.0 + GameData.prestige_points * 0.5
	GameData.gold = 0
	GameData.total_gold_earned = 0
	GameData.current_level = 1
	for type in GameData.ball_counts:
		GameData.ball_counts[type] = 0
	GameData.ball_counts["basic"] = 1
	for type in GameData.speed_levels:
		GameData.speed_levels[type] = 0
	for type in GameData.power_levels:
		GameData.power_levels[type] = 0
	for type in GameData.range_levels:
		GameData.range_levels[type] = 0
	GameData.click_level = 0
	for ball in ball_container.get_children():
		ball.queue_free()
	brick_grid.build_level(1)
	_spawn_owned_balls()
	shop.refresh()
	GameData.save_game()

func _spawn_owned_balls():
	for type in GameData.ball_counts:
		for i in GameData.ball_counts[type]:
			_spawn_ball(type)

func _spawn_ball(type: String):
	var b = ball_scene.instantiate()
	ball_container.add_child(b)
	b.setup(type, play_bounds)
	b.position = Vector2(
		randf_range(play_bounds.position.x + 50, play_bounds.end.x - 50),
		randf_range(play_bounds.size.y * 0.6, play_bounds.size.y * 0.85)
	)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameData.save_game()
