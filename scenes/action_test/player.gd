extends CharacterBody2D
signal movement_fx(kind: String, at: Vector2, amount: float)
@export_group("Ground movement")
@export var max_speed := 330.0
@export var acceleration := 2500.0
@export var deceleration := 3100.0
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
var health: Node
var combat: Node
var visuals: Node2D
var dust_timer := 0.0
var previous_feet := Vector2.ZERO

func _ready() -> void:
 collision_layer = 2
 collision_mask = 1
 floor_snap_length = 8
 visuals = $Visuals
 health = get_node_or_null("PlayerHealth")
 combat = get_node_or_null("PlayerCombat")

func alive() -> bool:
 return health==null or health.hp>0

func _physics_process(delta: float) -> void:
 if paused: return
 previous_feet = position
 if health: health.tick(delta)
 if combat: combat.tick(delta)
 roll_cooldown = maxf(0,roll_cooldown-delta)
 roll_time = maxf(0,roll_time-delta)
 landing = maxf(0,landing-delta*6)
 var floor_before := is_on_floor()
 grace = coyote_time if floor_before else maxf(0,grace-delta)
 buffer = maxf(0,buffer-delta)
 var direction := Input.get_axis("move_left","move_right") if control_enabled and alive() else 0.0
 if direction!=0: facing = direction
 if control_enabled and alive():
  if Input.is_action_just_pressed("jump"):
   buffer = jump_buffer_time
   buffer_released = false
  if Input.is_action_just_released("jump"):
   buffer_released = true
   if velocity.y < -short_jump_speed: velocity.y = -short_jump_speed
  if dodge_enabled and Input.is_action_just_pressed("roll") and roll_cooldown<=0:
   if combat: combat.reset_attack()
   roll_time = 0.24
   roll_cooldown = 0.70
   roll_direction = facing
   movement_fx.emit("roll",position,1)
 var rate := acceleration if direction!=0 else deceleration
 if not floor_before: rate = air_acceleration*air_control
 velocity.x = move_toward(velocity.x,direction*max_speed,rate*delta)
 if roll_time>0: velocity.x = roll_direction*570
 elif absf(knockback)>5:
  velocity.x = knockback
  knockback = move_toward(knockback,0,1800*delta)
 if not floor_before:
  var multiplier := fall_multiplier if velocity.y>apex_threshold else 1.0
  if absf(velocity.y)<apex_threshold: multiplier = apex_multiplier
  velocity.y = minf(velocity.y+gravity*multiplier*delta,1000)
 if buffer>0 and grace>0 and roll_time<=0 and alive():
  velocity.y = -short_jump_speed if buffer_released else -jump_speed
  buffer = 0
  grace = 0
  movement_fx.emit("jump",position,1)
 var falling_speed := velocity.y
 move_and_slide()
 # Consume buffered input on the landing frame, without an extra grounded delay.
 if not floor_before and is_on_floor():
  landing = clampf(falling_speed/800,0.2,1)
  movement_fx.emit("land",position,landing)
  if buffer>0 and alive():
   velocity.y = -short_jump_speed if buffer_released else -jump_speed
   buffer = 0
   grace = 0
 stride += absf(position.x-previous_feet.x)/33
 dust_timer -= delta
 if is_on_floor() and absf(velocity.x)>120 and dust_timer<=0:
  dust_timer = 0.12
  movement_fx.emit("run",position,0.35)
 visuals.update_pose(delta)

func bounce() -> void:
 velocity.y = -470
 grace = 0
 buffer = 0
 movement_fx.emit("stomp",position,1)

func reset_at(at: Vector2) -> void:
 position = at
 velocity = Vector2.ZERO
 knockback = 0
 roll_time = 0
 roll_cooldown = 0
 buffer = 0
 grace = 0
 control_enabled = true
 if health: health.reset_health()
 if combat: combat.reset_attack()
 reset_physics_interpolation()
