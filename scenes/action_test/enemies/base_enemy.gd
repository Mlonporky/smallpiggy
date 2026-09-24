extends CharacterBody2D
## Shared enemy body for the action test rooms: health, hit flash, knockback, contact damage,
## stomping, and the purify effect on defeat — the wizard's curse leaves the creature as a violet
## wisp that rises and bursts into warm sparks. Subclasses override steer() for behaviour and
## draw_body() for looks; the base draws a plain blob so it can serve as a training dummy.
signal defeated(at: Vector2)
## Monster parts are painted at one texture pixel per 0.42 world units, like the pig frames.
const ART_SCALE := 0.42
const FLASH := Color(2.3, 2.2, 1.9)
const GRAVITY := 1500.0
const WISP_TIME := 0.8
const PURIFY_TIME := 1.4
@export var max_hp := 48
@export var stompable := true
@export var touch_damage := 20
var hp := 48
var target: CharacterBody2D
var room: Node2D
var facing := -1.0
var flash := 0.0
var death_time := 0.0
var stun := 0.0
var clock := 0.0
var home := Vector2.ZERO
var tint := Color("92ab6b")
## Contact box size. Walkers stand on `position` (their feet); `centred` monsters hover around it.
var size := Vector2(60, 50)
var centred := false
## Flying and hanging monsters ignore gravity and terrain.
var flying := false
var art := ART_SCALE
var state := "IDLE"
var state_time := 0.0
## Short window after a stomp in which the bounced pig cannot be hurt by the same contact.
var stomp_grace := 0.0


func _ready() -> void:
	hp = max_hp
	home = position
	collision_layer = 4
	collision_mask = 0 if flying else 1
	texture_filter = CharacterSpriteStyle.FILTER
	var collider := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = size.x * 0.4
	capsule.height = maxf(size.y, capsule.radius * 2)
	collider.shape = capsule
	collider.position = contact_box().get_center() - position
	add_child(collider)


func set_state(value: String) -> void:
	state = value
	state_time = 0


## World-space contact box (also where hits and stomps are judged).
func contact_box() -> Rect2:
	if centred:
		return Rect2(position - size * 0.5, size)
	return Rect2(position + Vector2(-size.x * 0.5, -size.y + 1), size)


func steer(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 20)


## Called every living frame after movement, even while stunned (projectiles, timers).
func after_move(_delta: float) -> void:
	pass


## Whether touching the monster hurts right now.
func harmful() -> bool:
	return true


func tick(delta: float) -> void:
	clock += delta
	flash = maxf(0, flash - delta)
	if hp <= 0:
		death_time += delta
		if not flying and death_time < 0.5:
			velocity.x = move_toward(velocity.x, 0, 900 * delta)
			position.x += velocity.x * delta * 0.15
		visible = death_time < PURIFY_TIME
		queue_redraw()
		return
	stun = maxf(0, stun - delta)
	stomp_grace = maxf(0, stomp_grace - delta)
	state_time += delta
	if flying:
		if stun > 0:
			velocity = velocity.move_toward(Vector2.ZERO, 900 * delta)
		else:
			steer(delta)
		position += velocity * delta
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, 900)
		if stun <= 0:
			steer(delta)
		else:
			velocity.x = move_toward(velocity.x, 0, 700 * delta)
		move_and_slide()
		if room and position.y > room.bounds.end.y + 200:
			# Fell out of the level: gone without a purify burst.
			hp = 0
			collision_layer = 0
			death_time = PURIFY_TIME
	after_move(delta)
	touch_player()
	queue_redraw()


func touch_player() -> void:
	if target == null or not target.alive() or hp <= 0 or stomp_grace > 0 or not harmful():
		return
	var box := contact_box()
	if not box.intersects(target.body_box()):
		return
	if target.velocity.y > 90 and target.previous_feet.y <= box.position.y + size.y * 0.22:
		stomped()
	else:
		hurt_player(touch_damage)


## The pig landed on top. Spiky monsters hurt and throw the pig back up instead.
func stomped() -> void:
	stomp_grace = 0.2
	if stompable:
		take_hit(32, signf(position.x - target.position.x) * 100)
		target.bounce()
		room.hit_feedback(Vector2(position.x, contact_box().position.y), 0.04)
	elif target.health.take_damage(touch_damage, away()):
		target.velocity.y = -420


func hurt_player(amount: int) -> bool:
	return target.health.take_damage(amount, away())


## Direction from the monster toward the pig (for knockback).
func away() -> float:
	return signf(target.position.x - position.x) if target.position.x != position.x else -1.0


func take_hit(amount: int, impulse: float) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	flash = 0.12
	stun = 0.2
	velocity.x = impulse
	if hp == 0:
		die()


func die() -> void:
	collision_layer = 0
	death_time = 0
	defeated.emit(position)
	cue("purify")


func cue(kind: String) -> void:
	if room and room.has_method("cue"):
		room.cue(kind)


