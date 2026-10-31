extends Node2D
## Rigid cutouts: no limb scaling, mesh deformation, or independent head rotation.
const SHEET := preload("res://assets/characters/pig_single_joint/parts_v1.png")
const REGIONS := {
 "core": Rect2(132,29,723,816),
 "near_arm": Rect2(1090,166,190,295), "far_arm": Rect2(1385,150,205,320),
 "near_leg": Rect2(1090,525,215,259), "far_leg": Rect2(1398,525,211,259)}
# Anatomical sides, judged from the pig's own facing direction. In this
# three-quarter-right sheet, her left limbs are on the viewer's right.
const LEFT_ARM := "far_arm"
const LEFT_LEG := "far_leg"
const RIGHT_ARM := "near_arm"
const RIGHT_LEG := "near_leg"
const CORE_SCALE := 0.22
const ARM_SCALE := 0.155
const LEG_SCALE := 0.145
const CORE_PIVOT := Vector2(585,800)
const NEAR_SHOULDER := Vector2(445,554)
const FAR_SHOULDER := Vector2(725,588) # Anatomical left shoulder seated inside torso.
const ARM_PIVOTS := {"near_arm":Vector2(1182,214),"far_arm":Vector2(1482,211)}
# Opaque bottom tips measured on the original paint (not bounding-box centres).
const HOOF_POINTS := {"near_arm":Vector2(1187,450),"far_arm":Vector2(1495,449)}
# Convex outlines of opaque painted hoof pixels (alpha > 0.95, source y >= 415 (toe ends, excluding wrist)).
const FINGER_CONTOURS := {
 "near_arm": [Vector2(1134,415),Vector2(1256,415),Vector2(1256,416),Vector2(1251,426),Vector2(1247,432),Vector2(1241,438),Vector2(1237,441),Vector2(1231,443),Vector2(1192,450),Vector2(1182,450),Vector2(1174,448),Vector2(1162,442),Vector2(1155,437),Vector2(1150,433),Vector2(1144,427),Vector2(1136,418),Vector2(1134,415)],
 "far_arm": [Vector2(1429,415),Vector2(1538,415),Vector2(1537,417),Vector2(1532,425),Vector2(1530,428),Vector2(1517,441),Vector2(1513,444),Vector2(1509,446),Vector2(1504,448),Vector2(1500,449),Vector2(1490,449),Vector2(1459,444),Vector2(1454,443),Vector2(1451,442),Vector2(1447,440),Vector2(1443,437),Vector2(1438,432),Vector2(1436,429),Vector2(1429,415)]}
const PICKUP_LEAN := deg_to_rad(16.0)
const LEG_PIVOTS := {"near_leg":Vector2(1188,578),"far_leg":Vector2(1497,578)}
# Resting belly-to-ground clearance was 18.32 rig units; tuck half into the torso.
const LEG_INSET := 9.16
const HIP_POINTS := {
 "near_leg":Vector2(474,790)-Vector2(0,LEG_INSET/CORE_SCALE),
 "far_leg":Vector2(695,782)-Vector2(0,LEG_INSET/CORE_SCALE)}
const WALK_BOUNCE := 8.5
const CROUCH_TUCK := 24.0
const JOINT_COVER := preload("res://scenes/animation_studies/pig_joint_cover.gdshader")
const SOLES := {"near_leg":[Vector2(1164,771),Vector2(1228,774)],"far_leg":[Vector2(1462,773),Vector2(1528,774)]}
const STRIDE := 44.0
var core: Node2D
var parts: Dictionary = {}
var near_hand := Vector2.ZERO
var far_hand := Vector2.ZERO
var near_foot := Vector2.ZERO
var far_foot := Vector2.ZERO
var travel := 0.0
var movement := 0.0
var reach := 0.0
var hold := 0.0
var clock := 0.0
var near_angle := 0.0
var far_angle := 0.0
var bounce_height := 0.0

func sprite(key: String, parent: Node2D, pivot: Vector2, factor: float) -> Sprite2D:
 var result := Sprite2D.new()
 var texture := AtlasTexture.new()
 texture.atlas = SHEET
 texture.region = REGIONS[key]
 result.texture = texture
 result.centered = false
 result.offset = REGIONS[key].position-pivot
 result.scale = Vector2.ONE*factor
 parent.add_child(result)
 parts[key] = result
 return result

