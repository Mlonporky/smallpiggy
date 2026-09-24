extends CharacterBody2D
signal movement_fx(kind: String, at: Vector2, amount: float)
## Collision layer used by jump-through branches (hold S / Down + Space to drop through).
const ONE_WAY_LAYER := 16
@export_group("Ground movement")
@export var max_speed := 330.0
@export var acceleration := 2500.0
@export var deceleration := 3100.0
@export var turn_boost := 1.45
@export_group("Air movement")
@export var air_acceleration := 1400.0
@export_range(0.0,1.0) var air_control := 0.85
@export_group("Jump")
@export var jump_speed := 680.0
@export var gravity := 1450.0
@export var fall_multiplier := 1.35
@export var apex_multiplier := 0.7
@export var apex_threshold := 95.0
@export var coyote_time := 0.10
@export var jump_buffer_time := 0.13
@export var short_jump_speed := 250.0
@export var max_fall_speed := 1000.0
@export_group("Assists")
@export var corner_correction := 14.0
@export var ledge_assist := 18.0
var facing := 1.0
var stride := 0.0
var landing := 0.0
var grace := 0.0
var buffer := 0.0
var buffer_released := false
var paused := false
var control_enabled := true
var knockback := 0.0
var roll_time := 0.0
var roll_cooldown := 0.0
var roll_direction := 1.0
var dodge_enabled := false
var launched := false
var drop_time := 0.0
var dropped_through: Array[Object] = []
var health: Node
var combat: Node
var visuals: Node2D
var dust_timer := 0.0
var previous_feet := Vector2.ZERO


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | ONE_WAY_LAYER
	floor_snap_length = 8
	visuals = $Visuals
	health = get_node_or_null("PlayerHealth")
	combat = get_node_or_null("PlayerCombat")


func alive() -> bool:
	return health == null or health.hp > 0


## World-space box of the body collider (feet at the bottom edge); used for contact checks.
func body_box() -> Rect2:
	var shape: CapsuleShape2D = $CollisionShape2D.shape
	return Rect2(position + Vector2(-shape.radius, -shape.height), Vector2(shape.radius * 2, shape.height))


func _physics_process(delta: float) -> void:
	if paused:
		return
	previous_feet = position
	if health:
		health.tick(delta)
	if combat:
		combat.tick(delta)
	roll_cooldown = maxf(0, roll_cooldown - delta)
	roll_time = maxf(0, roll_time - delta)
	landing = maxf(0, landing - delta * 6)
	_tick_drop(delta)
	var floor_before := is_on_floor()
	grace = coyote_time if floor_before else maxf(0, grace - delta)
	buffer = maxf(0, buffer - delta)
	var can_act := control_enabled and alive()
	var direction := Input.get_axis("move_left", "move_right") if can_act else 0.0
	if direction != 0:
		facing = signf(direction)
	if can_act:
		if Input.is_action_just_pressed("jump"):
			buffer = jump_buffer_time
			buffer_released = false
		if Input.is_action_just_released("jump"):
			buffer_released = true
			if velocity.y < -short_jump_speed and not launched:
				velocity.y = -short_jump_speed
		if dodge_enabled and Input.is_action_just_pressed("roll") and roll_cooldown <= 0:
			if combat:
				combat.reset_attack()
			roll_time = 0.24
			roll_cooldown = 0.70
			roll_direction = facing
			movement_fx.emit("roll", position, 1)
	var rate := acceleration if direction != 0 else deceleration
	if direction != 0 and signf(direction) != signf(velocity.x) and absf(velocity.x) > 10:
		rate *= turn_boost
	if not floor_before:
		rate = air_acceleration * air_control
	velocity.x = move_toward(velocity.x, direction * max_speed, rate * delta)
	if roll_time > 0:
		velocity.x = roll_direction * 570
	elif absf(knockback) > 5:
		velocity.x = knockback
		knockback = move_toward(knockback, 0, 1800 * delta)
	if not floor_before:
		var multiplier := fall_multiplier if velocity.y > apex_threshold else 1.0
		if absf(velocity.y) < apex_threshold:
			multiplier = apex_multiplier
		velocity.y = minf(velocity.y + gravity * multiplier * delta, max_fall_speed)
	if velocity.y >= 0:
		launched = false
	if buffer > 0 and grace > 0 and roll_time <= 0 and alive():
		if floor_before and _holding_down() and _try_drop_through():
			buffer = 0
			grace = 0
		else:
			_start_jump()
	if velocity.y < 0:
		_correct_head_corner(delta)
	var falling_speed := velocity.y
	move_and_slide()
	if not is_on_floor() and direction != 0 and is_on_wall() and velocity.y > -120:
		_assist_ledge(direction)
	# Consume buffered input on the landing frame, without an extra grounded delay.
	if not floor_before and is_on_floor():
		landing = clampf(falling_speed / 800, 0.2, 1)
		launched = false
		movement_fx.emit("land", position, landing)
		if buffer > 0 and alive():
			_start_jump()
	stride += absf(position.x - previous_feet.x) / 30
	dust_timer -= delta
	if is_on_floor() and absf(velocity.x) > 120 and dust_timer <= 0:
		dust_timer = 0.12
		movement_fx.emit("run", position, 0.35)
	visuals.update_pose(delta)


