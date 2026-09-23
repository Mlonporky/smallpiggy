extends CharacterBody2D
## Side-view physics and a small, code-drawn paper-cutout animation prototype.
const WeaponArt = preload("res://scenes/chapter2/underground/weapon_art.gd")
signal attacked(kind: int)
const SPEED := 285.0
const GRAVITY := 1500.0
const JUMP := -590.0
var enabled := false
var facing := 1.0
var stride := 0.0
var grace := 0.0
var jump_buffer := 0.0
var landing := 0.0
var landed_once := false
var last_floor := false
var paused := false
var weapon := 0
var hp := 100
var invulnerable := 0.0
var attack_cooldown := 0.0
var attack_pose := 0.0
var knockback := 0.0

func take_damage(amount: int, direction: float) -> void:
 if invulnerable>0 or hp<=0 or not enabled: return
 hp = maxi(0,hp-amount)
 invulnerable = 0.9
 knockback = direction*240
 velocity.y = -160
 if hp==0: enabled = false

func attack() -> void:
 if paused or not enabled or hp<=0 or weapon==0 or attack_cooldown>0: return
 attack_cooldown = [0.0,0.75,0.20,0.42][weapon]
 attack_pose = 0.25
 attacked.emit(weapon)

func _ready() -> void:
 var collision := CollisionShape2D.new()
 var shape := CapsuleShape2D.new()
 shape.radius = 21
 shape.height = 94
 collision.shape = shape
 collision.position.y = -47
 add_child(collision)
 collision_layer = 2
 collision_mask = 1
 floor_snap_length = 8

func _physics_process(delta: float) -> void:
 if paused: return
 invulnerable = maxf(0,invulnerable-delta)
 attack_cooldown = maxf(0,attack_cooldown-delta)
 attack_pose = maxf(0,attack_pose-delta)
 if Input.is_action_pressed("attack"): attack()
 modulate.a = 0.55 if invulnerable>0 and sin(invulnerable*35)>0 else 1.0
 var grounded := is_on_floor()
 grace = 0.10 if grounded else maxf(0,grace-delta)
 jump_buffer = maxf(0,jump_buffer-delta)
 if enabled and Input.is_action_just_pressed("jump"): jump_buffer = 0.12
 var direction := Input.get_axis("move_left","move_right") if enabled else 0.0
 velocity.x = move_toward(velocity.x,direction*SPEED,1800*delta)
 if absf(knockback)>2:
  velocity.x = knockback
  knockback = move_toward(knockback,0,1100*delta)
 if absf(velocity.x)>2: facing = signf(velocity.x)
 if enabled and jump_buffer>0 and grace>0:
  velocity.y = JUMP
  grace = 0
  jump_buffer = 0
 if not grounded: velocity.y = minf(velocity.y+GRAVITY*delta,950)
 if enabled and Input.is_action_just_released("jump") and velocity.y < -220:
  velocity.y = -220
 var old_x := position.x
 move_and_slide()
 stride += absf(position.x-old_x) / 33.0
 if is_on_floor() and not last_floor:
  landing = 1
  landed_once = true
  enabled = hp>0
 last_floor = is_on_floor()
 landing = maxf(0,landing-delta*5)
 queue_redraw()

func _draw() -> void:
 var grounded := is_on_floor()
 var step := sin(stride) if grounded and absf(velocity.x)>3 else 0.0
 var bob := absf(step)*3+landing*5
 draw_set_transform(Vector2(0,bob),0,Vector2(facing,1))
 # A red cape reads clearly against the cool, flat cave shapes.
 var flutter := sin(stride*0.8)*4 if grounded else -12.0
 draw_colored_polygon(PackedVector2Array([Vector2(-10,-72),Vector2(-39,-68),Vector2(-52,-22+flutter),Vector2(-29,-26),Vector2(-9,-38)]),Color("843e43"))
 draw_line(Vector2(-26,-60),Vector2(-39,-30+flutter),Color("b66758"),3,true)
 for side in [-1,1]:
  var foot := Vector2(side*12+step*side*12,-9 if grounded else -18+side*6)
  draw_line(Vector2(side*10,-35),foot,Color("d994a0"),13,true)
  draw_circle(foot+Vector2(3,0),8,Color("633f50"))
 draw_circle(Vector2(0,-46),28,Color("493e38"))
 draw_circle(Vector2(0,-46),25,Color("cf9589"))
 draw_colored_polygon(PackedVector2Array([Vector2(-24,-61),Vector2(18,-61),Vector2(23,-35),Vector2(-25,-34)]),Color("b4a179"))
 draw_circle(Vector2(-3,-82),33,Color("493e38"))
 draw_circle(Vector2(-3,-82),30,Color("e5b2a5"))
 draw_colored_polygon(PackedVector2Array([Vector2(-25,-99),Vector2(-26,-125),Vector2(-4,-108)]),Color("e5b2a5"))
 draw_colored_polygon(PackedVector2Array([Vector2(-21,-104),Vector2(-22,-116),Vector2(-12,-107)]),Color("d8879b"))
 draw_circle(Vector2(24,-79),16,Color("493e38"))
 draw_circle(Vector2(24,-79),13,Color("ce8e83"))
 draw_circle(Vector2(30,-80),2.6,Color("995e78"))
 draw_circle(Vector2(12,-91),3.4,Color("3c3449"))
 draw_circle(Vector2(13,-92),1,Color("fff4de"))
 draw_circle(Vector2(6,-76),5.5,Color("e990a1"))
 draw_arc(Vector2(13,-76),9,0.35,1.3,12,Color("995e78"),1.8,true)
 draw_line(Vector2(-18,-61),Vector2(16,-62),Color("994b48"),9,true)
 draw_circle(Vector2(17,-61),5,Color("edc581"))
 draw_line(Vector2(4,-49),Vector2(18,-38-step*3),Color("e5b2a5"),10,true)
 draw_set_transform(Vector2.ZERO)

 if weapon>0:
  var angle := 0.0
  if weapon==3: angle = lerpf(-1.25,0.8,1-attack_pose/0.25) if attack_pose>0 else -0.7
  WeaponArt.paint(self,weapon,Vector2(22*facing,-46+bob),angle*facing,facing)
 if hp<=0:
  draw_arc(Vector2(0,-137),18,0,TAU,24,Color("e9c88d"),2,true)
