class_name ForestSlime
extends CharacterBody2D

signal defeated

@onready var hurt_box: HurtBox2D = %HurtBox
@onready var hit_box: HitBox2D = %HitBox
@onready var health: HealthComponent = %Health

var target: Node2D
var active := false
var _busy := false
var _dead := false
var _home_position := Vector2.ZERO


func _ready() -> void:
	_home_position = global_position
	hurt_box.team = "enemy"
	hit_box.team = "enemy"
	hurt_box.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if active and target and not _busy:
		if global_position.distance_to(target.global_position) < 380.0:
			attack_lunge()
		else:
			velocity = global_position.direction_to(target.global_position) * 42.0
			move_and_slide()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		move_and_slide()


func set_target(value: Node2D) -> void:
	target = value


func attack_lunge() -> void:
	if _busy or _dead or not target:
		return
	_busy = true
	velocity = Vector2.ZERO
	var direction := global_position.direction_to(target.global_position)
	# Clear 0.8 second telegraph: squash, brighten, then lunge.
	var telegraph := create_tween()
	telegraph.tween_property(self, "scale", Vector2(1.25, 0.68), 0.48).set_trans(Tween.TRANS_SINE)
	telegraph.tween_property(self, "modulate", Color("d9a8ff"), 0.20)
	telegraph.tween_interval(0.12)
	await telegraph.finished
	scale = Vector2(0.82, 1.18)
	hit_box.position = direction * 28.0
	hit_box.activate(0.30)
	var elapsed := 0.0
	while elapsed < 0.30 and not _dead:
		velocity = direction * 330.0
		move_and_slide()
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	velocity = Vector2.ZERO
	var recovery := create_tween()
	recovery.set_parallel(true)
	recovery.tween_property(self, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK)
	recovery.tween_property(self, "modulate", Color.WHITE, 0.18)
	await recovery.finished
	await get_tree().create_timer(0.55).timeout
	_busy = false


func _on_damaged(source: HitBox2D) -> void:
	if _dead:
		return
	health.damage(source.damage)
	var away := (global_position - source.global_position).normalized()
	global_position += away * 22.0
	modulate = Color("fff0a8")
	var hit_tween := create_tween()
	hit_tween.tween_property(self, "modulate", Color.WHITE, 0.18)


func _on_died() -> void:
	_dead = true
	active = false
	velocity = Vector2.ZERO
	hurt_box.set_deferred("monitorable", false)
	var dissolve := create_tween()
	dissolve.set_parallel(true)
	dissolve.tween_property(self, "scale", Vector2(1.35, 0.08), 0.45).set_trans(Tween.TRANS_BACK)
	dissolve.tween_property(self, "modulate:a", 0.0, 0.45)
	await dissolve.finished
	defeated.emit()
	queue_free()


func _draw() -> void:
	# TODO_ASSET: replace this procedural placeholder with Forest Slime animation.
	draw_circle(Vector2(0, 6), 39, Color("7a4f9b"))
	draw_circle(Vector2(-22, -15), 23, Color("8d64ad"))
	draw_circle(Vector2(20, -16), 23, Color("8d64ad"))
	draw_circle(Vector2(-13, -5), 5, Color("fff3cf"))
	draw_circle(Vector2(13, -5), 5, Color("fff3cf"))
	draw_circle(Vector2(-13, -4), 2, Color("30233b"))
	draw_circle(Vector2(13, -4), 2, Color("30233b"))
	draw_arc(Vector2(0, 11), 10, 0.25, PI - 0.25, 12, Color("3c294b"), 3.0)
	draw_ellipse_shadow()


func draw_ellipse_shadow() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-42,39), Vector2(-28,32), Vector2(28,32), Vector2(42,39), Vector2(28,46), Vector2(-28,46)]), Color(0.02, 0.02, 0.05, 0.3))

