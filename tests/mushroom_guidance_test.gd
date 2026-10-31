extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/piggy-mushroom-guidance-"+label+".png")
func run() -> void:
 await process_frame
 var gs=root.get_node("GameState")
 gs.reset()
 change_scene_to_file("res://scenes/cabbage_act2/interior.tscn")
 for i in 5: await process_frame
 var room=current_scene
 assert(room.ui.prompt.text==room.HELP)
 gs.set_flag("wrapping_piece_1_found")
 assert(room.objective_text().contains("1 / 4"))
 for i in range(2,5): gs.set_flag("wrapping_piece_%d_found" % i)
 assert(room.objective_text()==room.TABLE_HELP)
 gs.set_flag("wrapping_puzzle_completed")
 assert(room.objective_text().contains("桌面机关"))
 gs.set_flag("mushroom_acorn_memory_seen")
 gs.set_flag("mushroom_table_puzzle_completed")
 gs.set_flag("mushroom_table_acorns_released")
 assert(room.objective_text().contains("红色纤维"))
 # A resumed investigation must explain the next interaction immediately.
 change_scene_to_file("res://scenes/cabbage_act2/interior.tscn")
 for i in 5: await process_frame
 room=current_scene
 assert(room.ui.prompt.text.contains("红色纤维"))
 await capture("fiber")
 gs.set_flag("mushroom_house_completed")
 gs.set_flag("mushroom_red_fiber_seen")
 await room.clear_objective_later()
 assert(room.ui.prompt.text.contains("下方门口"),"Old delayed hints cannot overwrite completed investigation")
 await capture("door")
 assert(gs.gift_fragments.is_empty() and gs.heart_progress==0)
 print("MUSHROOM_GUIDANCE_OK: fresh, partial, completed paper, memory, reload, final doorway")
 quit()
