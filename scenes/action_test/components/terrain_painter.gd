extends RefCounted
## Hand-drawn style terrain for the action test (native resolution, antialiased strokes).
## Every walkable top matches its collider exactly; moss lumps, drips and roots are decoration.
const EARTH_TOP := Color("2f4c34")
const EARTH_MID := Color("1a2e22")
const EARTH_DEEP := Color("101d17")
const RIM := Color("0c1511")
const MOSS := Color("6e8d46")
const MOSS_DARK := Color("4d6a35")
const MOSS_LIGHT := Color("a9c47a")
const BARK := Color("5d4631")
const BARK_DARK := Color("2e2218")
const BARK_LIGHT := Color("8a6a48")
## Antialiased strokes are costly in the Compatibility renderer; only the bright top edges use them.


static func paint(canvas: CanvasItem, rect: Rect2) -> void:
	if rect.size.y <= 40:
		paint_ledge(canvas, rect)
	else:
		paint_block(canvas, rect)


static func _rng(rect: Rect2) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x * 31 + rect.position.y * 17 + rect.size.x * 7)
	return rng


static func paint_block(canvas: CanvasItem, rect: Rect2) -> void:
	var rng := _rng(rect)
	# Soft vertical gradient: two vertex-coloured quads instead of many thin bands.
	var mid_y := rect.position.y + minf(280.0, rect.size.y)
	var deep := EARTH_MID.lerp(EARTH_DEEP, clampf((rect.size.y - 280.0) / 300.0, 0, 1))
	canvas.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, mid_y), Vector2(rect.position.x, mid_y)]),
		PackedColorArray([EARTH_TOP, EARTH_TOP, EARTH_TOP.lerp(EARTH_MID, clampf(rect.size.y / 280.0, 0, 1)), EARTH_TOP.lerp(EARTH_MID, clampf(rect.size.y / 280.0, 0, 1))]))
	if rect.size.y > 280:
		canvas.draw_polygon(PackedVector2Array([Vector2(rect.position.x, mid_y), Vector2(rect.end.x, mid_y), rect.end, Vector2(rect.position.x, rect.end.y)]),
			PackedColorArray([EARTH_MID, EARTH_MID, deep, deep]))
	# Gentle strata.
	for i in int(minf(rect.size.y, 420) / 90):
		var points := PackedVector2Array()
		var base := rect.position.y + 60 + i * 90 + rng.randf_range(-10, 10)
		var x := rect.position.x + 6
		while x < rect.end.x - 6:
			points.append(Vector2(x, base + sin(x * 0.013 + i) * 6))
			x += 24
		points.append(Vector2(rect.end.x - 6, base + sin((rect.end.x - 6) * 0.013 + i) * 6))
		canvas.draw_polyline(points, Color(0.07, 0.13, 0.10, 0.55), 2.0, false)
	# Rounded stones, denser near the surface.
	var count := int(rect.size.x * minf(rect.size.y, 320) / 16000.0)
	for i in count:
		var depth := pow(rng.randf(), 1.6) * minf(rect.size.y - 30, 320)
		var at := Vector2(rng.randf_range(rect.position.x + 14, rect.end.x - 14), rect.position.y + 34 + depth)
		if at.y > rect.end.y - 10:
			continue
		var radius := rng.randf_range(7, 17) * (1.0 - depth / 700.0)
		var tone: Color = [Color("2f4b35"), Color("26402d"), Color("34523a"), Color("233a2a")][rng.randi_range(0, 3)]
		canvas.draw_set_transform(at, rng.randf_range(-0.3, 0.3), Vector2(1.35, 0.85))
		canvas.draw_circle(Vector2.ZERO, radius + 1.5, Color(0.05, 0.09, 0.07, 0.45), true, -1, false)
		canvas.draw_circle(Vector2.ZERO, radius, tone, true, -1, false)
		canvas.draw_arc(Vector2.ZERO, radius - 2.5, PI * 1.15, PI * 1.75, 8, Color(0.6, 0.72, 0.52, 0.16), 2.0, false)
		canvas.draw_set_transform(Vector2.ZERO)
	# Dark rims on the sides.
	canvas.draw_line(rect.position + Vector2(1, 6), Vector2(rect.position.x + 1, rect.end.y), RIM, 3.0, false)
	canvas.draw_line(Vector2(rect.end.x - 1, rect.position.y + 6), rect.end - Vector2(1, 0), RIM, 3.0, false)
	_side_roots(canvas, rect, rng)
	_moss_cap(canvas, rect, rng, 16.0)


