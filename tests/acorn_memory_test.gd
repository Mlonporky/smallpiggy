extends SceneTree
const Film := preload("res://scenes/cabbage_act2/acorn_memory.gd")
const Art := preload("res://scenes/cabbage_act2/acorn_memory_art.gd")
var seen: Array[String] = []
var phases: Array[String] = []

func _initialize() -> void:
 call_deferred("run")

func frames(count := 4) -> void:
 for i in count: await process_frame

func key(code: int, pressed := true) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = pressed
 root.push_input(event,true)

func click(point: Vector2) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.position = point
 event.pressed = true
 root.push_input(event,true)
 await process_frame
 event.pressed = false
 root.push_input(event,true)
 await frames()

func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/acorn-memory-"+name+".png")

func attach(film: Control) -> void:
 film.dialogue.line_started.connect(func(line): seen.append(line.text))
 film.phase_changed.connect(func(name): phases.append(name))

func wait_phase(film: Control, target: String, limit := 12.0) -> void:
 var start := Time.get_ticks_msec()
 while film.phase != target and (Time.get_ticks_msec()-start)<limit*1000:
  await process_frame
 assert(film.phase == target,"Missing phase %s; stopped at %s" % [target,film.phase])

func advance(film: Control) -> void:
 # Use the same real input path as a player: first finish typing, then continue.
 key(KEY_E)
 key(KEY_E,false)
 await frames()
 while is_instance_valid(film) and film.dialogue._typing: await process_frame
 if is_instance_valid(film) and film.dialogue._line_active:
  key(KEY_SPACE)
  key(KEY_SPACE,false)
  await frames()

func art_check() -> void:
 for texture in [Art.PIG,Art.CABBAGE,Art.ACORN,Art.PICKUP]:
  var image: Image = texture.get_image()
  assert(image.get_pixel(0,0).a == 0 and image.get_pixel(image.get_width()-1,image.get_height()-1).a == 0)
  assert(image.has_mipmaps(),"Memory artwork must keep mipmaps")
 for pair in [[Art.PIG,Art.PIG_REGIONS],[Art.CABBAGE,Art.CABBAGE_REGIONS],[Art.PICKUP,[Art.PICKUP_REGION]]]:
  var extent := Rect2(Vector2.ZERO,pair[0].get_size())
  for region in pair[1]: assert(extent.encloses(region))
 assert(Film.PIG_LINE == "白白菜！橡子真的太可爱了！")
 assert(Film.CABBAGE_LINE == "猪对橡子是真爱呀！")
 assert(Film.REFLECTION == "那个白菜感觉很熟悉，好像是我。。。可是我旁边的粉嘟嘟的是谁呢。。。我怎么完全想不起来？")

func walk(point: Vector2) -> void:
 for frame in 650:
  var delta: Vector2 = point-current_scene.player.position
  if delta.length() < 10: break
  for pair in [[KEY_LEFT,delta.x < -6],[KEY_RIGHT,delta.x > 6],[KEY_UP,delta.y < -6],[KEY_DOWN,delta.y > 6]]:
   var event := InputEventKey.new()
   event.physical_keycode = pair[0]
   event.pressed = pair[1]
   Input.parse_input_event(event)
  await physics_frame
 for code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
  var event := InputEventKey.new()
  event.physical_keycode = code
  event.pressed = false
  Input.parse_input_event(event)
 assert(current_scene.player.position.distance_to(point)<22)
 await frames()

