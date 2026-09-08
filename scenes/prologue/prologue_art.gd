class_name PrologueArt
extends Control

@export_enum("castle", "manor_lights") var art_mode := "castle"
@export var active_lights := 5:
	set(value):
		active_lights = clampi(value, 0, 5)
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if art_mode == "manor_lights":
		_draw_manor_lights()
	else:
		_draw_castle()


func _draw_castle() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("100d1c"))
	# Layered stone hall and tall arches.
	for y in range(0, 648, 48):
		var offset := 24 if int(y / 48) % 2 else 0
		for x in range(-48 + offset, 1200, 96):
			draw_rect(Rect2(x, y, 92, 44), Color(0.14, 0.12, 0.20, 0.72), false, 2.0)
	for x in [80.0, 330.0, 822.0, 1072.0]:
		draw_rect(Rect2(x - 32, 72, 64, 576), Color("262035"))
		draw_rect(Rect2(x - 42, 62, 84, 24), Color("3a2a49"))
		draw_rect(Rect2(x - 45, 596, 90, 52), Color("171320"))
	for center_x in [205.0, 947.0]:
		draw_arc(Vector2(center_x, 235), 112, PI, TAU, 48, Color("493358"), 22.0)
		draw_rect(Rect2(center_x - 101, 235, 202, 240), Color("181426"))
		draw_line(Vector2(center_x, 125), Vector2(center_x, 475), Color(0.52, 0.34, 0.65, 0.18), 4.0)
	# Purple flames.
	for x in [140.0, 1012.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x,380), Vector2(x-18,424), Vector2(x,413), Vector2(x+17,424)]), Color("a14ed0"))
		draw_circle(Vector2(x, 419), 14, Color("6f2c91"))
	draw_rect(Rect2(0, 520, 1152, 128), Color("090812"))
	draw_colored_polygon(PackedVector2Array([Vector2(310,648), Vector2(480,475), Vector2(672,475), Vector2(842,648)]), Color("231c31"))


func _draw_manor_lights() -> void:
	var positions := [Vector2(630, 264), Vector2(775, 250), Vector2(850, 302), Vector2(985, 255), Vector2(1050, 315)]
	for i in active_lights:
		var pos: Vector2 = positions[i]
		for radius in [38.0, 26.0, 14.0]:
			draw_circle(pos, radius, Color(1, 0.72, 0.24, 0.025 + (38.0 - radius) * 0.005))
		draw_circle(pos, 7, Color("ffe09a"))