func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 core = Node2D.new()
 add_child(core)
 for key in LEG_PIVOTS:
  var leg := sprite(key,core,LEG_PIVOTS[key],LEG_SCALE)
  leg.position = (HIP_POINTS[key]-CORE_PIVOT)*CORE_SCALE
  leg.z_index = 3 if key==LEFT_LEG else 1
 var far := sprite("far_arm",core,ARM_PIVOTS.far_arm,ARM_SCALE)
 far.position = (FAR_SHOULDER-CORE_PIVOT)*CORE_SCALE
 far.z_index = 3
 sprite("core",core,CORE_PIVOT,CORE_SCALE).z_index = 2
 var near := sprite("near_arm",core,ARM_PIVOTS.near_arm,ARM_SCALE)
 near.position = (NEAR_SHOULDER-CORE_PIVOT)*CORE_SCALE
 near.z_index = 1
 add_joint_cover(far,ARM_SCALE,10.0,(HOOF_POINTS[LEFT_ARM]-ARM_PIVOTS[LEFT_ARM]).normalized())
 add_joint_cover(parts[LEFT_LEG],LEG_SCALE,-1.0)
 # Registered collar patch covers the shoulder cap, attached to the same core.
 var collar := Polygon2D.new()
 collar.texture = SHEET
 collar.z_index = 4
 # Follow the painted cloth hem; a rectangular patch would slice the arm flat.
 var hem := PackedVector2Array([Vector2(260,440),Vector2(805,440),Vector2(805,590),Vector2(780,568),Vector2(756,547),Vector2(737,540),Vector2(720,555),Vector2(691,566),Vector2(655,555),Vector2(627,538),Vector2(576,531),Vector2(535,528),Vector2(481,542),Vector2(434,560),Vector2(386,589),Vector2(345,627),Vector2(300,680),Vector2(260,680)])
 collar.uv = hem
 var points := PackedVector2Array()
 for point in hem: points.append((point-CORE_PIVOT)*CORE_SCALE)
 collar.polygon = points
 core.add_child(collar)
 update_pose()

func add_joint_cover(part: Sprite2D, factor: float, radius: float, axis := Vector2.DOWN) -> void:
 var cover := ShaderMaterial.new()
 cover.shader = JOINT_COVER
 cover.set_shader_parameter("torso_texture",SHEET)
 cover.set_shader_parameter("torso_pivot",CORE_PIVOT)
 cover.set_shader_parameter("torso_scale",CORE_SCALE)
 cover.set_shader_parameter("part_scale",factor)
 cover.set_shader_parameter("joint_radius",radius)
 cover.set_shader_parameter("joint_axis",axis)
 cover.set_shader_parameter("tuck_range",Vector2(part.offset.y,part.offset.y+part.texture.get_height())*factor)
 part.material = cover

func update_joint_cover(part: Sprite2D, amount: float) -> void:
 var cover: ShaderMaterial = part.material
 cover.set_shader_parameter("part_x",part.transform.x)
 cover.set_shader_parameter("part_y",part.transform.y)
 cover.set_shader_parameter("part_origin",part.position)
 cover.set_shader_parameter("cover_amount",amount)

func sole_height(key: String) -> float:
 var lowest := -INF
 var part: Sprite2D = parts[key]
 for source in SOLES[key]:
  var point: Vector2 = (part.transform*(source-LEG_PIVOTS[key])).rotated(core.rotation)
  lowest = maxf(lowest,point.y)
 return lowest

func foot_position(key: String) -> Vector2:
 var center: Vector2 = (SOLES[key][0]+SOLES[key][1])*0.5
 return core.transform*(parts[key].transform*(center-LEG_PIVOTS[key]))

