class_name MemoryEcho
extends Node2D


func _ready() -> void:
	visible = false
	queue_redraw()


func play() -> void:
	visible = true
	modulate = Color(1, 0.74, 0.82, 0.0)
	scale = Vector2(0.88, 0.88)
	var appear := create_tween()
	appear.set_parallel(true)
	appear.tween_property(self, "modulate:a", 0.68, 0.55)
	appear.tween_property(self, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	await appear.finished


func fade_out() -> void:
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.42)
	await fade.finished
	visible = false


func _process(_delta: float) -> void:
	if visible:
		position.y += sin(Time.get_ticks_msec() * 0.004) * 0.035


func _draw() -> void:
	# Intentionally indistinct: Chapter 1 must not reveal LittlePig clearly.
	draw_circle(Vector2(0, -24), 23, Color(1, 0.54, 0.66, 0.38))
	draw_circle(Vector2(-17, -41), 11, Color(1, 0.54, 0.66, 0.32))
	draw_circle(Vector2(17, -41), 11, Color(1, 0.54, 0.66, 0.32))
	draw_style_box(_body_box(), Rect2(-30, -5, 60, 65))
	draw_circle(Vector2(-25, 46), 15, Color(1, 0.54, 0.66, 0.28))
	draw_circle(Vector2(25, 46), 15, Color(1, 0.54, 0.66, 0.28))
	for radius in [52.0, 68.0, 84.0]:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(1, 0.88, 0.67, 0.12), 2.0)


func _body_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 0.54, 0.66, 0.3)
	box.corner_radius_top_left = 22
	box.corner_radius_top_right = 22
	box.corner_radius_bottom_left = 18
	box.corner_radius_bottom_right = 18
	return box

