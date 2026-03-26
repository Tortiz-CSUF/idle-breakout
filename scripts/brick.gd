extends Node2D

var hp: int = 1
var max_hp: int = 1
var gold_value: int = 1
var brick_color: Color = Color(0.2, 0.6, 0.9)
var grid_x: int = 0
var grid_y: int = 0
var poison_timer: float = 0.0
var poison_dps: float = 0.0
var poison_accum: float = 0.0

const BRICK_W = 52
const BRICK_H = 20
const BRICK_PAD = 2

@onready var label: Label = $Label

signal brick_destroyed(brick)
signal poison_tick_gold(amount)

func _ready():
	_pick_color()
	queue_redraw()

func setup(x: int, y: int, health: int, gold: int):
	grid_x = x
	grid_y = y
	hp = health
	max_hp = health
	gold_value = gold
	_pick_color()
	_update_label()
	queue_redraw()

func _pick_color():
	# vibrant colors based on hp, matching the real game's look
	if max_hp <= 2:
		brick_color = Color(0.3, 0.85, 0.35)    # green
	elif max_hp <= 5:
		brick_color = Color(0.2, 0.55, 0.95)    # blue
	elif max_hp <= 8:
		brick_color = Color(0.3, 0.85, 0.9)     # cyan
	elif max_hp <= 12:
		brick_color = Color(1.0, 0.85, 0.15)    # yellow
	elif max_hp <= 20:
		brick_color = Color(1.0, 0.5, 0.15)     # orange
	elif max_hp <= 40:
		brick_color = Color(1.0, 0.3, 0.35)     # red
	elif max_hp <= 80:
		brick_color = Color(0.95, 0.25, 0.65)   # pink/magenta
	elif max_hp <= 200:
		brick_color = Color(0.65, 0.3, 0.9)     # purple
	elif max_hp <= 500:
		brick_color = Color(0.4, 0.85, 0.9)     # light cyan
	elif max_hp <= 2000:
		brick_color = Color(0.85, 0.85, 0.85)   # silver
	else:
		brick_color = Color(1.0, 0.85, 0.3)     # gold

func _process(delta):
	if poison_timer > 0:
		poison_timer -= delta
		poison_accum += poison_dps * delta
		if poison_accum >= 1.0:
			var dmg = int(poison_accum)
			poison_accum -= dmg
			var gold = mini(dmg, hp)
			if gold > 0:
				emit_signal("poison_tick_gold", gold)
			take_damage(dmg)
			
		if poison_timer <= 0:
			poison_timer = 0.0
			poison_dps = 0.0
			poison_accum = 0.0
			queue_redraw()
			
func take_damage(amount: int) -> bool:
	hp -= amount
	_update_label()
	queue_redraw()
	if hp <= 0:
		hp = 0
		emit_signal("brick_destroyed", self)
		return true
	return false

func apply_poison(dps: float, duration: float):
	poison_dps = dps
	poison_timer = duration

func _update_label():
	if label:
		label.text = GameData.format_number(hp)

func _draw():
	var rect = Rect2(-BRICK_W / 2.0, -BRICK_H / 2.0, BRICK_W, BRICK_H)
	draw_rect(rect, brick_color)
	# Purple Overlay when poisoned
	if poison_timer > 0:
		draw_rect(rect, Color(0.0, 0.82, 0.275, 0.875))
	# slight white highlight on top edge, dark on bottom for depth
	draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.end.x, rect.position.y), Color(1, 1, 1, 0.25), 1.0)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.end.y), Color(0, 0, 0, 0.15), 1.0)

func get_rect() -> Rect2:
	return Rect2(global_position.x - BRICK_W / 2.0, global_position.y - BRICK_H / 2.0, BRICK_W, BRICK_H)
