extends "res://scenes/animation_studies/editable_pig_motion.gd"
## Continuous poses on the saved five-part assembly; no replacement body frames.
var craft := 0.0
var fasten := 0.0
var release := 0.0
var body_outline := PackedVector2Array()
var finger_outlines: Dictionary = {}

func _ready() -> void:
 super._ready()
 var body: Sprite2D = core.get_node("Body")
 var pixels := body.texture.get_image()
 var points := PackedVector2Array()
 for y in range(0, pixels.get_height(), 4):
  for x in range(0, pixels.get_width(), 4):
   if pixels.get_pixel(x,y).a > 0.6:
    points.append(Vector2(x,y)+body.offset)
 body_outline = Geometry2D.convex_hull(points)
 for key in ["Arm_A", "Arm_B"]:
  var art: Sprite2D = artwork[key]
  var atlas: AtlasTexture = art.texture
  pixels = atlas.get_image()
  points = PackedVector2Array()
  for y in range(int(415-atlas.region.position.y),pixels.get_height()):
   for x in pixels.get_width():
    if pixels.get_pixel(x,y).a > 0.95:
     points.append(Vector2(x,y)+art.offset)
  finger_outlines[key] = Geometry2D.convex_hull(points)
 update_pose()

func finger_height(key: String) -> float:
 var lowest := -INF
 for point in finger_outlines[key]:
  lowest = maxf(lowest,to_local(artwork[key].to_global(point)).y)
 return lowest

func level_fingers() -> void:
 # A common reachable fingertip height, achieved only by shoulder rotation.
 if finger_outlines.is_empty(): return
 var maxima: Array[float] = []
 for key in ["Arm_A", "Arm_B"]:
  var high := -INF
  for i in 49:
   joints[key].rotation = -1.5+float(i)/48.0*1.9
   high = maxf(high,finger_height(key))
  maxima.append(high)
 var target := minf(maxima[0],maxima[1])-2.0-2.0*absf(sin(travel/STRIDE*TAU))
 for key in ["Arm_A", "Arm_B"]:
  var low := -1.5
  var high := -0.15
  for i in 18:
   joints[key].rotation = (low+high)*0.5
   if finger_height(key) < target: low=joints[key].rotation
   else: high=joints[key].rotation

func update_pose() -> void:
 if joints.is_empty(): return
 core.transform = rest_core
 for key in LIMBS: joints[key].transform = rest[key]
 var phase := (travel/STRIDE+0.1)*TAU
 var gait := sin(phase)
 var lean := deg_to_rad(32.0)*reach
 core.rotation += lean
 joints.Leg_A.rotation += gait*0.28*movement-lean
 joints.Leg_B.rotation += -gait*0.28*movement-lean
 joints.Leg_A.position.y -= 24.0*reach
 level_fingers()
 var arm_a: float = joints.Arm_A.rotation
 var arm_b: float = joints.Arm_B.rotation
 # Let A hang toward the ground as the entire connected torso leans over it.
 joints.Arm_A.rotation = lerpf(arm_a,-lean,reach)
 joints.Arm_A.rotation = lerpf(joints.Arm_A.rotation,-1.30,hold)
 joints.Arm_B.rotation = lerpf(arm_b,-1.24,craft)
 joints.Arm_A.rotation = lerpf(joints.Arm_A.rotation,-4.08,fasten)
 joints.Arm_B.rotation = lerpf(joints.Arm_B.rotation,-2.00,fasten)
 joints.Arm_A.rotation = lerp_angle(joints.Arm_A.rotation,arm_a,release)
 joints.Arm_B.rotation = lerp_angle(joints.Arm_B.rotation,arm_b,release)
 bounce_height = WALK_BOUNCE*pow(cos(phase),2)*movement
 var floor_now := maxf(sole_height("Leg_A"),sole_height("Leg_B"))
 var body: Sprite2D = core.get_node("Body")
 for point in body_outline:
  floor_now = maxf(floor_now,to_local(body.to_global(point)).y)
 core.position.y -= floor_now+bounce_height
 near_hand = hand_position("Arm_A")
 far_hand = hand_position("Arm_B")

func collar_point() -> Vector2:
 var body: Sprite2D = core.get_node("Body")
 return to_local(body.to_global(Vector2(655,535)-Vector2(132,29)+body.offset))
