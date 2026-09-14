class_name PropInteractable
extends Interactable

@export_enum("coffee", "cup", "tableware", "slot", "fragment") var visual_kind := "cup"
@export var accent := Color("e8a3aa")
@export var display_label := ""


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	queue_redraw()


func _draw() -> void:
	match visual_kind:
		"coffee":
			draw_style_box(_box(Color("776a60"), 8), Rect2(-28, -36, 56, 72))
			draw_rect(Rect2(-17, -23, 34, 26), Color("b5c3b5"))
			draw_circle(Vector2(0, 20), 6, Color("eed799"))
		"cup":
			draw_circle(Vector2.ZERO, 22, accent)
			draw_circle(Vector2.ZERO, 14, Color("5b3d36"))
			draw_arc(Vector2(22, 0), 10, -PI / 2.0, PI / 2.0, 12, accent, 6.0)
		"tableware":
			for x in [-12.0, 0.0, 12.0]:
				draw_line(Vector2(x, -25), Vector2(x, 25), accent, 5.0)
			draw_circle(Vector2(12, -24), 6, accent)
		"slot":
			draw_circle(Vector2.ZERO, 38, Color(accent, 0.16))
			draw_arc(Vector2.ZERO, 38, 0, TAU, 48, Color(accent, 0.65), 2.0)
		"fragment":
			var points := PackedVector2Array([Vector2(-26,-18), Vector2(24,-24), Vector2(30,13), Vector2(4,26), Vector2(-31,12)])
			draw_colored_polygon(points, accent)
			for x in [-12.0, 8.0]:
				draw_circle(Vector2(x, 0), 4, Color("8b3d4a"))
	if not display_label.is_empty():
		draw_string(preload("res://assets/fonts/game_font.tres"), Vector2(-42, 55), display_label, HORIZONTAL_ALIGNMENT_CENTER, 84, 15, Color(1, 0.95, 0.85, 0.8))


func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box

