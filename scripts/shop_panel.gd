extends VBoxContainer

const BALL_TYPES = ["basic", "plasma", "sniper", "scatter", "poison", "cannon"]
const IMPLEMENTED = ["basic", "plasma","sniper"]
const BALL_LABELS = {
	"basic": "BASIC BALL",
	"plasma": "PLASMA BALL",
	"sniper": "SNIPER BALL",
	"scatter": "SCATTER BALL",
	"poison": "POISON BALL",
	"cannon": "CANNON BALL",
}

signal buy_ball(type)
signal upgrade_speed(type)
signal upgrade_power(type)
signal upgrade_range(type)
signal delete_ball(type)
signal upgrade_click
signal prestige_requested

var gold_label: Label
var level_label: Label
var balls_label: Label
var ball_entries := {}
var click_panel: PanelContainer
var prestige_panel: PanelContainer

func _ready():
	_build_ui()

func _build_ui():
	var title = Label.new()
	title.text = "IDLE BREAKOUT"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	gold_label = Label.new()
	gold_label.text = "Gold: 0"
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_child(gold_label)

	level_label = Label.new()
	level_label.text = "Level 1"
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(level_label)

	balls_label = Label.new()
	balls_label.add_theme_font_size_override("font_size", 12)
	balls_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(balls_label)

	add_child(HSeparator.new())

	for type in BALL_TYPES:
		var entry = _make_ball_entry(type)
		add_child(entry)
		ball_entries[type] = entry

	add_child(HSeparator.new())

	click_panel = _make_click_entry()
	add_child(click_panel)

	add_child(HSeparator.new())

	prestige_panel = _make_prestige_entry()
	add_child(prestige_panel)

func _make_ball_entry(type: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "Entry_" + type
	var available = type in IMPLEMENTED

	var style = StyleBoxFlat.new()
	if available:
		style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	else:
		style.bg_color = Color(0.1, 0.1, 0.12, 0.6)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# top row: icon + name + count
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	vbox.add_child(header)

	var icon = Label.new()
	icon.add_theme_font_size_override("font_size", 16)
	if available:
		icon.text = "●"
		icon.add_theme_color_override("font_color", GameData.get_ball_color(type))
	else:
		icon.text = "⊕"
		icon.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	header.add_child(icon)

	var name_lbl = Label.new()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 13)
	if available:
		name_lbl.text = BALL_LABELS[type]
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	else:
		name_lbl.text = BALL_LABELS[type] + "  [SOON]"
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	header.add_child(name_lbl)

	var count_lbl = Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	header.add_child(count_lbl)

	# buttons row: Speed | Power
	var btns = HBoxContainer.new()
	btns.add_theme_constant_override("separation", 4)
	vbox.add_child(btns)

	var speed_btn = Button.new()
	speed_btn.name = "SpeedBtn"
	speed_btn.add_theme_font_size_override("font_size", 9)
	speed_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_btn.custom_minimum_size = Vector2(0, 40)
	speed_btn.pressed.connect(func(): emit_signal("upgrade_speed", type))
	btns.add_child(speed_btn)

	var power_btn = Button.new()
	power_btn.name = "PowerBtn"
	power_btn.add_theme_font_size_override("font_size", 9)
	power_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_btn.custom_minimum_size = Vector2(0, 40)
	power_btn.pressed.connect(func(): emit_signal("upgrade_power", type))
	btns.add_child(power_btn)

	# range button (only for balls that have a range stat)
	if GameData.has_range_stat(type):
		var range_btn = Button.new()
		range_btn.name = "RangeBtn"
		range_btn.add_theme_font_size_override("font_size", 9)
		range_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		range_btn.custom_minimum_size = Vector2(0, 40)
		range_btn.pressed.connect(func(): emit_signal("upgrade_range", type))
		btns.add_child(range_btn)

	# second row: buy + delete
	var btns2 = HBoxContainer.new()
	btns2.add_theme_constant_override("separation", 4)
	vbox.add_child(btns2)

	var buy_btn = Button.new()
	buy_btn.name = "BuyBtn"
	buy_btn.add_theme_font_size_override("font_size", 10)
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.pressed.connect(func(): emit_signal("buy_ball", type))
	btns2.add_child(buy_btn)

	var del_btn = Button.new()
	del_btn.name = "DeleteBtn"
	del_btn.add_theme_font_size_override("font_size", 10)
	del_btn.text = "DELETE x1"
	del_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	del_btn.pressed.connect(func(): emit_signal("delete_ball", type))
	btns2.add_child(del_btn)

	return panel

func _make_click_entry() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "ClickEntry"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var btn = Button.new()
	btn.name = "ClickUpgBtn"
	btn.add_theme_font_size_override("font_size", 10)
	btn.custom_minimum_size = Vector2(0, 42)
	btn.pressed.connect(func(): emit_signal("upgrade_click"))
	vbox.add_child(btn)

	return panel

