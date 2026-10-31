extends Node2D
## Small eye moisture and dust, sampled from the same paused cinematic clock.
var actor: Node2D
var tear := 0.0
var dust_time := -1.0
func _draw() -> void:
 if actor == null: return
 if tear > 0 and actor.kind == "boy" and actor.frame == 4:
  # Neutral pose in the explicit left-facing row; same inspected eye, not a face ratio.
  var eye: Vector2 = actor.sprite.position + (Vector2(487,527)-actor.bounds[4].position)*actor.sprite.scale
  draw_set_transform(eye,0,Vector2(1,.42))
  draw_circle(Vector2.ZERO,1.8,Color(.84,.92,.91,tear*.75),true,-1,true)
  draw_set_transform(Vector2.ZERO)
  draw_circle(eye+Vector2(-.5,-.45),.55,Color(1,.98,.90,tear*.85),true,-1,true)
 if dust_time >= 0 and actor.rig != null:
  for stroke in [1.02,1.66]:
   var age: float=dust_time-stroke
   if age<0 or age>.65: continue
   var origin: Vector2=actor.to_local(actor.rig.core.to_global(Vector2(-1,-35)))
   for i in 5:
    var point:=origin+Vector2((i-2)*3.0+sin(i*2.4)*age*9,age*(8+i*2))
    draw_circle(point,.7+.2*(i%2),Color(.71,.61,.45,(1.0-age/.65)*.35),true,-1,true)
