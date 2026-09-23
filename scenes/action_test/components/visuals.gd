extends Node2D
var facing := 1.0
var stride := 0.0
var landing := 0.0
func update_pose(delta: float) -> void:
 var body = get_parent()
 facing = body.facing
 stride = body.stride
 landing = body.landing
 var stretch := Vector2.ONE
 if not body.is_on_floor(): stretch = Vector2(0.96,1.05) if body.velocity.y<0 else Vector2(0.94,1.08)
 elif landing>0: stretch = Vector2(1+landing*0.09,1-landing*0.08)
 if body.roll_time>0: stretch = Vector2(1.13,0.68)
 scale = scale.lerp(stretch,1-exp(-18*delta))
 modulate.a = 0.5 if body.health and body.health.invulnerable>0 and sin(body.health.invulnerable*35)>0 else 1.0
 queue_redraw()
func _draw() -> void:
 var grounded: bool = get_parent().is_on_floor()
 var step := sin(stride) if grounded and absf(get_parent().velocity.x)>3 else 0.0
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
