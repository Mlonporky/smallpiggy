extends SceneTree
func _initialize() -> void: call_deferred("_run")
func capture(name: String) -> void:
 await RenderingServer.frame_post_draw
 print("CAPTURE: "+name)
 root.get_texture().get_image().save_png("/private/tmp/"+name+".png")
func _run() -> void:
 await process_frame
 root.size = Vector2i(1152,648)
 var state = root.get_node("GameState")
 state.reset()
 state.set_flag("ch1_opening_done")
 var index := 0
 for id in ["bedroom","kitchen","living"]:
  index += 1
  var scene = load("res://scenes/chapter1/%s.tscn" % id).instantiate()
  scene.auto_exit_enabled = false
  scene.route_on_exit = false
  root.add_child(scene)
  await process_frame
  scene.lines = {}
  if id == "bedroom": scene.player.position = Vector2(590,465)
  scene.lock(true)
  scene.memory_beat(index)
  await create_timer(0.8).timeout
  await capture("memory_clear_"+str(index))
  await create_timer(3.0).timeout
  if id == "kitchen":
   scene.ui.inspect(preload("res://assets/chapter1/cabbage_bowl_hd.png"),preload("res://assets/chapter1/pig_bowl_hd.png"))
   await process_frame
   await capture("dishes_hd_pair")
   scene.ui.inspecting = false
   await process_frame
  if id == "living":
   scene.ui.inspect(preload("res://assets/chapter1/pillow_plush_hd.png"))
   await process_frame
   await capture("pillow_plush_closeup")
   scene.ui.inspecting = false
   await process_frame
   scene.ui.inspect(preload("res://assets/chapter1/gift_fragment_hd.png"))
   await process_frame
   await capture("gift_fragment_closeup")
   scene.ui.inspecting = false
   await process_frame
  scene.queue_free()
  await process_frame
 print("PROPS_VISUAL_OK")
 quit()
