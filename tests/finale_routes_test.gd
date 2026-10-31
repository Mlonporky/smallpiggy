extends SceneTree
func _initialize() -> void: call_deferred("run")
func frames(n:=4) -> void:
 for i in n: await process_frame
func fresh(path: String) -> Node:
 change_scene_to_file(path)
 await frames()
 return current_scene
func run() -> void:
 await process_frame
 var gs:=root.get_node("GameState")
 var saves:=root.get_node("SaveManager")
 saves.save_path="/tmp/finale-routes-save.json"
 gs.reset()
 var room=await fresh("res://scenes/cabbage_act2/interior.tscn")
 room.story.test_mode=true
 # Red fibre requires the opened table's completed memory; no premature flags.
 await room.inspect_red_fiber()
 assert(not gs.has_flag("mushroom_house_completed"))
 gs.set_flag("mushroom_acorn_memory_seen")
 gs.set_flag("mushroom_table_puzzle_completed")
 var lines: Array=[]
 room.story.dialogue.line_started.connect(func(line): lines.append(line.text))
 await room.inspect_red_fiber()
 assert(gs.has_flag("mushroom_red_fiber_seen") and gs.has_flag("mushroom_house_completed"))
 assert(not gs.has_flag("cabbage_memory_restored"))
 assert(lines==["怎么会有这么多橡子……","红色的……","怎么觉得心里怪怪的。"])
 room.leave()
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.mode=="cabbage_path")
 current_scene.set_process(false)
 Input.action_press("move_right")
 for i in 965: current_scene._process(1.0/60)
 Input.action_release("move_right")
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.scene_file_path.ends_with("dark_path/dark_path.tscn"))
 assert(gs.has_flag("finale_cabbage_path_done"))
 # Exercise the actual fall handoff without repeating the already tested approach.
 current_scene._set_phase(current_scene.Phase.FALL)
 current_scene.phase_time=2.49
 for i in 20: await physics_frame
 assert(current_scene.scene_file_path.ends_with("story_cave.tscn"))
 var cave=current_scene
 for enemy in cave.enemies: assert(enemy.position.x<6900,"Last climb must have no enemies")
 # Seed a grounded last-platform arrival; this is a route test, not a full platform playthrough.
 cave.player.reset_at(Vector2(7470,630))
 for i in 120:
  await physics_frame
  if not is_instance_valid(cave) or current_scene!=cave: break
 if root.get_node("SceneRouter").is_busy(): await root.get_node("SceneRouter").transition_finished
 assert(gs.has_flag("cave_level_completed"))
 assert(current_scene.scene_file_path.ends_with("final_chapter.tscn"))
 assert(current_scene.mode=="pig_path")
 current_scene.set_process(false)
 Input.action_press("move_right")
 for i in 2400:
  if current_scene.mode=="cinematic": break
  current_scene._process(1.0/60)
 Input.action_release("move_right")
 assert(current_scene.current_id()=="someone")
 assert(not gs.has_flag("cabbage_memory_restored"))
 # Finishing the standalone level must still leave GameState untouched.
 var before: Dictionary=gs.to_dictionary()
 var independent=await fresh("res://scenes/action_test/test_level.tscn")
 independent.player.reset_at(Vector2(7470,630))
 for i in 45: await physics_frame
 assert(independent.finished and gs.to_dictionary()==before)
 # Alternate order: leave the mushroom house before finishing its investigation.
 # Cave completion must send the boy back to finish his clues, not dead-end.
 gs.reset()
 gs.set_flag("cave_level_completed")
 var early=await fresh("res://scenes/finale/final_chapter.tscn")
 assert(early.mode=="pig_path")
 early.set_process(false)
 Input.action_press("move_right")
 for i in 2400:
  if early._pending_route: break
  early._process(1.0/60)
 Input.action_release("move_right")
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.scene_file_path.ends_with("cabbage_act2/interior.tscn"))
 assert(gs.has_flag("finale_pig_path_done") and not gs.has_flag("mushroom_house_completed"))
 gs.reset()
 assert(saves.load_game().ends_with("cabbage_act2/interior.tscn"))
 assert(gs.has_flag("finale_pig_path_done"))
 # Puzzle mechanics are exercised separately; seed only their completion here.
 gs.set_flag("mushroom_acorn_memory_seen")
 current_scene.story.test_mode=true
 await current_scene.inspect_red_fiber()
 current_scene.leave()
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.mode=="cabbage_path")
 current_scene.set_process(false)
 Input.action_press("move_right")
 for i in 1800:
  if current_scene.mode=="cinematic": break
  current_scene._process(1.0/60)
 Input.action_release("move_right")
 assert(current_scene.current_id()=="someone" and current_scene.reunion_ready())
 print("FINALE_ROUTES_OK: both investigation orders, unfinished clues return, saved role handoff, standalone isolation")
 quit()