func update_pose() -> void:
 if parts.is_empty(): return
 var phase := travel/STRIDE+0.1
 var gait := sin(phase*TAU)
 core.rotation = PICKUP_LEAN*reach
 # Walking retains its fixed hip swing. The user-requested crouch retracts the
 # intact anatomical left leg beneath the belly, without a kick or size change.
 for key in LEG_PIVOTS:
  parts[key].position = (HIP_POINTS[key]-CORE_PIVOT)*CORE_SCALE
  if key==LEFT_LEG: parts[key].position.y -= CROUCH_TUCK*reach
 parts.near_leg.rotation = gait*0.28*movement-core.rotation
 parts.far_leg.rotation = -gait*0.28*movement-core.rotation
 # Retro-style springy steps: land with legs apart, rise as they pass each other.
 # All parts rise together, so neither hip nor neck can separate. Bounce fades
 # with movement, keeping standing/pickup grounded and never sinking a hoof.
 bounce_height = WALK_BOUNCE*pow(cos(phase*TAU),2)*movement
 var supported_y := minf(-sole_height("near_leg"),-2.0-sole_height("far_leg"))
 core.position = Vector2(2*reach,supported_y-bounce_height)
 near_foot = foot_position("near_leg")
 far_foot = foot_position("far_leg")
 # One horizontal fingertip plane. Solve rotations only; shoulder positions and
 # painted arm lengths stay fixed even as the intact body leans forward.
 var near_shoulder := shoulder("near_arm")
 var far_shoulder := shoulder("far_arm")
 var near_length := (HOOF_POINTS.near_arm-ARM_PIVOTS.near_arm).length()*ARM_SCALE
 var far_length := (HOOF_POINTS.far_arm-ARM_PIVOTS.far_arm).length()*ARM_SCALE
 var lowest_common := minf(near_shoulder.y+near_length,far_shoulder.y+far_length)
 var swing_lift := near_length*(1.0-cos(gait*0.16*movement))
 var tip_y := lowest_common-lerpf(swing_lift,12.0,hold)
 var near_side := -1.0 if gait>0.0 and movement>0.0 else 1.0
 var far_side := 1.0 # Far hoof stays on the visible, forward side of the body.
 near_angle = align_fingertip("near_arm",tip_y,near_side)
 far_angle = align_fingertip("far_arm",tip_y,far_side)
 # A rotated cloven hoof changes which visible tip is lowest. Align the actual
 # silhouette, not only the reference landmark used to solve the first angle.
 var visible_height := fingertip("near_arm").y
 var low := -1.7-core.rotation
 var high := 0.15-core.rotation
 for iteration in 20:
  parts.far_arm.rotation = (low+high)*0.5
  if fingertip("far_arm").y>visible_height: high=parts.far_arm.rotation
  else: low=parts.far_arm.rotation
 far_angle = (low+high)*0.5
 parts.far_arm.rotation = far_angle
 near_hand = hoof("near_arm")
 far_hand = hoof("far_arm")
 update_joint_cover(parts[LEFT_ARM],1.0)
 update_joint_cover(parts[LEFT_LEG],reach)

func align_fingertip(key: String, height: float, side: float) -> float:
 var source: Vector2 = (HOOF_POINTS[key]-ARM_PIVOTS[key])*ARM_SCALE
 var rise := clampf(height-shoulder(key).y,-source.length(),source.length())
 var across := side*sqrt(maxf(0,source.length_squared()-rise*rise))
 var angle := source.angle_to(Vector2(across,rise))-core.rotation
 parts[key].rotation = angle
 return angle

func fingertip_source(key: String) -> Vector2:
 var part: Sprite2D = parts[key]
 var bottom := -INF
 var point := Vector2.ZERO
 for source in FINGER_CONTOURS[key]:
  var actual: Vector2 = core.transform*(part.transform*(source-ARM_PIVOTS[key]))
  if actual.y>bottom:
   bottom=actual.y
   point=source
 return point

func fingertip(key: String) -> Vector2:
 var part: Sprite2D = parts[key]
 return core.transform*(part.transform*(fingertip_source(key)-ARM_PIVOTS[key]))

func hoof(key: String) -> Vector2:
 # A held object keeps one material point, even when a different toe becomes
 # lowest on screen. Switching silhouette vertices must not teleport the prop.
 var part: Sprite2D = parts[key]
 return core.transform*(part.transform*(HOOF_POINTS[key]-ARM_PIVOTS[key]))

func shoulder(key: String) -> Vector2:
 return core.transform*parts[key].position
