extends SceneTree
const Rig := preload("res://scenes/animation_studies/single_joint_pig.gd")
const Preview := preload("res://scenes/animation_studies/single_joint_preview.tscn")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
 if not value and not failures.has(message): failures.append(message)

func run() -> void:
 await process_frame
 var before: Dictionary = root.get_node("GameState").to_dictionary()
 var sample := Preview.instantiate()
 root.add_child(sample)
 sample.playing = false
 var pig = sample.pig
 check(Rig.LEFT_ARM=="far_arm" and Rig.LEFT_LEG=="far_leg","Left must be anatomical left in this view")
 check(pig.parts[Rig.RIGHT_ARM].material==null and pig.parts[Rig.RIGHT_LEG].material==null,"Cover applied to anatomical right by mistake")
 var source: Image = Rig.SHEET.get_image()
 check(source.has_mipmaps(),"Missing texture mipmaps")
 for key in Rig.REGIONS:
  var crop := source.get_region(Rect2i(Rig.REGIONS[key]))
  var used := crop.get_used_rect()
  check(used.position.x>0 and used.position.y>0 and used.end.x<crop.get_width() and used.end.y<crop.get_height(),"Cutout region clips painted edge: "+key)
 for key in Rig.ARM_PIVOTS:
  var pivot: Vector2 = Rig.ARM_PIVOTS[key]
  var hoof: Vector2 = Rig.HOOF_POINTS[key]
  check(source.get_pixelv(Vector2i(pivot)).a>0.95,"Shoulder anchor outside paint")
  check(source.get_pixelv(Vector2i(hoof)).a>0.95,"Hoof anchor outside paint")
 var previous_nut := Vector2.ZERO
 var previous_hands: Array[Vector2] = []
 for i in 1441:
  sample.time = i/120.0
  sample.evaluate()
  for key in Rig.ARM_PIVOTS:
   var part: Sprite2D = pig.parts[key]
   var texture: AtlasTexture = part.texture
   # Source-pixel endpoints through actual Sprite2D offsets and transforms.
   var painted_hoof: Vector2 = pig.core.transform*part.transform*(Rig.HOOF_POINTS[key]-texture.region.position+part.offset)
   var painted_shoulder: Vector2 = pig.core.transform*part.transform*(Rig.ARM_PIVOTS[key]-texture.region.position+part.offset)
   var expected_length: float = Rig.ARM_PIVOTS[key].distance_to(Rig.HOOF_POINTS[key])*Rig.ARM_SCALE
   check(absf(painted_hoof.distance_to(painted_shoulder)-expected_length)<0.0001,"Arm changes length")
   check(part.scale.is_equal_approx(Vector2.ONE*Rig.ARM_SCALE),"Arm stretched or mirrored")
   check(painted_shoulder.distance_to(pig.shoulder(key))<0.0001,"Arm detached from shoulder")
   var tip_source: Vector2 = pig.fingertip_source(key)
   var visible_tip: Vector2 = pig.core.transform*part.transform*(tip_source-texture.region.position+part.offset)
   check(source.get_pixelv(Vector2i(tip_source)).a>0.95,"Fingertip lies outside painted hoof")
   check(visible_tip.distance_to(pig.fingertip(key))<0.0001,"Hoof doesn't match visible texture")
  check(absf(pig.fingertip("near_arm").y-pig.fingertip("far_arm").y)<0.001,"Painted fingertips leave their shared horizontal plane")
  check(pig.parts.core.rotation==0 and pig.parts.core.scale.is_equal_approx(Vector2.ONE*Rig.CORE_SCALE),"Head/body transform changed internally")
  check(pig.near_foot.y<=0.001 and pig.far_foot.y<=-1.999,"Hoof goes through floor")
  if i>0:
   check(sample.nut.position.distance_to(previous_nut)<1.5,"Acorn jumps")
   check(pig.near_hand.distance_to(previous_hands[0])<0.7 and pig.far_hand.distance_to(previous_hands[1])<0.7,"Arm jumps")
  for name in Rig.LEG_PIVOTS:
   var leg: Sprite2D = pig.parts[name]
   var pivot: Vector2 = Rig.LEG_PIVOTS[name]
   var atlas: AtlasTexture = leg.texture
   var painted_hip: Vector2 = leg.to_global(pivot-atlas.region.position+leg.offset)
   var tuck: float = Rig.CROUCH_TUCK*pig.reach if name==Rig.LEFT_LEG else 0.0
   var body_hip: Vector2 = pig.core.to_global((Rig.HIP_POINTS[name]-Rig.CORE_PIVOT)*Rig.CORE_SCALE+Vector2(0,-tuck))
   check(painted_hip.distance_to(body_hip)<0.0001,"Leg retracts away from its vertical tuck path")
   check(leg.scale.is_equal_approx(Vector2.ONE*Rig.LEG_SCALE),"Leg changes size")
   check(leg.get_parent()==pig.core,"Leg does not inherit body bob")
   check(source.get_pixelv(Vector2i(Rig.HIP_POINTS[name])).a>0.95,"Hip attachment is outside torso")
   var endpoint: Vector2 = leg.to_global(Rig.SOLES[name][0]-atlas.region.position+leg.offset)
   var length: float = Rig.SOLES[name][0].distance_to(pivot)*Rig.LEG_SCALE*sample.FACTOR
   check(absf(endpoint.distance_to(painted_hip)-length)<0.0001,"Leg length changes during swing")
  check(pig.parts[Rig.RIGHT_LEG].z_index==1 and pig.parts[Rig.RIGHT_ARM].z_index==1,"Right limbs must be on layer 1")
  check(pig.parts.core.z_index==2,"Torso must be on layer 2")
  check(pig.parts[Rig.LEFT_LEG].z_index==3 and pig.parts[Rig.LEFT_ARM].z_index==3,"Left limbs must be on layer 3")
  previous_nut = sample.nut.position
  previous_hands = [pig.near_hand,pig.far_hand]
 sample.time=7.5
 sample.evaluate()
 check(sample.nut.position.distance_to(sample.ground_nut)<0.001,"Acorn changes owner before contact")
 # A visible whole-body lean; the left leg retracts inside rather than kicking out.
 sample.time=7.4
 sample.evaluate()
 check(pig.core.rotation>=deg_to_rad(15.5),"Pickup torso barely leans")
 check(pig.core.position.y+pig.sole_height(Rig.LEFT_LEG) < -8.0,"Left leg did not retract inside the belly")
 check(absf(pig.parts[Rig.LEFT_LEG].rotation+pig.core.rotation)<0.001,"Left leg kicks forward while crouching")
 check(absf(pig.parts[Rig.RIGHT_LEG].rotation+pig.core.rotation)<0.001,"Crouch reintroduces a forward lunge")
 check(is_equal_approx(pig.parts[Rig.LEFT_LEG].material.get_shader_parameter("cover_amount"),1.0),"Tucked leg must be hidden by torso")
 check(pig.parts[Rig.LEFT_ARM].material.get_shader_parameter("joint_radius")>=10.0,"Shoulder is not covered by torso")
 check(absf(pig.core.position.y+pig.sole_height(Rig.RIGHT_LEG))<0.4,"Right foot loses pickup support")
 # Half the previous belly-to-ground clearance, with unchanged leg artwork/length.
 pig.movement=0.0
 pig.reach=0.0
 pig.hold=0.0
 pig.update_pose()
 var belly_bottom: float = pig.core.position.y+(837.0-Rig.CORE_PIVOT.y)*Rig.CORE_SCALE
 check(absf(-belly_bottom-18.32*0.5)<0.01,"Resting belly clearance must halve")
 var top := INF
 var bottom := -INF
 pig.movement=1.0
 for frame in 241:
  pig.travel=Rig.STRIDE*float(frame)/240.0
  pig.update_pose()
  top=minf(top,pig.core.position.y)
  bottom=maxf(bottom,pig.core.position.y)
 check(bottom-top>7.0 and bottom-top<11.0,"Walk bounce must have a visible, bounded amplitude")
 pig.movement=0.0
 pig.update_pose()
 check(pig.bounce_height==0.0,"Bounce continues after stopping")
 # Input smoke: pause, step, replay. No story state may change.
 sample.time=2.0
 sample.playing=true
 var key := InputEventKey.new()
 key.pressed=true
 key.keycode=KEY_SPACE
 sample._unhandled_input(key)
 check(not sample.playing,"Pause failed")
 key.keycode=KEY_RIGHT
 sample._unhandled_input(key)
 check(is_equal_approx(sample.time,2.0+1.0/60.0),"Frame step failed")
 key.keycode=KEY_R
 sample._unhandled_input(key)
 check(sample.time==0 and sample.playing,"Replay failed")
 check(root.get_node("GameState").to_dictionary()==before,"Study changed story state")
 sample.queue_free()
 await process_frame
 if failures.is_empty():
  print("SINGLE_JOINT_PIG_OK 1441 poses; anatomical sides; left-leg tuck; shoulder cover; rigid limbs; layers 1/2/3; continuity; state isolation")
  quit()
 else:
  for failure in failures: push_error(failure)
  quit(1)
