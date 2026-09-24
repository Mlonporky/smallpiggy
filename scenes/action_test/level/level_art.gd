extends RefCounted
## Hand-drawn props for the action test level (native resolution, antialiased).
const FONT = preload("res://assets/fonts/game_font.tres")


static func mushroom(canvas: CanvasItem, at: Vector2, squash: float, big: bool) -> void:
	# `at` is the ground point under the stem. `squash` 0..1 flattens the cap after a bounce.
	var s := 1.3 if big else 1.0
	var cap_color := Color("e0a23f") if big else Color("d4626a")
	var cap_shade := Color("a8702a") if big else Color("9e3f4c")
	var stem_h := 26.0 * s * (1.0 - squash * 0.45)
	canvas.draw_rect(Rect2(at + Vector2(-9 * s, -stem_h), Vector2(18 * s, stem_h)), Color("e9dcc0"))
	canvas.draw_line(at + Vector2(-9 * s, -stem_h), at + Vector2(-9 * s, 0), Color("8d7c64"), 2.0, true)
	canvas.draw_line(at + Vector2(9 * s, -stem_h), at + Vector2(9 * s, 0), Color("8d7c64"), 2.0, true)
	var cap_w := 40.0 * s * (1.0 + squash * 0.35)
	var cap_h := 30.0 * s * (1.0 - squash * 0.5)
	var base := at + Vector2(0, -stem_h + 4)
	var points := PackedVector2Array()
	for i in 17:
		var a := PI + i * PI / 16.0
		points.append(base + Vector2(cos(a) * cap_w, sin(a) * cap_h))
	canvas.draw_colored_polygon(points, cap_color)
	var rim := points.duplicate()
	rim.append(points[0])
	canvas.draw_polyline(rim, cap_shade, 2.5, true)
	canvas.draw_line(base + Vector2(-cap_w, 0), base + Vector2(cap_w, 0), cap_shade, 4.0, true)
	for spot in [Vector2(-0.45, -0.45), Vector2(0.1, -0.75), Vector2(0.55, -0.35), Vector2(-0.1, -0.25)]:
		canvas.draw_circle(base + Vector2(spot.x * cap_w, spot.y * cap_h), 4.5 * s, Color("fbf0da"), true, -1, true)
	if big:
		canvas.draw_circle(base + Vector2(0, -cap_h * 0.4), cap_w * 1.1, Color(1.0, 0.85, 0.45, 0.10), true, -1, true)


static func thorns(canvas: CanvasItem, rect: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x * 13 + rect.position.y)
	var ground := rect.end.y
	# Bramble tangle, then pale spikes.
	var x := rect.position.x
	var tangle := PackedVector2Array()
	while x <= rect.end.x:
		tangle.append(Vector2(x, ground - 8 - absf(sin(x * 0.09)) * 8))
		x += 8
	canvas.draw_polyline(tangle, Color("2f2420"), 7.0, true)
	canvas.draw_polyline(tangle, Color("5b3f33"), 3.0, true)
	x = rect.position.x + 6
	while x < rect.end.x - 4:
		var h := rng.randf_range(0.65, 1.0) * rect.size.y
		var lean := rng.randf_range(-5, 5)
		var spike := PackedVector2Array([Vector2(x - 6, ground - 4), Vector2(x + lean, ground - h), Vector2(x + 6, ground - 4)])
		canvas.draw_colored_polygon(spike, Color("d9cfae"))
		canvas.draw_polyline(PackedVector2Array([spike[0], spike[1], spike[2]]), Color("6e5b45"), 1.5, true)
		x += rng.randf_range(11, 16)


static func firefly(canvas: CanvasItem, at: Vector2, time: float) -> void:
	var pulse := 0.6 + 0.4 * sin(time * 4.0)
	canvas.draw_circle(at, 17, Color(0.95, 0.92, 0.45, 0.10 * pulse), true, -1, true)
	canvas.draw_circle(at, 9, Color(0.98, 0.95, 0.55, 0.25 * pulse), true, -1, true)
	canvas.draw_circle(at, 4.5, Color(1.0, 0.98, 0.75, 0.95), true, -1, true)
	var wing := Color(0.9, 1.0, 0.95, 0.45)
	var flap := sin(time * 22.0) * 0.4
	canvas.draw_line(at + Vector2(-2, -2), at + Vector2(-8, -7 + flap * 4), wing, 2.5, true)
	canvas.draw_line(at + Vector2(2, -2), at + Vector2(8, -7 - flap * 4), wing, 2.5, true)


static func sparkle(canvas: CanvasItem, at: Vector2, t: float) -> void:
	# Short burst after a firefly is collected (t: 0..1).
	var alpha := 1.0 - t
	for i in 6:
		var a := i * TAU / 6.0 + t
		canvas.draw_line(at + Vector2(cos(a), sin(a)) * (6 + 18 * t), at + Vector2(cos(a), sin(a)) * (12 + 26 * t), Color(1, 0.96, 0.6, alpha), 2.0, true)


