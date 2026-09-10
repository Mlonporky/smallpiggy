extends SceneTree
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 await process_frame
 var state = root.get_node("GameState")
 state.reset()
 state.set_flag("ch1_opening_done")
 for id in ["bedroom","kitchen","living"]:
  var scene = load("res://scenes/chapter1/%s.tscn" % id).instantiate()
  scene.route_on_exit = false
  scene.test_mode = true
  root.add_child(scene)
  await create_timer(0.1).timeout
  assert(not scene.ui.choosing,"Spawn inside exit")
  var exits = scene.get_node("RoomExits")
  for zone in exits.zones:
   var center: Vector2 = zone[1].get_center()
   var direction := Vector2.DOWN if zone[0] == "outside" else (Vector2.RIGHT if center.x>700 else Vector2.LEFT)
   scene.player.position = center-direction*100
   scene.player.reset_physics_interpolation()
   await physics_frame
   var action := "move_down" if direction.y>0 else ("move_right" if direction.x>0 else "move_left")
   Input.action_press(action)
   var end := Time.get_ticks_msec()+3000
   while not scene.ui.choosing and Time.get_ticks_msec()<end: await physics_frame
   Input.action_release(action)
   assert(scene.ui.choosing,"Door approach blocked: "+id+zone[0])
   assert(scene.ui.menu.get_node(zone[0]).disabled == scene.exit_locks().has(zone[0]))
   assert(scene.last_route.is_empty(),"Automatic transition before confirmation")
   scene.ui.menu.get_node("cancel").pressed.emit()
   await create_timer(0.25).timeout
   assert(not scene.ui.choosing and not scene.busy,"Cancel/retrigger failure")
  scene.queue_free()
  await process_frame
 print("CHAPTER1_BOTTOM_EXIT_OK: five real door approaches, bottom outside, gates, cancellation, no automatic travel")
 quit()
