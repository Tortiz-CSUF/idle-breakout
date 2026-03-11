extends Node

var gold: float = 0.0
var total_gold_earned: float = 0.0
var prestige_points: int = 0
var prestige_multiplier: float = 1.0
var current_level: int = 1
var click_level: int = 0

var ball_counts := {
	"basic": 1,
	"plasma": 0,
	"sniper": 0,
	"scatter": 0,
	"poison": 0,
	"cannon": 0,
}

var speed_levels := {
	"basic": 0,
	"plasma": 0,
	"sniper": 0,
	"scatter": 0,
	"poison": 0,
	"cannon": 0,
}

var power_levels := {
	"basic": 0,
	"plasma": 0,
	"sniper": 0,
	"scatter": 0,
	"poison": 0,
	"cannon": 0,
}

var range_levels := {
	"plasma": 0,
}

# base stats
var _base_damage := {
	"basic": 1,
	"plasma": 3,
	"sniper": 2,
	"scatter": 1,
	"poison": 1,
	"cannon": 50,
}

var _base_speed := {
	"basic": 5,
	"plasma": 3,
	"sniper": 4,
	"scatter": 4,
	"poison": 3,
	"cannon": 1,
}

var _base_range := {
	"plasma": 1,
}

# pixels per second = stat * 40
const SPEED_SCALE = 40.0
# range in pixels = stat * 30
const RANGE_SCALE = 30.0

func get_ball_cost(type: String) -> int:
	var base_costs := {
		"basic": 10,
		"plasma": 100,
		"sniper": 500,
		"scatter": 2500,
		"poison": 10000,
		"cannon": 50000,
	}
	var count = ball_counts.get(type, 0)
	return int(ceil(base_costs[type] * pow(1.15, count)))

func get_power_upgrade_cost(type: String) -> int:
	var base := {
		"basic": 20,
		"plasma": 150,
		"sniper": 800,
		"scatter": 4000,
		"poison": 15000,
		"cannon": 80000,
	}
	var lvl = power_levels.get(type, 0)
	return int(ceil(base[type] * pow(1.35, lvl)))

func get_speed_upgrade_cost(type: String) -> int:
	var base := {
		"basic": 30,
		"plasma": 200,
		"sniper": 1000,
		"scatter": 5000,
		"poison": 20000,
		"cannon": 100000,
	}
	var lvl = speed_levels.get(type, 0)
	return int(ceil(base[type] * pow(1.4, lvl)))

func get_range_upgrade_cost(type: String) -> int:
	var base := {
		"plasma": 250,
	}
	if not type in base:
		return 0
	var lvl = range_levels.get(type, 0)
	return int(ceil(base[type] * pow(1.5, lvl)))

func get_ball_damage(type: String) -> int:
	var base = _base_damage[type]
	var lvl = power_levels.get(type, 0)
	return int(ceil((base + lvl) * prestige_multiplier))

func get_ball_damage_next(type: String) -> int:
	var base = _base_damage[type]
	var lvl = power_levels.get(type, 0) + 1
	return int(ceil((base + lvl) * prestige_multiplier))

func get_ball_speed_stat(type: String) -> int:
	return _base_speed[type] + speed_levels.get(type, 0)

func get_ball_speed_stat_next(type: String) -> int:
	return _base_speed[type] + speed_levels.get(type, 0) + 1

func get_ball_speed(type: String) -> float:
	return get_ball_speed_stat(type) * SPEED_SCALE

func get_ball_range_stat(type: String) -> int:
	return _base_range.get(type, 0) + range_levels.get(type, 0)

func get_ball_range_stat_next(type: String) -> int:
	return _base_range.get(type, 0) + range_levels.get(type, 0) + 1

func get_ball_range(type: String) -> float:
	return get_ball_range_stat(type) * RANGE_SCALE

func has_range_stat(type: String) -> bool:
	return type in _base_range

func get_ball_color(type: String) -> Color:
	var colors := {
		"basic": Color(0.95, 0.85, 0.1),
		"plasma": Color(0.95, 0.2, 0.55),
		"sniper": Color(0.3, 0.8, 1.0),
		"scatter": Color(0.3, 1.0, 0.4),
		"poison": Color(0.7, 0.2, 0.9),
		"cannon": Color(1.0, 0.7, 0.1),
	}
	return colors.get(type, Color.WHITE)

func get_ball_radius(type: String) -> float:
	var radii := {
		"basic": 6.0,
		"plasma": 9.0,
		"sniper": 5.0,
		"scatter": 6.0,
		"poison": 7.0,
		"cannon": 14.0,
	}
	return radii.get(type, 6.0)

func get_max_balls() -> int:
	return 50 + prestige_points * 25

func get_total_balls() -> int:
	var total = 0
	for type in ball_counts:
		total += ball_counts[type]
	return total

func can_buy_ball() -> bool:
	return get_total_balls() < get_max_balls()

func get_click_damage() -> int:
	return int(ceil((1 + click_level) * prestige_multiplier))

func get_click_damage_next() -> int:
	return int(ceil((1 + click_level + 1) * prestige_multiplier))

func get_click_upgrade_cost() -> int:
	return int(ceil(15 * pow(1.3, click_level)))

func get_prestige_cost() -> int:
	return int(500000 * pow(8, prestige_points))

func add_gold(amount: int) -> void:
	gold += amount
	total_gold_earned += amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

func brick_hp_for_level(lvl: int) -> int:
	return int(ceil(2.0 * pow(1.3, lvl - 1)))

func gold_per_brick(lvl: int) -> int:
	return int(ceil(1.0 * pow(1.2, lvl - 1) * prestige_multiplier))

func format_number(n: float) -> String:
	var v = int(round(n))
	var s = str(v)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

func save_game() -> void:
	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	if not file:
		return
	var data := {
		"gold": gold,
		"total_gold": total_gold_earned,
		"prestige": prestige_points,
		"level": current_level,
		"click_level": click_level,
		"counts": ball_counts,
		"speed_levels": speed_levels,
		"power_levels": power_levels,
		"range_levels": range_levels,
	}
	file.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists("user://save.dat"):
		return
	var file = FileAccess.open("user://save.dat", FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) != OK:
		return
	var data = json.data
	gold = data.get("gold", 0.0)
	total_gold_earned = data.get("total_gold", 0.0)
	prestige_points = data.get("prestige", 0)
	prestige_multiplier = 1.0 + prestige_points * 0.5
	current_level = data.get("level", 1)
	click_level = int(data.get("click_level", 0))
	var c = data.get("counts", {})
	for key in c:
		if key in ball_counts:
			ball_counts[key] = int(c[key])
	var sl = data.get("speed_levels", {})
	for key in sl:
		if key in speed_levels:
			speed_levels[key] = int(sl[key])
	var pl = data.get("power_levels", {})
	for key in pl:
		if key in power_levels:
			power_levels[key] = int(pl[key])
	var rl = data.get("range_levels", {})
	for key in rl:
		if key in range_levels:
			range_levels[key] = int(rl[key])
