extends "res://tests/action_route_test.gd"
## Graphical regression: deliberately suppress rendering to exercise screenshot timeouts.
func run() -> void:
 await process_frame
 if DisplayServer.get_name() == "headless":
  push_error("This test requires a graphical backend")
  quit(1)
  return
 root.get_node("GameState").reset()
 root.get_node("GameState").set_flag("cave_level_completed")
 change_scene_to_file("res://scenes/finale/final_chapter.tscn")
 while not is_instance_valid(current_scene): await process_frame
 for i in 30: await process_frame
 RenderingServer.render_loop_enabled = false
 var before := RenderingServer.get_signal_connection_list("frame_post_draw").size()
 await capture("cleanup-a")
 await capture("cleanup-b")
 var after := RenderingServer.get_signal_connection_list("frame_post_draw").size()
 print("CAPTURE_PENDING before=",before," after=",after)
 if after != before:
  push_error("Screenshot timeouts must release pending draw callbacks")
  quit(1)
  return
 print("ROUTE_CAPTURE_CLEANUP_OK")
 # Exit with rendering disabled, matching the controlled failing reproduction.
 quit()