func run() -> void:
 await process_frame
 art_check()
 var gs := root.get_node("GameState")
 var saves := root.get_node("SaveManager")
 saves.save_path = "/tmp/piggy-acorn-memory-%s-test.json" % DisplayServer.get_name()
 gs.reset()
 var original: Dictionary = gs.to_dictionary()
 change_scene_to_file("res://scenes/cabbage_act2/acorn_memory_preview.tscn")
 await frames()
 var film = current_scene.memory
 attach(film)
 assert(film.preview_mode and not film.auto_advance)
 await wait_phase(film,"table_opening")
 await create_timer(0.5).timeout
 assert(film.lid_left.scale.x > 0.14 and film.lid_left.scale.x < 1)
 await capture("opening")
 await wait_phase(film,"acorn_spill")
 assert(film.acorns.size() == 28)
 await create_timer(0.8).timeout
 await capture("spill")
 await wait_phase(film,"trail_walk")
 assert(film.settled == 28,"All falling acorns must land before entering memory")
 var start_pig: Vector2 = film.pig.position
 var start_cabbage: Vector2 = film.cabbage.position
 await create_timer(1.1).timeout
 assert(film.pig.position.x > start_pig.x+85 and film.cabbage.position.x > start_cabbage.x+85)
 assert(film.cabbage.sprite.texture.atlas == Art.CABBAGE)
 assert(film.pig.sprite.material.get_shader_parameter("blur") < 0.025)
 await capture("trail")
 await wait_phase(film,"pickup_reach")
 await create_timer(0.28).timeout
 assert(film.pig.pose == 4 and film.pig.sprite.texture.atlas == Art.PICKUP)
 await capture("reach")
 await wait_phase(film,"pickup_lift")
 var ground: Vector2 = film.picked_acorn.position
 await create_timer(0.3).timeout
 assert(film.picked_acorn.position.y < ground.y-20)
 await capture("lift")
 await wait_phase(film,"pig_dialogue")
 await create_timer(0.65).timeout
 assert(film.pig.pose == 5)
 assert(film.dialogue.panel.visible)
 key(KEY_ESCAPE)
 key(KEY_ESCAPE,false)
 await frames()
 assert(film.phase == "pig_dialogue","Esc must not drop a partially viewed memory")
 await capture("pig-line")
 await advance(film)
 await wait_phase(film,"necklace_threading")
 await create_timer(0.4).timeout
 assert(film.pig.pose == 6)
 await capture("threading")
 await wait_phase(film,"necklace_worn")
 assert(film.pig.pose == 7)
 await capture("necklace")
 await wait_phase(film,"cabbage_dialogue")
 await create_timer(0.55).timeout
 await capture("cabbage-line")
 await advance(film)
 await wait_phase(film,"reflection")
 assert(not film.trail_layer.visible and film.reality.visible)
 await create_timer(1.5).timeout
 await capture("reflection-preview")
 await advance(film)
 await frames(8)
 assert(seen == [Film.PIG_LINE,Film.CABBAGE_LINE,Film.REFLECTION])
 assert(gs.to_dictionary() == original,"Film preview cannot write story state")
 # Seed four collected fragments and a one-move board; solve through actual UI.
 # Collection itself is covered by wrapping_puzzle_test, rather than simulated here.
 for i in 4: gs.set_flag("wrapping_piece_%d_found" % (i+1))
 gs.flags["mushroom_table_tiles"] = [0,1,2,3,4,5,6,8,7]
 change_scene_to_file("res://scenes/cabbage_act2/interior.tscn")
 await frames(8)
 await walk(Vector2(810,830))
 await walk(Vector2(800,765))
 var boy_position: Vector2 = current_scene.player.position
 key(KEY_E)
 key(KEY_E,false)
 await frames(8)
 var puzzle = current_scene.table_puzzle
 assert(is_instance_valid(puzzle) and puzzle.memory_enabled)
 await click(puzzle.tiles[7].get_global_rect().get_center())
 for i in 300:
  if is_instance_valid(current_scene.acorn_memory): break
  await process_frame
 assert(is_instance_valid(current_scene.acorn_memory),"Solving must automatically open the table")
 film = current_scene.acorn_memory
 seen.clear()
 attach(film)
 film.auto_advance = true
 film.auto_duration = 0.08
 assert(not gs.has_flag("mushroom_acorn_memory_seen"))
 assert(not current_scene.player.input_enabled)
 await wait_phase(film,"acorn_spill")
 assert(gs.has_flag("mushroom_table_acorns_released"))
 assert(current_scene.room_acorns.visible and not current_scene.table_tiles[0].visible)
 assert(saves.save_game(current_scene.scene_file_path))
 await wait_phase(film,"reflection",18)
 assert(not film.stage.visible and current_scene.player.position == boy_position)
 assert(not gs.has_flag("mushroom_acorn_memory_seen"),"Reflection must finish before seen is committed")
 await capture("reflection-room")
 while current_scene.busy: await process_frame
 assert(gs.has_flag("mushroom_acorn_memory_seen") and current_scene.player.input_enabled)
 assert(seen == [Film.PIG_LINE,Film.CABBAGE_LINE,Film.REFLECTION])
 assert(gs.heart_progress == 0 and gs.gift_fragments.is_empty())
 assert(gs.cabbage_emotional_state == gs.CabbageEmotionalState.HOLLOW)
 await capture("room-after")
 # The saved mid-film state must resume the unseen memory, without releasing
 # another pile of nuts. Loading must not pretend it was fully watched.
 gs.reset()
 change_scene_to_file(saves.load_game())
 await frames(8)
 assert(not gs.has_flag("mushroom_acorn_memory_seen") and gs.has_flag("mushroom_table_acorns_released"))
 current_scene.story.test_mode = true
 await walk(Vector2(810,830))
 await walk(Vector2(800,765))
 key(KEY_E)
 key(KEY_E,false)
 await frames()
 for i in 300:
  if is_instance_valid(current_scene.acorn_memory): break
  await process_frame
 film = current_scene.acorn_memory
 assert(is_instance_valid(film) and not film.release_table)
 while current_scene.busy: await process_frame
 assert(gs.has_flag("mushroom_acorn_memory_seen"))
 assert(saves.save_game(current_scene.scene_file_path))
 gs.reset()
 change_scene_to_file(saves.load_game())
 await frames(8)
 current_scene.story.test_mode = true
 await walk(Vector2(810,830))
 await walk(Vector2(800,765))
 key(KEY_E)
 key(KEY_E,false)
 await frames(8)
 assert(current_scene.table_puzzle.solved and not is_instance_valid(current_scene.acorn_memory))
 await click(current_scene.table_puzzle.memory_button.get_global_rect().get_center())
 for i in 300:
  if is_instance_valid(current_scene.acorn_memory): break
  await process_frame
 assert(is_instance_valid(current_scene.acorn_memory) and not current_scene.acorn_memory.release_table)
 while current_scene.busy: await process_frame
 print("ACORN_MEMORY_OK")
 quit()
