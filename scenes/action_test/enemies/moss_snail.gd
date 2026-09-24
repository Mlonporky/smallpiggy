extends "res://scenes/action_test/enemies/base_enemy.gd"
## 苔壳蜗牛 · moss snail. Slow and stubborn. Its stone shell faces forward, so the sword and the
## dagger glance off its front with a clang and push the pig back, and a stomp only bounces off the
## shell. Jump over and strike its soft back (it takes a moment to turn round), or bring the hammer:
## one hammer blow cracks the shell away, after which it panics and hurries about.
const BODY = preload("res://assets/chapter2/monsters/snail_body.png")
const SHELL = preload("res://assets/chapter2/monsters/snail_shell.png")
const BODY_ANCHOR := Vector2(82, 86)
const SHELL_CENTER := Vector2(65, 70)
## Shell centre over the body's back, in body pixels (the body faces right).
const SHELL_SEAT := Vector2(74, 34)
const TURN_DELAY := 1.4
@export var patrol_width := 120.0
var shell := true
var tucked := 0.0
var crawl := 0.0
var turn := -1.0
var behind := 0.0
var sweat := 0.0


func _ready() -> void:
	max_hp = 60
	touch_damage = 16
	art = 0.5
	size = Vector2(72, 54)
	super._ready()
	turn = facing


func harmful() -> bool:
	return tucked <= 0


func steer(delta: float) -> void:
	tucked = maxf(0, tucked - delta)
	var gap: Vector2 = target.position - position
	# It notices a pig behind it, slowly: after TURN_DELAY it turns to face her.
	if target.alive() and absf(gap.y) < 80 and absf(gap.x) < 220 and signf(gap.x) == -facing:
		behind += delta
		if behind >= TURN_DELAY:
			facing *= -1
			behind = 0
	else:
		behind = 0
	if position.x < home.x - patrol_width:
		facing = 1
	elif position.x > home.x + patrol_width:
		facing = -1
	if is_on_wall() or not ground_ahead(facing, 40):
		facing *= -1
	var speed := 0.0 if tucked > 0 else (32.0 if shell else 96.0)
	velocity.x = move_toward(velocity.x, facing * speed, 400 * delta)


func after_move(delta: float) -> void:
	crawl += absf(velocity.x) * delta
	turn = move_toward(turn, facing, delta * 5.0)
	sweat += delta


func take_hit(amount: int, impulse: float) -> void:
	if hp <= 0:
		return
	var weapon = target.combat.weapon if target and target.combat else null
	if shell:
		if weapon and weapon.kind == "hammer":
			shell = false
			tucked = 0
			room.burst("shell", position + Vector2(0, -30), 1.4)
			cue("crack")
		elif tucked > 0 or impulse == 0 or signf(impulse) != facing:
			_clang(signf(impulse) if impulse != 0 else -facing)
			return
	super.take_hit(amount, impulse * (1.0 if shell else 1.4))


## A blade glances off the shell: no damage, the pig is pushed back and the snail tucks in.
func _clang(direction: float) -> void:
	tucked = 0.7
	flash = 0.06
	target.knockback = -direction * 260
	room.burst("clang", position + Vector2(-direction * 22, -30), 1.0)
	cue("clang")


func stomped() -> void:
	if not shell:
		super.stomped()
		return
	stomp_grace = 0.25
	tucked = 0.8
	target.bounce()
	room.burst("clang", position + Vector2(0, -52), 0.8)
	cue("clang")


func draw_body(alpha: float) -> void:
	var color := tone(alpha)
	var dying := hp <= 0
	var tuck := minf(1.0, tucked * 5.0)
	var pulse := sin(crawl * 0.16) * 0.05
	shadow(36, Vector2.ZERO, 0.3 * alpha)
	var body_stretch := Vector2(turn * (1.0 + pulse - tuck * 0.45), 1.0 - pulse * 0.5 - tuck * 0.3)
	if dying:
		body_stretch.y *= 1.0 - minf(0.5, death_time * 1.2)
	var body := Transform2D(0, body_stretch * art, 0, Vector2.ZERO) * Transform2D(0, -BODY_ANCHOR)
	part(BODY, BODY_ANCHOR, Vector2.ZERO, body_stretch, 0, color)
	draw_set_transform(Vector2.ZERO)
	if shell:
		var seat := Transform2D(0, Vector2(turn, 1) * art, 0, Vector2.ZERO) * Transform2D(0, -BODY_ANCHOR) * SHELL_SEAT
		seat += Vector2(0, tuck * 7.0 + sin(crawl * 0.16) * 0.9)
		part(SHELL, SHELL_CENTER, seat, Vector2(turn, 1), -turn * pulse * 0.4, color)
		draw_set_transform(Vector2.ZERO)
	elif not dying:
		# Shell-less and flustered: little sweat drops fly off its back.
		for k in 2:
			var t := fmod(sweat * 1.6 + k * 0.5, 1.0)
			var at: Vector2 = body * Vector2(120 + k * 14, 30) + Vector2(turn * t * 10, -t * 14 + t * t * 18)
			draw_circle(at, 2.4 * (1 - t) + 0.8, Color(0.75, 0.9, 1.0, 0.85 * (1 - t) * alpha), true, -1, true)
