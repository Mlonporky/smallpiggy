extends Node2D
signal connected(at: Vector2, pause_time: float)
signal swung
var weapon: Resource = null
var state := "IDLE"
var timer := 0.0
var queued := 0.0
var struck: Array[int] = []
var hitbox: Area2D
var shape: RectangleShape2D
var attack_direction := 1.0
var enabled := true
func _ready() -> void:
 hitbox = Area2D.new()
 hitbox.collision_layer = 0
 hitbox.collision_mask = 4
 shape = RectangleShape2D.new()
 shape.size = Vector2(96,80)
 var collider := CollisionShape2D.new()
 collider.shape = shape
 hitbox.add_child(collider)
 add_child(hitbox)
func reset_attack() -> void:
 state = "IDLE"
 timer = 0
 queued = 0
 struck.clear()
func tick(delta: float) -> void:
 var body = get_parent()
 if not enabled or not body.alive():
  reset_attack()
  return
 queued = maxf(0,queued-delta)
 if Input.is_action_just_pressed("attack"): queued = 0.12
 if state=="IDLE":
  if queued>0 and weapon and body.roll_time<=0:
   attack_direction = body.facing
   state = "WINDUP"
   timer = weapon.windup
   queued = 0
   struck.clear()
   swung.emit()
 else:
  timer -= delta
  if timer<=0:
   match state:
    "WINDUP":
     state = "ACTIVE"
     timer = weapon.active_time
    "ACTIVE":
     state = "RECOVERY"
     timer = weapon.recovery
    "RECOVERY": state = "IDLE"
 if weapon:
  shape.size.x = weapon.reach
  hitbox.position = Vector2((20+weapon.reach/2)*attack_direction,-38)
 if state=="ACTIVE":
  for enemy in hitbox.get_overlapping_bodies():
   if not enemy.has_method("take_hit") or enemy.hp<=0 or enemy.get_instance_id() in struck: continue
   var query := PhysicsRayQueryParameters2D.create(body.global_position+Vector2(0,-38),enemy.global_position+Vector2(0,-28),1)
   if not get_world_2d().direct_space_state.intersect_ray(query).is_empty(): continue
   struck.append(enemy.get_instance_id())
   enemy.take_hit(weapon.damage,attack_direction*weapon.knockback)
   connected.emit(enemy.global_position+Vector2(0,-28),weapon.hit_pause)
 queue_redraw()
func _draw() -> void:
 if not weapon or state=="IDLE" or state=="WINDUP": return
 # A crescent trail follows the sweep, then fades during the first part of recovery.
 var sweep := 1.0
 var fade := 1.0
 if state=="ACTIVE": sweep = clampf(1.0-timer/maxf(0.001,weapon.active_time),0.15,1.0)
 else:
  fade = clampf(timer/maxf(0.001,weapon.recovery)*1.6-0.6,0.0,1.0)
  if fade<=0: return
 var start := -1.25
 var finish := start+2.3*sweep
 draw_set_transform(Vector2(0,-38),0,Vector2(attack_direction,1))
 for i in 4:
  var t := float(i)/4.0
  var from := lerpf(start,finish,t*0.7)
  draw_arc(Vector2.ZERO,weapon.reach-i*5.0,from,finish,18,Color(0.9,0.96,0.82,(0.16+0.2*t)*fade),7.0-i,true)
 draw_arc(Vector2.ZERO,weapon.reach,finish-0.35,finish,8,Color(1,1,0.93,0.85*fade),3.0,true)
 draw_set_transform(Vector2.ZERO)
