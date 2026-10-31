extends SceneTree
## Sample actual production boundaries, including same-shot continuity and input travel.
const Story=preload("res://scenes/finale/finale_story.gd")
const OUT="res://docs/verification/motion_2026-10-31/"
var results: Array[Dictionary]=[]

func _initialize() -> void: call_deferred("run")

func run() -> void:
 await process_frame
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 var film=load("res://scenes/finale/final_chapter_preview.tscn").instantiate()
 root.add_child(film)
 film.set_process(false)
 # Consecutive dialogue/acting beats in the same setup may not teleport actors,
 # change camera scale, or snap an arm because the previous walk phase differed.
 for pair in [["someone","reunion_silence"],["reunion_silence","first_reunion"],
  ["reunion_close","close_name"],["reunion_rest","wizard_return"],
  ["wizard_return","protect"],["joy_failing","step_forward"],
  ["step_forward","reach_hand"],["reach_hand","hold_hands"],
  ["hold_hands","shared_joy"],["wizard_dissolve","curse_broken"],
  ["home_seek","walk_away"],["walk_away","final_secret"],["final_reply","leave_frame"]]:
  film.enter_beat(Story.index_of(pair[0]))
  film.beat_time=float(Story.BEATS[film.beat][1])
  film._animate(0)
  var before: Array[Vector2]=[film.pig.position,film.cabbage.position,film.world.position,film.world.scale,film.pig.hand_world()]
  film.enter_beat(Story.index_of(pair[1]))
  var after: Array[Vector2]=[film.pig.position,film.cabbage.position,film.world.position,film.world.scale,film.pig.hand_world()]
  var maximum:=0.0
  for i in before.size(): maximum=maxf(maximum,before[i].distance_to(after[i]))
  assert(maximum<.05,"Boundary jump: "+str(pair)+" "+str(maximum))
  results.append({"boundary":str(pair),"maximum_step":maximum})
 # Camera pushes have eased endpoints and stay bounded at both playback speeds.
 for speed in [1.0,1.5]:
  root.get_node("AppSettings").story_speed=speed
  for id in ["first_reunion","wizard_return","walk_away","leave_frame"]:
   film.enter_beat(Story.index_of(id))
   var previous: Vector2=film.pig.global_position
   var maximum:=0.0
   var duration: float=Story.BEATS[film.beat][1]
   for i in range(1,ceili(duration*60/speed)+1):
    film.beat_time=minf(duration,i*speed/60)
    film._animate(speed/60)
    var point: Vector2=film.pig.global_position
    maximum=maxf(maximum,point.distance_to(previous))
    previous=point
   assert(maximum<12,"Discontinuous motion: "+id+" "+str(maximum))
   results.append({"motion":id,"speed":speed,"max_screen_root_step_60fps":maximum})
  # Real input follows the return path through the arrival into dialogue.
  film.enter_beat(Story.index_of("return_home"))
  Input.action_press("move_right")
  var last_pig: Vector2
  var last_cabbage: Vector2
  for i in 900:
   last_pig=film.pig.position
   last_cabbage=film.cabbage.position
   film._process(1.0/60)
   if film.current_id()!="return_home": break
  Input.action_release("move_right")
  assert(film.current_id()=="home_here","Arrival did not complete")
  var jump: float=maxf(last_pig.distance_to(film.pig.position),last_cabbage.distance_to(film.cabbage.position))
  assert(jump<.05,"Return-home teleport: "+str(jump))
  results.append({"motion":"return_home_to_dialogue","speed":speed,"maximum_step":jump})
 # The new background is first shown under the same full curtain as the old one.
 film.enter_beat(Story.index_of("light_travels"))
 film.beat_time=3.5
 film._animate(0)
 assert(film.curtain.color.a==1)
 film.enter_beat(Story.index_of("manor_restore"))
 assert(film.curtain.color.a==1)
 film.enter_beat(Story.index_of("walk_away"))
 film.beat_time=.6
 film._animate(0)
 var paused_hand: Vector2=film.pig.hand_world()
 film.paused=true
 film._process(.4)
 assert(film.beat_time==.6 and film.pig.hand_world()==paused_hand)
 film.paused=false
 film.enter_beat(Story.index_of("walk_away"))
 film.beat_time=.6
 film._animate(0)
 assert(film.pig.hand_world().distance_to(paused_hand)<.001,"Seek/replay changed pose")
 film.flags["finale_pig_path_done"]=true
 film.enter_path("cabbage_path")
 film.path_distance=2699
 Input.action_press("move_right")
 film._process(1.0/60)
 Input.action_release("move_right")
 assert(film.mode=="reunion_walk" and film.curtain.color.a==1,"Path swap revealed a bright frame")
 film._process(1.0/60)
 assert(film.curtain.color.a>0 and film.curtain.color.a<1)
 assert(root.get_node("GameState").to_dictionary()==state)
 # Cards dissolve both into one another and back to the live actors.
 film.enter_beat(Story.index_of("memory_house"))
 film.beat_time=1
 film._animate(0)
 var outgoing: Texture2D=film.memory.texture
 film.enter_beat(Story.index_of("memory_together"))
 assert(film.previous_memory.texture==outgoing and film.previous_memory.modulate.a==1)
 assert(film.memory.modulate.a==0 and film.memory_shade.modulate.a==1)
 film.beat_time=.12
 film._animate(0)
 assert(is_equal_approx(film.previous_memory.modulate.a,.5) and is_equal_approx(film.memory.modulate.a,.5))
 film.beat_time=.24
 film._animate(0)
 film.enter_beat(Story.index_of("remember_name"))
 assert(film.previous_memory.modulate.a==1 and film.memory_shade.modulate.a==1)
 film.beat_time=.24
 film._animate(0)
 assert(not film.previous_memory.visible and not film.memory_shade.visible)
 film.queue_free()
 await process_frame
 # Continuous opening plates keep camera and brightness through the boundary.
 var opening=load("res://scenes/prologue/prologue.tscn").instantiate()
 opening.autoplay=false
 opening.route_on_finish=false
 root.add_child(opening)
 for index in [5,7]:
  opening.set_shot(index,opening.shots[index].duration)
  var transform: Transform2D=opening.picture.get_transform()
  assert(opening.shade.color.a==0)
  opening.set_shot(index+1,0)
  assert(opening.picture.get_transform().is_equal_approx(transform))
  assert(opening.shade.color.a==0,"Black dip inside continuous action")
  assert(opening.effects.particle_clock==float(opening.shots[index].duration))
 opening.queue_free()
 await process_frame
 FileAccess.open(OUT+"transitions.json",FileAccess.WRITE).store_string(JSON.stringify(results,"  "))
 print("MOTION_TRANSITION_OK same-shot boundaries, 1x/1.5x, input arrival, replay, pause, opening")
 quit()
