extends Node2D
var kind := "heal"
var weapon: Resource
var amount := 20
var lock_time := 0.0
var pulse := 0.0
var consumed := false
func tick(delta: float) -> void:
 lock_time = maxf(0,lock_time-delta)
 pulse += delta
 queue_redraw()
func _draw() -> void:
 if consumed or (kind=="weapon" and weapon==null): return
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE*(1.25 if kind=="heal" and amount>20 else 1.0))
 var bob := sin(pulse*3)*3
 draw_arc(Vector2(0,-25+bob),30,0,TAU,24,Color(0.8,0.87,0.58,0.35),2)
 if kind=="heal":
  draw_circle(Vector2(-5,-24+bob),12,Color("d18c69"))
  draw_circle(Vector2(6,-24+bob),12,Color("d18c69"))
  draw_line(Vector2(0,-35+bob),Vector2(3,-43+bob),Color("b9bb7d"),4)
  draw_circle(Vector2(8,-40+bob),5,Color("829765"))
 else:
  draw_line(Vector2(-16,-6+bob),Vector2(12,-40+bob),Color("b5bc9b"),5)
  if weapon.kind=="hammer": draw_rect(Rect2(0,-49+bob,28,20),Color("a7afa2"))
  elif weapon.kind=="dagger": draw_line(Vector2(-6,-21+bob),Vector2(9,-39+bob),Color("e4dcc1"),8)
  else: draw_line(Vector2(-4,-26+bob),Vector2(18,-48+bob),Color("d1e1cc"),8)
  draw_line(Vector2(-12,-23+bob),Vector2(3,-13+bob),Color("d4b16e"),4)
