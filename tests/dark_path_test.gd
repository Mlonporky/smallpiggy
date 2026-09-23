extends SceneTree
var completed := 0
var frames: Array[float] = []

func _initialize() -> void:
 call_deferred("run")

func key(code: int, pressed: bool) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = pressed
 Input.parse_input_event(event)

func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/dark-path-"+name+".png")

func run() -> void:
 await process_frame
 var before: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/chapter2/dark_path/dark_path.tscn")
 for i in 4: await process_frame
 var scene = current_scene
 scene.continue_underground = false
 scene.fall_completed.connect(func(): completed += 1)
 await create_timer(1.5).timeout
 await capture("emerge")
 await create_timer(1.3).timeout
 assert(scene.phase == scene.Phase.WALK)
 assert(scene.pig_position.x >= 399)
 assert(scene.stage.clip_contents,"Oversized background must stay inside the darkened viewport")
 var source: Image = scene.ACTIONS.get_image()
 assert(source.get_pixel(0,0).a == 0 and source.get_pixel(510,500).a == 0,"Generated sprites need real transparency")
 key(KEY_A,true)
 await create_timer(1).timeout
 key(KEY_A,false)
 assert(scene.pig_position.x >= 350,"Cannot walk back into unimplemented cave")
 key(KEY_D,true)
 await create_timer(2.4).timeout
 key(KEY_D,false)
 await create_timer(0.3).timeout
 await capture("walk")
 var light: Vector2 = scene.light_material.get_shader_parameter("light_position")
 assert(light.distance_to(scene.pig_position-scene.camera_position+Vector2(0,-74)) < 1)
 key(KEY_ESCAPE,true)
 await process_frame
 key(KEY_ESCAPE,false)
 await create_timer(0.05).timeout
 assert(scene.paused)
 var at: Vector2 = scene.pig_position
 var time: float = scene.phase_time
 var murmur_time: float = scene.murmur_time
 var murmur_count: int = scene.murmur_count
 assert(murmur_count >= 2,"Encouragement must repeat without blocking movement")
 key(KEY_D,true)
 await create_timer(0.4).timeout
 assert(scene.pig_position == at and scene.phase_time == time)
 assert(scene.murmur_time == murmur_time and scene.murmur_count == murmur_count)
 key(KEY_ESCAPE,true)
 await process_frame
 key(KEY_ESCAPE,false)
 var deadline := Time.get_ticks_msec()+10000
 while scene.phase == scene.Phase.WALK and Time.get_ticks_msec() < deadline:
  frames.append(scene.get_process_delta_time())
  await process_frame
 assert(scene.phase == scene.Phase.CRACK,"Real movement must trigger collapse")
 key(KEY_D,false)
 assert(not scene.murmur.visible,"Bubble must disappear on collapse")
 await create_timer(0.23).timeout
 await capture("crack")
 await create_timer(0.55).timeout
 assert(scene.phase == scene.Phase.FALL)
 assert(scene.frame_index == 5)
 assert(scene.foreground.visible and scene.debris.size() == 6)
 await capture("fall")
 key(KEY_A,true)
 await create_timer(2.4).timeout
 key(KEY_A,false)
 assert(scene.phase == scene.Phase.END and completed == 1)
 assert(scene.ending.visible)
 if DisplayServer.get_name() != "headless":
  root.get_window().size = Vector2i(900,560)
  await create_timer(0.1).timeout
  var end_rect: Rect2 = scene.ending.get_global_rect()
  assert(end_rect.position.x >= 0 and end_rect.end.x <= root.size.x)
  assert(end_rect.position.y >= 0 and end_rect.end.y <= root.size.y)
 assert(root.get_node("GameState").to_dictionary() == before,"Preview must not change progress")
 await capture("end")
 key(KEY_R,true)
 await process_frame
 key(KEY_R,false)
 for i in 6: await process_frame
 assert(current_scene.phase == current_scene.Phase.EMERGE)
 assert(current_scene.murmur_time == 0 and not current_scene.murmur.visible)
 assert(root.get_node("GameState").to_dictionary() == before)
 frames.sort()
 if not frames.is_empty(): print("FRAME_P95_MS=",frames[int(frames.size()*0.95)]*1000)
 print("DARK_PATH_OK")
 quit()
