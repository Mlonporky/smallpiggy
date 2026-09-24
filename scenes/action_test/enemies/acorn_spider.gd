extends "res://scenes/action_test/enemies/base_enemy.gd"
## 橡果蛛 · acorn spider. Hangs on a silk thread under a ledge; spawn it at the ceiling point it
## hangs from. When the pig passes underneath it trembles and dust trickles down (telegraph), then
## it drops fast to her head height and dangles there, swaying and blocking the way, before it
## climbs back up. Strike it while it dangles, roll under it, or wait it out.
const BODY = preload("res://assets/chapter2/monsters/spider_body.png")
const CENTER := Vector2(60, 70)
const REST := 44.0
const TREMBLE_TIME := 0.4
const DANGLE_TIME := 1.5
var anchor := Vector2.ZERO
var drop_y := -1.0
var cooldown := 0.0
var sway := 0.0


func _ready() -> void:
	flying = true
	centred = true
	max_hp = 30
	touch_damage = 18
	size = Vector2(42, 40)
	anchor = position
	position = anchor + Vector2(0, REST)
	super._ready()
	set_state("HANG")


func _find_floor() -> void:
	# Dangle with the body at the pig's head height above whatever floor lies below. Measured on
	# the first physics frame, once the level's colliders are in the physics space.
	var ray := PhysicsRayQueryParameters2D.create(anchor + Vector2(0, 6), anchor + Vector2(0, 1200), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(ray)
	drop_y = (hit.position.y if hit else anchor.y + 600.0) - 54.0


func steer(delta: float) -> void:
	if drop_y < 0:
		_find_floor()
	cooldown = maxf(0, cooldown - delta)
	var x := anchor.x
	match state:
		"TREMBLE":
			x += sin(clock * 60.0) * 1.5
			velocity.y = 0
			if state_time >= TREMBLE_TIME:
				set_state("DROP")
				cue("drop")
		"DROP":
			velocity.y = minf(velocity.y + 2600 * delta, 1100)
			if position.y + velocity.y * delta >= drop_y:
				velocity.y = (drop_y - position.y) / delta
				set_state("DANGLE")
				sway = 1.0
		"DANGLE":
			velocity.y = (drop_y + sin(state_time * 5.0) * 3.0 - position.y) / delta
			sway = move_toward(sway, 0.35, delta)
			x += sin(state_time * 3.2) * 7.0 * sway
			if state_time >= DANGLE_TIME:
				set_state("CLIMB")
		"CLIMB":
			velocity.y = -150
			if position.y + velocity.y * delta <= anchor.y + REST:
				velocity.y = (anchor.y + REST - position.y) / delta
				set_state("HANG")
				cooldown = 1.2
		_:
			velocity.y = (anchor.y + REST + sin(clock * 2.0) * 3.0 - position.y) / delta * 0.2
			if cooldown <= 0 and target.alive() and absf(target.position.x - anchor.x) < 90 and target.position.y > drop_y:
				set_state("TREMBLE")
	velocity.x = (x - position.x) / delta * 0.5


func take_hit(amount: int, impulse: float) -> void:
	super.take_hit(amount, impulse * 0.6)
	sway = 1.0


func draw_body(alpha: float) -> void:
	var color := tone(alpha)
	var top := anchor - position
	var silk := Color(0.94, 0.92, 0.84, 0.55 * alpha)
	draw_line(top, Vector2(0, -12), silk, 1.4, true)
	if state == "TREMBLE":
		for k in 3:
			var fall := fmod(state_time * 2.2 + k * 0.33, 1.0)
			draw_circle(top + Vector2(-10 + k * 10, 6 + fall * 50), 1.8, Color(0.75, 0.68, 0.55, 0.8 * (1 - fall)), true, -1, true)
	var leg_color := Color(Color("2a1a13"), alpha)
	var joint := Color(Color("5a3a2a"), alpha)
	var tuck := 1.0 if state == "DROP" else 0.0
	for side in [-1.0, 1.0]:
		for i in 4:
			var phase := clock * (9.0 if state == "DANGLE" else 3.0) + i * 1.3 + (0.0 if side < 0 else 0.7)
			var wiggle := sin(phase) * (3.0 if state == "DANGLE" else 1.2)
			var root := Vector2(side * 9.0, -2.0 + i * 3.5)
			var knee := root + Vector2(side * (12.0 + i * 1.5 - tuck * 4.0), -9.0 + i * 3.5 - tuck * 6.0 + wiggle)
			var foot := knee + Vector2(side * (5.0 + i * 1.5 - tuck * 3.0), 11.0 + i * 2.0 - tuck * 10.0 - wiggle * 0.5)
			draw_polyline(PackedVector2Array([root, knee, foot]), leg_color, 3.0, true)
			draw_circle(knee, 1.7, joint, true, -1, true)
	var stretch := Vector2(1.0 + sin(clock * 3.0) * 0.02, 1.0 - sin(clock * 3.0) * 0.02)
	if state == "DROP":
		stretch = Vector2(0.92, 1.1)
	var angle := (position.x - anchor.x) * 0.02
	part(BODY, CENTER, Vector2.ZERO, stretch, angle, color)
	draw_set_transform(Vector2.ZERO)
