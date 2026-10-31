extends SceneTree
const PREVIEW = preload("res://scenes/animation_studies/editable_pig_preview.tscn")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
 if not ok and not failures.has(message): failures.append(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var scene_text := FileAccess.get_file_as_string("res://scenes/animation_studies/editable_pig.tscn")
 var before: Dictionary = root.get_node("GameState").to_dictionary()
 var workshop = load("res://scenes/animation_studies/editable_pig.tscn").instantiate()
 root.add_child(workshop)
 var reference = workshop.get_node("Pig")
 var preview = PREVIEW.instantiate()
 root.add_child(preview)
 preview.playing = false
 var pig = preview.pig
 preview.time = 0.0
 preview.evaluate()
 # Actual sprite pixels, not just joint transforms, must match the saved scene.
 for name in ["Arm_A", "Arm_B", "Leg_A", "Leg_B"]:
  var original = reference.get_node("BodyPivot/" + name + "/Artwork")
  var current = pig.artwork[name]
  for point in [Vector2.ZERO, Vector2(20,30), Vector2(-40,150)]:
   var expected: Vector2 = reference.get_node("BodyPivot").to_local(original.to_global(point))
   var actual: Vector2 = pig.core.to_local(current.to_global(point))
   check(expected.distance_to(actual)<0.001, "Rest artwork changed: " + name)
 var prev_nut: Vector2 = preview.nut.position
 var prev_tip: Vector2 = pig.far_hand
 var max_nut_delta := 0.0
 for frame in 1441:
  preview.time = frame/120.0
  preview.evaluate()
  for name in ["Arm_A", "Arm_B", "Leg_A", "Leg_B"]:
   var joint = pig.joints[name]
   var art = pig.artwork[name]
   var original = reference.get_node("BodyPivot/" + name)
   check(joint.global_position.distance_to(art.global_position)<0.0001, "Painted joint detached: " + name)
   check(art.scale.is_equal_approx(original.get_node("Artwork").scale), "Artwork stretched: " + name)
   check(joint.z_index==original.z_index, "Saved layer overwritten: " + name)
   var resting: Transform2D = pig.rest[name]
   var expected_pos: Vector2 = resting.origin
   if name=="Leg_A": expected_pos.y -= 12.0*pig.reach
   check(joint.position.distance_to(expected_pos)<0.001, "Joint migrated: " + name)
  check(maxf(pig.sole_height("Leg_A"),pig.sole_height("Leg_B"))<=pig.baseline_floor+0.001, "Foot penetrates floor")
  max_nut_delta = maxf(max_nut_delta, preview.nut.position.distance_to(prev_nut))
  check(pig.far_hand.distance_to(prev_tip)<1.0, "Hand jumps")
  prev_nut = preview.nut.position
  prev_tip = pig.far_hand
 check(max_nut_delta<1.5,"Prop jumps")
 preview.time=7.5
 preview.evaluate()
 check(preview.nut.position.distance_to(preview.ground_nut)<0.001,"Transfer before contact")
 check(root.get_node("GameState").to_dictionary()==before,"Story state changed")
 check(FileAccess.get_file_as_string("res://scenes/animation_studies/editable_pig.tscn")==scene_text,"User scene modified")
 if failures.is_empty(): print("USER_ASSEMBLY_MOTION_OK: saved sprite geometry/layers; 1441 poses; shoulder/hip pivots; rigid parts; no floor penetration; continuous prop transfer; source/state untouched")
 else:
  for failure in failures: push_error(failure)
 quit(0 if failures.is_empty() else 1)
