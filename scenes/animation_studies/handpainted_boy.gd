extends Node2D
## Phase 4 candidate only. One continuous head/torso, rigid limbs and fixed joints.
const SHEET := preload("res://assets/characters/boy_handpainted_v1/parts_v1.png")
const REGIONS := {
 "Body":Rect2(125,53,650,825),
 "Arm_A":Rect2(873,251,261,288), "Arm_B":Rect2(1173,250,258,287),
 "Leg_A":Rect2(876,595,233,345), "Leg_B":Rect2(1215,594,249,345)}
const PIVOTS := {
 "Body":Vector2(500,1095),
 "Arm_A":Vector2(952,321), "Arm_B":Vector2(1341,320),
 "Leg_A":Vector2(996,652), "Leg_B":Vector2(1313,650)}
const JOINTS := {
 "Arm_A":Vector2(-82,-448), "Arm_B":Vector2(106,-449),
 "Leg_A":Vector2(-66,-283), "Leg_B":Vector2(63,-285)}
const REST := {"Arm_A":0.45,"Arm_B":-0.45,"Leg_A":0.0,"Leg_B":0.0}
const TIPS := {"Arm_A":Vector2(1054,523),"Arm_B":Vector2(1247,520)}
var height := 170.0
var facing := 1.0
var travel := 0.0
var movement := 0.0
var core: Node2D
var joints: Dictionary = {}
var artwork: Dictionary = {}
var soles: Dictionary = {}
var body_top := 63.0
var reference_height := 1032.0
var stride := 52.0

func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 core = Node2D.new()
 add_child(core)
 for key in REGIONS:
  var joint := Node2D.new()
  joint.position = JOINTS.get(key,Vector2.ZERO)
  joint.z_index = 2 if key == "Body" else (3 if key == "Arm_A" else 1)
  core.add_child(joint)
  joints[key] = joint
  var sprite := Sprite2D.new()
  sprite.texture = SpriteAtlas.frame(SHEET,REGIONS[key])
  sprite.centered = false
  sprite.offset = REGIONS[key].position-PIVOTS[key]
  joint.add_child(sprite)
  artwork[key] = sprite
 # Reuse the exact cape pixels over the shoulder root, without moving the joint.
 var cover := Polygon2D.new()
 var uv := PackedVector2Array([Vector2(216,570),Vector2(410,546),Vector2(615,582),Vector2(634,658),Vector2(577,710),Vector2(518,658),Vector2(445,628),Vector2(399,645),Vector2(350,691),Vector2(249,735),Vector2(161,780),Vector2(173,684)])
 var points := PackedVector2Array()
 for p in uv: points.append(p-PIVOTS.Body)
 cover.polygon = points
 cover.uv = uv
 cover.texture = SHEET
 cover.z_index = 4
 core.add_child(cover)
 _measure_source()
 sample(0,0,1)
 # Calibrate from the visible hair top and real boot contour, not the sheet size.
 reference_height = -(REGIONS.Body.position.y+_body_top_in_region()-PIVOTS.Body.y+core.position.y)
 scale = Vector2.ONE*(height/reference_height)
 stride = 4.0*280.0*sin(0.27)*scale.y

func _body_top_in_region() -> float:
 return body_top-REGIONS.Body.position.y

func _measure_source() -> void:
 var img := SHEET.get_image()
 for key in ["Leg_A","Leg_B"]:
  var contour := PackedVector2Array()
  var rect := Rect2i(REGIONS[key])
  for x in range(rect.position.x,rect.end.x):
   for y in range(rect.end.y-1,rect.position.y-1,-1):
    if img.get_pixel(x,y).a>0.1:
     contour.append(Vector2(x,y)-PIVOTS[key])
     break
  soles[key] = contour
 for y in range(int(REGIONS.Body.position.y),int(REGIONS.Body.end.y)):
  var found := false
  for x in range(int(REGIONS.Body.position.x),int(REGIONS.Body.end.x)):
   if img.get_pixel(x,y).a>0.1: found=true;break
  if found: body_top=y;break

func sample(distance: float, amount: float, direction: float) -> void:
 travel = distance
 movement = clampf(amount,0,1)
 facing = direction
 var phase := TAU*travel/maxf(stride,1)
 var swing := sin(phase)*movement
 joints.Leg_A.rotation = swing*0.27
 joints.Leg_B.rotation = -swing*0.27
 joints.Arm_A.rotation = REST.Arm_A-swing*0.14
 joints.Arm_B.rotation = REST.Arm_B+swing*0.14
 core.rotation = -0.012*movement
 core.position = Vector2.ZERO
 core.position.y = -maxf(sole_height("Leg_A"),sole_height("Leg_B"))
 scale.x = absf(scale.x)*facing
 queue_redraw()

func sole_height(key: String) -> float:
 var bottom := -INF
 for point in soles[key]:
  bottom = maxf(bottom,to_local(joints[key].to_global(point)).y)
 return bottom

func hand_point(key: String) -> Vector2:
 return joints[key].to_global(TIPS[key]-PIVOTS[key])

func _draw() -> void:
 # Soft contact shadow is presentation only, outside the connected rig.
 draw_set_transform(Vector2(0,8),0,Vector2(1,0.16))
 draw_circle(Vector2.ZERO,170,Color(0.12,0.10,0.08,0.13),true,-1,true)
 draw_set_transform(Vector2.ZERO)
