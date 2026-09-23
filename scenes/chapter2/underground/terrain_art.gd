extends RefCounted
## Stone stays within the collider; only decorative hanging vines extend below.
static func paint(canvas: CanvasItem, rect: Rect2) -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = int(rect.position.x*31+rect.position.y*17)
 var depth: float = rect.size.y
 var silhouette := PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.position+Vector2(rect.size.x,rect.size.y)])
 for i in range(int(rect.size.x/18),-1,-1):
  silhouette.append(rect.position+Vector2(minf(rect.size.x,i*18),depth-rng.randi_range(0,2)*3))
 canvas.draw_colored_polygon(silhouette,Color("142a21"))
 for row in int(depth/15):
  for col in int(rect.size.x/27):
   var at := rect.position+Vector2(col*27+(row%2)*9,row*15+12)
   var width := minf(rng.randi_range(3,8)*3,rect.end.x-at.x)
   var colors := [Color("24382a"),Color("304330"),Color("1c3025"),Color("384832")]
   canvas.draw_rect(Rect2(at,Vector2(width,9)),colors[rng.randi_range(0,3)])
 for i in range(0,int(rect.size.x),6):
  var at := rect.position+Vector2(i,0)
  canvas.draw_rect(Rect2(at,Vector2(minf(6,rect.size.x-i),6)),Color("9bb474"))
  canvas.draw_rect(Rect2(at+Vector2(0,6),Vector2(minf(6,rect.size.x-i),rng.randi_range(1,4)*3)),Color("536d3c"))
  if rng.randf()<0.35:
   canvas.draw_rect(Rect2(at+Vector2(0,-3),Vector2(3,3)),Color("b3c18b"))
 for i in int(rect.size.x/55):
  var x := rect.position.x+21+i*55
  var length := rng.randi_range(3,9)*6
  var start := rect.position.y+depth-6
  for j in range(0,length,6):
   var at := Vector2(x+sin(j*0.12+i)*6,start+j).snapped(Vector2(3,3))
   canvas.draw_rect(Rect2(at,Vector2(3,6)),Color("435636"))
   if j%12==0: canvas.draw_rect(Rect2(at+Vector2(-6,0),Vector2(6,3)),Color("627747"))
