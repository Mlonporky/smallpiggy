extends Node2D
## Mid-depth cave layer between the far painting and the playfield: dark pillars, hanging root
## curtains and faint light shafts. Low contrast on purpose; it only adds depth. Moves at `factor`
## of the playfield speed, same direction, positioned on physics ticks (interpolated with the camera).
var factor := Vector2(0.42, 0.20)
var size := Vector2.ZERO
var anchor := Vector2.ZERO
var seed_value := 7
const CHUNK := 1024.0


func setup(bounds: Rect2, view: Vector2) -> void:
	z_index = -40
	var half := view * 0.5
	var travel := Vector2(maxf(0, bounds.size.x - view.x), maxf(0, bounds.size.y - view.y))
	anchor = bounds.position + half + travel * 0.5
	size = view + travel * factor + Vector2(80, 80)
	_build_chunks()


func follow(camera_center: Vector2) -> void:
	position = camera_center - (camera_center - anchor) * factor


func _build_chunks() -> void:
	# Separate canvas items per 1024 px strip, so strips outside the camera are culled.
	for child in get_children():
		child.queue_free()
	var left := -size.x * 0.5
	var x := left
	while x < size.x * 0.5:
		var chunk := Node2D.new()
		add_child(chunk)
		var from := x
		chunk.draw.connect(func(): _paint(chunk, from, minf(from + CHUNK, size.x * 0.5)))
		x += CHUNK


func _paint(canvas: CanvasItem, from: float, to: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + int(from)
	var left := from
	var top := -size.y * 0.5
	var bottom := size.y * 0.5
	# Light shafts first, so pillars and roots cut through them.
	var x := left + rng.randf_range(100, 400)
	while x < to:
		var width := rng.randf_range(90, 180)
		var slant := rng.randf_range(160, 260)
		var shaft := PackedVector2Array([Vector2(x, top), Vector2(x + width, top), Vector2(x + width + slant, bottom), Vector2(x + slant * 0.9, bottom)])
		var colors := PackedColorArray([Color(0.78, 0.86, 0.62, 0.075), Color(0.78, 0.86, 0.62, 0.075), Color(0.78, 0.86, 0.62, 0.0), Color(0.78, 0.86, 0.62, 0.0)])
		canvas.draw_polygon(shaft, colors)
		x += rng.randf_range(700, 1300)
	# Distant pillars / root trunks.
	x = left + rng.randf_range(0, 250)
	while x < to:
		var width := rng.randf_range(55, 120)
		var tone := Color(0.07, 0.13, 0.11, rng.randf_range(0.55, 0.75))
		var trunk := PackedVector2Array()
		var steps := 10
		for i in steps + 1:
			var t := float(i) / steps
			trunk.append(Vector2(x + sin(t * 3.0 + x) * 10 - width * (0.5 + 0.15 * (1 - t)), lerpf(top, bottom, t)))
		for i in range(steps, -1, -1):
			var t := float(i) / steps
			trunk.append(Vector2(x + sin(t * 3.0 + x) * 10 + width * (0.5 + 0.15 * (1 - t)), lerpf(top, bottom, t)))
		canvas.draw_colored_polygon(trunk, tone)
		for band in rng.randi_range(1, 3):
			var y := lerpf(top, bottom, rng.randf_range(0.2, 0.8))
			canvas.draw_line(Vector2(x - width * 0.6, y), Vector2(x + width * 0.6, y + rng.randf_range(-12, 12)), Color(0.10, 0.18, 0.14, 0.6), 5.0, true)
		x += rng.randf_range(420, 820)
	# Hanging root curtains.
	x = left
	while x < to:
		var length := rng.randf_range(120, 420)
		var sway := rng.randf_range(-20, 20)
		var root := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			root.append(Vector2(x + sin(t * 2.4 + x * 0.01) * 8 + sway * t, top + t * length))
		canvas.draw_polyline(root, Color(0.08, 0.14, 0.11, 0.8), rng.randf_range(2.5, 6.0), true)
		if rng.randf() < 0.5:
			canvas.draw_circle(root[8], 3.0, Color(0.10, 0.18, 0.13, 0.8), true, -1, true)
		x += rng.randf_range(18, 90)
