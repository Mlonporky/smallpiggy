extends SceneTree

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
 root.get_texture().get_image().save_png("/tmp/underground-"+name+".png")

func walk_to(pig: CharacterBody2D, x: float) -> void:
 key(KEY_D,true)
 var deadline := Time.get_ticks_msec()+4000
 while pig.position.x<x and Time.get_ticks_msec()<deadline: await process_frame
 assert(pig.position.x>=x,"Must walk to takeoff edge")

func run() -> void:
 await process_frame
 var before: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/chapter2/dark_path/dark_path.tscn")
 await create_timer(3).timeout
 var path = current_scene
 key(KEY_D,true)
 await create_timer(1.1).timeout
 await capture("murmur")
 var deadline := Time.get_ticks_msec()+30000
 while (current_scene == path or current_scene == null) and Time.get_ticks_msec()<deadline: await process_frame
 key(KEY_D,false)
 assert(current_scene != path,"Fall must transition; phase=%s x=%s" % [path.phase,path.pig_position.x] if is_instance_valid(path) else "scene transition")
 var scene = current_scene
 scene.combat.active = false # Platform regression runs separately from combat.
 var pig = scene.pig
 assert(not pig.enabled and not pig.landed_once,"Controls start after the real landing")
 await create_timer(0.3).timeout
 await capture("fall")
 await create_timer(1.2).timeout
 assert(pig.is_on_floor() and pig.landed_once and pig.enabled)
 assert(absf(pig.position.y-730)<2,"Feet must meet platform top")
 await capture("land")
 key(KEY_A,true)
 await create_timer(1.2).timeout
 key(KEY_A,false)
 await create_timer(0.1).timeout
 assert(pig.position.x>=20 and pig.position.x<25,"Left wall must stop the capsule")
 # Hold movement against the raised block: horizontal movement cannot climb it.
 key(KEY_D,true)
 await create_timer(2.1).timeout
 key(KEY_D,false)
 await create_timer(0.1).timeout
 assert(pig.position.x<562 and pig.position.x>540)
 key(KEY_SPACE,true)
 key(KEY_D,true)
 await create_timer(0.30).timeout
 assert(pig.position.y<620 and not pig.is_on_floor())
 await capture("jump")
 key(KEY_D,false)
 await create_timer(0.65).timeout
 key(KEY_SPACE,false)
 assert(pig.is_on_floor() and absf(pig.position.y-622)<2,"First raised platform must be reachable")
 # Space held through landing must not cause automatic repeat jumps.
 await create_timer(0.15).timeout
 await capture("platform")
 key(KEY_ESCAPE,true)
 await create_timer(0.06).timeout
 key(KEY_ESCAPE,false)
 assert(scene.paused)
 var at: Vector2 = pig.position
 var elapsed: float = scene.elapsed
 key(KEY_D,true)
 key(KEY_SPACE,true)
 await create_timer(0.25).timeout
 assert(pig.position==at and scene.elapsed==elapsed)
 key(KEY_D,false)
 key(KEY_SPACE,false)
 key(KEY_ESCAPE,true)
 await create_timer(0.06).timeout
 key(KEY_ESCAPE,false)
 # Continue the staircase using normal keys, including air steering.
 await walk_to(pig,755)
 key(KEY_SPACE,true)
 await create_timer(0.72).timeout
 key(KEY_D,false)
 key(KEY_SPACE,false)
 await create_timer(0.18).timeout
 assert(pig.is_on_floor() and absf(pig.position.y-526)<2,"Second platform must be reachable: %s" % pig.position)
 await walk_to(pig,1045)
 key(KEY_SPACE,true)
 await create_timer(0.67).timeout
 key(KEY_D,false)
 key(KEY_SPACE,false)
 await create_timer(0.18).timeout
 assert(pig.is_on_floor() and absf(pig.position.y-440)<2,"Top platform must be reachable: %s" % pig.position)
 await capture("top")
 key(KEY_D,true)
 await create_timer(1.7).timeout
 key(KEY_D,false)
 await create_timer(0.2).timeout
 assert(pig.is_on_floor() and pig.position.x>1510 and pig.position.x<=1516)
 # Walk back through the room to prove falling is actual gravity.
 key(KEY_A,true)
 await create_timer(3.0).timeout
 key(KEY_A,false)
 await create_timer(0.1).timeout
 assert(pig.is_on_floor() and absf(pig.position.y-730)<2)
 assert(pig.position.x>810,"Raised block also blocks movement from the right")
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(900,560)
  await create_timer(0.15).timeout
  assert(scene.stage.get_global_rect().end.x<=scene.get_viewport_rect().size.x+1)
  assert(scene.stage.get_global_rect().end.y<=scene.get_viewport_rect().size.y+1)
  await capture("small")
 key(KEY_R,true)
 await create_timer(0.1).timeout
 key(KEY_R,false)
 assert(current_scene != scene and not current_scene.pig.landed_once)
 assert(not current_scene.paused)
 assert(root.get_node("GameState").to_dictionary()==before)
 print("UNDERGROUND_LANDING_OK")
 quit()
