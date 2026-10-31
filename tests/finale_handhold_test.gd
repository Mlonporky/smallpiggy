extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
const Motion=preload("res://scenes/finale/handhold_motion.gd")
var film: Node
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/art_direction/finale/handhold_v2/"+label+".png")
func run() -> void:
 await process_frame
 var source_before:=FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn")
 var original: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/handhold_preview.tscn")
 for i in 3: await process_frame
 film=current_scene
 film.set_process(false)
 var previous: Array[Vector2]=[]
 var max_step:=0.0
 var rigid: Dictionary={}
 for actor in [film.pig,film.cabbage]:
  for key in ["Arm_A","Arm_B","Leg_A","Leg_B"]:
   rigid[str(actor.get_instance_id())+key]=[actor.rig.joints[key].position,actor.rig.artwork[key].scale]
 var response_start:=Vector2.ZERO
 var pause_hand:=Vector2.ZERO
 var samples:=0
 for id in ["step_forward","reach_hand","hold_hands","shared_joy"]:
  film.enter_beat(Story.index_of(id))
  var duration: float=Story.BEATS[film.beat][1]
  for i in range(int(duration*120)+1):
   film.beat_time=minf(duration,i/120.0)
   film._animate(1.0/120.0)
   var hands: Array[Vector2]=[film.pig.hand_world(),film.cabbage.hand_world()]
   if not previous.is_empty():
    for j in 2: max_step=maxf(max_step,previous[j].distance_to(hands[j]))
   previous=hands
   for actor in [film.pig,film.cabbage]:
    for key in ["Arm_A","Arm_B","Leg_A","Leg_B"]:
     var saved: Array=rigid[str(actor.get_instance_id())+key]
     assert(actor.rig.joints[key].position.is_equal_approx(saved[0]),"Joint moved: "+key)
     assert(actor.rig.artwork[key].scale.is_equal_approx(saved[1]),"Part stretched: "+key)
   var joined: bool=id=="shared_joy" or (id=="hold_hands" and film.beat_time>=1.8)
   assert(film.hand_contact==joined,"Contact flag timing")
   if joined: assert(hands[0].distance_to(hands[1])<0.05,"Hands separated: "+str(hands))
   if id=="hold_hands" and i==0:
    pause_hand=hands[0]
    response_start=hands[1]
   if id=="hold_hands" and film.beat_time<=0.8:
    assert(hands[0].distance_to(pause_hand)<0.05,"Pig moved before response pause")
    assert(hands[1].distance_to(response_start)<0.05,"Cabbage did not hold out its hand")
    assert(hands[0].distance_to(hands[1])>8.0,"Already touching during pause")
   samples+=1
  film.fx.queue_redraw()
  await capture(id)
 assert(max_step<1.4,"Discontinuous gesture: "+str(max_step))
 # A direct checkpoint entry must show the same pose as sequential playback.
 var held_pig: Vector2=film.pig.hand_world()
 var held_cabbage: Vector2=film.cabbage.hand_world()
 film.enter_beat(Story.index_of("first_reunion"))
 film.enter_beat(Story.index_of("shared_joy"))
 assert(held_pig.distance_to(film.pig.hand_world())<0.05)
 assert(held_cabbage.distance_to(film.cabbage.hand_world())<0.05)
 # Real UI pause freezes the chapter's clock and hands; no rig runs autonomously.
 film.enter_beat(Story.index_of("hold_hands"))
 film.beat_time=1.2
 film._animate(0)
 var held: Vector2=film.pig.hand_world()
 var key:=InputEventKey.new()
 key.keycode=KEY_ESCAPE
 key.pressed=true
 root.push_input(key,true)
 film.set_process(true)
 await create_timer(0.12).timeout
 assert(film.paused and film.beat_time==1.2)
 assert(held.distance_to(film.pig.hand_world())<0.05)
 assert(root.get_node("GameState").to_dictionary()==original)
 assert(FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn")==source_before)
 print("FINALE_HANDHOLD_OK samples=",samples," max_hand_step=",max_step)
 film.queue_free()
 await process_frame
 quit()
