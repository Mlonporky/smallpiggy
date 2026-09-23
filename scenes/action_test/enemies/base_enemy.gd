extends CharacterBody2D
signal defeated(at: Vector2)
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
func _ready() -> void:
 hp = max_hp
 home = position
 collision_layer = 4
 collision_mask = 1
 var collider := CollisionShape2D.new()
 var capsule := CapsuleShape2D.new()
 capsule.radius = 24
 capsule.height = 48
 collider.shape = capsule
 collider.position.y = -24
 add_child(collider)
func steer(_delta: float) -> void: velocity.x = move_toward(velocity.x,0,20)
func tick(delta: float) -> void:
 clock += delta
 flash = maxf(0,flash-delta)
 if hp<=0:
  death_time += delta
  position.x += velocity.x*delta*0.15
  modulate.a = maxf(0,1-death_time/0.4)
  queue_redraw()
  return
 stun = maxf(0,stun-delta)
 velocity.y = minf(velocity.y+1500*delta,900)
 if stun<=0: steer(delta)
 else: velocity.x = move_toward(velocity.x,0,700*delta)
 move_and_slide()
 var box := Rect2(position+Vector2(-30,-49),Vector2(60,50))
 var player_box := Rect2(target.position+Vector2(-21,-94),Vector2(42,94))
 if target.alive() and box.intersects(player_box):
  if stompable and target.velocity.y>90 and target.previous_feet.y<=position.y-38:
   take_hit(32,signf(position.x-target.position.x)*100)
   target.bounce()
   room.hit_feedback(position+Vector2(0,-40),0.04)
  else: target.health.take_damage(touch_damage,signf(target.position.x-position.x) if target.position.x!=position.x else -1)
 queue_redraw()
func take_hit(amount: int, impulse: float) -> void:
 if hp<=0: return
 hp = maxi(0,hp-amount)
 flash = 0.12
 stun = 0.2
 velocity.x = impulse
 if hp==0:
  collision_layer = 0
  defeated.emit(position)
func _draw() -> void:
 var squash := sin(clock*4)*0.04+flash*0.8
 if hp<=0: squash = minf(0.8,death_time*2)
 draw_set_transform(Vector2.ZERO,0,Vector2(1+squash,1-squash))
 var points := PackedVector2Array()
 for i in 25:
  var a := PI+i*PI/24
  points.append(Vector2(cos(a)*33,-5+sin(a)*43))
 points.append(Vector2(27,0))
 points.append(Vector2(-27,0))
 draw_colored_polygon(points,Color("fff2c9") if flash>0 else tint)
 for x in [-10,10]: draw_circle(Vector2(x,-21),3,Color("273b2b"))
 draw_arc(Vector2(0,-18),7,0,PI,12,Color("365032"),2)
 draw_set_transform(Vector2.ZERO)
 if not stompable:
  for x in [-22,0,22]: draw_colored_polygon(PackedVector2Array([Vector2(x-7,-40),Vector2(x,-66),Vector2(x+7,-40)]),Color("d2c59a"))
 if hp<max_hp and hp>0:
  draw_rect(Rect2(-28,-76,56,5),Color("18271e"))
  draw_rect(Rect2(-28,-76,56.0*hp/max_hp,5),Color("d9be83"))
