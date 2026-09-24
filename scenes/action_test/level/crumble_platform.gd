extends StaticBody2D
## Cracked slab: standing on it starts a short shake, then it breaks, falls away and grows back.
## States are driven by the level's `tick`, so they pause with hit-stop and the pause menu.
const Terrain = preload("res://scenes/action_test/components/terrain_painter.gd")
@export var break_delay := 0.45
@export var respawn_delay := 2.2
var rect := Rect2()
var state := "SOLID"
var timer := 0.0
var fall := 0.0
var shape: CollisionShape2D


func setup(area: Rect2) -> void:
	rect = area
	position = rect.position
	collision_layer = 1
	collision_mask = 0
	shape = CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.size * 0.5
	add_child(shape)
	queue_redraw()


func is_standing(player: CharacterBody2D) -> bool:
	return player.is_on_floor() and absf(player.position.y - rect.position.y) < 4 and player.position.x > rect.position.x - 16 and player.position.x < rect.end.x + 16


func tick(delta: float, player: CharacterBody2D) -> String:
	var event := ""
	match state:
		"SOLID":
			if is_standing(player):
				state = "SHAKING"
				timer = break_delay
				event = "crack"
		"SHAKING":
			timer -= delta
			if timer <= 0:
				state = "FALLEN"
				timer = respawn_delay
				fall = 0
				shape.set_deferred("disabled", true)
				event = "break"
		"FALLEN":
			timer -= delta
			fall += delta
			if timer <= 0:
				state = "RETURNING"
				timer = 0.35
		"RETURNING":
			timer -= delta
			if timer <= 0 and not _player_inside(player):
				state = "SOLID"
				shape.set_deferred("disabled", false)
	match state:
		"FALLEN":
			modulate.a = clampf(1.0 - fall / 0.7, 0, 1)
		"RETURNING":
			modulate.a = 1.0 - clampf(timer / 0.35, 0, 1)
		_:
			modulate.a = 1.0
	queue_redraw()
	return event


func reset_slab() -> void:
	state = "SOLID"
	timer = 0
	fall = 0
	shape.set_deferred("disabled", false)
	modulate.a = 1.0
	queue_redraw()


func _player_inside(player: CharacterBody2D) -> bool:
	return rect.intersects(player.body_box())


func _draw() -> void:
	var local := Rect2(Vector2.ZERO, rect.size)
	match state:
		"SOLID":
			Terrain.paint_crumble(self, local, 0.0)
		"SHAKING":
			var t := 1.0 - timer / break_delay
			var jitter := Vector2(sin(timer * 90.0) * 2.5 * t, 0)
			draw_set_transform(jitter)
			Terrain.paint_crumble(self, local, t)
			draw_set_transform(Vector2.ZERO)
		"FALLEN":
			# Two halves drop and fade.
			var drop := 380.0 * fall * fall + 40.0 * fall
			if fall < 0.7:
				var half := Vector2(local.size.x * 0.5, local.size.y)
				draw_set_transform(Vector2(-4 * fall * 10, drop), -0.5 * fall)
				Terrain.paint_crumble(self, Rect2(Vector2.ZERO, half), 1.0)
				draw_set_transform(Vector2(half.x + 4 * fall * 10, drop * 1.1), 0.6 * fall)
				Terrain.paint_crumble(self, Rect2(Vector2.ZERO, half), 1.0)
				draw_set_transform(Vector2.ZERO)
		"RETURNING":
			Terrain.paint_crumble(self, local, 0.0)
