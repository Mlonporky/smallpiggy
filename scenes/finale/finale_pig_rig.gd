extends "res://scenes/cabbage_act2/acorn_memory_rig.gd"
## Saved A/B assembly, only shoulder rotation for the new contact gesture.
var cape: MeshInstance2D
var attention := 0.0
var brush := 0.0
var contact_weight := 0.0
var guard_weight := 0.0
var contact_angle := -1.1
var height_cache_key: Array = []
var height_maxima: Array[float] = []

func _ready() -> void:
 super._ready()
 cape=preload("res://scenes/finale/cape_surface.gd").new()
 cape.setup(core.get_node("Body"))

func sample_cape(seconds: float, gust := 0.0) -> void:
 cape.sample(seconds,.22+.78*gust)

func finger_height(key: String) -> float:
 # Equivalent local transform, without walking the global scene hierarchy for
 # every contour vertex during the shoulder solver's iterations.
 var transform: Transform2D=core.transform*joints[key].transform*artwork[key].transform
 var lowest: float=-INF
 for point in finger_outlines[key]: lowest=maxf(lowest,(transform*point).y)
 return lowest

func level_fingers() -> void:
 if finger_outlines.is_empty(): return
 var key: Array=[core.transform,joints.Arm_A.position,joints.Arm_B.position,
  joints.Arm_A.scale,joints.Arm_B.scale,artwork.Arm_A.transform,artwork.Arm_B.transform]
 if key!=height_cache_key:
  height_cache_key=key
  height_maxima.clear()
  for limb in ["Arm_A","Arm_B"]:
   var maximum: float=-INF
   for i in 49:
    joints[limb].rotation=-1.5+float(i)/48.0*1.9
    maximum=maxf(maximum,finger_height(limb))
   height_maxima.append(maximum)
 var target: float=minf(height_maxima[0],height_maxima[1])-2.0-2.0*absf(sin(travel/STRIDE*TAU))
 for limb in ["Arm_A","Arm_B"]:
  var low:=-1.5
  var high:=-.15
  for i in 18:
   joints[limb].rotation=(low+high)*.5
   if finger_height(limb)<target: low=joints[limb].rotation
   else: high=joints[limb].rotation

func update_pose() -> void:
 super.update_pose()
 if joints.is_empty(): return
 # Tilt the connected assembly gently; hips and shoulders remain fixed in core.
 # Counter-rotate the legs and settle the actual painted soles onto the ground.
 if attention > 0:
  var tilt := deg_to_rad(-3.0)*attention
  core.rotation += tilt
  joints.Leg_A.rotation -= tilt
  joints.Leg_B.rotation -= tilt
  level_fingers()
  core.position.y -= maxf(sole_height("Leg_A"),sole_height("Leg_B"))
 # B is the numbered foreground arm, without an anatomical left/right claim.
 joints.Arm_B.rotation = lerp_angle(joints.Arm_B.rotation,-.95,brush)
 joints.Arm_A.rotation = lerp_angle(joints.Arm_A.rotation,-1.1,guard_weight)
 joints.Arm_B.rotation = lerp_angle(joints.Arm_B.rotation,-1.25,guard_weight)
 joints.Arm_A.rotation = lerp_angle(joints.Arm_A.rotation, contact_angle, contact_weight)
 near_hand = hand_position("Arm_A")

func shoulder() -> Vector2:
 return to_local(joints.Arm_A.global_position)

func aim_hand(target: Vector2, weight: float) -> void:
 var local_target: Vector2 = core.to_local(to_global(target)) - joints.Arm_A.position
 var tip: Vector2 = joints.Arm_A.to_local(artwork.Arm_A.get_node("Tip").global_position)
 contact_angle = local_target.angle() - tip.angle()
 contact_weight = weight
 update_pose()
