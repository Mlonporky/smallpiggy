extends "res://scenes/action_test/enemies/base_enemy.gd"
## 灰翅夜蛾 · shade moth. Drifts in a lazy figure-eight around its roost. When the pig is below and
## within reach it stops with wings spread and eye-spots glowing (telegraph; it keeps tracking her
## for the first part), then swoops through where she stood along a curve and climbs back out on the
## far side. A hit breaks off the swoop. Stompable in mid-air: a well-timed bounce off its back
## carries the pig higher than a jump.
const BODY = preload("res://assets/chapter2/monsters/moth_body.png")
const WING = preload("res://assets/chapter2/monsters/moth_wing.png")
const BODY_CENTER := Vector2(50, 64)
const WING_PIVOT := Vector2(124, 72)
## Shoulders on the body texture where the left / right wing roots sit.
const SHOULDER := Vector2(44, 62)
const LOCK_TIME := 0.6
const TRACK_TIME := 0.35
const SWOOP_SPEED := 480.0
## How far from its roost a swoop may carry it sideways (keeps it clear of nearby walls).
@export var roam := 220.0
var cooldown := 1.0
var aim := Vector2.ZERO
var swoop_from := Vector2.ZERO
var swoop_via := Vector2.ZERO
var swoop_to := Vector2.ZERO
var swoop_time := 1.0
var trail: Array[Vector2] = []


func _ready() -> void:
	flying = true
	centred = true
	art = 0.36
	max_hp = 36
	touch_damage = 16
	size = Vector2(46, 38)
	super._ready()
	set_state("HOVER")


func _in_reach() -> bool:
	var gap: Vector2 = target.position - position
	return target.alive() and absf(gap.x) < 300 and gap.y > 40 and gap.y < 420


func steer(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	match state:
		"LOCK":
			velocity = velocity.move_toward(Vector2.ZERO, 700 * delta)
			if state_time < TRACK_TIME:
				aim = target.position + Vector2(0, -40)
			if state_time >= LOCK_TIME:
				_begin_swoop()
		"SWOOP":
			var t := minf(1.0, (state_time + delta) / swoop_time)
			velocity = (_curve(t) - position) / delta
			if t >= 1.0:
				set_state("RECOVER")
				cooldown = 1.4
		_:
			var goal := home + Vector2(sin(clock * 0.9) * 70, sin(clock * 1.8) * 18)
			var drift := ((goal - position) * 2.2).limit_length(240 if state == "RECOVER" else 160)
			velocity = velocity.lerp(drift, 1 - exp(-3.0 * delta))
			if state == "RECOVER" and (position.distance_to(goal) < 40 or state_time > 2.5):
				set_state("HOVER")
			elif state == "HOVER" and cooldown <= 0 and _in_reach():
				set_state("LOCK")
				aim = target.position + Vector2(0, -40)
				cue("alert")
	if velocity.x != 0 and state != "LOCK":
		facing = signf(velocity.x)


func _begin_swoop() -> void:
	# Symmetric curve whose lowest point is exactly the aim (never below the pig's middle).
	swoop_from = position
	swoop_to = Vector2(clampf(aim.x + (aim.x - position.x), home.x - roam, home.x + roam), position.y)
	swoop_via = aim * 2.0 - (swoop_from + swoop_to) * 0.5
	var length := swoop_from.distance_to(aim) + aim.distance_to(swoop_to)
	swoop_time = clampf(length / SWOOP_SPEED, 0.6, 1.3)
	set_state("SWOOP")
	cue("swoop")


func _curve(t: float) -> Vector2:
	return swoop_from.lerp(swoop_via, t).lerp(swoop_via.lerp(swoop_to, t), t)


func after_move(_delta: float) -> void:
	if state == "SWOOP":
		trail.push_front(position)
	elif not trail.is_empty():
		trail.pop_back()
	if trail.size() > 8:
		trail.pop_back()


func take_hit(amount: int, impulse: float) -> void:
	if hp <= 0:
		return
	super.take_hit(amount, impulse)
	velocity.y = -140
	if state == "SWOOP" or state == "LOCK":
		set_state("RECOVER")
		cooldown = 1.6


func draw_body(alpha: float) -> void:
	var color := tone(alpha)
	for k in trail.size():
		var fade := 1.0 - float(k) / trail.size()
		draw_circle(trail[k] - position, 5.0 * fade, Color(0.8, 0.7, 1.0, 0.25 * fade * alpha), true, -1, true)
	var open := 0.62 + 0.38 * sin(clock * 13.0)
	var lean := clampf(velocity.x / 700.0, -0.3, 0.3)
	match state:
		"LOCK":
			open = 1.0 + sin(clock * 40.0) * 0.03
			var pulse := 0.5 + 0.5 * sin(state_time * 18.0)
			draw_circle(Vector2.ZERO, 40, Color(0.72, 0.45, 1.0, (0.12 + 0.12 * pulse) * alpha), true, -1, true)
		"SWOOP":
			open = 0.3 + 0.08 * sin(clock * 30.0)
			lean = clampf(velocity.x / 900.0, -0.45, 0.45)
		"RECOVER":
			open = 0.55 + 0.45 * sin(clock * 19.0)
	if hp <= 0:
		open = 0.35
	var bob := sin(clock * 13.0 + 0.8) * 2.0 if state == "HOVER" else 0.0
	var body := Transform2D(lean, Vector2.ONE * art, 0, Vector2(0, bob)) * Transform2D(0, -BODY_CENTER)
	# The painted wing is the left one; the right is mirrored. Closing wings also lift their tips.
	for side in [-1.0, 1.0]:
		var root: Vector2 = body * Vector2(50 + side * (50 - SHOULDER.x), SHOULDER.y)
		part(WING, WING_PIVOT, root, Vector2(-side * open, 1.0), lean - side * (1.0 - open) * 0.3, color)
	part(BODY, BODY_CENTER, Vector2(0, bob), Vector2.ONE, lean, color)
	draw_set_transform(Vector2.ZERO)