func _make_prestige_entry() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "PrestigeEntry"

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.12, 0.25, 0.8)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "PRESTIGE"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.6, 1.0))
	vbox.add_child(title_lbl)

	var desc = Label.new()
	desc.name = "PrestigeDesc"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.6, 0.55, 0.65))
	vbox.add_child(desc)

	var current_lbl = Label.new()
	current_lbl.name = "PrestigeCurrent"
	current_lbl.add_theme_font_size_override("font_size", 11)
	current_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.85))
	vbox.add_child(current_lbl)

	var progress_lbl = Label.new()
	progress_lbl.name = "PrestigeProgress"
	progress_lbl.add_theme_font_size_override("font_size", 10)
	progress_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(progress_lbl)

	var bar_bg = ColorRect.new()
	bar_bg.name = "BarBG"
	bar_bg.custom_minimum_size = Vector2(0, 8)
	bar_bg.color = Color(0.15, 0.15, 0.15)
	vbox.add_child(bar_bg)

	var bar_fill = ColorRect.new()
	bar_fill.name = "BarFill"
	bar_fill.custom_minimum_size = Vector2(0, 8)
	bar_fill.color = Color(0.7, 0.4, 0.9)
	bar_bg.add_child(bar_fill)

	var btn = Button.new()
	btn.name = "PrestigeBtn"
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func(): emit_signal("prestige_requested"))
	vbox.add_child(btn)

	return panel

func refresh():
	if gold_label:
		gold_label.text = "Gold: " + GameData.format_number(GameData.gold)
	if level_label:
		level_label.text = "Level " + str(GameData.current_level)
		if GameData.prestige_points > 0:
			level_label.text += "  (x" + str(GameData.prestige_multiplier) + " prestige)"
	if balls_label:
		var total = GameData.get_total_balls()
		var cap = GameData.get_max_balls()
		balls_label.text = "Balls: " + str(total) + " / " + str(cap)
		if total >= cap:
			balls_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
		else:
			balls_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	var at_cap = not GameData.can_buy_ball()

	for type in BALL_TYPES:
		var entry = ball_entries.get(type)
		if not entry:
			continue
		var available = type in IMPLEMENTED
		var count = GameData.ball_counts[type]

		var count_lbl = entry.find_child("CountLabel", true, false)
		if count_lbl:
			count_lbl.text = "(x" + str(count) + ")"

		var speed_btn = entry.find_child("SpeedBtn", true, false)
		if speed_btn:
			var cur = GameData.get_ball_speed_stat(type)
			var nxt = GameData.get_ball_speed_stat_next(type)
			var cost = GameData.get_speed_upgrade_cost(type)
			speed_btn.text = "Speed\n" + str(cur) + " >> " + str(nxt) + "\n$" + GameData.format_number(cost)
			speed_btn.disabled = not available or count == 0 or GameData.gold < cost

		var power_btn = entry.find_child("PowerBtn", true, false)
		if power_btn:
			var cur = GameData.get_ball_damage(type)
			var nxt = GameData.get_ball_damage_next(type)
			var cost = GameData.get_power_upgrade_cost(type)
			power_btn.text = "Power\n" + str(cur) + " >> " + str(nxt) + "\n$" + GameData.format_number(cost)
			power_btn.disabled = not available or count == 0 or GameData.gold < cost

		var range_btn = entry.find_child("RangeBtn", true, false)
		if range_btn:
			var cur = GameData.get_ball_range_stat(type)
			var nxt = GameData.get_ball_range_stat_next(type)
			var cost = GameData.get_range_upgrade_cost(type)
			range_btn.text = "Range\n" + str(cur) + " >> " + str(nxt) + "\n$" + GameData.format_number(cost)
			range_btn.disabled = not available or count == 0 or GameData.gold < cost

		var buy_btn = entry.find_child("BuyBtn", true, false)
		if buy_btn:
			var cost = GameData.get_ball_cost(type)
			buy_btn.text = "BUY $" + GameData.format_number(cost)
			buy_btn.disabled = not available or at_cap or GameData.gold < cost

		var del_btn = entry.find_child("DeleteBtn", true, false)
		if del_btn:
			del_btn.disabled = not available or count <= 0

	if click_panel:
		var click_btn = click_panel.find_child("ClickUpgBtn", true, false)
		if click_btn:
			var cur = GameData.get_click_damage()
			var nxt = GameData.get_click_damage_next()
			var cost = GameData.get_click_upgrade_cost()
			click_btn.text = "Click X\n" + str(cur) + " >> " + str(nxt) + "\n$" + GameData.format_number(cost)
			click_btn.disabled = GameData.gold < cost

	if prestige_panel:
		var cost = GameData.get_prestige_cost()
		var earned = GameData.total_gold_earned
		var progress = clamp(earned / float(cost), 0.0, 1.0) if cost > 0 else 0.0
		var next_mult = 1.0 + (GameData.prestige_points + 1) * 0.5

		var desc_lbl = prestige_panel.find_child("PrestigeDesc", true, false)
		if desc_lbl:
			desc_lbl.text = "Reset all progress for a permanent damage multiplier."

		var cur_lbl = prestige_panel.find_child("PrestigeCurrent", true, false)
		if cur_lbl:
			if GameData.prestige_points > 0:
				cur_lbl.text = "Current: x" + str(GameData.prestige_multiplier) + " all damage"
			else:
				cur_lbl.text = "No prestige bonus yet"

		var prog_lbl = prestige_panel.find_child("PrestigeProgress", true, false)
		if prog_lbl:
			prog_lbl.text = GameData.format_number(earned) + " / " + GameData.format_number(cost) + " gold earned"

		var bar_bg = prestige_panel.find_child("BarBG", true, false)
		var bar_fill = prestige_panel.find_child("BarFill", true, false)
		if bar_bg and bar_fill:
			bar_fill.size = Vector2(bar_bg.size.x * progress, bar_bg.size.y)

		var btn = prestige_panel.find_child("PrestigeBtn", true, false)
		if btn:
			btn.text = "Prestige for x" + str(next_mult) + " damage"
			btn.disabled = earned < cost
