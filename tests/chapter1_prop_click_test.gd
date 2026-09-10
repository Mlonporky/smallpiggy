extends SceneTree
func _initialize() -> void: call_deferred("_run")
func click_at(scene: Node2D, world: Vector2) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = true
 event.position = scene.get_global_transform_with_canvas()*world
 root.push_input(event,true)
 await process_frame
 event = event.duplicate()
 event.pressed = false
 root.push_input(event,true)
 for i in 5: await process_frame
 while scene.busy: await process_frame
func _run() -> void:
 await process_frame
 var state = root.get_node("GameState")
 state.reset()
 state.set_flag("ch1_opening_done")
 var scene = load("res://scenes/chapter1/kitchen.tscn").instantiate()
 scene.test_mode = true
 scene.auto_exit_enabled = false
 root.add_child(scene)
 await process_frame
 await click_at(scene,Vector2(1005,345))
 assert(not state.has_flag("pig_cup_checked"),"Remote/locked click accepted")
 state.set_flag("coffee_made")
 scene.hotspots.cup.set_enabled(true)
 scene.player.position = Vector2(1000,530)
 scene.player.reset_physics_interpolation()
 scene.player.face(Vector2.DOWN)
 for i in 3: await physics_frame
 assert(scene.player._nearest_interactable == scene.hotspots.cup,"Facing away lost proximity selection")
 await click_at(scene,Vector2(1005,345))
 assert(state.has_flag("pig_cup_checked"),"Near cup click failed")
 scene.player.position = Vector2(380,740)
 scene.player.reset_physics_interpolation()
 await click_at(scene,Vector2(620,740))
 assert(state.has_flag("double_tableware_checked"),"Side-of-table click failed")
 assert(scene.ui.closeup.texture.resource_path.ends_with("cabbage_bowl_hd.png"))
 assert(scene.ui.companion.texture.resource_path.ends_with("pig_bowl_hd.png"))
 assert(scene.memory.z_index > scene.get_node("ExplorationLight").z_index)
 scene.test_mode = false
 scene.player.position = Vector2(1200,550)
 scene.player.reset_physics_interpolation()
 var messages: Array[String] = []
 scene.dialogue.line_started.connect(func(line): messages.append(line.text))
 var trash_click := InputEventMouseButton.new()
 trash_click.button_index = MOUSE_BUTTON_LEFT
 trash_click.pressed = true
 trash_click.position = scene.get_global_transform_with_canvas()*Vector2(1230,455)
 root.push_input(trash_click,true)
 await process_frame
 assert(messages == ["里面没什么值得留念的东西。"],"Trash click did not show supplied text")
 assert(not scene.ui.closeup.visible and not scene.ui.companion.visible,"Trash opened an image")
 for repeat in 3:
  scene.dialogue._advance_requested = true
  await create_timer(0.1).timeout
 assert(not scene.busy)
 scene.queue_free()
 await process_frame
 print("PROP_CLICK_OK: distance and story gates, real clicks, orientation independence, paired HD dishes")
 quit()
