extends ForestSlime
const FX = preload("res://scenes/chapter2/combat_fx.gd")
var art: Sprite2D
var frames: Array
var phase := 0.0
var state := "idle"
var state_time := 0.0
var lunge_direction := Vector2.DOWN
var shielded := true
var damage_cooldown := 0.0
var ambush := false

func _ready() -> void:
	super._ready()
	frames = JSON.parse_string(FileAccess.get_file_as_string("res://assets/chapter2/atlas.json"))["slime"]
	art = Sprite2D.new()
	art.texture = preload("res://assets/chapter2/slime.png")
	art.region_enabled = true
	art.centered = false
	art.scale = Vector2.ONE * 0.47
	art.texture_filter = CharacterSpriteStyle.FILTER
	add_child(art)
	$HurtBox/CollisionShape2D.position.y = -45
	hit_box.damage = 20

func _process(delta: float) -> void:
	phase += delta
	var r: Array = frames[int(phase * 5.0) % 3]
	art.region_rect = Rect2(r[0], r[1], r[2], r[3])
	art.position = Vector2(-float(r[2])*0.235, -float(r[3])*0.47)
	queue_redraw()

func _physics_process(delta: float) -> void:
	damage_cooldown = maxf(0, damage_cooldown - delta)
	if _dead or not active or not is_instance_valid(target): return
	state_time += delta
	if state == "idle":
		if position.distance_to(target.position) <= 210:
			attack_lunge()
		else:
			velocity = position.direction_to(target.position) * 115
			move_and_slide()
	elif state == "windup":
		# Aim is committed before the dash; the player can dodge or jump.
		scale = Vector2(1 + 0.22 * minf(state_time/0.75,1), 1 - 0.28 * minf(state_time/0.75,1))
		if state_time >= 0.85:
			state = "dash"
			state_time = 0
			scale = Vector2(0.85,1.12)
			hit_box.position = lunge_direction * 36 + Vector2(0,-35)
			hit_box.activate(0.55)
			FX.sound(self,"swing")
	elif state == "dash":
		velocity = lunge_direction * 370
		move_and_slide()
		if state_time >= 0.55:
			state = "recover"
			state_time = 0
			velocity = Vector2.ZERO
			hit_box.monitoring = false
	elif state == "recover":
		scale = scale.lerp(Vector2.ONE, minf(1,delta * 14))
		if state_time >= 1.05:
			state = "idle"
			state_time = 0
			_busy = false

func attack_lunge() -> void:
	if _busy or _dead or not target: return
	_busy = true
	state = "windup"
	state_time = 0
	lunge_direction = position.direction_to(target.position)
	FX.spawn(get_parent(), target.position, "warning", Vector2.RIGHT, Color("e59cda"), 65)

func stop_attack() -> void:
	active = false
	state = "idle"
	state_time = 0
	_busy = false
	velocity = Vector2.ZERO
	hit_box.set_deferred("monitoring",false)
	scale = Vector2.ONE

func _on_damaged(source: HitBox2D) -> void:
	if _dead or damage_cooldown > 0: return
	damage_cooldown = 0.35
	FX.spawn(get_parent(), position + Vector2(0,-40), "impact", Vector2.RIGHT, Color("ffeeb5"), 70)
	FX.sound(self, "impact")
	if shielded:
		# Intro cannot be skipped by attacking before the visible ambush lands.
		return
	health.damage(source.damage)
	if not _dead:
		move_and_collide((global_position-source.global_position).normalized() * 14)
		modulate = Color("fff0a8")
		var tween := create_tween()
		tween.tween_property(self,"modulate",Color.WHITE,0.2)

func _on_died() -> void:
	stop_attack()
	super._on_died()

func _draw() -> void:
	if shielded and not _dead:
		draw_arc(Vector2(0,-45),62,0,TAU,48,Color(0.73,0.48,0.92,0.22+sin(phase*2)*0.08),3,true)
