extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func key(code: int, pressed: bool) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = code
 event.keycode = code
 event.pressed = pressed
 Input.parse_input_event(event)

func walk(point: Vector2) -> void:
 var player = current_scene.player
 for frame in 500:
  var delta: Vector2 = point-player.position
  if delta.length() < 10: break
  key(KEY_LEFT,delta.x < -6)
  key(KEY_RIGHT,delta.x > 6)
  key(KEY_UP,delta.y < -6)
  key(KEY_DOWN,delta.y > 6)
  await physics_frame
 for code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: key(code,false)
 assert(player.position.distance_to(point)<20,"Unreachable waypoint: %s, stopped at %s" % [point,player.position])
 for i in 10: await physics_frame

func capture(label: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/outdoor-"+label+".png")

func enter(target: String) -> void:
 key(KEY_E,true)
 await process_frame
 key(KEY_E,false)
 for i in 4: await process_frame
 assert(current_scene.ui.choosing,"E must open destination choice")
 assert(current_scene.ui.menu.get_node(target).has_focus())
 key(KEY_ENTER,true)
 await process_frame
 key(KEY_ENTER,false)
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.location == target)

func run() -> void:
 await process_frame
 root.get_node("SaveManager").save_path = "/tmp/piggy_outdoor_navigation.json"
 root.get_node("GameState").reset()
 # Discovery dialogue has its own coverage in mushroom_exploration_test.
 root.get_node("GameState").set_flag("mushroom_house_discovered")
 change_scene_to_file("res://scenes/cabbage_act2/villa.tscn")
 for i in 4: await process_frame
 key(KEY_E,true)
 await process_frame
 key(KEY_E,false)
 for i in 4: await process_frame
 assert(current_scene.ui.choosing)
 key(KEY_ESCAPE,true)
 await process_frame
 key(KEY_ESCAPE,false)
 for i in 4: await process_frame
 assert(not current_scene.ui.choosing and current_scene.player.input_enabled)
 for point in [Vector2(1080,570),Vector2(850,650),Vector2(1030,765),Vector2(1260,835)]: await walk(point)
 await capture("villa-road")
 await enter("path")
 await walk(Vector2(270,440))
 await enter("villa")
 await walk(Vector2(1260,835))
 await enter("path")
 for point in [Vector2(360,520),Vector2(510,670),Vector2(760,755),Vector2(1050,795),Vector2(1145,755)]: await walk(point)
 await capture("garden")
 await enter("mushroom")
 for point in [Vector2(650,730),Vector2(865,690)]: await walk(point)
 await capture("mushroom-door")
 root.get_node("GameState").set_flag("s2_cave_discovered")
 change_scene_to_file("res://scenes/chapter2/forest_path.tscn")
 for i in 4: await process_frame
 current_scene.allow_save = false
 for point in [Vector2(700,810),Vector2(740,650),Vector2(835,490),Vector2(965,380),Vector2(1130,290)]: await walk(point)
 await capture("cave-mouth")
 for action in [0,KEY_SPACE,KEY_SHIFT]:
  key(KEY_UP,true)
  if action: key(action,true)
  for i in 100: await physics_frame
  key(KEY_UP,false)
  if action: key(action,false)
  assert(current_scene.player.position.y >= 259,"Cannot stand in upper cave artwork, including jump/roll")
 key(KEY_E,true)
 await process_frame
 key(KEY_E,false)
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.scene_file_path.ends_with("cave.tscn"))
 print("OUTDOOR_NAVIGATION_OK")
 quit()
