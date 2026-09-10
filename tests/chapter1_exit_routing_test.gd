extends SceneTree

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 await process_frame
 var state = root.get_node("GameState")
 state.reset()
 for flag in ["ch1_opening_done","bedroom_memory_complete","bedroom_exit_intro_done","kitchen_memory_complete","ch1_can_leave_home"]:
  state.set_flag(flag)
 change_scene_to_file("res://scenes/chapter1/bedroom.tscn")
 await process_frame
 await process_frame
 for step in [["kitchen","kitchen",Vector2(285,560)], ["living","living",Vector2(350,620)], ["kitchen","kitchen",Vector2(1140,565)], ["bedroom","bedroom",Vector2(1010,610)], ["kitchen","kitchen",Vector2(285,560)], ["living","living",Vector2(350,620)]]:
  current_scene.test_mode = true
  current_scene.ui.test_mode = true
  current_scene.travel(step[0])
  await root.get_node("SceneRouter").transition_finished
  assert(current_scene.room_id == step[1],"Wrong destination")
  assert(current_scene.player.position.distance_to(step[2]) < 2,"Wrong entrance position")
  assert(not current_scene.busy and current_scene.player.input_enabled,"Control not restored")
 current_scene.test_mode = true
 current_scene.travel("outside")
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.scene_file_path.ends_with("forest_clearing.tscn"),"Outside exit did not reach pig scene")
 print("CHAPTER1_EXIT_ROUTING_OK: real transitions bedroom ↔ kitchen ↔ living → outside, matching entrances and input")
 quit()
