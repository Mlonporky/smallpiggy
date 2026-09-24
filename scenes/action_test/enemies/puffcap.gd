extends "res://scenes/action_test/enemies/base_enemy.gd"
## 噗噗菇 · puffcap. Rooted to its spot. When the pig comes within range its cap swells and the
## violet spots glow (telegraph), then it puffs three spore balls in lobbed arcs around where she
## stands. Spores sting, but any weapon swing pops them in the air. Stomping the cap springs the
## pig up like a bounce mushroom (and hurts the puffcap).
const STEM = preload("res://assets/chapter2/monsters/puff_stem.png")
const CAP = preload("res://assets/chapter2/monsters/puff_cap.png")
const SPORE = preload("res://assets/chapter2/monsters/spore.png")
const STEM_ANCHOR := Vector2(60, 104)
const CAP_ANCHOR := Vector2(90, 100)
## Where the cap sits on the stem, in stem pixels.
const CAP_SEAT := Vector2(60, 36)
const SPORE_CENTER := Vector2(21, 21)
const SPORE_GRAVITY := 520.0
const SWELL_TIME := 0.6
const SPORE_DAMAGE := 12
@export var reach := 380.0
var spores: Array[Dictionary] = []
var cooldown := 0.8
var swell := 0.0
var sprung := 0.0
var puffed := 0.0


func _ready() -> void:
	max_hp = 40
	touch_damage = 14
	size = Vector2(56, 62)
	super._ready()


func steer(delta: float) -> void:
	velocity.x = 0
	cooldown = maxf(0, cooldown - delta)
	var gap: Vector2 = target.position - position
	if gap.x != 0:
		facing = signf(gap.x)
	if state == "SWELL":
		swell = minf(1.0, state_time / SWELL_TIME)
		if state_time >= SWELL_TIME:
			_puff()
			set_state("IDLE")
			cooldown = 2.2
	elif cooldown <= 0 and target.alive() and absf(gap.x) < reach and absf(gap.y) < 260:
		set_state("SWELL")


func _puff() -> void:
	var mouth := position + Vector2(0, -58)
	var aim: Vector2 = target.body_box().get_center()
	var flight := 1.05
	for spread in [-0.35, 0.0, 0.35]:
		var goal := aim + Vector2((aim.x - mouth.x) * spread, 0)
		var launch := Vector2((goal.x - mouth.x) / flight, (goal.y - mouth.y - 0.5 * SPORE_GRAVITY * flight * flight) / flight)
		spores.append({"pos": mouth, "vel": launch, "age": 0.0, "spin": randf() * TAU})
	puffed = 0.35
	room.burst("spore", mouth, 0.9)
	cue("puff")


func after_move(delta: float) -> void:
	if state != "SWELL":
		swell = move_toward(swell, 0.0, delta * 5.0)
	sprung = move_toward(sprung, 0.0, delta * 3.5)
	puffed = maxf(0, puffed - delta)
	var cut := swing_rect()
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.collision_mask = 1
	for i in range(spores.size() - 1, -1, -1):
		var spore: Dictionary = spores[i]
		spore.age += delta
		spore.vel.y += SPORE_GRAVITY * delta
		spore.vel.x *= 1.0 - 0.2 * delta
		spore.pos += spore.vel * delta
		spore.spin += delta * 3.0
		query.position = spore.pos
		var popped: bool = spore.age > 3.0 or not space.intersect_point(query, 1).is_empty()
		if not popped and cut.has_area() and cut.grow(6).has_point(spore.pos):
			popped = true
			room.burst("hit", spore.pos, 0.5)
		if not popped and target.alive() and target.body_box().grow(7).has_point(spore.pos):
			target.health.take_damage(SPORE_DAMAGE, signf(spore.vel.x) if spore.vel.x != 0 else 1.0)
			popped = true
		if popped:
			room.burst("spore", spore.pos, 0.6)
			spores.remove_at(i)


func stomped() -> void:
	stomp_grace = 0.25
	take_hit(32, 0)
	target.launch(880)
	sprung = 1.0
	swell = 0
	set_state("IDLE")
	cooldown = maxf(cooldown, 1.2)
	room.hit_feedback(position + Vector2(0, -60), 0.04)
	cue("bounce")


func die() -> void:
	super.die()
	for spore in spores:
		room.burst("spore", spore.pos, 0.6)
	spores.clear()


func draw_body(alpha: float) -> void:
	var color := tone(alpha)
	var glow := swell
	var shake := sin(clock * 55.0) * 1.2 * maxf(0, swell - 0.5) * 2.0
	var dying := hp <= 0
	var wobble := sin(clock * 2.2) * 0.02
	var stem_stretch := Vector2(1 + swell * 0.05 + sprung * 0.12, 1 - swell * 0.03 - sprung * 0.18)
	if dying:
		stem_stretch.y *= 1.0 - minf(0.45, death_time * 1.2)
	shadow(28, Vector2.ZERO, 0.3 * alpha)
	var stem := Transform2D(0, stem_stretch * art, 0, Vector2(shake, 0)) * Transform2D(0, -STEM_ANCHOR)
	part(STEM, STEM_ANCHOR, Vector2(shake, 0), stem_stretch, 0, color)
	draw_set_transform(Vector2.ZERO)
	var ink := Color(0.14, 0.11, 0.16, alpha)
	var mouth: Vector2 = stem * Vector2(60 + facing * 2, 80)
	if puffed > 0:
		draw_circle(mouth, 3.4, ink, true, -1, true)
	elif state == "SWELL":
		draw_circle(mouth, 1.8, ink, true, -1, true)
	else:
		draw_line(mouth + Vector2(-3, 0), mouth + Vector2(3, 0.6), ink, 1.6, true)
	var seat: Vector2 = stem * CAP_SEAT
	var cap_stretch := Vector2(1 + swell * 0.2 + sprung * 0.25 + wobble, 1 + swell * 0.14 - sprung * 0.35 - wobble)
	if glow > 0:
		draw_circle(seat + Vector2(0, -18), 44 + 10 * glow, Color(0.72, 0.45, 1.0, 0.16 * glow), true, -1, true)
	var cap_color := Color(color.r * (1 + glow * 0.35), color.g, color.b * (1 + glow * 0.5), alpha)
	part(CAP, CAP_ANCHOR, seat, cap_stretch, sin(clock * 1.7) * 0.03, cap_color)
	draw_set_transform(Vector2.ZERO)
	for spore in spores:
		var pulse := 1.6 + sin(spore.age * 14.0) * 0.12
		part(SPORE, SPORE_CENTER, spore.pos - position, Vector2.ONE * pulse, spore.spin, Color.WHITE)
	draw_set_transform(Vector2.ZERO)
