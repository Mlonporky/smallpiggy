extends SceneTree
const Rig := preload("res://scenes/cabbage_act2/acorn_memory_rig.gd")
const SOURCE := "res://scenes/animation_studies/editable_pig.tscn"
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var saved := FileAccess.get_file_as_bytes(SOURCE)
 var rig := Rig.new()
 root.add_child(rig)
 var lengths: Dictionary = {}
 var sizes: Dictionary = {}
 for key in rig.LIMBS:
  sizes[key] = rig.artwork[key].scale
  lengths[key] = rig.artwork[key].get_node("Tip").position*rig.artwork[key].scale
 var previous_hand := Vector2.ZERO
 for i in 721:
  var t := float(i)/60.0
  rig.travel = 95.0*minf(t,4.0)
  rig.movement = sin(t/4.0*PI) if t<4.0 else 0.0
  rig.reach = smoothstep(4.0,5.2,t)*(1.0-smoothstep(5.5,6.6,t))
  rig.hold = smoothstep(5.5,6.6,t)
  rig.craft = smoothstep(7.0,7.5,t)
  rig.fasten = smoothstep(8.0,9.0,t)
  rig.release = smoothstep(10.0,10.7,t)
  rig.update_pose()
  for key in rig.LIMBS:
   var art: Sprite2D = rig.artwork[key]
   var joint: Node2D = rig.joints[key]
   assert(art.position == Vector2.ZERO,"Painted shoulder or hip must remain on its pivot")
   assert(art.scale.is_equal_approx(sizes[key]),"No stretched or shortened parts")
   var tip: Vector2 = rig.to_local(art.get_node("Tip").global_position)
   var pivot: Vector2 = rig.to_local(joint.global_position)
   assert(absf(tip.distance_to(pivot)-lengths[key].length()) < 0.01)
   var expected: Vector2 = rig.rest[key].origin
   if key == "Leg_A": expected.y -= 24.0*rig.reach
   assert(joint.position.distance_to(expected)<0.01,"Walking must never move hip or shoulder pivots")
  if t < 4.0:
   assert(absf(rig.finger_height("Arm_A")-rig.finger_height("Arm_B"))<0.3,"Actual fingertip outlines must stay level while walking")
  for key in ["Leg_A","Leg_B"]:
   assert(rig.sole_height(key)<0.02,"Feet must not pass below the ground")
  var body: Sprite2D = rig.core.get_node("Body")
  for point in rig.body_outline:
   assert(rig.to_local(body.to_global(point)).y < 0.02,"Leaning belly must remain above ground")
  var hand: Vector2 = rig.hand_position("Arm_A")
  if i > 0: assert(hand.distance_to(previous_hand)<8.0,"Continuous gesture required")
  previous_hand = hand
 assert(saved == FileAccess.get_file_as_bytes(SOURCE),"Preserve the user-edited source")
 print("ACORN_MEMORY_RIG_OK poses=721")
 quit()
