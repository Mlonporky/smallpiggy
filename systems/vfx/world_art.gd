class_name WorldArt
extends Node2D

@export_enum("home", "forest") var theme := "home"


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if theme == "forest":
		_draw_forest()
	else:
		_draw_home()


func _draw_home() -> void:
	# Overscan prevents exposed clear color while Camera2D settles at a limit.
	draw_rect(Rect2(-1000, -700, 2000, 1400), Color("b9ae91"))
	draw_rect(Rect2(-900, -520, 1800, 1040), Color("d9cba8"))
	for x in range(-900, 901, 64):
		draw_line(Vector2(x, -312), Vector2(x, 312), Color(0.54, 0.47, 0.34, 0.11), 2.0)
	# Rugs and room zones.
	draw_style_box(_rounded(Color("849178"), 20), Rect2(-500, -250, 370, 450))
	draw_style_box(_rounded(Color("c08f70"), 20), Rect2(-80, -250, 570, 450))
	draw_rect(Rect2(-552, 210, 1104, 102), Color("85694f"))
	# Windows and light shafts.
	draw_rect(Rect2(-455, -292, 160, 22), Color("9bc3c7"))
	draw_colored_polygon(PackedVector2Array([Vector2(-455,-270), Vector2(-295,-270), Vector2(-220,120), Vector2(-530,120)]), Color(1, 0.94, 0.69, 0.12))
	# Table.
	draw_circle(Vector2(215, -25), 112, Color("815f43"))
	draw_circle(Vector2(215, -25), 98, Color("b8885d"))
	draw_circle(Vector2(215, -25), 84, Color("c79b70"))
	# Counters.
	draw_style_box(_rounded(Color("705744"), 12), Rect2(390, -250, 105, 188))
	draw_style_box(_rounded(Color("d1b189"), 10), Rect2(399, -241, 87, 168))
	# Foreground warmth.
	draw_circle(Vector2(-470, 265), 82, Color("63805c"))
	draw_circle(Vector2(470, 265), 92, Color("63805c"))


func _draw_forest() -> void:
	draw_rect(Rect2(-1300, -850, 2600, 1700), Color("17263a"))
	draw_circle(Vector2.ZERO, 430, Color("273d45"))
	# Winding clearing.
	var path := PackedVector2Array([
		Vector2(-680, 250), Vector2(-520, 80), Vector2(-310, 35),
		Vector2(-60, 85), Vector2(190, 30), Vector2(520, -100), Vector2(720, -240),
		Vector2(720, 310), Vector2(-680, 310),
	])
	draw_colored_polygon(path, Color("4d5946"))
	for pos in [Vector2(-610,-270), Vector2(-410,-220), Vector2(-180,-300), Vector2(90,-270), Vector2(340,-300), Vector2(580,-260), Vector2(-650,80), Vector2(650,80)]:
		draw_circle(pos, 74, Color("1b3231"))
		draw_circle(pos + Vector2(0,-35), 52, Color("29483d"))
		draw_rect(Rect2(pos.x - 14, pos.y + 25, 28, 100), Color("4a3a37"))
	# Purple curse fog layers.
	for pos in [Vector2(-480,-120), Vector2(-90,-180), Vector2(330,-130), Vector2(560,160)]:
		draw_circle(pos, 105, Color(0.43, 0.2, 0.58, 0.1))


func _rounded(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box
