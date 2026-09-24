extends Node2D
## Pig drawn from the approved 小呆猪 side-view frames (assets/chapter2/pig_unified), shaded and
## finely outlined, at about two thirds of the earlier code-drawn height. Only this node deforms;
## the collider never changes. Motion stays procedural on top of the four walk frames:
## distance-driven frame cycle, small bob, lean, a quick squash turn instead of an instant flip,
## a damped landing spring, take-off stretch and a spinning roll.
const FRAMES := [
	preload("res://assets/chapter2/pig_unified/frames/cape_right_00.png"),
	preload("res://assets/chapter2/pig_unified/frames/cape_right_01.png"),
	preload("res://assets/chapter2/pig_unified/frames/cape_right_02.png"),
	preload("res://assets/chapter2/pig_unified/frames/cape_right_03.png")]
## Foot anchor of every frame (see pig_unified/README.md) and the front hoof that holds weapons.
const PIVOT := Vector2(160, 300)
const HOOF := Vector2(203, 238)
## Visible height is 207 px of the 320 px frame; 0.42 gives ~87 world units (was ~127).
const SCALE := 0.42
## World distance covered by one frame of the walk cycle.
const STEP := 17.0
var facing := 1.0
var stride := 0.0
var landing := 0.0
var turn := 1.0
var run_blend := 0.0
var air_blend := 0.0
var fall_blend := 0.0
var lean := 0.0
var squash := 0.0
var squash_velocity := 0.0
var clock := 0.0
var previous_vy := 0.0
var previous_landing := 0.0
## Ready angle of a held weapon: forward and slightly up, clear of the face.
const READY := -0.3
var weapon_angle := READY
var hand := Vector2(18, -26)
var upper := Transform2D.IDENTITY


func _ready() -> void:
	texture_filter = CharacterSpriteStyle.FILTER


func reset_pose() -> void:
	var body = get_parent()
	facing = body.facing
	turn = facing
	run_blend = 0
	air_blend = 0
	fall_blend = 0
	lean = 0
	squash = 0
	squash_velocity = 0
	scale = Vector2.ONE


func update_pose(delta: float) -> void:
	var body = get_parent()
	clock += delta
	facing = body.facing
	stride = body.stride
	var grounded: bool = body.is_on_floor()
	var speed := clampf(absf(body.velocity.x) / 330.0, 0, 1.2)
	turn = move_toward(turn, facing, delta * 13.0)
	run_blend = lerpf(run_blend, speed if grounded else 0.0, 1 - exp(-14 * delta))
	air_blend = lerpf(air_blend, 0.0 if grounded else 1.0, 1 - exp(-(22 if grounded else 12) * delta))
	fall_blend = lerpf(fall_blend, clampf(body.velocity.y / 500.0, 0, 1), 1 - exp(-10 * delta))
	var forward: float = body.velocity.x * facing / 330.0
	lean = lerpf(lean, clampf(forward, -0.6, 1.0) * (0.07 if grounded else 0.04), 1 - exp(-10 * delta))
	# Landing and take-off feed a damped spring rather than snapping the scale.
	if body.landing > previous_landing + 0.05:
		squash_velocity += 3.0 * body.landing
	if previous_vy >= -60 and body.velocity.y < -300:
		squash_velocity -= 2.4
	previous_landing = body.landing
	previous_vy = body.velocity.y
	squash_velocity += (-420.0 * squash - 20.0 * squash_velocity) * delta
	squash += squash_velocity * delta
	squash = clampf(squash, -0.25, 0.28)
	var stretch := -0.04 * air_blend * (1.0 - fall_blend) - 0.06 * fall_blend * air_blend
	var breathe := sin(clock * 2.3) * 0.015 * (1.0 - run_blend) * (1.0 - air_blend)
	var amount := squash + stretch
	scale = Vector2(1 + amount, 1 - amount + breathe)
	_weapon_pose(body, delta)
	modulate.a = 0.5 if body.health and body.health.invulnerable > 0 and sin(body.health.invulnerable * 35) > 0 else 1.0
	queue_redraw()


func _weapon_pose(body, delta: float) -> void:
	var combat = body.combat
	var goal := READY + sin(stride * 30.0 / STEP * PI * 0.5) * 0.08 * run_blend - 0.3 * air_blend
	if combat and combat.weapon and combat.state != "IDLE":
		var w = combat.weapon
		match combat.state:
			"WINDUP":
				var t: float = 1.0 - combat.timer / maxf(0.001, w.windup)
				weapon_angle = lerpf(READY, -2.15, ease(clampf(t, 0, 1), 0.5))
			"ACTIVE":
				var t: float = 1.0 - combat.timer / maxf(0.001, w.active_time)
				weapon_angle = lerpf(-2.15, 0.95, ease(clampf(t, 0, 1), 0.4))
			"RECOVERY":
				var t: float = 1.0 - combat.timer / maxf(0.001, w.recovery)
				weapon_angle = lerpf(0.95, READY, smoothstep(0.0, 1.0, clampf(t, 0, 1)))
	else:
		weapon_angle = lerpf(weapon_angle, goal, 1 - exp(-16 * delta))


func _frame(body, grounded: bool) -> int:
	if not grounded and air_blend > 0.5:
		return 2 if body.velocity.y < 0 else 0
	if run_blend < 0.12:
		return 0
	return int(fposmod(stride * 30.0 / STEP, 4.0))


func _draw() -> void:
	var body = get_parent()
	var grounded: bool = body.is_on_floor()
	var distance := stride * 30.0
	var bob := -absf(sin(distance / STEP * PI * 0.5)) * 1.6 * run_blend
	var hip := Vector2(0, -34)
	var base := Transform2D(0, Vector2(0, bob))
	upper = base * Transform2D(0, hip) * Transform2D(lean, Vector2.ZERO) * Transform2D(0, -hip)
	if grounded:
		draw_set_transform(Vector2(2, 1), 0, Vector2(1, 0.24))
		draw_circle(Vector2.ZERO, 24 - run_blend * 2, Color(0.02, 0.05, 0.03, 0.32), true, -1, true)
	var sprite := Transform2D(0, Vector2(turn * SCALE, SCALE), 0, Vector2.ZERO) * Transform2D(0, -PIVOT)
	if body.roll_time > 0:
		var t: float = 1.0 - body.roll_time / 0.24
		var center := Vector2(0, -36)
		var spin := base * Transform2D(0, center) * Transform2D(t * TAU * signf(turn if turn != 0 else 1.0), Vector2.ONE * 0.9, 0, Vector2.ZERO) * Transform2D(0, -center)
		draw_set_transform_matrix(spin * sprite)
		draw_texture(FRAMES[2], Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
		return
	var frame: Transform2D = upper * sprite
	draw_set_transform_matrix(frame)
	draw_texture(FRAMES[_frame(body, grounded)], Vector2.ZERO)
	draw_set_transform(Vector2.ZERO)
	hand = frame * HOOF
