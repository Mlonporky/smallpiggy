extends RefCounted
## Shared flat shapes for the rack, hand-held weapons and selection cards.
static func paint(canvas: CanvasItem, kind: int, at: Vector2, angle := 0.0, mirror := 1.0) -> void:
 canvas.draw_set_transform(at,angle,Vector2(mirror,1))
 match kind:
  1:
   canvas.draw_arc(Vector2(-3,0),30,-PI/2,PI/2,24,Color("dcad77"),5,true)
   canvas.draw_line(Vector2(-3,-30),Vector2(-12,0),Color("efe4c7"),1.5,true)
   canvas.draw_line(Vector2(-12,0),Vector2(-3,30),Color("efe4c7"),1.5,true)
   canvas.draw_line(Vector2(-18,0),Vector2(37,0),Color("e7d9b4"),2,true)
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(44,0),Vector2(33,-5),Vector2(33,5)]),Color("afd8cd"))
  2:
   canvas.draw_style_box(_box(Color("526b7c")),Rect2(-10,-12,49,21))
   canvas.draw_rect(Rect2(23,-10,25,11),Color("aac3c6"))
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(-6,3),Vector2(10,3),Vector2(5,25),Vector2(-11,22)]),Color("b58465"))
   canvas.draw_line(Vector2(0,-7),Vector2(24,-7),Color("d3c99d"),3,true)
  3:
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(5,-7),Vector2(56,-7),Vector2(70,0),Vector2(56,7),Vector2(5,7)]),Color("c2dfd9"))
   canvas.draw_line(Vector2(8,0),Vector2(58,0),Color("789eac"),2,true)
   canvas.draw_line(Vector2(3,-15),Vector2(3,15),Color("d5af68"),5,true)
   canvas.draw_line(Vector2(-16,0),Vector2(1,0),Color("986950"),7,true)
 canvas.draw_set_transform(Vector2.ZERO)

static func _box(color: Color) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = color
 box.set_corner_radius_all(4)
 return box
