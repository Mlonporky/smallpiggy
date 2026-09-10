extends SceneTree

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 await process_frame
 root.size = Vector2i(1152,768)
 var state = root.get_node("GameState")
 var folder := "/private/tmp/piggy-exploration-light"
 DirAccess.make_dir_recursive_absolute(folder)
 for id in ["bedroom","kitchen","living"]:
  state.reset()
  state.set_flag("ch1_opening_done")
  var scene = load("res://scenes/chapter1/%s.tscn" % id).instantiate()
  scene.test_mode = true
  scene.route_on_exit = false
  scene.auto_exit_enabled = false
  root.add_child(scene)
  await create_timer(1.3).timeout
  await capture(folder+"/"+id+".png")
  if id == "kitchen":
   scene.ui.show_closeup(SpriteAtlas.frame(scene.get_node("Background").texture,Rect2(545,670,355,165)))
   await capture(folder+"/new_tableware_closeup.png")
   scene.ui.hide_closeup()
   scene.ui.show_closeup(preload("res://assets/chapter1/pig_cup_hd.png"))
   await capture(folder+"/pig_cup_hd_closeup.png")
   scene.ui.hide_closeup()
   await scene.interact("coffee")
   await create_timer(1.2).timeout
   await capture(folder+"/cup_unlocked.png")
  if id == "living":
   assert(scene.get_node("ExplorationLight").strengths[1] == 0.0)
   await scene.interact("pillow")
   await create_timer(1.3).timeout
   assert(scene.get_node("ExplorationLight").strengths[1] > 0.37)
   await capture(folder+"/paper_arrived.png")
  if id == "living":
   scene.open_exit_menu("outside")
   await process_frame
   await capture(folder+"/outside_menu.png")
   scene.ui.menu.get_node("cancel").pressed.emit()
   var deadline := Time.get_ticks_msec()+5000
   while scene.busy and Time.get_ticks_msec()<deadline: await process_frame
   assert(not scene.busy,"Exit menu did not finish closing")
  var clue: String = {"bedroom":"painting","kitchen":"cup","living":"paper"}[id]
  await scene.interact(clue)
  await create_timer(1.3).timeout
  var light = scene.get_node("ExplorationLight")
  var index := 1 if id == "living" else 0
  assert(is_equal_approx(light.strengths[index],0.18))
  await capture(folder+"/"+id+"_checked.png")
  scene.queue_free()
  await process_frame
 print("EXPLORATION_LIGHT_OK: clue fade, hidden paper, arrival and three-room renders")
 quit()

func capture(path: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
 print("CAPTURE: "+path)
