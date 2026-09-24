extends "res://scenes/action_test/enemies/base_enemy.gd"
## 栗刺球 · burr hog (chestnut hedgehog). Trundles along its patrol. When the pig comes level with
## it, it stops, bristles and shows a "!" (telegraph), curls into a spiked ball and rolls at her
## until it meets a wall or a ledge — then sits dizzy with its spines laid flat. Only while dizzy
## can it be stomped, and it takes extra damage. A hit on the rolling ball knocks it off course and
## dizzies it too. Otherwise: roll through it (Shift) or jump over.
const BODY = preload("res://assets/chapter2/monsters/burr_body.png")
const BALL = preload("res://assets/chapter2/monsters/burr_ball.png")
const BODY_ANCHOR := Vector2(100, 158)
const BALL_CENTER := Vector2(85, 85)
const ROLL_SPEED := 430.0
@export var patrol_width := 200.0
var cooldown := 0.6
var roll_angle := 0.0
var step_phase := 0.0
var turn := -1.0


func _ready() -> void:
	max_hp = 72
	stompable = false
	touch_damage = 20
	size = Vector2(60, 48)
	tint = Color("b2976b")
	super._ready()
	turn = facing


func set_state(value: String) -> void:
	super.set_state(value)
	stompable = value == "DIZZY"
	touch_damage = 26 if value == "ROLL" else 20


func steer(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	var gap: Vector2 = target.position - position
	match state:
		"NOTICE":
			velocity.x = move_toward(velocity.x, 0, 1400 * delta)
			if state_time >= 0.5:
				set_state("ROLL")
				cue("roll")
		"ROLL":
			velocity.x = facing * ROLL_SPEED
			roll_angle += facing * ROLL_SPEED * delta / 26.0
			if is_on_wall() or not ground_ahead(facing, 30, 60) or state_time > 1.8:
				_dizzy(-facing * 90)
				room.burst("land", position + Vector2(facing * 24, 0), 1.0)
				room.camera.add_trauma(0.12)
		"DIZZY":
			velocity.x = move_toward(velocity.x, 0, 500 * delta)
			if state_time >= 1.2:
				set_state("PATROL")
				cooldown = 1.0
		_:
			if position.x < home.x - patrol_width:
				facing = 1
			elif position.x > home.x + patrol_width:
				facing = -1
			if is_on_wall() or not ground_ahead(facing, 40):
				facing *= -1
			velocity.x = move_toward(velocity.x, facing * 62, 500 * delta)
			if cooldown <= 0 and target.alive() and absf(gap.y) < 70 and absf(gap.x) < 300:
				facing = signf(gap.x) if gap.x != 0 else facing
				velocity.x = 0
				set_state("NOTICE")
				cue("alert")


func after_move(delta: float) -> void:
	step_phase += absf(velocity.x) * delta
	turn = move_toward(turn, facing, delta * 9.0)


func _dizzy(push: float) -> void:
	set_state("DIZZY")
	velocity.x = push


func take_hit(amount: int, impulse: float) -> void:
	if hp <= 0:
		return
	var rolling := state == "ROLL"
	var bonus := 1.5 if state == "DIZZY" else 1.0
	super.take_hit(int(round(amount * bonus)), impulse)
	if rolling and hp > 0:
		_dizzy(impulse * 1.2)


func draw_body(alpha: float) -> void:
	var dying := hp <= 0
	var color := tone(alpha)
	if state == "ROLL" and not dying:
		shadow(28, Vector2.ZERO, 0.3 * alpha)
		for k in 3:
			var y := -34.0 + k * 11
			draw_line(Vector2(-facing * (30 + k * 6), y), Vector2(-facing * (54 + k * 10), y), Color(0.95, 0.9, 0.75, 0.35), 2.0, true)
		part(BALL, BALL_CENTER, Vector2(0, -24), Vector2.ONE, roll_angle, color)
		return
	var bob := -absf(sin(step_phase / 9.0)) * 1.8
	var tilt := 0.0
	var stretch := Vector2(turn, 1)
	var shake := 0.0
	match state:
		"NOTICE":
			shake = sin(clock * 70.0) * 1.3
			stretch.y = 1.0 + 0.07 * minf(1.0, state_time * 4.0)
		"DIZZY":
			stretch = Vector2(turn * 1.05, 0.93)
			tilt = sin(clock * 6.0) * 0.08
	if dying:
		stretch.y *= 1.0 - minf(0.4, death_time)
	shadow(30, Vector2.ZERO, 0.3 * alpha)
	# Little feet, stepping in turn while it walks.
	var feet := Color(Color("3b2418"), alpha)
	for foot in [-18.0, 16.0]:
		var lift := maxf(0.0, sin(step_phase / 9.0 + (0.0 if foot < 0 else PI))) * 3.0
		draw_set_transform(Vector2(foot * turn + shake, -2 - lift), 0, Vector2(1, 0.6))
		draw_circle(Vector2.ZERO, 6, feet, true, -1, true)
	part(BODY, BODY_ANCHOR, Vector2(shake, bob), stretch, tilt, color)
	draw_set_transform(Vector2.ZERO)
	if dying:
		return
	if state == "NOTICE":
		var pop := minf(1.0, state_time * 8.0)
		var at := Vector2(turn * 14, -76 - 6 * pop)
		draw_circle(at, 11 * pop, Color("fff1c2"), true, -1, true)
		draw_arc(at, 11 * pop, 0, TAU, 20, Color("5a3a1e"), 2.0, true)
		draw_line(at + Vector2(0, -6) * pop, at + Vector2(0, 2) * pop, Color("c0392b"), 3.0 * pop, true)
		draw_circle(at + Vector2(0, 5.5) * pop, 1.8 * pop, Color("c0392b"), true, -1, true)
	elif state == "DIZZY":
		for k in 3:
			var a := clock * 5.0 + k * TAU / 3.0
			var star := Vector2(cos(a) * 20, -62 + sin(a) * 6)
			_star(star, 5.0, Color(1, 0.9, 0.45, 0.95))


func _star(at: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 8:
		var r := radius if i % 2 == 0 else radius * 0.4
		var a := i * PI / 4.0 + clock * 3.0
		points.append(at + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, color)
