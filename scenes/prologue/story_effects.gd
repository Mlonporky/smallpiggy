extends Node2D
## Subtle deterministic effects; clock is supplied by the pausable timeline.
var shot_id := ""
var clock := 0.0
var change := 0.0
var joy_soft: Texture2D = preload("res://assets/prologue/joy_soft.png")
var joy_burst: Texture2D = preload("res://assets/prologue/joy_burst.png")

func _draw() -> void:
	match shot_id:
		"gift":
			_motes(Vector2(590, 310), Color(1.0, 0.79, 0.37, 0.65), 15, 0.65)
			var soft_alpha := (0.16 + sin(clock * 1.4) * 0.045) * smoothstep(0.5, 2.0, clock)
			draw_texture_rect(joy_soft, Rect2(500, 200 - sin(clock) * 3.0, 165, 165), false, Color(1, 1, 1, soft_alpha))
			var burst_t := clampf((clock - 13.0) / 2.6, 0.0, 1.0)
			var extent := lerpf(100.0, 250.0, burst_t)
			draw_texture_rect(joy_burst, Rect2(Vector2(575, 285) - Vector2.ONE * extent * 0.5, Vector2.ONE * extent), false, Color(1, 1, 1, sin(burst_t * PI) * 0.46))
		"alarm", "discovery":
			var pulse := 0.5 + 0.5 * sin(clock * (8.0 if shot_id == "alarm" else 2.0))
			_halo(Vector2(468, 290), 67.0, Color(0.73, 0.46, 1.0, 0.09 + pulse * 0.09))
		"arrival":
			_motes(Vector2(670, 350), Color(0.68, 0.36, 0.94, 0.52), 24, 1.5)
			_halo(Vector2(470, 350), 110.0, Color(0.53, 0.28, 0.86, 0.13))
		"gift_torn":
			_motes(Vector2(680, 400), Color(0.8, 0.56, 1.0, 0.65), 34, 1.6)
			_halo(Vector2(630, 370), 140.0, Color(0.63, 0.32, 0.85, 0.13))
		"transform":
			var strength := sin(change * PI)
			draw_rect(Rect2(0, 0, 1152, 648), Color(0.14, 0.05, 0.24, 0.18 * smoothstep(0.0, 2.0, clock)))
			_halo(Vector2(355, 292), 90.0 + strength * 38.0, Color(0.81, 0.64, 1.0, strength * 0.35))
			_motes(Vector2(355, 310), Color(0.8, 0.62, 1.0, strength * 0.9), 35, 0.8)
		"pig_panic", "teleport":
			draw_rect(Rect2(0, 0, 1152, 648), Color(0.15, 0.04, 0.25, 0.22))
			var strength := sin(change * PI) if shot_id == "teleport" else 0.3
			_halo(Vector2(515, 336), 100.0, Color(0.76, 0.5, 1.0, strength * 0.48))
			if shot_id == "teleport":
				_halo(Vector2(680, 365), 105.0, Color(0.76, 0.5, 1.0, strength * 0.48))
				_motes(Vector2(680, 390), Color(0.81, 0.65, 1.0, strength), 28, 1.4)
			_motes(Vector2(515, 425), Color(0.81, 0.65, 1.0, strength), 46, 1.4)
			if shot_id == "teleport":
				for i in 3:
					var points := PackedVector2Array()
					for j in 81:
						var angle := float(j) / 80.0 * TAU
						points.append(Vector2(515, 430 - i * 65) + Vector2(cos(angle) * 92, sin(angle) * 22))
					draw_polyline(points, Color(0.8, 0.59, 1.0, strength * 0.6), 2.0, true)
		"title":
			draw_rect(Rect2(0, 0, 1152, 648), Color(0.04, 0.035, 0.085, 0.72))

func _halo(center: Vector2, radius: float, color: Color) -> void:
	for i in range(12, 0, -1):
		var tint := color
		tint.a *= 0.085
		draw_circle(center, radius * float(i) / 12.0, tint)

func _motes(center: Vector2, color: Color, count: int, speed: float) -> void:
	for i in count:
		var seed_phase := float(i) * 2.399963
		var travel := fposmod(clock * speed * 0.22 + float(i) / count, 1.0)
		var pos := center + Vector2(sin(seed_phase + clock * 0.35) * (22 + i % 7 * 11), -travel * 155)
		var tint := color
		tint.a *= sin(travel * PI)
		draw_circle(pos, 1.4 + float(i % 3) * 0.65, tint)