static func paint_ledge(canvas: CanvasItem, rect: Rect2) -> void:
	# A thick root log with a mossy top, used for solid thin ledges.
	var rng := _rng(rect)
	var box := StyleBoxFlat.new()
	box.bg_color = BARK
	box.border_color = BARK_DARK
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(minf(rect.size.y * 0.5, 12)))
	box.anti_aliasing = true
	canvas.draw_style_box(box, rect)
	for i in int(rect.size.x / 34):
		var x := rect.position.x + 16 + i * 34 + rng.randf_range(-6, 6)
		canvas.draw_line(Vector2(x, rect.position.y + 9), Vector2(x + rng.randf_range(8, 16), rect.end.y - 5), Color(BARK_DARK, 0.55), 1.5, false)
	canvas.draw_line(Vector2(rect.position.x + 8, rect.end.y - 4), Vector2(rect.end.x - 8, rect.end.y - 4), Color(BARK_LIGHT, 0.35), 1.5, false)
	_hanging_vines(canvas, rect, rng)
	_moss_cap(canvas, rect, rng, 9.0)


static func paint_branch(canvas: CanvasItem, rect: Rect2) -> void:
	# Jump-through branch: slimmer, lighter wood with leaf tufts; clearly different from solid logs.
	var rng := _rng(rect)
	var top := rect.position.y
	var points := PackedVector2Array()
	var x := rect.position.x
	while x <= rect.end.x:
		points.append(Vector2(x, top + 5 + sin(x * 0.05) * 1.5))
		x += 12
	canvas.draw_polyline(points, BARK_DARK, 13.0, false)
	canvas.draw_polyline(points, Color("7c5e3e"), 9.0, false)
	var highlight := PackedVector2Array()
	for p in points:
		highlight.append(p + Vector2(0, -2.5))
	canvas.draw_polyline(highlight, Color("a4845c"), 2.0, true)
	for i in int(rect.size.x / 46) + 1:
		var at := Vector2(rect.position.x + 12 + i * 46 + rng.randf_range(-8, 8), top + 3)
		if at.x > rect.end.x - 6:
			break
		_leaf(canvas, at + Vector2(0, -2), -0.9, 9, Color("7fa257"))
		_leaf(canvas, at + Vector2(6, 0), -0.2, 8, Color("5f8543"))
		_leaf(canvas, at + Vector2(-5, 3), 2.6, 7, Color("6d924c"))


static func paint_crumble(canvas: CanvasItem, rect: Rect2, crack: float) -> void:
	# Pale cracked slab; `crack` 0..1 widens the fractures before it breaks.
	var box := StyleBoxFlat.new()
	box.bg_color = Color("8d937c").lerp(Color("a18c71"), crack * 0.5)
	box.border_color = Color("3c3f33")
	box.set_border_width_all(2)
	box.set_corner_radius_all(5)
	box.anti_aliasing = true
	canvas.draw_style_box(box, rect)
	canvas.draw_line(rect.position + Vector2(6, 5), Vector2(rect.end.x - 6, rect.position.y + 5), Color("c6c8ad"), 2.0, false)
	var mid := rect.position.x + rect.size.x * 0.45
	var spread := 1.0 + crack * 3.0
	canvas.draw_polyline(PackedVector2Array([Vector2(mid, rect.position.y + 2), Vector2(mid - 7, rect.get_center().y), Vector2(mid + 4, rect.end.y - 2)]), Color("3c3f33"), spread, false)
	canvas.draw_polyline(PackedVector2Array([Vector2(mid + 28, rect.position.y + 3), Vector2(mid + 22, rect.end.y - 4)]), Color("4a4d3f"), spread * 0.8, false)
	canvas.draw_polyline(PackedVector2Array([Vector2(rect.position.x + 14, rect.end.y - 3), Vector2(rect.position.x + 24, rect.get_center().y)]), Color("4a4d3f"), spread * 0.7, false)


