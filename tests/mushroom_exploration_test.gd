extends SceneTree
var gs: Node
var seen: Array[String] = []

func _initialize() -> void:
 call_deferred("run")

func key(code: int, pressed: bool) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = pressed
 Input.parse_input_event(event)

func walk(point: Vector2) -> void:
 for frame in 500:
  var delta: Vector2 = point-current_scene.player.position
  if delta.length() < 10: break
  key(KEY_LEFT,delta.x < -6)
  key(KEY_RIGHT,delta.x > 6)
  key(KEY_UP,delta.y < -6)
  key(KEY_DOWN,delta.y > 6)
  await physics_frame
 for code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: key(code,false)
 assert(current_scene.player.position.distance_to(point)<22,"Blocked route to %s at %s" % [point,current_scene.player.position])
 for i in 8: await physics_frame

func capture(label: String) -> void:
 if DisplayServer.get_name() == "headless": return
 if label == "closeup": await create_timer(0.15).timeout
 if label == "password": await create_timer(0.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/mushroom-"+label+".png")

func run() -> void:
 await process_frame
 gs = root.get_node("GameState")
 gs.reset()
 root.get_node("SaveManager").save_path = "/tmp/piggy-mushroom-test.json"
 change_scene_to_file("res://scenes/cabbage_act2/mushroom.tscn")
 for i in 4: await process_frame
 var story = current_scene.mushroom_story
 story.test_mode = true
 story.dialogue.line_started.connect(func(line): seen.append(line.text))
 await walk(Vector2(700,710))
 while current_scene.busy: await process_frame
 assert(gs.has_flag("mushroom_house_discovered"))
 assert(seen == Array(story.DISCOVERY))
 await walk(Vector2(835,710))
 key(KEY_E,true)
 await process_frame
 key(KEY_E,false)
 for i in 4: await process_frame
 assert(current_scene.ui.choosing)
 key(KEY_ENTER,true)
 await process_frame
 key(KEY_ENTER,false)
 for i in 6: await process_frame
 assert(is_instance_valid(story.lock_panel))
 assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(story.lock_panel.get_global_rect()),"Password panel must fit on screen")
 assert(not current_scene.player.input_enabled)
 story.code_input.text = "0000"
 story.code_input.text_submitted.emit("0000")
 await process_frame
 assert(story.lock_result.is_empty())
 assert(not gs.has_flag("mushroom_house_unlocked"))
 await capture("password")
 while story.lock_panel.animating: await process_frame
 key(KEY_ESCAPE,true)
 await process_frame
 key(KEY_ESCAPE,false)
 for i in 4: await process_frame
 assert(not current_scene.busy)
 assert(current_scene.player.input_enabled)
 current_scene.travel("door")
 for i in 4: await process_frame
 story.code_input.text = "2129"
 story.code_input.text_submitted.emit("2129")
 await root.get_node("SceneRouter").transition_finished
 assert(gs.has_flag("mushroom_house_unlocked"))
 assert(current_scene.scene_file_path.ends_with("interior.tscn"))
 current_scene.story.test_mode = true
 current_scene.ui.test_mode = true
 current_scene.story.dialogue.line_started.connect(func(line):
  seen.append(line.text)
  if line.text == "这个……": capture("pickup-head")
  if line.text == "是一样的。": capture("closeup"))
 await capture("interior")
 await walk(Vector2(550,810))
 await walk(Vector2(562,604))
 assert(current_scene.near_paper())
 # Attempt to walk into solid table, then investigate from its left edge.
 key(KEY_RIGHT,true)
 for i in 40: await physics_frame
 key(KEY_RIGHT,false)
 assert(current_scene.player.position.x < 615)
 assert(not current_scene.table_front.visible,"The table must not cover the boy's head in the left aisle")
 await capture("table")
 key(KEY_E,true)
 await process_frame
 key(KEY_E,false)
 for i in 4: await process_frame
 while current_scene.busy:
  assert(not current_scene.table_front.visible,"Side-on pickup must preserve the full head throughout the shot")
  await process_frame
 assert(gs.has_flag("wrapping_piece_1_found"))
 assert(gs.has_flag("QUEST_MUSHROOM_WRAPPING_PAPER"))
 assert(not current_scene.paper.visible)
 assert(gs.heart_progress == 0 and gs.gift_fragments.is_empty())
 assert(seen == Array(current_scene.story.DISCOVERY)+Array(current_scene.story.UNLOCK)+Array(current_scene.story.PAPER))
 await capture("objective")
 var count := seen.size()
 await current_scene.inspect_paper()
 assert(seen.size() == count,"Repeat must not replay first discovery")
 var save = root.get_node("SaveManager")
 assert(save.save_game(current_scene.scene_file_path))
 gs.reset()
 assert(save.load_game().ends_with("interior.tscn"))
 assert(gs.has_flag("wrapping_piece_1_found"))
 current_scene.leave()
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.player.position.distance_to(Vector2(850,745)) < 3)
 current_scene.travel("door")
 await root.get_node("SceneRouter").transition_finished
 assert(not current_scene.paper.visible)
 assert(current_scene.player.input_enabled)
 await walk(Vector2(720,970))
 key(KEY_E,true)
 await process_frame
 key(KEY_E,false)
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.location == "mushroom")
 print("MUSHROOM_EXPLORATION_OK")
 quit()
