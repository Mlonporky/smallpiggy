extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
var gs: Node
var saves: Node
func _initialize() -> void: call_deferred("run")
func frames(n:=3) -> void:
 for i in n: await process_frame
func key(code: int, pressed:=true) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=pressed
 root.push_input(event,true)
func tap(code: int) -> void:
 key(code)
 await process_frame
 key(code,false)
 await frames()
func fresh(path: String) -> Node:
 change_scene_to_file(path)
 await frames()
 return current_scene
func capture(label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/finale-"+label+".png")
func run() -> void:
 await process_frame
 gs=root.get_node("GameState")
 saves=root.get_node("SaveManager")
 saves.save_path="/tmp/finale-test-"+DisplayServer.get_name()+".json"
 gs.reset()
 gs.set_flag("unrelated_user_progress")
 var original: Dictionary=gs.to_dictionary()
 var scene=await fresh("res://scenes/finale/final_chapter_preview.tscn")
 assert(scene.preview and scene.mode=="pig_path")
 assert(not scene.reunion_ready())
 scene.set_process(false)
 Input.action_press("move_right")
 for i in 3600:
  if scene.mode=="cinematic": break
  scene._process(1.0/60.0)
 Input.action_release("move_right")
 assert(scene.mode=="cinematic" and scene.current_id()=="someone",scene.mode)
 assert(gs.to_dictionary()==original)
 scene.set_process(true)
 await tap(KEY_ESCAPE)
 var t: float=scene.beat_time
 await create_timer(0.1).timeout
 assert(scene.paused and scene.beat_time==t)
 await tap(KEY_ESCAPE)
 assert(not scene.paused)
 scene.set_process(false)
 # The secret, recognition, curse and completion must occur in order through input.
 for i in Story.BEATS.size():
  assert(scene.beat==i,"Unexpected beat at "+str(i))
  var id: String=Story.BEATS[i][0]
  if id=="secret_phrase": assert(not scene.has("cabbage_memory_restored"))
  if id=="memory_house": assert(scene.has("cabbage_memory_restored"))
  if id=="wizard_dissolve": assert(not scene.has("curse_broken"))
  if id=="curse_broken": assert(scene.has("curse_broken") and scene.has("wizard_defeated"))
  if id in ["first_reunion","remember_you","hold_hands","wizard_dissolve","manor_restore","home_promise","the_end","credits"]:
   scene.beat_time=0.8 if id!="manor_restore" else 8
   scene._animate(0.016)
   scene.fx.queue_redraw()
   await capture(id)
  if id=="return_home":
   scene.pig.position=Vector2(898,626)
   scene._animate(0.016)
  elif id!="credits":
   scene.beat_time=float(Story.BEATS[i][1])+0.02
   await tap(KEY_E)
 assert(scene.has("ending_completed"))
 assert(gs.to_dictionary()==original,"Preview must never mutate any story state")
 # A story entry without both branches cannot start recognition.
 gs.reset()
 gs.set_flag("cave_level_completed")
 scene=await fresh("res://scenes/finale/final_chapter.tscn")
 assert(scene.mode=="pig_path" and not scene.reunion_ready())
 assert(not gs.has_flag("cabbage_memory_restored"))
 # Resume saves at key beats, including after completion, in an isolated save slot.
 gs.set_flag("mushroom_house_completed")
 gs.set_flag("finale_pig_path_done")
 gs.set_flag("finale_cabbage_path_done")
 scene=await fresh("res://scenes/finale/final_chapter.tscn")
 assert(scene.mode=="reunion_walk")
 scene.enter_beat(Story.index_of("memory_house"))
 assert(gs.cabbage_emotional_state==gs.CabbageEmotionalState.MEMORY_RETURNED)
 assert(gs.has_flag("cabbage_memory_restored") and not gs.has_flag("curse_broken"))
 gs.reset()
 assert(saves.load_game()=="res://scenes/finale/final_chapter.tscn")
 scene=await fresh("res://scenes/finale/final_chapter.tscn")
 assert(scene.current_id()=="memory_house")
 scene.enter_beat(Story.index_of("curse_broken"))
 assert(gs.has_flag("curse_broken") and gs.has_flag("wizard_defeated"))
 assert(not gs.has_flag("ending_completed"))
 scene.enter_beat(Story.index_of("credits"))
 assert(gs.has_flag("ending_completed") and gs.story_phase==gs.StoryPhase.COMPLETED)
 gs.reset()
 saves.load_game()
 scene=await fresh("res://scenes/finale/final_chapter.tscn")
 assert(scene.current_id()=="credits")
 # Disk failure must remain visible and must not exit to the menu.
 saves.save_path="/tmp/nonexistent-finale-folder/save.json"
 scene._show_menu()
 scene._save_and_exit()
 assert(scene.save_error and scene.menu_note.text.contains("保存失败"))
 # Source atlas must remain intact; real alpha is required for the handhold art.
 var pair: Image=scene.PAIR.get_image()
 assert(pair.get_pixel(0,0).a==0,"Handhold key pose needs transparency")
 print("FINALE_TEST_OK")
 await fresh("res://scenes/bootstrap/main.tscn")
 await frames()
 quit()
