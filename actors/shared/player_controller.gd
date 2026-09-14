class_name PiggyPlayer
extends CharacterBody2D

signal prompt_changed(text: String)
signal health_changed(current: int, maximum: int)
signal player_died
signal attack_started

@export_enum("white_cabbage", "little_pig") var character_id := "white_cabbage"
@export var combat_enabled := false
@export var move_speed := 205.0
const WALK_SPEED_MULTIPLIER := 1.5
@export var acceleration := 1150.0
@export var deceleration := 1450.0
@export var handpainted_room := false
@export var sheet_override: Texture2D
@export var sheet_row_edges: PackedInt32Array = []
@export var visible_height := 150.0

@onready var visual_root: Node2D = %VisualRoot
@onready var sprite: Sprite2D = %Sprite
@onready var interaction_detector: Area2D = %InteractionDetector
@onready var hit_box: HitBox2D = %HitBox
@onready var hurt_box: HurtBox2D = %HurtBox
@onready var health: HealthComponent = %Health

var input_enabled := true
var _facing := Vector2.DOWN
var _attacking := false
var _invulnerable := false
var _animation_clock := 0.0
var _nearest_interactable: Interactable
var walk_phase := 0.0
var _travelled := 0.0
var _frame_bounds: Array[Rect2] = []
var _script_walking := false
var _walk_target := Vector2.ZERO


func _ready() -> void:
	# TODO_ASSET: replace placeholder spritesheet with final authored animation frames.
	if character_id == "little_pig":
		sprite.texture = load("res://assets/sprites/characters/little_pig.png")
	else:
		sprite.texture = load("res://assets/sprites/characters/white_cabbage.png")
	if sheet_override:
		sprite.texture = sheet_override
	sprite.texture_filter = CharacterSpriteStyle.FILTER
	if handpainted_room:
		_frame_bounds = SpriteAtlas.bounds(sprite.texture, 3, 4, sheet_row_edges, 0.01)
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.region_enabled = true
		sprite.centered = false
		sprite.modulate = Color(0.94, 0.9, 0.82, 1)
		visual_root.position = Vector2.ZERO
		var shadow := visual_root.get_node("Shadow") as Polygon2D
		shadow.position = Vector2.ZERO
		var body := $CollisionShape2D as CollisionShape2D
		body.position = Vector2.ZERO
		var feet := CircleShape2D.new()
		feet.radius = 15.0
		body.shape = feet
		_update_visual(0.0)
	hurt_box.team = "player"
	hit_box.team = "player"
	hurt_box.damaged.connect(_on_damaged)
	health.health_changed.connect(func(current: int, maximum: int): health_changed.emit(current, maximum))
	health.died.connect(_on_died)
	health_changed.emit(health.current_health, health.max_health)


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if _script_walking:
		direction = global_position.direction_to(_walk_target)
		if global_position.distance_to(_walk_target) < 5.0:
			_script_walking = false
			direction = Vector2.ZERO
	elif input_enabled and not _attacking:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.0:
		_facing = _cardinal_facing(direction)
		velocity = velocity.move_toward(direction * move_speed * WALK_SPEED_MULTIPLIER, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	var previous_position := global_position
	move_and_slide()
	_travelled = global_position.distance_to(previous_position)
	_update_visual(delta)
	_update_interaction()
	if input_enabled and _wants_interaction() and _nearest_interactable:
		_nearest_interactable.interact(self)
	if combat_enabled and input_enabled and Input.is_action_just_pressed("attack"):
		attack()
	if input_enabled and Input.is_action_just_pressed("quick_save"):
		var save_manager := get_node_or_null("/root/SaveManager")
		if save_manager:
			save_manager.save_game()


func _wants_interaction() -> bool:
	return Input.is_action_just_pressed("interact")


func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		velocity = Vector2.ZERO


func face(direction: Vector2) -> void:
	if direction.length_squared() > 0.0:
		_facing = _cardinal_facing(direction)


func walk_to(target: Vector2, timeout := 8.0) -> bool:
	_walk_target = target
	_script_walking = true
	var elapsed := 0.0
	while _script_walking and elapsed < timeout:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	_script_walking = false
	velocity = Vector2.ZERO
	return global_position.distance_to(target) < 8.0


func attack() -> void:
	if _attacking or not combat_enabled:
		return
	_attacking = true
	attack_started.emit()
	velocity = Vector2.ZERO
	hit_box.position = _facing * 48.0
	visual_root.scale = Vector2(0.92, 1.08)
	await get_tree().create_timer(0.12).timeout # anticipation
	visual_root.scale = Vector2(1.14, 0.9)
	hit_box.activate(0.10)
	await get_tree().create_timer(0.10).timeout # active
	visual_root.scale = Vector2.ONE
	await get_tree().create_timer(0.18).timeout # recovery
	_attacking = false


func _update_interaction() -> void:
	interaction_detector.position = _facing * 46.0
	var next: Interactable = null
	var shortest := INF
	for area in interaction_detector.get_overlapping_areas():
		if area is Interactable and area.enabled:
			var distance := global_position.distance_squared_to(area.global_position)
			if distance < shortest:
				shortest = distance
				next = area
	if handpainted_room and get_parent().get_parent().has_method("nearest_reachable"):
		next = get_parent().get_parent().nearest_reachable(global_position)
	if next != _nearest_interactable:
		_nearest_interactable = next
		prompt_changed.emit(_nearest_interactable.prompt_text if _nearest_interactable else "")


func _update_visual(delta: float) -> void:
	_animation_clock += delta
	var moving := _travelled > 0.05
	# Integrated distance preserves phase through acceleration and collisions.
	walk_phase = fposmod(walk_phase + _travelled / (95.0 if handpainted_room else 72.0), 1.0)
	var row := 0
	if _facing == Vector2.LEFT:
		row = 1
	elif _facing == Vector2.RIGHT:
		row = 2
	elif _facing == Vector2.UP:
		row = 3
	if moving:
		var cycle := [0, 1, 2, 1]
		_show_frame(row * 3 + cycle[int(walk_phase * 4.0) % 4])
		if not _attacking:
			visual_root.scale = visual_root.scale.lerp(Vector2.ONE, minf(1.0, delta * 15.0))
	else:
		_show_frame(row * 3 + 1)
		if not _attacking:
			visual_root.scale = Vector2(1.0 + sin(_animation_clock * 2.2) * 0.003, 1.0 - sin(_animation_clock * 2.2) * 0.003)


func _show_frame(index: int) -> void:
	if not handpainted_room:
		sprite.frame = index
		return
	var rect := _frame_bounds[index]
	sprite.region_rect = rect
	var factor := visible_height / rect.size.y
	sprite.scale = Vector2.ONE * factor
	sprite.position = Vector2(-rect.size.x * factor * 0.5, -visible_height)


func _on_damaged(source: HitBox2D) -> void:
	if _invulnerable:
		return
	_invulnerable = true
	hurt_box.invulnerable = true
	health.damage(source.damage)
	var knock_direction := (global_position - source.global_position).normalized()
	global_position += knock_direction * 18.0
	for i in 5:
		sprite.visible = not sprite.visible
		await get_tree().create_timer(0.07).timeout
	sprite.visible = true
	await get_tree().create_timer(0.45).timeout
	_invulnerable = false
	hurt_box.invulnerable = false


func _on_died() -> void:
	set_input_enabled(false)
	player_died.emit()


func _cardinal_facing(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP
