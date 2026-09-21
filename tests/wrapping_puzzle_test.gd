extends SceneTree
const Art := preload("res://scenes/cabbage_act2/wrapping_art.gd")
var seen_completed := 0
var seen_back := 0

func _initialize() -> void:
 call_deferred("run")

func capture(label: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/wrapping-"+label+".png")

func mouse_button(puzzle: Control, point: Vector2, pressed: bool) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = pressed
 event.position = puzzle.stage.get_global_transform()*point
 event.global_position = event.position
 root.push_input(event,true)
 for i in 3: await process_frame

func drag(puzzle: Control, index: int, destination: Vector2) -> void:
 await mouse_button(puzzle,puzzle.pieces[index].position,true)
 assert(puzzle.dragging == index,"Must select only the irregular paper polygon")
 var motion := InputEventMouseMotion.new()
 motion.position = puzzle.stage.get_global_transform()*destination
 root.push_input(motion,true)
 for i in 3: await process_frame
 await mouse_button(puzzle,destination,false)
 while puzzle.animating: await process_frame

func key(code: int, pressed: bool) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = pressed
 Input.parse_input_event(event)

func walk(point: Vector2) -> void:
 for frame in 600:
  var delta: Vector2 = point-current_scene.player.position
  if delta.length() < 10: break
  key(KEY_LEFT,delta.x < -6)
  key(KEY_RIGHT,delta.x > 6)
  key(KEY_UP,delta.y < -6)
  key(KEY_DOWN,delta.y > 6)
  await physics_frame
 for code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: key(code,false)
 assert(current_scene.player.position.distance_to(point)<22,"Unreachable %s, stopped at %s" % [point,current_scene.player.position])
 for i in 8: await physics_frame

func interact() -> void:
 key(KEY_E,true)
 await process_frame
 key(KEY_E,false)
 for i in 4: await process_frame

func geometry_check() -> void:
 var polygons := Art.polygons()
 assert(polygons.size() == 4)
 for polygon in polygons: assert(not Geometry2D.triangulate_polygon(polygon).is_empty())
 # Every sampled point of the sheet belongs to exactly one fragment.
 for y in range(3,400,7):
  for x in range(3,600,7):
   var point := Vector2(x+0.31,y+0.17)
   var count := 0
   for polygon in polygons:
    if Geometry2D.is_point_in_polygon(point,polygon): count += 1
   assert(count == (1 if Geometry2D.is_point_in_polygon(point,Art.outer()) else 0),"Paper has a gap or an overlap at %s" % point)
 assert(Art.MESSAGE == "白白菜，生日\n\n爱你的，呆")

func run() -> void:
 await process_frame
 geometry_check()
 var gs := root.get_node("GameState")
 var save := root.get_node("SaveManager")
 save.save_path = "/tmp/piggy_wrapping_test.json"
 gs.reset()
 var original: Dictionary = gs.to_dictionary()
 change_scene_to_file("res://scenes/cabbage_act2/wrapping_preview.tscn")
 for i in 5: await process_frame
 var puzzle = current_scene.puzzle
 puzzle.completed.connect(func(): seen_completed += 1)
 puzzle.back_revealed.connect(func(): seen_back += 1)
 assert(not puzzle.flip_button.visible and not puzzle.back.visible)
 await capture("pieces")
 await drag(puzzle,0,puzzle.target(3))
 assert(not puzzle.placed[0],"Wrong placement must return to tray")
 # Empty part of a fragment bounding box must not be draggable.
 var empty_offset := Vector2(149,-99)
 assert(not Geometry2D.is_point_in_polygon(Art.center(0)+empty_offset,Art.polygons()[0]))
 await mouse_button(puzzle,puzzle.pieces[0].position+empty_offset*puzzle.pieces[0].scale,true)
 assert(puzzle.dragging == -1,"Transparent corner cannot pick up a fragment")
 await mouse_button(puzzle,puzzle.pieces[0].position+empty_offset*puzzle.pieces[0].scale,false)
 for i in [2,0,3,1]: await drag(puzzle,i,puzzle.target(i)+Vector2(8,-5))
 assert(seen_completed == 1 and puzzle.solved)
 await capture("complete")
 await puzzle.flip()
 assert(seen_back == 1 and puzzle.back.visible and not puzzle.front.visible)
 assert(puzzle.back.get_node("Paper/Message").text == Art.MESSAGE)
 await capture("message")
 await puzzle.flip()
 assert(not puzzle.showing_back and puzzle.front.visible)
 if DisplayServer.get_name() != "headless":
  root.size = Vector2i(900,560)
  for i in 6: await process_frame
  assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(puzzle.stage.get_global_rect()))
  await puzzle.flip()
  await capture("resized")
  root.size = Vector2i(1152,648)
 assert(gs.to_dictionary() == original,"Preview must not write story state")
 change_scene_to_file("res://scenes/cabbage_act2/interior.tscn")
 for i in 5: await process_frame
 current_scene.story.test_mode = true
 current_scene.ui.test_mode = true
 assert(current_scene.collectibles.collected_count() == 0)
 await current_scene.collectibles.collect(0)
 assert(current_scene.collectibles.collected_count() == 0,"Cannot collect before table or from far away")
 await walk(Vector2(550,810))
 await walk(Vector2(562,604))
 await interact()
 while current_scene.busy: await process_frame
 assert(current_scene.collectibles.collected_count() == 1)
 await walk(Vector2(558,350))
 await walk(Vector2(704,345))
 await capture("bookshelf")
 await interact()
 while current_scene.busy: await process_frame
 assert(current_scene.collectibles.collected_count() == 2)
 # Keep collection across save/load, without re-awarding the same fragment.
 assert(save.save_game(current_scene.scene_file_path))
 gs.reset()
 var path: String = save.load_game()
 change_scene_to_file(path)
 for i in 5: await process_frame
 current_scene.story.test_mode = true
 current_scene.ui.test_mode = true
 assert(current_scene.collectibles.collected_count() == 2)
 assert(not current_scene.collectibles.scraps[1].visible)
 await walk(Vector2(810,830))
 await walk(Vector2(895,830))
 await capture("crate")
 await interact()
 while current_scene.busy: await process_frame
 assert(current_scene.collectibles.collected_count() == 3)
 await walk(Vector2(750,825))
 await walk(Vector2(550,810))
 await walk(Vector2(510,803))
 await capture("basket")
 await interact()
 while current_scene.busy: await process_frame
 assert(current_scene.collectibles.collected_count() == 4)
 assert(gs.gift_fragments.is_empty() and gs.heart_progress == 0)
 await walk(Vector2(560,790))
 await walk(Vector2(562,604))
 await interact()
 while not is_instance_valid(current_scene.puzzle): await process_frame
 puzzle = current_scene.puzzle
 await drag(puzzle,2,puzzle.target(2))
 puzzle.close()
 for i in 5: await process_frame
 assert(current_scene.player.input_enabled)
 assert(save.save_game(current_scene.scene_file_path))
 gs.reset()
 path = save.load_game()
 change_scene_to_file(path)
 for i in 5: await process_frame
 current_scene.story.test_mode = true
 await walk(Vector2(550,810))
 await walk(Vector2(562,604))
 await interact()
 while not is_instance_valid(current_scene.puzzle): await process_frame
 puzzle = current_scene.puzzle
 assert(puzzle.placed[2],"Partially completed puzzle must persist")
 for i in [0,3,1]: await drag(puzzle,i,puzzle.target(i))
 assert(gs.has_flag("wrapping_puzzle_completed"))
 assert(not gs.has_flag("QUEST_MUSHROOM_WRAPPING_PAPER"))
 await puzzle.flip()
 assert(gs.has_flag("wrapping_message_seen"))
 await capture("room-message")
 puzzle.close()
 for i in 5: await process_frame
 assert(current_scene.player.input_enabled)
 # Clicking the table must still work after its original paper has been picked up.
 var click := InputEventMouseButton.new()
 click.button_index = MOUSE_BUTTON_LEFT
 click.pressed = true
 click.position = current_scene.get_global_transform_with_canvas()*current_scene.PAPER_POSITION
 root.push_input(click,true)
 await process_frame
 click.pressed = false
 root.push_input(click,true)
 for i in 20:
  if is_instance_valid(current_scene.puzzle): break
  await process_frame
 assert(is_instance_valid(current_scene.puzzle),"Clicking the table must reopen the paper")
 assert(current_scene.puzzle.solved,"Completed paper can be viewed again")
 assert(gs.gift_fragments.is_empty() and gs.heart_progress == 0)
 print("WRAPPING_PUZZLE_OK")
 quit()
