extends CharacterBody2D
## Independent small enemy; all time is advanced by the room's pause-aware tick.
enum State { IDLE, WINDUP, HOP, RECOVER, DEAD }
var state := State.IDLE
var clock := 0.0
var hp := 64
var flash := 0.0
var heading := -1.0
var home := Vector2.ZERO
var tint := Color("91a966")
var death_time := 0.0
var attack_count := 0

func _ready() -> void:
 collision_layer = 4
 collision_mask = 1
 var collision := CollisionShape2D.new()
 var shape := CapsuleShape2D.new()
 shape.radius = 24
 shape.height = 48
 collision.shape = shape
 collision.position = Vector2(0,-24)
 add_child(collision)
 home = position

func tick(delta: float, target: CharacterBody2D) -> void:
 clock += delta
 flash = maxf(0,flash-delta)
 if state == State.DEAD:
  death_time += delta
  modulate.a = maxf(0,1-death_time/0.55)
  queue_redraw()
  return
 velocity.y = minf(velocity.y+1300*delta,800)
 match state:
  State.IDLE:
   velocity.x = move_toward(velocity.x,0,900*delta)
   if target.enabled and is_on_floor() and absf(target.position.x-position.x)<300 and absf(target.position.y-position.y)<125 and clock>0.6:
    heading = 1 if target.position.x>position.x else -1
    state = State.WINDUP
    clock = 0
  State.WINDUP:
   velocity.x = 0
   if clock>=0.65:
    state = State.HOP
    clock = 0
    attack_count += 1
    velocity = Vector2(heading*230,-330)
  State.HOP:
   if is_on_wall(): velocity.x = -velocity.x*0.25
   if is_on_floor() and clock>0.12:
    state = State.RECOVER
    clock = 0
  State.RECOVER:
   velocity.x = move_toward(velocity.x,0,1100*delta)
   if clock>0.7:
    state = State.IDLE
    clock = 0
 move_and_slide()
 if state == State.HOP and target.position.distance_to(position)<180:
  var hurt := Rect2(target.position+Vector2(-21,-94),Vector2(42,94))
  var body := Rect2(position+Vector2(-27,-48),Vector2(54,48))
  if hurt.intersects(body): target.take_damage(16,heading)
 queue_redraw()

func hit(damage: int, direction: float) -> void:
 if state == State.DEAD: return
 hp = maxi(0,hp-damage)
 flash = 0.14
 velocity.x = direction*150
 if hp == 0:
  state = State.DEAD
  velocity = Vector2.ZERO
 else:
  state = State.RECOVER
  clock = 0

func _draw() -> void:
 var squash := 0.0
 if state == State.WINDUP: squash = 0.3*clampf(clock/0.65,0,1)
 elif state == State.HOP: squash = -0.15
 else: squash = sin(clock*5)*0.04
 if state == State.DEAD: squash = minf(0.85,death_time*1.8)
 draw_set_transform(Vector2.ZERO,0,Vector2(1+squash,1-squash))
 var outline := PackedVector2Array()
 for i in 25:
  var a := PI+PI*float(i)/24
  outline.append(Vector2(cos(a)*36,-7+sin(a)*49))
 outline.append(Vector2(28,0))
 outline.append(Vector2(-29,0))
 var border := outline.duplicate()
 border.append(outline[0])
 draw_polyline(border,Color("233b29"),6)
 draw_colored_polygon(outline,Color("f7e9cb") if flash>0 else tint)
 draw_arc(Vector2(-8,-24),17,3.4,4.9,12,Color("c6d79a"),4,true)
 for x in [-12,12]:
  draw_circle(Vector2(x+heading*3,-23),4,Color("233f48"))
 draw_arc(Vector2(heading*2,-17),7,0.1,PI-0.1,12,Color("385c61"),2,true)
 draw_set_transform(Vector2.ZERO)
 if state == State.WINDUP:
  draw_line(Vector2(-28,8),Vector2(28,8),Color("eaba78"),3,true)
  draw_circle(Vector2(0,-76),4,Color("ffd591"))
 if hp<64 and state != State.DEAD:
  draw_rect(Rect2(-29,-70,58,5),Color("31414b"))
  draw_rect(Rect2(-29,-70,58*hp/64.0,5),Color("e7bf84"))
 if state == State.DEAD:
  for i in 7:
   var at := Vector2.from_angle(i*TAU/7)*death_time*65+Vector2(0,-20+death_time*30)
   draw_circle(at,maxf(0.1,4*(1-death_time/0.6)),tint)
