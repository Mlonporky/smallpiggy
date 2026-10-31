extends ForestSlime
const FX = preload("res://scenes/chapter2/combat_fx.gd")
const ATTACK_DAMAGE := 12
const WINDUP := 0.70
const DASH := 0.38
const RECOVERY := 0.80
var art: Sprite2D
var frames: Array
var phase := 0.0
var state := "idle"
var state_time := 0.0
var lunge_direction := Vector2.DOWN
var damage_cooldown := 0.0
var recoil := Vector2.ZERO
var hit_pause := 0.0
var flash_time := 0.0
var last_attack_serial := -1
var telegraph: Node2D
var last_attacker: Node

func _ready() -> void:
	super._ready()
	frames = JSON.parse_string(FileAccess.get_file_as_string("res://assets/chapter2/atlas.json"))["slime"]
	art = Sprite2D.new()
	art.texture = preload("res://assets/chapter2/slime.png")
	art.region_enabled = true
	art.centered = false
	art.texture_filter = CharacterSpriteStyle.FILTER
	add_child(art)
	var r: Array = frames[0]
	art.region_rect = Rect2(r[0], r[1], r[2], r[3])
	art.scale = Vector2.ONE * 0.47
	$HurtBox/CollisionShape2D.position.y = -45
	health.max_health = 24
	health.reset()
	hit_box.damage = ATTACK_DAMAGE

func _process(delta: float) -> void:
	phase += delta
	# Deform the gelatinous artwork, never its physical collision shapes.
	var desired := Vector2(1.0 + sin(phase*3.0)*0.025,1.0 - sin(phase*3.0)*0.025)
	var lift := 0.0
	if state == "windup": desired = Vector2(1.20,0.74)
	elif state == "dash":
		desired = Vector2(0.87,1.12)
		lift = sin(PI*clampf(state_time/DASH,0,1))*22.0
	elif state == "stagger": desired = Vector2(1.15,0.84)
	art.scale = art.scale.lerp(desired * 0.47,1.0-exp(-18.0*delta))
	var r: Array = frames[0]
	art.position = Vector2(-float(r[2])*art.scale.x*0.5,-float(r[3])*art.scale.y-lift)
	art.modulate = Color("fff0a8") if flash_time > 0 else Color.WHITE
	queue_redraw()

func _physics_process(delta: float) -> void:
	damage_cooldown = maxf(0, damage_cooldown - delta)
	flash_time = maxf(0, flash_time - delta)
	if _dead: return
	if recoil.length() > 1:
		move_and_collide(recoil * delta)
		recoil = recoil.move_toward(Vector2.ZERO,1000*delta)
	if not active or not is_instance_valid(target): return
	if hit_pause > 0:
		hit_pause = maxf(0,hit_pause-delta)
		return
	state_time += delta
	match state:
		"idle":
			if position.distance_to(target.position) <= 210: attack_lunge()
			else:
				velocity = position.direction_to(target.position) * 125
				move_and_slide()
		"windup":
			if state_time >= WINDUP:
				state = "dash"
				state_time = 0
				hit_box.position = lunge_direction * 36 + Vector2(0,-35)
				hit_box.monitoring = true
				FX.sound(self,"swing")
		"dash":
			velocity = lunge_direction * 390
			move_and_slide()
			for area in hit_box.get_overlapping_areas():
				if area is HurtBox2D: area.receive_hit(hit_box)
			if state_time >= DASH or get_slide_collision_count() > 0:
				state = "recover"
				state_time = 0
				velocity = Vector2.ZERO
				hit_box.monitoring = false
				FX.spawn(get_parent(),position,"land",Vector2.RIGHT,Color("d4b6e6"),45)
		"recover", "stagger":
			if state_time >= RECOVERY:
				state = "idle"
				state_time = 0
				_busy = false

func attack_lunge() -> void:
	if _busy or _dead or not target: return
	_busy = true
	state = "windup"
	state_time = 0
	velocity = Vector2.ZERO
	lunge_direction = position.direction_to(target.position)
	# The lane shown here is exactly the committed movement direction.
	telegraph = FX.spawn(get_parent(),position,"lane",lunge_direction,Color("e59cda"),390*DASH)
	telegraph.duration = WINDUP

func stop_attack() -> void:
	if is_instance_valid(telegraph): telegraph.queue_free()
	active = false
	state = "idle"
	state_time = 0
	_busy = false
	velocity = Vector2.ZERO
	recoil = Vector2.ZERO
	hit_pause = 0
	hit_box.set_deferred("monitoring",false)

func receive_joy(at: Vector2, radius: float) -> bool:
	if _dead or global_position.distance_to(at) > radius: return false
	if is_instance_valid(telegraph): telegraph.queue_free()
	state = "stagger"
	state_time = 0
	_busy = true
	velocity = Vector2.ZERO
	hit_box.set_deferred("monitoring",false)
	recoil = at.direction_to(global_position) * 320
	flash_time = 0.2
	FX.spawn(get_parent(),position+Vector2(0,-35),"impact",Vector2.RIGHT,Color("ffdc87"),90)
	health.damage(2)
	return true

func _on_damaged(source: HitBox2D) -> void:
	if _dead: return
	var attacker := source.get_parent()
	if "attack_serial" in attacker:
		if attacker == last_attacker and attacker.attack_serial == last_attack_serial: return
		last_attacker = attacker
		last_attack_serial = attacker.attack_serial
	elif damage_cooldown > 0: return
	damage_cooldown = 0.20
	FX.spawn(get_parent(), position + Vector2(0,-40), "impact", Vector2.RIGHT, Color("ffeeb5"), 60)
	FX.sound(self, "impact")
	health.damage(source.damage)
	if not _dead:
		recoil = (global_position-source.global_position).normalized() * 160
		flash_time = 0.14
		hit_pause = 0.045

func _on_died() -> void:
	stop_attack()
	super._on_died()

func _draw() -> void:
	if _dead: return
	draw_rect(Rect2(-38,-135,76,5),Color(0.12,0.06,0.16,0.8))
	draw_rect(Rect2(-38,-135,76*float(health.current_health)/health.max_health,5),Color("cf9ad8"))
