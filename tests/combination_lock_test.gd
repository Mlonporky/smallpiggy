extends SceneTree
var result_count := 0
var accepted := false
var elapsed_frames: Array[float] = []

func _initialize() -> void:
 call_deferred("run")

func key(code: int, pressed: bool) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.unicode = code if code >= KEY_0 and code <= KEY_9 else 0
 event.pressed = pressed
 Input.parse_input_event(event)

func tap(code: int) -> void:
 key(code,true)
 await process_frame
 key(code,false)
 for i in 3: await process_frame

func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/lock-"+name+".png")

func connect_result(lock: Control) -> void:
 lock.finished.connect(func(value):
  result_count += 1
  accepted = value)

func run() -> void:
 await process_frame
 var state_before: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/cabbage_act2/lock_preview.tscn")
 for i in 5: await process_frame
 var lock = current_scene.lock
 connect_result(lock)
 await create_timer(0.3).timeout
 assert(lock.code_input.text.is_empty())
 for wheel in lock.wheels: assert(wheel.text == "·")
 var texture: Texture2D = lock.body.texture.atlas
 assert(texture.get_image().get_pixel(0,0).a < 0.01,"Lock art must have real alpha")
 await capture("closed")
 # Mouse keypad input, deletion, keyboard input and nonnumeric filtering.
 lock.digit_buttons[0].pressed.emit()
 assert(lock.code_input.text == "1")
 lock.digit_buttons[10].pressed.emit()
 assert(lock.code_input.text.is_empty())
 lock.code_input.text = "a中"
 lock.update_digits(lock.code_input.text)
 assert(lock.code_input.text.is_empty())
 await tap(KEY_ENTER)
 assert(not lock.animating and result_count == 0)
 for i in 4: await tap(KEY_0)
 assert(lock.code_input.text == "0000")
 await tap(KEY_ENTER)
 assert(lock.animating and not lock.opened)
 await capture("wrong")
 while lock.animating: await process_frame
 assert(result_count == 0 and lock.shackle.position == Vector2(220,195))
 lock.digit_buttons[1].pressed.emit()
 assert(lock.code_input.text == "2", "Keypad retry replaces selected wrong code")
 await tap(KEY_ESCAPE)
 assert(result_count == 1 and not accepted)
 current_scene.start()
 lock = current_scene.lock
 connect_result(lock)
 for i in 4: await process_frame
 for digit in [KEY_2,KEY_1,KEY_2,KEY_9]: await tap(digit)
 assert(lock.code_input.text == "2129")
 await create_timer(0.2).timeout
 assert(lock.wheels[0].text == "2" and lock.wheels[3].text == "9")
 await capture("entered")
 await tap(KEY_ENTER)
 assert(lock.animating and lock.submit_button.disabled)
 await tap(KEY_ESCAPE)
 assert(result_count == 1,"Escape cannot interrupt an accepted unlock")
 var last := Time.get_ticks_usec()
 while not lock.opened:
  await process_frame
  var now := Time.get_ticks_usec()
  elapsed_frames.append(float(now-last)/1000.0)
  last = now
 assert(lock.shackle.position.y < 165 and lock.shackle.rotation < -0.2)
 assert(result_count == 1,"Unlock must remain visible before handing off")
 await capture("open")
 while result_count == 1: await process_frame
 assert(result_count == 2 and accepted)
 await lock.submit()
 assert(result_count == 2,"No duplicate completion")
 assert(root.get_node("GameState").to_dictionary() == state_before,"Preview must not change story state")
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(900,560)
  for i in 6: await process_frame
  assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(lock.stage.get_global_rect()))
  await capture("resized")
 elapsed_frames.sort()
 print("LOCK_ANIMATION_OK frames=%d p95_ms=%.2f" % [elapsed_frames.size(),elapsed_frames[int(elapsed_frames.size()*0.95)]])
 quit()
