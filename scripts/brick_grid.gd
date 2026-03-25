extends Node2D

const COLS = 16
const ROWS = 28
const BRICK_W = 52
const BRICK_H = 20
const PAD = 2
const OFFSET_X = 6
const OFFSET_Y = 6

var bricks: Array = []
var brick_scene: PackedScene
var rng := RandomNumberGenerator.new()

signal level_cleared
signal gold_earned(amount, pos)

func _ready():
	brick_scene = load("res://scenes/brick.tscn")

func build_level(lvl: int):
	clear_bricks()
	rng.seed = hash(lvl * 7919)

	var layout = _generate_layout(lvl)
	var base_hp = GameData.brick_hp_for_level(lvl)
	var gold_val = GameData.gold_per_brick(lvl)

	for row in ROWS:
		for col in COLS:
			var cell = layout[row][col]
			if cell <= 0:
				continue
			var b = brick_scene.instantiate()
			add_child(b)
			var xp = OFFSET_X + col * (BRICK_W + PAD) + BRICK_W / 2.0
			var yp = OFFSET_Y + row * (BRICK_H + PAD) + BRICK_H / 2.0
			b.position = Vector2(xp, yp)

			var hp = max(1, int(round(base_hp * cell)))
			var gold = max(1, int(ceil(gold_val * cell)))
			b.setup(col, row, hp, gold)
			b.brick_destroyed.connect(_on_brick_destroyed)
			b.poison_tick_gold.connect(_on_poison_gold)
			bricks.append(b)

func _generate_layout(lvl: int) -> Array:
	var formations = [
		"columns", "full_grid", "pillars_center", "scattered_clusters",
		"three_towers", "border_fill", "zigzag", "fortress",
		"diagonal_bands", "dense_random",
	]
	var pick = formations[lvl % formations.size()]

	# every 10 levels is a wall
	if lvl % 10 == 0:
		pick = "full_grid"

	match pick:
		"columns":        return _layout_columns()
		"full_grid":      return _layout_full_grid()
		"pillars_center": return _layout_pillars_center()
		"scattered_clusters": return _layout_scattered_clusters()
		"three_towers":   return _layout_three_towers()
		"border_fill":    return _layout_border_fill()
		"zigzag":         return _layout_zigzag()
		"fortress":       return _layout_fortress()
		"diagonal_bands": return _layout_diagonal_bands()
		"dense_random":   return _layout_dense_random()
		_:                return _layout_full_grid()

func _empty() -> Array:
	var grid = []
	for row in ROWS:
		var r = []
		r.resize(COLS)
		r.fill(0.0)
		grid.append(r)
	return grid

# --- formations ---

func _layout_columns() -> Array:
	# like the screenshot: left column, center cluster, right column with gaps
	var grid = _empty()
	var left_col = rng.randi_range(0, 1)
	var right_col = COLS - 1 - rng.randi_range(0, 1)
	var center_start = rng.randi_range(5, 7)
	var center_w = rng.randi_range(3, 5)

	for row in ROWS:
		# left pillar
		grid[row][left_col] = _rand_hp_mult()

		# right pillar
		grid[row][right_col] = _rand_hp_mult()

		# center columns
		for c in range(center_start, min(center_start + center_w, COLS)):
			grid[row][c] = _rand_hp_mult()

	return grid

func _layout_full_grid() -> Array:
	var grid = _empty()
	for row in ROWS:
		for col in COLS:
			grid[row][col] = _rand_hp_mult()
	return grid

func _layout_pillars_center() -> Array:
	# several vertical pillars spaced across the field
	var grid = _empty()
	var num_pillars = rng.randi_range(4, 7)
	var pillar_cols = []
	for i in num_pillars:
		pillar_cols.append(rng.randi_range(0, COLS - 1))

	for row in ROWS:
		for pc in pillar_cols:
			grid[row][pc] = _rand_hp_mult()
			# sometimes widen the pillar
			if rng.randf() < 0.4 and pc + 1 < COLS:
				grid[row][pc + 1] = _rand_hp_mult()

	return grid

