extends Node2D
## Short-lived, pause-aware procedural trails; authored sprites remain unchanged.
var kind := "slash"
var direction := Vector2.RIGHT
var tint := Color("ffe5a3")
var duration := 0.3
var age := 0.0
var radius := 100.0

static func spawn(parent: Node, at: Vector2, style: String, facing := Vector2.RIGHT, color := Color("ffe5a3"), size := 100.0) -> Node2D:
	var effect = load("res://scenes/chapter2/combat_fx.gd").new()
	effect.position = at
	effect.kind = style
	effect.direction = facing
	effect.tint = color
	effect.radius = size
	effect.duration = 1.15 if style in ["joy","aura"] else (0.65 if style == "warning" else 0.32)
	effect.z_index = 8
	parent.add_child(effect)
	return effect

func _process(delta: float) -> void:
	age += delta
	if age >= duration: queue_free()
	queue_redraw()

func _draw() -> void:
	var t := clampf(age / duration, 0, 1)
	var color := tint
	color.a *= sin(PI * t)
	if kind == "slash":
		var angle := direction.angle()
		for i in 4:
			draw_arc(Vector2.ZERO, radius - i * 6, angle - 1.05 + t * 0.6, angle + 0.65 + t * 0.6, 28, Color(color, color.a * (1.0 - i * 0.22)), 5.0 - i, true)
	elif kind == "warning":
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, color, 4, true)
		draw_circle(Vector2.ZERO, radius, Color(color, color.a * 0.10))
	else:
		var count := 26 if kind == "joy" else (7 if kind == "aura" else 12)
		for i in count:
			var angle := i * TAU / count + sin(i * 7.3) * 0.25
			var point := Vector2.from_angle(angle) * radius * (0.5 + 0.5 * absf(sin(i * 3.7))) * ease(t, 0.5)
			point.y *= 0.65
			if kind in ["joy","aura"]: point.y -= t * (40 + 30 * absf(sin(i)))
			var size := (5.0 if kind == "joy" else 3.0) * (1.0 - t * 0.7)
			draw_colored_polygon(PackedVector2Array([point+Vector2(0,-size*2),point+Vector2(size,0),point+Vector2(0,size*2),point+Vector2(-size,0)]), color)
		if kind == "aura": return
		draw_arc(Vector2.ZERO, maxf(1, radius * t), 0, TAU, 64, Color(color,color.a * 0.5), 3, true)

static func sound(parent: Node, kind: String) -> void:
	var mapped: String = {"impact":"hit", "joy":"purify"}.get(kind,kind)
	preload("res://systems/audio/gameplay_audio.gd").play_at(parent,mapped)
