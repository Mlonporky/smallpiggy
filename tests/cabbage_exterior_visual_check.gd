extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 await process_frame
 for place in ["villa","path","mushroom"]:
  change_scene_to_file("res://scenes/cabbage_act2/"+place+".tscn")
  await process_frame
  await process_frame
  current_scene.player.set_input_enabled(false)
  await create_timer(0.5).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/cabbage-"+place+".png")
 print("CABBAGE_EXTERIOR_VISUAL_OK")
 quit()
