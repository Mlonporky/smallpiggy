extends SceneTree
const Story = preload("res://scenes/finale/finale_story.gd")
const OUTPUT := "res://docs/art_direction/finale/transformation_v1/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var state: Dictionary = root.get_node("GameState").to_dictionary()
 var source := FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn")
 change_scene_to_file("res://scenes/finale/transformation_preview.tscn")
 for i in 3: await process_frame
 var film := current_scene
 film.set_process(false)
 film.enter_beat(Story.index_of("remember_you"))
 var actor: Node2D = film.cabbage
 var prepared_id: int = actor.rig.get_instance_id()
 var transition: Node2D = actor.transformation
 var rig_parts: Dictionary = {}
 for key in actor.rig.joints:
  rig_parts[key] = [actor.rig.joints[key].position, actor.rig.artwork[key].scale]
 var boy_size: Vector2 = actor.sprite.scale
 var boy_position: Vector2 = actor.sprite.position
 var previous := -1.0
 for frame in 181:
  film.beat_time = frame / 120.0
  film._animate(0)
  assert(transition.progress >= previous)
  previous = transition.progress
  assert(actor.position == Vector2(1000, 616))
  assert(actor.sprite.scale == boy_size and actor.sprite.position == boy_position, "Boy proportions or feet moved")
  for key in rig_parts:
   assert([actor.rig.joints[key].position, actor.rig.artwork[key].scale] == rig_parts[key], "Rig moved or stretched")
  assert(actor.sprite.visible == (transition.progress < 1.0))
 assert(transition.progress == 1.0)
 for seconds in [0.0, .36, .65, .92, 1.4]:
  film.beat_time = seconds
  film._animate(0)
  if DisplayServer.get_name() != "headless":
   await process_frame
   RenderingServer.force_draw(false)
   root.get_texture().get_image().save_png(OUTPUT + "pose_" + str(seconds) + ".png")
 # Image-level endpoints must match the ordinary boy/cabbage render, not only
 # the shader progress variable. The whole-frame background remains unchanged.
 if DisplayServer.get_name() != "headless":
  for endpoint in [0.0, 1.4]:
   film.enter_beat(Story.index_of("remember_you"))
   film.beat_time = endpoint
   film._animate(0)
   await process_frame
   RenderingServer.force_draw(false)
   var at: Vector2 = actor.global_position
   var crop := Rect2i(Vector2i(at) - Vector2i(90, 160), Vector2i(180, 170))
   var transition_pixels := root.get_texture().get_image().get_region(crop)
   actor.configure("boy" if endpoint == 0.0 else "cabbage")
   actor.pose(false)
   await process_frame
   RenderingServer.force_draw(false)
   var normal_pixels := root.get_texture().get_image().get_region(crop)
   transition_pixels.save_png("/tmp/transition-endpoint-" + str(endpoint) + ".png")
   normal_pixels.save_png("/tmp/normal-endpoint-" + str(endpoint) + ".png")
   var transition_bytes := transition_pixels.get_data()
   var normal_bytes := normal_pixels.get_data()
   var pixel_error := 0
   for byte in transition_bytes.size(): pixel_error = maxi(pixel_error, absi(transition_bytes[byte] - normal_bytes[byte]))
   # A custom shader may round an 8-bit channel by one level on OpenGL.
   assert(pixel_error <= 1, "Transition endpoint differs from ordinary actor: " + str(endpoint))
   print("TRANSFORMATION_ENDPOINT ", endpoint, " max_channel_error=", pixel_error)
  film.enter_beat(Story.index_of("remember_you"))
  transition = actor.transformation
 # Pause freezes both the scene clock and the shader, even while processing.
 film.beat_time = .65
 film._animate(0)
 var frozen: float = transition.progress
 film._show_menu()
 film.set_process(true)
 await create_timer(.15).timeout
 assert(film.beat_time == .65 and transition.progress == frozen)
 film._resume()
 film.set_process(false)
 # Skip directly out of the transition: no shader or boy silhouette may leak.
 film.enter_beat(Story.index_of("reunion_close"))
 assert(actor.kind == "cabbage" and actor.transformation == null and not actor.sprite.visible)
 for key in actor.rig.artwork:
  assert(actor.rig.artwork[key].material == null)
  for child in actor.rig.artwork[key].get_children(): assert(child.material == null)
 # Re-entry restores the boy, including direct checkpoint reconstruction.
 film.enter_beat(Story.index_of("remember_you"))
 assert(actor.rig.get_instance_id() == prepared_id, "Replay must reuse prepared rig")
 assert(actor.transformation.progress == 0.0 and actor.sprite.visible)
 film.beat_time = .65
 film._animate(0)
 assert(is_equal_approx(actor.transformation.progress, frozen))
 film.enter_beat(Story.index_of("remember"))
 assert(actor.kind == "boy" and actor.rig == null and actor.sprite.material == null)
 # Finish and keyboard replay of the isolated preview.
 film.enter_beat(Story.index_of("close_name"))
 film._process(3.0)
 assert(film.finished and film.audio.paused)
 var replay := InputEventKey.new()
 replay.keycode = KEY_SPACE
 replay.pressed = true
 root.push_input(replay, true)
 assert(not film.finished and not film.audio.paused)
 assert(film.current_id() == "remember_you" and actor.transformation.progress == 0.0)
 assert(root.get_node("GameState").to_dictionary() == state)
 assert(FileAccess.get_file_as_bytes("res://scenes/animation_studies/editable_pig.tscn") == source)
 print("FINALE_TRANSFORMATION_OK samples=181 fixed_parts pause skip replay isolation")
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 quit()