static func campfire(canvas: CanvasItem, at: Vector2, lit: bool, time: float) -> void:
	canvas.draw_line(at + Vector2(-26, -4), at + Vector2(22, -12), Color("6b4a31"), 9.0, true)
	canvas.draw_line(at + Vector2(-22, -12), at + Vector2(26, -4), Color("80583a"), 9.0, true)
	for i in 5:
		var a := i * TAU / 5.0
		canvas.draw_circle(at + Vector2(cos(a) * 30, -3 + sin(a) * 4), 6, Color("55594e"), true, -1, true)
	if not lit:
		canvas.draw_circle(at + Vector2(0, -12), 5, Color("3b3a36"), true, -1, true)
		for i in 3:
			var rise := fmod(time * 18.0 + i * 20.0, 60.0)
			canvas.draw_circle(at + Vector2(sin(time + i) * 4, -18 - rise), 3 + rise * 0.06, Color(0.6, 0.62, 0.58, 0.25 * (1.0 - rise / 60.0)), true, -1, true)
		return
	canvas.draw_circle(at + Vector2(0, -26), 70, Color(1.0, 0.72, 0.35, 0.10), true, -1, true)
	canvas.draw_circle(at + Vector2(0, -22), 38, Color(1.0, 0.72, 0.35, 0.14), true, -1, true)
	for layer in 3:
		var height: float = [46.0, 34.0, 20.0][layer]
		var width: float = [16.0, 11.0, 6.0][layer]
		var color: Color = [Color("e8753b"), Color("f5b04c"), Color("fff0b0")][layer]
		var sway := sin(time * 7.0 + layer) * 4.0
		var flame := PackedVector2Array([at + Vector2(-width, -8), at + Vector2(-width * 0.5, -height * 0.55), at + Vector2(sway, -height), at + Vector2(width * 0.55, -height * 0.5), at + Vector2(width, -8)])
		canvas.draw_colored_polygon(flame, color)
	for i in 3:
		var t := fmod(time * 0.9 + i * 0.33, 1.0)
		canvas.draw_circle(at + Vector2(sin(time * 3.0 + i * 2.0) * 10, -40 - t * 60), 2.0, Color(1, 0.8, 0.4, 1.0 - t), true, -1, true)


static func exit_light(canvas: CanvasItem, at: Vector2, time: float) -> void:
	# A warm crack of daylight: shaft from above plus a mossy arch around the opening.
	var shaft := PackedVector2Array([at + Vector2(-60, -700), at + Vector2(40, -700), at + Vector2(90, 0), at + Vector2(-90, 0)])
	canvas.draw_polygon(shaft, PackedColorArray([Color(1, 0.93, 0.7, 0.22), Color(1, 0.93, 0.7, 0.22), Color(1, 0.9, 0.6, 0.06), Color(1, 0.9, 0.6, 0.06)]))
	canvas.draw_arc(at + Vector2(0, -80), 86, PI, TAU, 32, Color("2a3a2c"), 22.0, true)
	canvas.draw_arc(at + Vector2(0, -80), 86, PI, TAU, 32, Color("6e8d46"), 6.0, true)
	canvas.draw_rect(Rect2(at + Vector2(-72, -80), Vector2(144, 80)), Color(1.0, 0.94, 0.72, 0.30))
	canvas.draw_circle(at + Vector2(0, -80), 70, Color(1.0, 0.94, 0.72, 0.30), true, -1, true)
	for i in 6:
		var t := fmod(time * 0.35 + i / 6.0, 1.0)
		canvas.draw_circle(at + Vector2(sin(time + i * 1.7) * 50, -20 - t * 220), 2.5, Color(1, 0.97, 0.8, 0.8 * (1.0 - t)), true, -1, true)


static func sign(canvas: CanvasItem, at: Vector2, text: String) -> void:
	var size := 22
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	# Board sits above the pig's head (~87 units), so standing in front never hides the text.
	var board := Rect2(at + Vector2(-width * 0.5 - 14, -136), Vector2(width + 28, 40))
	canvas.draw_line(at + Vector2(0, -96), at, Color("4b3726"), 6.0, true)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("6c5238")
	box.border_color = Color("33241a")
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.anti_aliasing = true
	canvas.draw_style_box(box, board)
	canvas.draw_string(FONT, board.position + Vector2(14, 28), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("f6e9c8"))


static func leaf_curtain(canvas: CanvasItem, rect: Rect2, alpha: float) -> void:
	# Hanging leaves that hide a nook; fades when the pig steps inside.
	if alpha <= 0.01:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x)
	canvas.draw_rect(rect.grow_individual(0, 0, 0, -30), Color(0.07, 0.12, 0.09, 0.93 * alpha))
	var x := rect.position.x - 10
	while x < rect.end.x + 10:
		var length := rect.size.y * rng.randf_range(0.75, 1.05)
		var points := PackedVector2Array()
		for j in 8:
			var t := j / 7.0
			points.append(Vector2(x + sin(t * 3.0 + x) * 5, rect.position.y + t * length))
		canvas.draw_polyline(points, Color(0.16, 0.25, 0.15, alpha), 5.0, true)
		for j in range(1, 8):
			var leaf_at := points[j]
			var tone := Color("3f6135") if j % 2 == 0 else Color("557a41")
			var tip := leaf_at + Vector2(10 if j % 2 == 0 else -10, 8)
			var side := (tip - leaf_at).orthogonal() * 0.3
			var mid := (leaf_at + tip) * 0.5
			canvas.draw_colored_polygon(PackedVector2Array([leaf_at, mid + side, tip, mid - side]), Color(tone, alpha))
		x += rng.randf_range(12, 20)
