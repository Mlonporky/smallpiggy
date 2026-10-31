extends Node2D
## Atlas regions measured from alpha components. A/B are part IDs, not anatomy.
const SHEET := preload("res://assets/finale/cabbage_parts_v1.png")
const REGIONS := {
 "Body": Rect2(69,72,866,891), "Arm_A": Rect2(1012,265,196,319),
 "Arm_B": Rect2(1277,265,198,318), "Leg_A": Rect2(910,658,257,266),
 "Leg_B": Rect2(1236,665,242,259)}
const PIVOTS := {"Body":Vector2(504,939),"Arm_A":Vector2(1119,324),
 "Arm_B":Vector2(1375,324),"Leg_A":Vector2(1073,716),"Leg_B":Vector2(1390,720)}
const POINTS := {"Arm_A":Vector2(1050,513),"Arm_B":Vector2(1430,512),
 "Leg_A":Vector2(1035,917),"Leg_B":Vector2(1368,917)}
var core: Node2D
var joints: Dictionary = {}
var artwork: Dictionary = {}
var rest: Dictionary = {}
var travel := 0.0
var movement := 0.0
var contact_weight := 0.0
var contact_angle := 0.0
var near_hand := Vector2.ZERO
var body_points := PackedVector2Array()

func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 core=Node2D.new()
 add_child(core)
 for key in ["Leg_A","Arm_A","Body","Leg_B","Arm_B"]:
  var pivot:=Node2D.new()
  core.add_child(pivot)
  var art:=Sprite2D.new()
  var atlas:=AtlasTexture.new()
  atlas.atlas=SHEET
  atlas.region=REGIONS[key]
  atlas.filter_clip=true
  art.texture=atlas
  art.centered=false
  art.offset=REGIONS[key].position-PIVOTS[key]
  art.scale=Vector2.ONE*(0.166 if key=="Body" else 0.118)
  pivot.add_child(art)
  if key=="Body":
   # The separate foot begins inside this rectangle's bottom-right corner.
   # Clip through the transparent gutter; do not show a neighbouring atlas part.
   var cutout:=Polygon2D.new()
   var source:=PackedVector2Array([Vector2(69,72),Vector2(935,72),Vector2(935,790),Vector2(885,790),Vector2(885,963),Vector2(69,963)])
   var vertices:=PackedVector2Array()
   for at in source: vertices.append(at-PIVOTS.Body)
   cutout.polygon=vertices
   cutout.uv=source
   cutout.texture=SHEET
   art.self_modulate.a=0
   art.add_child(cutout)
  if key=="Arm_A": pivot.position=Vector2(-42,-36); pivot.z_index=1
  elif key=="Arm_B": pivot.position=Vector2(9,-35); pivot.z_index=3
  elif key=="Leg_A": pivot.position=Vector2(-25,-5); pivot.z_index=1
  elif key=="Leg_B": pivot.position=Vector2(13,-5); pivot.z_index=1
  else: pivot.z_index=2
  joints[key]=pivot
  artwork[key]=art
  rest[key]=pivot.transform
 update_pose()

func point(key: String) -> Vector2:
 var art: Sprite2D=artwork[key]
 return to_local(art.to_global(POINTS[key]-PIVOTS[key]))

func update_pose() -> void:
 if joints.is_empty(): return
 core.position=Vector2.ZERO
 for key in joints: joints[key].transform=rest[key]
 var phase:=travel/44.0*TAU
 joints.Leg_A.rotation=sin(phase)*0.23*movement
 joints.Leg_B.rotation=-sin(phase)*0.23*movement
 joints.Arm_A.rotation=sin(phase)*0.16*movement
 joints.Arm_B.rotation=-sin(phase)*0.16*movement
 joints.Arm_A.rotation=lerp_angle(joints.Arm_A.rotation,contact_angle,contact_weight)
 # Lift the connected assembly to the lowest painted sole, never move a hip.
 var floor_y: float=maxf(point("Leg_A").y,point("Leg_B").y)
 core.position.y=-floor_y-2.5*pow(sin(phase),2)*movement
 near_hand=point("Arm_A")

func shoulder() -> Vector2:
 return to_local(joints.Arm_A.global_position)

func aim_hand(target: Vector2, weight: float) -> void:
 var toward: Vector2=core.to_local(to_global(target))-joints.Arm_A.position
 var tip: Vector2=(POINTS.Arm_A-PIVOTS.Arm_A)*artwork.Arm_A.scale
 contact_angle=toward.angle()-tip.angle()
 contact_weight=weight
 update_pose()