func _start_jump() -> void:
	velocity.y = -short_jump_speed if buffer_released else -jump_speed
	buffer = 0
	grace = 0
	launched = false
	movement_fx.emit("jump", position, 1)


func bounce() -> void:
	velocity.y = -470
	grace = 0
	buffer = 0
	movement_fx.emit("stomp", position, 1)


## Strong upward launch (bounce mushrooms). Releasing jump does not cut it short.
func launch(speed: float) -> void:
	velocity.y = -speed
	grace = 0
	buffer = 0
	launched = true
	landing = 0
	movement_fx.emit("bounce", position, 1.2)


func _holding_down() -> bool:
	return Input.is_action_pressed("move_down")


func _try_drop_through() -> bool:
	var dropped := false
	for i in get_slide_collision_count():
		var body := get_slide_collision(i).get_collider()
		if body is CollisionObject2D and body.collision_layer & ONE_WAY_LAYER and not body in dropped_through:
			add_collision_exception_with(body)
			dropped_through.append(body)
			dropped = true
	if dropped:
		drop_time = 0.28
		position.y += 2
		velocity.y = 60
	return dropped


func _tick_drop(delta: float) -> void:
	if dropped_through.is_empty():
		return
	drop_time -= delta
	if drop_time <= 0:
		for body in dropped_through:
			if is_instance_valid(body):
				remove_collision_exception_with(body)
		dropped_through.clear()


func _correct_head_corner(delta: float) -> void:
	# Bumping a ceiling corner by a few pixels slides the pig around it instead of stopping the jump.
	var rise := Vector2(0, velocity.y * delta)
	if not test_move(global_transform, rise):
		return
	var step := 2.0
	while step <= corner_correction:
		for side in [signf(velocity.x) if velocity.x != 0 else 1.0, -signf(velocity.x) if velocity.x != 0 else -1.0]:
			var shift := Vector2(side * step, 0)
			if not test_move(global_transform, shift) and not test_move(global_transform.translated(shift), rise):
				position += shift
				return
		step += 2.0


func _assist_ledge(direction: float) -> void:
	# Landing just short of a ledge top lifts the pig onto it rather than sliding down the wall.
	var step := 3.0
	while step <= ledge_assist:
		var lift := Vector2(0, -step)
		var ahead := Vector2(direction * 6, 0)
		if not test_move(global_transform, lift) and not test_move(global_transform.translated(lift), ahead):
			position += lift + Vector2(direction * 2, 0)
			velocity.y = 0
			return
		step += 3.0


func reset_at(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	knockback = 0
	roll_time = 0
	roll_cooldown = 0
	buffer = 0
	grace = 0
	launched = false
	control_enabled = true
	if health:
		health.reset_health()
	if combat:
		combat.reset_attack()
	if visuals and visuals.has_method("reset_pose"):
		visuals.reset_pose()
	reset_physics_interpolation()
