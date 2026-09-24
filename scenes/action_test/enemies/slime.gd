extends "res://scenes/action_test/enemies/base_enemy.gd"
## 苔团史莱姆 · moss slime. Wobbles and now and then hops about its spot; once the pig is near it
## hops toward her: a readable crouch before every hop, a stretch in the air, a squash on landing
## and a short rest. Eyes follow the pig and blink. Stompable.
## Variants: "big" (大苔团) is slower and heavier and splits into two quick "small" ones on defeat.
const BODY = preload("res://assets/chapter2/monsters/slime_body.png")
const EYE = preload("res://assets/chapter2/monsters/slime_eye.png")
const ANCHOR := Vector2(85, 142)
const EYE_ANCHOR := Vector2(13, 16)
const EYES := [Vector2(66, 86), Vector2(104, 86)]
const CROUCH_TIME := 0.32
@export var variant := "normal"
var grow := 1.0
var hop_speed := 150.0
var hop_height := 380.0
var rest := 0.6
var squash := 0.0
var squash_velocity := 0.0
var look := Vector2.ZERO
var blink := 2.0
var reach := 320.0


func _ready() -> void:
	match variant:
		"big":
			grow = 1.45
			max_hp = 80
			touch_damage = 24
			hop_speed = 125
			hop_height = 430
			rest = 0.85
			reach = 360
		"small":
			grow = 0.66
			max_hp = 18
			touch_damage = 12
			hop_speed = 190
			hop_height = 330
			rest = 0.3
	size = Vector2(60, 50) * grow
	super._ready()
	blink = randf_range(1.2, 3.5)


func steer(delta: float) -> void:
	var gap: Vector2 = target.position - position
	var aware: bool = target.alive() and absf(gap.x) < reach and absf(gap.y) < 110 * grow
	var grounded := is_on_floor()
	match state:
		"AIR":
			if is_on_wall():
				velocity.x = 0
			if grounded and state_time > 0.05:
				set_state("REST")
				velocity.x = 0
				squash_velocity += 5.0
				room.burst("land", position, 0.45 * grow)
		"CROUCH":
			velocity.x = move_toward(velocity.x, 0, 900 * delta)
			if state_time >= CROUCH_TIME:
				var wander := not aware
				var speed := hop_speed * (0.45 if wander else 1.0)
				# Never hop off a ledge: hop on the spot instead.
				velocity.x = facing * speed if ground_ahead(facing, speed * 0.55 + size.x * 0.3, 70) else 0.0
				velocity.y = -hop_height * (0.6 if wander else 1.0)
				set_state("AIR")
				squash_velocity -= 4.0
		_:
			velocity.x = move_toward(velocity.x, 0, 900 * delta)
			if aware and gap.x != 0:
				facing = signf(gap.x)
			if grounded and state_time >= (rest if aware else 2.4):
				if not aware:
					facing = signf(home.x - position.x) if absf(home.x - position.x) > 30 else -facing
				set_state("CROUCH")


func after_move(delta: float) -> void:
	# Squash spring: crouch before a hop, stretch rising, settle on the ground.
	var goal := 0.0
	match state:
		"CROUCH":
			goal = 0.24 * minf(1.0, state_time / (CROUCH_TIME * 0.6))
		"AIR":
			goal = -0.16 if velocity.y < 0 else -0.05
	squash_velocity += (-240.0 * (squash - goal) - 13.0 * squash_velocity) * delta
	squash = clampf(squash + squash_velocity * delta, -0.3, 0.35)
	var toward: Vector2 = (target.position + Vector2(0, -40) - (position + Vector2(0, -26 * grow))).limit_length(60) / 60.0
	look = look.lerp(toward * Vector2(4.5, 3.0), 1 - exp(-8 * delta))
	blink -= delta
	if blink < -0.13:
		blink = randf_range(1.6, 4.0)


func die() -> void:
	super.die()
	if variant == "big" and room.has_method("spawn_enemy"):
		# The big one splits: two little slimes pop out to either side.
		for side in [-1.0, 1.0]:
			room.call_deferred("spawn_enemy", "slime_small", position + Vector2(side * 16, -8), {"velocity": Vector2(side * 170, -380), "state": "AIR", "facing": side})


func draw_body(alpha: float) -> void:
	var s := squash
	if hp <= 0:
		s = minf(0.55, death_time * 1.6)
	var stretch := Vector2(1 + s, 1 - s) * grow
	var lift := 1.0 - clampf(-velocity.y / 400.0, 0, 1) * 0.4 if state == "AIR" else 1.0
	shadow(26 * grow * (1 + s * 0.6) * lift, Vector2.ZERO, 0.3 * alpha)
	var body := Transform2D(0, stretch * art, 0, Vector2.ZERO) * Transform2D(0, -ANCHOR)
	part(BODY, ANCHOR, Vector2.ZERO, stretch, 0, tone(alpha))
	var lid := 1.0
	if blink < 0 or flash > 0:
		lid = 0.2
	var ink := Color(0.09, 0.2, 0.15, alpha)
	if hp <= 0:
		# Purified: eyes close in relief.
		for e in EYES:
			var at: Vector2 = body * e
			draw_set_transform(Vector2.ZERO)
			draw_arc(at + Vector2(0, 1.5 * grow), 3.4 * grow, PI * 1.1, PI * 1.9, 8, ink, 1.6 * grow, true)
	else:
		for e in EYES:
			part(EYE, EYE_ANCHOR, body * (e + look), Vector2(stretch.x, stretch.y * lid), 0, tone(alpha))
	draw_set_transform(Vector2.ZERO)
	var mouth: Vector2 = body * (Vector2(85, 101) + look * 0.6)
	if state == "CROUCH" or (state == "AIR" and velocity.y < 0):
		draw_circle(mouth + Vector2(0, 1), 2.6 * grow, ink, true, -1, true)
	else:
		draw_arc(mouth, 3.2 * grow, PI * 0.15, PI * 0.85, 8, ink, 1.5 * grow, true)
