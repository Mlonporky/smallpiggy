extends Control
## Close study of a physical thread; the brief pulse does not reveal a person.
var time := 0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(delta: float) -> void:
 time+=delta
 queue_redraw()
func _draw() -> void:
 var extent:=get_viewport_rect().size
 draw_rect(Rect2(Vector2.ZERO,extent),Color(0.05,0.04,0.045,0.92))
 var at:=extent*Vector2(0.5,0.38)
 draw_set_transform(at)
 draw_style_box(_paper(),Rect2(-205,-112,410,225))
 for j in 7:
  var points:=PackedVector2Array()
  for i in 40:
   var x: float=-115+i*6
   points.append(Vector2(x,sin(x*0.025+j*0.08)*13+j*0.7))
  draw_polyline(points,Color("a23b44").lightened(j*0.015),0.8,true)
 draw_set_transform(Vector2.ZERO)
 var pulse:=sin(clampf((time-1.5)/0.4,0,1)*PI)*0.045
 draw_rect(Rect2(Vector2.ZERO,extent),Color(0.8,0.13,0.18,pulse))
func _paper() -> StyleBoxFlat:
 var box:=StyleBoxFlat.new()
 box.bg_color=Color("c3ad8e")
 box.set_corner_radius_all(8)
 return box