## True if a solid surface lies under the point `ahead` units in front (checked `depth` down).
func ground_ahead(direction: float, ahead: float, depth := 48.0) -> bool:
	var probe := position + Vector2(direction * ahead, -8)
	var ray := PhysicsRayQueryParameters2D.create(probe, probe + Vector2(0, depth), 1)
	return not get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


## World rectangle of the pig's weapon while its swing is live (empty otherwise); lets
## projectiles be cut out of the air.
func swing_rect() -> Rect2:
	var combat = target.combat if target else null
	if combat == null or combat.weapon == null or combat.state != "ACTIVE":
		return Rect2()
	return Rect2(combat.hitbox.global_position - combat.shape.size * 0.5, combat.shape.size)


## Modulate for a part: white normally, bright while flashing from a hit.
func tone(alpha := 1.0) -> Color:
	var color := FLASH if flash > 0 else Color.WHITE
	color.a = alpha
	return color


## Draws a painted part: `anchor` (texture px) lands on `at` (local units).
func part(texture: Texture2D, anchor: Vector2, at: Vector2, stretch := Vector2.ONE, angle := 0.0, color := Color.WHITE) -> void:
	draw_set_transform_matrix(Transform2D(angle, stretch * art, 0, at) * Transform2D(0, -anchor))
	draw_texture(texture, Vector2.ZERO, color)


func shadow(radius: float, at := Vector2.ZERO, alpha := 0.3) -> void:
	draw_set_transform(at, 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, radius, Color(0.02, 0.05, 0.03, alpha), true, -1, true)
	draw_set_transform(Vector2.ZERO)


func _draw() -> void:
	if hp <= 0:
		var alpha := 1.0 - death_time / 0.4
		if alpha > 0:
			draw_body(alpha)
			draw_set_transform(Vector2.ZERO)
		draw_purify()
		return
	draw_body(1.0)
	draw_set_transform(Vector2.ZERO)
	if hp < max_hp:
		var top := contact_box().position.y - position.y - 16
		var width := clampf(size.x, 40, 70)
		var bar := Rect2(-width * 0.5, top, width, 5)
		draw_rect(bar.grow(1.5), Color(0.06, 0.1, 0.08, 0.8))
		draw_rect(Rect2(bar.position, Vector2(width * hp / max_hp, 5)), Color("e7c58a"))


func draw_body(alpha: float) -> void:
	var squash := sin(clock * 4) * 0.04 + flash * 0.8
	if hp <= 0:
		squash = minf(0.8, death_time * 2)
	draw_set_transform(Vector2.ZERO, 0, Vector2(1 + squash, 1 - squash))
	var points := PackedVector2Array()
	for i in 25:
		var a := PI + i * PI / 24
		points.append(Vector2(cos(a) * 33, -5 + sin(a) * 43))
	points.append(Vector2(27, 0))
	points.append(Vector2(-27, 0))
	draw_colored_polygon(points, Color(Color("fff2c9") if flash > 0 else tint, alpha))
	for x in [-10, 10]:
		draw_circle(Vector2(x, -21), 3, Color(Color("273b2b"), alpha))
	draw_arc(Vector2(0, -18), 7, 0, PI, 12, Color(Color("365032"), alpha), 2)


## The curse leaving: a violet wisp spirals up, then pops into warm sparks.
func draw_purify() -> void:
	var t := death_time
	var origin := contact_box().get_center() - position
	var top := origin + Vector2(sin(WISP_TIME * 9.0) * 5, -64)
	if t < WISP_TIME:
		var rise := ease(t / WISP_TIME, 0.6)
		var at := origin + Vector2(sin(t * 9.0) * 5, -64 * rise)
		var radius := lerpf(11, 6, rise)
		for k in 4:
			var lag := at + Vector2(-sin((t - 0.05 * (k + 1)) * 9.0) * 3, 7.0 * (k + 1))
			draw_circle(lag, radius * (0.7 - 0.14 * k), Color(0.72, 0.5, 1.0, 0.35 - 0.07 * k), true, -1, true)
		draw_circle(at, radius * 2.1, Color(0.72, 0.45, 1.0, 0.16), true, -1, true)
		draw_circle(at, radius, Color(0.8, 0.58, 1.0, 0.9), true, -1, true)
		draw_circle(at + Vector2(-radius, -radius) * 0.3, radius * 0.4, Color(1, 0.96, 1, 0.95), true, -1, true)
	elif t < PURIFY_TIME:
		var s := (t - WISP_TIME) / (PURIFY_TIME - WISP_TIME)
		draw_circle(top, 9 * (1 - s) * (1 - s), Color(1, 0.9, 0.62, 0.85 * (1 - s)), true, -1, true)
		for k in 10:
			var a := k * TAU / 10 + 0.3
			var spark := top + Vector2(cos(a), sin(a)) * (8 + 42 * ease(s, 0.5)) + Vector2(0, 14 * s * s)
			draw_circle(spark, 3.2 * (1 - s) + 0.6, Color(1, 0.86, 0.5, 1 - s), true, -1, true)
