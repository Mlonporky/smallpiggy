extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var reference:=preload("res://scenes/cabbage_act2/acorn_memory_rig.gd").new()
 var fast:=preload("res://scenes/finale/finale_pig_rig.gd").new()
 root.add_child(reference)
 root.add_child(fast)
 var maximum:=0.0
 for i in 721:
  for rig in [reference,fast]:
   rig.travel=i*.73
   rig.movement=.7
   rig.reach=sin(i*.02)*.4+.4
   rig.hold=maxf(0,sin(i*.04))
   rig.craft=maxf(0,cos(i*.03))
   rig.fasten=maxf(0,sin(i*.01))
   rig.release=maxf(0,cos(i*.01))
   rig.update_pose()
  for limb in ["Arm_A","Arm_B","Leg_A","Leg_B"]:
   maximum=maxf(maximum,absf(fast.joints[limb].rotation-reference.joints[limb].rotation))
   assert(fast.joints[limb].position.distance_to(reference.joints[limb].position)<.001)
  assert(fast.core.position.distance_to(reference.core.position)<.001)
 assert(maximum<.0001,"Optimized solver changed the pose: "+str(maximum))
 # Same work/phase inputs; timings describe only the pose routine, not frame rate.
 var timings: Array=[]
 for rig in [reference,fast]:
  rig.reach=0
  rig.hold=0
  rig.craft=0
  rig.fasten=0
  rig.release=0
  rig.update_pose()
  var start:=Time.get_ticks_usec()
  for i in 1000:
   rig.travel=i*.73
   rig.update_pose()
  timings.append((Time.get_ticks_usec()-start)/1000.0)
 print("FINALE_RIG_EQUIVALENT samples=721 max_radians=",maximum," 1000_pose_ms=",timings)
 var out:=FileAccess.open("res://docs/art_direction/finale/residents_v1/rig_solver_comparison.json",FileAccess.WRITE)
 out.store_string(JSON.stringify({"samples":721,"max_radians":maximum,"reference_1000_ms":timings[0],"cached_1000_ms":timings[1]},"  "))
 out.close()
 reference.queue_free()
 fast.queue_free()
 await process_frame
 quit()
