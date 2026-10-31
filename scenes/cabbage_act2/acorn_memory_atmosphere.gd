extends Node2D
## Quiet drifting motes and grounded shadows, drawn in the trail's coordinates.
var pig: Node2D
var cabbage: Node2D
var elapsed := 0.0

func _process(delta: float) -> void:
 elapsed += delta
 queue_redraw()

func _draw() -> void:
 for actor in [pig,cabbage]:
  if not is_instance_valid(actor): continue
  draw_set_transform(actor.position+Vector2(0,3),0,Vector2(1,0.18))
  for ring in range(6,0,-1):
   draw_circle(Vector2.ZERO,32+ring*4,Color(0.22,0.16,0.10,0.018),true,-1,true)
 draw_set_transform(Vector2.ZERO)
 for i in 22:
  var seed_value := float(i)*127.71
  var x := fposmod(seed_value+elapsed*(4.0+float(i%4)),1536.0)
  var y := 200.0+fposmod(seed_value*0.71+elapsed*3,380.0)
  var alpha := 0.11+0.10*sin(elapsed*0.7+float(i))
  draw_circle(Vector2(x+sin(elapsed*.5+i)*8,y),1.2+float(i%3)*.3,Color(1,.90,.67,alpha),true,-1,true)
