extends Node2D
## Load the user's saved assembly. Only this runtime copy receives motion.
const ASSEMBLY := preload("res://scenes/animation_studies/editable_pig.tscn")
const STRIDE := 44.0
const WALK_BOUNCE := 8.5
const PICKUP_LEAN := deg_to_rad(16.0)
const LIMBS := ["Arm_A", "Arm_B", "Leg_A", "Leg_B"]
const SOLES := {
 "Leg_A": [Vector2(1164, 771), Vector2(1228, 774)],
 "Leg_B": [Vector2(1462, 773), Vector2(1528, 774)]}
var assembly: Node2D
var core: Node2D
var joints: Dictionary = {}
var artwork: Dictionary = {}
var rest: Dictionary = {}
var rest_core: Transform2D
var baseline_floor := 0.0
var near_hand := Vector2.ZERO
var far_hand := Vector2.ZERO
var travel := 0.0
var movement := 0.0
var reach := 0.0
var hold := 0.0
var bounce_height := 0.0

func _ready() -> void:
 var workshop := ASSEMBLY.instantiate()
 assembly = workshop.get_node("Pig")
 workshop.remove_child(assembly)
 texture_filter = workshop.texture_filter
 workshop.free()
 # The workshop's translation and zoom are presentation, not limb dimensions.
 assembly.position = Vector2.ZERO
 assembly.scale = Vector2.ONE
 add_child(assembly)
 core = assembly.get_node("BodyPivot")
 for key in LIMBS:
  var joint: Node2D = core.get_node(key)
  var art: Sprite2D = joint.get_node("Artwork")
  # The cutouts were authored with their painted shoulder/hip at local (0,0).
  # Moving Artwork in the editor can separate that point from its Marker2D.
  # Recenter the runtime pivot without changing any painted pixel's rest pose.
  joint.position = joint.transform * art.position
  art.position = Vector2.ZERO
  joints[key] = joint
  artwork[key] = art
  rest[key] = joint.transform
 rest_core = core.transform
 baseline_floor = maxf(sole_height("Leg_A"), sole_height("Leg_B"))
 assembly.position.y = -baseline_floor
 baseline_floor = 0.0
 update_pose()

func painted_point(key: String, source: Vector2) -> Vector2:
 var art: Sprite2D = artwork[key]
 var atlas: AtlasTexture = art.texture
 var local_point := source - atlas.region.position + art.offset
 if art.centered:
  local_point -= atlas.region.size * 0.5
 return to_local(art.to_global(local_point))

func sole_height(key: String) -> float:
 var lowest := -INF
 for source in SOLES[key]:
  lowest = maxf(lowest, painted_point(key, source).y)
 return lowest

func hand_position(key: String) -> Vector2:
 return to_local(artwork[key].get_node("Tip").global_position)

func update_pose() -> void:
 if joints.is_empty():
  return
 core.transform = rest_core
 for key in LIMBS:
  joints[key].transform = rest[key]
 var gait := sin((travel / STRIDE + 0.1) * TAU)
 var lean := PICKUP_LEAN * reach
 core.rotation += lean
 # Fixed hips throughout walking. Preserve the saved sizes and rest angles.
 joints.Leg_A.rotation += gait * 0.28 * movement - lean
 joints.Leg_B.rotation += -gait * 0.28 * movement - lean
 # A is behind the torso in the saved assembly. It retracts on the spot while
 # the visible B leg supports the lean; no anatomical left/right is inferred.
 joints.Leg_A.position.y -= 12.0 * reach
 joints.Arm_A.rotation += -gait * 0.14 * movement - 1.1 * reach - 1.1 * hold
 joints.Arm_B.rotation += gait * 0.14 * movement - 0.28 * hold
 bounce_height = WALK_BOUNCE * pow(cos((travel / STRIDE + 0.1) * TAU), 2) * movement
 var floor_now := maxf(sole_height("Leg_A"), sole_height("Leg_B"))
 core.position.y += baseline_floor - floor_now - bounce_height
 near_hand = hand_position("Arm_A")
 far_hand = hand_position("Arm_B")
