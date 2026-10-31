extends Node2D
## Two distant residents; deterministic poses, fixed shoulders, no new story flags.
const SHEET := preload("res://assets/finale/residents_parts_v1.png")
const DEFINITIONS := [
 {"body":Rect2(285,0,366,511),"a":Rect2(744,196,198,221),"b":Rect2(1102,196,198,221),
  "origin":Vector2(470,502),"pivot_a":Vector2(812,270),"pivot_b":Vector2(1235,270),
  "shoulder_a":Vector2(340,302),"shoulder_b":Vector2(607,297),"feet":[Vector2(385,503),Vector2(568,503)],
  "position":Vector2(550,550),"size":0.175,"delay":0.0},
 {"body":Rect2(285,511,350,509),"a":Rect2(744,693,206,225),"b":Rect2(1088,695,202,224),
  "origin":Vector2(467,1005),"pivot_a":Vector2(815,767),"pivot_b":Vector2(1230,770),
  "shoulder_a":Vector2(343,800),"shoulder_b":Vector2(600,790),"feet":[Vector2(381,1005),Vector2(558,1005)],
  "position":Vector2(1315,516),"size":0.145,"delay":0.18}]
var residents: Array[Dictionary] = []
var recovery := 0.0

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 for definition in DEFINITIONS:
  var root:=Node2D.new()
  root.position=definition.position
  add_child(root)
  var shadow:=Polygon2D.new()
  var points:=PackedVector2Array()
  for i in 32: points.append(Vector2(cos(i*TAU/32)*23,sin(i*TAU/32)*4))
  shadow.polygon=points
  shadow.color=Color(0.07,0.08,0.06,0.23)
  root.add_child(shadow)
  var core:=Node2D.new()
  root.add_child(core)
  var body:=_part(core,definition.body,definition.origin,definition.size)
  var arm_a:=Node2D.new()
  arm_a.position=(definition.shoulder_a-definition.origin)*definition.size
  core.add_child(arm_a)
  var arm_b:=Node2D.new()
  arm_b.position=(definition.shoulder_b-definition.origin)*definition.size
  core.add_child(arm_b)
  var a:=_part(arm_a,definition.a,definition.pivot_a,definition.size*.70)
  var b:=_part(arm_b,definition.b,definition.pivot_b,definition.size*.70)
  residents.append({"root":root,"core":core,"body":body,"a":arm_a,"b":arm_b,"art_a":a,"art_b":b,"definition":definition})
 sample(0)

func _part(parent: Node, region: Rect2, pivot: Vector2, factor: float) -> Sprite2D:
 var art:=Sprite2D.new()
 var atlas:=AtlasTexture.new()
 atlas.atlas=SHEET
 atlas.region=region
 atlas.filter_clip=true
 art.texture=atlas
 art.centered=false
 art.offset=region.position-pivot
 art.scale=Vector2.ONE*factor
 parent.add_child(art)
 return art

func sample(seconds: float) -> void:
 recovery=smoothstep(6.45,7.4,seconds)
 for resident in residents:
  var definition: Dictionary=resident.definition
  var time:=seconds-float(definition.delay)
  var awake:=smoothstep(6.45,7.2,time)
  var greeting:=smoothstep(7.0,7.6,time)
  var rest:=smoothstep(10.2,11.0,time)
  # One connected body: feet ground the small change of posture, no head sliding.
  resident.core.rotation=lerpf(-.035,0.0,awake)
  resident.core.modulate=Color("656175").lerp(Color.WHITE,awake)
  resident.a.rotation=lerpf(.28,.06,awake)
  resident.b.rotation=(-2.8+sin((time-7.6)*5.0)*.14*smoothstep(7.6,7.9,time))*greeting*(1.0-rest)
  var floor_y: float=-INF
  for foot in definition.feet:
   var local: Vector2=(foot-definition.origin)*float(definition.size)
   floor_y=maxf(floor_y,local.rotated(resident.core.rotation).y)
  resident.core.position.y=-floor_y
