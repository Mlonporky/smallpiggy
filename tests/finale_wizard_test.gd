extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
var film: Node
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 film.fx.queue_redraw()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/art_direction/finale/wizard_v2/"+label+".png")
func run() -> void:
 await process_frame
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/wizard_preview.tscn")
 for i in 4: await process_frame
 film=current_scene
 film.set_process(false)
 var actor: Node=film.wizard
 var joints: Dictionary={}
 var scales: Dictionary={}
 for key in actor.joints: joints[key]=actor.joints[key].position
 for key in actor.artwork: scales[key]=actor.artwork[key].scale
 var count:=0
 var previous: Vector2=Vector2.ZERO
 var maximum:=0.0
 var previous_dissolve:=0.0
 for id in ["wizard_return","protect","things_remain","memory_objects","final_curse","joy_failing","step_forward","reach_hand","hold_hands","shared_joy","hearts_return","joy_burst","wizard_dissolve"]:
  film.enter_beat(Story.index_of(id))
  var duration: float=Story.BEATS[film.beat][1]
  for i in range(int(duration*60)+1):
   film.beat_time=minf(duration,i/60.0)
   film._animate(1.0/60.0)
   for key in joints: assert(actor.joints[key].position==joints[key],"Shoulder moved")
   for key in scales: assert(actor.artwork[key].scale==scales[key],"Part stretched")
   assert(actor.hand_point("Arm_A").distance_to(actor.staff_grip())<0.001,"Staff detached from grip")
   var tip: Vector2=actor.staff_tip()
   if count>0: maximum=maxf(maximum,tip.distance_to(previous))
   previous=tip
   assert(actor.position.x<=275.01,"Wizard should recoil away from the wave")
   if id=="wizard_dissolve":
    assert(actor.dissolve>=previous_dissolve)
    previous_dissolve=actor.dissolve
   if id=="hold_hands" and film.beat_time>=1.8: assert(film.hand_contact)
   count+=1
  await capture(id)
 assert(maximum<2.0,"Discontinuous staff movement: "+str(maximum))
 assert(actor.dissolve==1 and actor.portal_strength==0)
 if DisplayServer.get_name()!="headless":
  film.enter_beat(Story.index_of("wizard_dissolve"))
  for at in [0.7,1.5,2.3]:
   film.beat_time=at
   film._animate(0)
   await capture("dissolve_"+str(at))
 # Direct saved-beat entry rebuilds the same shader state and fixed hand grip.
 film.enter_beat(Story.index_of("final_curse"))
 film.beat_time=2.2
 film._animate(0)
 var pose: Vector2=actor.staff_tip()
 film.enter_beat(Story.index_of("wizard_dissolve"))
 film.enter_beat(Story.index_of("final_curse"))
 film.beat_time=2.2
 film._animate(0)
 assert(pose.distance_to(actor.staff_tip())<0.001)
 var event:=InputEventKey.new()
 event.keycode=KEY_ESCAPE
 event.pressed=true
 root.push_input(event,true)
 film.set_process(true)
 await create_timer(.15).timeout
 assert(film.paused and film.beat_time==2.2)
 assert(pose.distance_to(actor.staff_tip())<0.001)
 assert(root.get_node("GameState").to_dictionary()==state)
 print("FINALE_WIZARD_OK samples=",count," max_staff_step=",maximum," dust=",actor.dust.size())
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 3: await process_frame
 quit()