func _layout_scattered_clusters() -> Array:
	var grid = _empty()
	var num = rng.randi_range(6, 12)
	for i in num:
		var cr = rng.randi_range(1, ROWS - 3)
		var cc = rng.randi_range(1, COLS - 3)
		var h = rng.randi_range(3, 8)
		var w = rng.randi_range(2, 4)
		for dr in h:
			for dc in w:
				var r = cr + dr
				var c = cc + dc
				if r < ROWS and c < COLS:
					grid[r][c] = _rand_hp_mult()
	return grid

func _layout_three_towers() -> Array:
	var grid = _empty()
	var positions = [1, COLS / 2, COLS - 3]
	var widths = [rng.randi_range(1, 3), rng.randi_range(2, 4), rng.randi_range(1, 3)]
	for t in 3:
		var start_row = rng.randi_range(0, 5)
		for row in range(start_row, ROWS):
			for dc in widths[t]:
				var c = positions[t] + dc
				if c >= 0 and c < COLS:
					grid[row][c] = _rand_hp_mult()
	return grid

func _layout_border_fill() -> Array:
	# bricks along the edges, some scattered inside
	var grid = _empty()
	for row in ROWS:
		for col in COLS:
			var on_edge = row < 2 or row >= ROWS - 2 or col < 2 or col >= COLS - 2
			if on_edge:
				grid[row][col] = _rand_hp_mult()
			elif rng.randf() < 0.12:
				grid[row][col] = _rand_hp_mult() * 1.5
	return grid

func _layout_zigzag() -> Array:
	var grid = _empty()
	var width = rng.randi_range(2, 4)
	for row in ROWS:
		# zigzag offset
		var phase = (row / 3) % 3
		var start = phase * (COLS / 3)
		for dc in width:
			var c = start + dc
			if c >= 0 and c < COLS:
				grid[row][c] = _rand_hp_mult()
		# also add some on the far side
		var mirror = COLS - 1 - start - width
		if mirror >= 0 and mirror < COLS:
			grid[row][mirror] = _rand_hp_mult()
	return grid

func _layout_fortress() -> Array:
	# walls with an inner chamber
	var grid = _empty()
	var wall_l = 2
	var wall_r = COLS - 3
	var wall_top = 3
	var wall_bot = ROWS - 4
	var inner_l = 6
	var inner_r = COLS - 7
	var inner_top = 8
	var inner_bot = ROWS - 9

	for row in ROWS:
		for col in COLS:
			# outer walls
			if (col == wall_l or col == wall_r) and row >= wall_top and row <= wall_bot:
				grid[row][col] = _rand_hp_mult()
			elif (row == wall_top or row == wall_bot) and col >= wall_l and col <= wall_r:
				grid[row][col] = _rand_hp_mult()
			# inner walls
			elif (col == inner_l or col == inner_r) and row >= inner_top and row <= inner_bot:
				grid[row][col] = _rand_hp_mult() * 1.3
			elif (row == inner_top or row == inner_bot) and col >= inner_l and col <= inner_r:
				grid[row][col] = _rand_hp_mult() * 1.3

	return grid

func _layout_diagonal_bands() -> Array:
	var grid = _empty()
	var band_w = rng.randi_range(2, 4)
	for row in ROWS:
		for col in COLS:
			var diag = (row + col) % (band_w * 2)
			if diag < band_w:
				grid[row][col] = _rand_hp_mult()
	return grid

func _layout_dense_random() -> Array:
	var grid = _empty()
	var density = rng.randf_range(0.3, 0.65)
	for row in ROWS:
		for col in COLS:
			if rng.randf() < density:
				grid[row][col] = _rand_hp_mult()
	return grid

# helpers

func _rand_hp_mult() -> float:
	# gives varied hp within a level, like the real game
	return rng.randf_range(0.5, 1.5)

func clear_bricks():
	for b in bricks:
		if is_instance_valid(b):
			b.queue_free()
	bricks.clear()

func _on_brick_destroyed(brick):
	bricks.erase(brick)
	brick.queue_free()
	if bricks.is_empty():
		emit_signal("level_cleared")

func get_weakest_brick() -> Node2D:
	var weakest: Node2D = null
	var lowest_hp := INF
	for b in bricks:
		if is_instance_valid(b) and b.hp < lowest_hp:
			lowest_hp = b.hp
			weakest = b
	return weakest

func get_bricks() -> Array:
	bricks = bricks.filter(func(b): return is_instance_valid(b) and b.hp > 0)
	return bricks
