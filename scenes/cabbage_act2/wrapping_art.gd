extends RefCounted
## One illustration, four shared tear boundaries: the fragments fit exactly.
const SIZE := Vector2(600,400)
const MESSAGE := "白白菜，生日\n\n爱你的，呆"
const FRONT := preload("res://assets/cabbage_act2/wrapping/front.png")
const BACK := preload("res://assets/cabbage_act2/wrapping/back_blank.png")
const TOP := [Vector2(286,0),Vector2(296,27),Vector2(275,50),Vector2(309,74),Vector2(290,97),Vector2(322,126),Vector2(295,154),Vector2(307,188)]
const LEFT := [Vector2(0,203),Vector2(43,193),Vector2(77,211),Vector2(111,181),Vector2(146,205),Vector2(181,177),Vector2(216,198),Vector2(255,170),Vector2(307,188)]
const RIGHT := [Vector2(307,188),Vector2(343,214),Vector2(378,183),Vector2(413,224),Vector2(450,204),Vector2(491,230),Vector2(530,200),Vector2(569,223),Vector2(600,214)]
const BOTTOM := [Vector2(307,188),Vector2(287,221),Vector2(320,253),Vector2(301,280),Vector2(341,309),Vector2(318,343),Vector2(340,371),Vector2(332,400)]
const OUTER := [Vector2(0,8),Vector2(70,4),Vector2(131,9),Vector2(202,2),Vector2(286,0),Vector2(368,5),Vector2(450,1),Vector2(521,8),Vector2(600,6),Vector2(597,81),Vector2(600,149),Vector2(600,214),Vector2(596,272),Vector2(600,337),Vector2(598,396),Vector2(518,400),Vector2(447,395),Vector2(383,399),Vector2(332,400),Vector2(248,397),Vector2(174,400),Vector2(85,396),Vector2(0,392),Vector2(4,326),Vector2(0,271),Vector2(0,203),Vector2(4,144),Vector2(0,88)]

static func reversed(points: Array) -> Array:
 var copy := points.duplicate()
 copy.reverse()
 return copy

# Shear the shared geometry into a surviving parallelogram-shaped remnant.
static func remnant(points: Array) -> PackedVector2Array:
 var result := PackedVector2Array()
 for point in points:
  var edge := 7.0*sin(point.y*0.19) if point.x < 5 or point.x > 595 else 0.0
  result.append(Vector2(0.72*point.x+0.30*(400-point.y)+edge,point.y))
 return result

static func outer() -> PackedVector2Array:
 return remnant(OUTER)

static func polygons() -> Array[PackedVector2Array]:
 return [
  remnant(OUTER.slice(0,5)+TOP.slice(1)+reversed(LEFT).slice(1)+OUTER.slice(26)),
  remnant(TOP+RIGHT.slice(1)+reversed(OUTER.slice(4,12)).slice(1)),
  remnant(LEFT+BOTTOM.slice(1)+OUTER.slice(19,26)),
  remnant(RIGHT+OUTER.slice(12,19)+reversed(BOTTOM).slice(1))
 ]

static func bounds(index: int) -> Rect2:
 var points := polygons()[index]
 var rect := Rect2(points[0],Vector2.ZERO)
 for point in points: rect = rect.expand(point)
 return rect

static func center(index: int) -> Vector2:
 return bounds(index).get_center()

static func make_piece(index: int, edges := true) -> Node2D:
 var node := Node2D.new()
 var shape := Polygon2D.new()
 shape.texture = FRONT
 var points := polygons()[index]
 var polygon := PackedVector2Array()
 var uv := PackedVector2Array()
 for point in points:
  polygon.append(point-center(index))
  uv.append(point/SIZE*FRONT.get_size())
 shape.polygon = polygon
 shape.uv = uv
 shape.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 node.add_child(shape)
 if edges:
  var outline := Line2D.new()
  outline.points = polygon
  outline.closed = true
  outline.width = 1.6
  outline.default_color = Color("ffe4c9")
  outline.antialiased = true
  node.add_child(outline)
 return node

static func make_whole(reverse_side := false) -> Node2D:
 var node := Node2D.new()
 var shape := Polygon2D.new()
 shape.polygon = outer()
 shape.name = "Paper"
 shape.texture = BACK if reverse_side else FRONT
 var uv := PackedVector2Array()
 for point in outer(): uv.append(point/SIZE*shape.texture.get_size())
 shape.uv = uv
 shape.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 node.add_child(shape)
 # Keep the joins visible even after the four fragments snap together.
 for boundary in [TOP,LEFT,RIGHT,BOTTOM]:
  var seam := Line2D.new()
  seam.points = remnant(boundary)
  seam.width = 1.0
  seam.default_color = Color(0.48,0.31,0.22,0.20) if reverse_side else Color(1,0.88,0.74,0.42)
  seam.antialiased = true
  node.add_child(seam)
 if reverse_side:
  shape.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
  var writing := Label.new()
  writing.name = "Message"
  writing.text = MESSAGE
  writing.position = Vector2(294,110)
  writing.size = Vector2(470,235)
  writing.rotation = 0.0
  writing.add_theme_font_override("font",preload("res://assets/fonts/game_font.tres"))
  writing.add_theme_font_size_override("font_size",36)
  writing.add_theme_color_override("font_color",Color("765344"))
  writing.add_theme_constant_override("line_spacing",14)
  shape.add_child(writing)
 return node