static func _moss_cap(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator, thickness: float) -> void:
	var top := rect.position.y
	var left := rect.position.x
	var right := rect.end.x
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	var x := left
	while x < right:
		upper.append(Vector2(x, top - 1.5 - absf(sin(x * 0.11)) * 2.0))
		lower.append(Vector2(x, top + thickness * (0.55 + 0.45 * absf(sin(x * 0.047 + 1.3))) + (rng.randf() * 3.0)))
		x += 10
	upper.append(Vector2(right, top - 1.5))
	lower.append(Vector2(right, top + thickness * 0.6))
	var cap := upper.duplicate()
	for i in range(lower.size() - 1, -1, -1):
		cap.append(lower[i])
	canvas.draw_colored_polygon(cap, MOSS)
	canvas.draw_polyline(lower, MOSS_DARK, 2.5, false)
	canvas.draw_polyline(upper, MOSS_LIGHT, 3.0, true)
	# Moss drips over the edges and occasional drops along the lip.
	for side in [left + 3, right - 3]:
		var length := thickness + rng.randf_range(6, 18)
		canvas.draw_line(Vector2(side, top), Vector2(side, top + length), MOSS_DARK, 5.0, false)
		canvas.draw_circle(Vector2(side, top + length), 3.2, MOSS_DARK, true, -1, false)
	# Grass blades and tiny pale flowers.
	x = left + 6
	while x < right - 4:
		if rng.randf() < 0.55:
			var h := rng.randf_range(4, 11)
			var lean := rng.randf_range(-3, 3)
			canvas.draw_line(Vector2(x, top), Vector2(x + lean, top - h), Color("8fb15e"), 1.6, false)
		if rng.randf() < 0.05:
			canvas.draw_circle(Vector2(x, top - 5), 2.4, Color("f0e3b0"), true, -1, false)
			canvas.draw_circle(Vector2(x, top - 5), 1.0, Color("e0a86a"), true, -1, false)
		x += rng.randf_range(7, 13)


static func _side_roots(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator) -> void:
	if rect.size.y < 120:
		return
	for side in [-1.0, 1.0]:
		if rng.randf() < 0.35:
			continue
		var x: float = rect.position.x + 4 if side < 0 else rect.end.x - 4
		var points := PackedVector2Array()
		var length := rng.randf_range(70, 160)
		for j in 9:
			var t := j / 8.0
			points.append(Vector2(x + sin(t * 3.0 + rng.randf()) * 5 * -side, rect.position.y + 10 + t * length))
		canvas.draw_polyline(points, Color("3d3024"), 4.0, false)
		canvas.draw_polyline(points, Color("5b4633"), 1.5, false)


static func _hanging_vines(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator) -> void:
	for i in int(rect.size.x / 60):
		if rng.randf() < 0.4:
			continue
		var x := rect.position.x + 20 + i * 60 + rng.randf_range(-10, 10)
		var length := rng.randf_range(18, 58)
		var points := PackedVector2Array()
		for j in 7:
			var t := j / 6.0
			points.append(Vector2(x + sin(t * 4.0 + i) * 4, rect.end.y - 2 + t * length))
		canvas.draw_polyline(points, Color("41583a"), 2.5, false)
		for j in range(2, 7, 2):
			_leaf(canvas, points[j], 1.2 if j % 4 == 0 else 1.9, 6, Color("587a44"))


static func _leaf(canvas: CanvasItem, at: Vector2, angle: float, length: float, color: Color) -> void:
	var tip := at + Vector2(cos(angle), sin(angle)) * length
	var side := Vector2(-sin(angle), cos(angle)) * length * 0.32
	var mid := (at + tip) * 0.5
	canvas.draw_colored_polygon(PackedVector2Array([at, mid + side, tip, mid - side]), color)
