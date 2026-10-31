extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
const OUT="res://docs/art_direction/finale/reunion_v2/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 var source:=FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn")
 change_scene_to_file("res://scenes/finale/reunion_preview.tscn")
 for i in 3: await process_frame
 var film:=current_scene
 film.set_process(false)
 var rig: Node2D=film.pig.rig
 var transforms: Dictionary={}
 for key in rig.joints: transforms[key]=[rig.joints[key].position,rig.artwork[key].transform]
 for f in 337:
  film._arrival_pose(f/120.0)
  for key in transforms:
   assert(rig.joints[key].position==transforms[key][0] and rig.artwork[key].transform==transforms[key][1],"Detached or stretched body part")
  assert(absf(maxf(rig.sole_height("Leg_A"),rig.sole_height("Leg_B")))<.001,"Floating sole")
  if rig.brush==0: assert(absf(rig.finger_height("Arm_A")-rig.finger_height("Arm_B"))<.001)
 film._arrival_pose(1.02)
 print("BRUSH_TIP core_local=",rig.core.to_local(rig.to_global(rig.hand_position("Arm_B"))))
 for capture in [["pig_path",0.2],["pig_path",1.02],["pig_path",1.66],["someone",.7],["someone",4.3],["remember_name",1.0],["remember_pause",.4],["reunion_close",1.0]]:
  if capture[0]=="pig_path": film.enter_path("pig_path"); film._arrival_pose(capture[1])
  else:
   film.enter_beat(Story.index_of(capture[0]))
   film.beat_time=capture[1]
   film._animate(0)
  if DisplayServer.get_name()!="headless":
   await process_frame
   RenderingServer.force_draw(false)
   root.get_texture().get_image().save_png(OUT+capture[0]+"_"+str(capture[1])+".png")
 film.enter_beat(Story.index_of("someone"))
 film.beat_time=.7
 film._animate(0)
 assert(film.cabbage.position.x==1640,"Boy shown before attention pause")
 film.enter_beat(Story.index_of("remember_name"))
 film.beat_time=1
 film._animate(0)
 assert(film.cabbage.expression.tear>0)
 film.enter_beat(Story.index_of("remember_you"))
 assert(film.cabbage.expression.tear==0 and rig.attention==0 and rig.brush==0,"Expression leaked through skip")
 film._enter_shot(0)
 assert(film.curtain.color.a==1.0,"Preview must initialize its fade before first draw")
 film.beat_time=1
 film._arrival_pose(1)
 var frozen: float=rig.brush
 film._show_menu()
 film._process(.25)
 assert(film.beat_time==1 and rig.brush==frozen)
 film._resume()
 for i in 4000:
  if film.finished: break
  film._process(1.0/120)
 assert(film.finished and film.audio.paused)
 film._show_menu()
 film._resume()
 assert(film.audio.paused, "Closing finished preview menu resumed audio")
 var replay:=InputEventKey.new()
 replay.keycode=KEY_SPACE
 replay.pressed=true
 root.push_input(replay,true)
 assert(not film.finished and film.shot==0 and not film.audio.paused)
 film._process(.01)
 assert(film.audio.music_duck_target==1.0,"Arrival replay retained recognition ducking")
 assert(root.get_node("GameState").to_dictionary()==state)
 assert(FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn")==source)
 print("FINALE_REUNION_OK fixed_parts soles fingertips pause skip replay isolation")
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 quit()
