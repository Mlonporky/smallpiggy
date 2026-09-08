class_name PrologueMagicCircle
extends Node2D

var spinning := false


func _ready() -> void:
	visible = false
	queue_redraw()


func _process(delta: float) -> void:
	if spinning:
		rotation += delta * 0.48


func activate() -> void:
	visible = true
	spinning = true
	modulate = Color(0.83, 0.4, 1.0, 0.0)
	scale = Vector2(0.15, 0.15)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.86, 0.55)
	tween.tween_property(self, "scale", Vector2.ONE, 1.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


func surge() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.18)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_ELASTIC)


func _draw() -> void:
	for radius in [92.0, 128.0, 178.0, 222.0]:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 96, Color(0.81, 0.43, 1.0, 0.78), 4.0)
	for i in 12:
		var angle := TAU * i / 12.0
		var inner := Vector2.from_angle(angle) * 95.0
		var outer := Vector2.from_angle(angle) * 215.0
		draw_line(inner, outer, Color(0.76, 0.38, 1.0, 0.5), 2.0)
		draw_circle(outer, 8, Color(0.93, 0.68, 1.0, 0.72))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-148), Vector2(128,74), Vector2(-128,74)]), Color(0.56, 0.19, 0.78, 0.10))
	draw_arc(Vector2.ZERO, 64, 0, TAU, 64, Color("f0b8ff"), 5.0)

