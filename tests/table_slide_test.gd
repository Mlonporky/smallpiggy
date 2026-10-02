extends SceneTree
const Model := preload("res://scenes/cabbage_act2/table_slide_model.gd")
var completion_count := 0
var path: Array[int] = []

func _initialize() -> void:
 call_deferred("run")

func frames(count := 4) -> void:
 for i in count: await process_frame

func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 if "complete" in name: await create_timer(0.4).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/table-slide-"+name+".png")

func key(code: int, pressed := true) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = pressed
 root.push_input(event,true)

func click(point: Vector2) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = true
 event.position = point
 root.push_input(event,true)
 await process_frame
 event.pressed = false
 root.push_input(event,true)
 await frames()

func tile_click(puzzle: Control, tile: int) -> void:
 var point: Vector2 = puzzle.tiles[tile].get_global_rect().get_center()
 await click(point)
 for i in 100:
  if not puzzle.animating: return
  await process_frame
 assert(false,"Tile animation did not finish")

func search(board: Array, depth: int, bound: int, previous: int) -> int:
 var estimate := depth+Model.distance(board)
 if estimate > bound: return estimate
 if board == Model.GOAL: return -1
 var best := 999
 var empty := board.find(Model.EMPTY)
 for next in Model.neighbors(empty):
  if next == previous: continue
  var tile := int(board[next])
  board[empty] = tile
  board[next] = Model.EMPTY
  path.append(tile)
  var result := search(board,depth+1,bound,empty)
  board[next] = tile
  board[empty] = Model.EMPTY
  if result == -1: return -1
  path.pop_back()
  best = mini(best,result)
 return best

func solution(board: Array) -> Array[int]:
 path.clear()
 var bound := Model.distance(board)
 while bound <= 32:
  var next := search(board.duplicate(),0,bound,-1)
  if next == -1: return path.duplicate()
  bound = next
 assert(false,"Legal shuffle should have a solution")
 return []

func walk(point: Vector2) -> void:
 for frame in 700:
  var delta: Vector2 = point-current_scene.player.position
  if delta.length() < 10: break
  for pair in [[KEY_LEFT,delta.x < -6],[KEY_RIGHT,delta.x > 6],[KEY_UP,delta.y < -6],[KEY_DOWN,delta.y > 6]]:
   var event := InputEventKey.new()
   event.keycode = pair[0]
   event.physical_keycode = pair[0]
   event.pressed = pair[1]
   Input.parse_input_event(event)
  await physics_frame
 for code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
  var event := InputEventKey.new()
  event.physical_keycode = code
  event.pressed = false
  Input.parse_input_event(event)
 assert(current_scene.player.position.distance_to(point)<22,"Table aisle is not reachable: goal %s, stopped %s" % [point,current_scene.player.position])
 await frames()

func run() -> void:
 await process_frame
 var rng := RandomNumberGenerator.new()
 rng.seed = 3030
 for i in 400:
  var board := Model.shuffle(rng)
  assert(Model.valid(board) and board != Model.GOAL and Model.distance(board) >= 8)
 assert(not Model.valid([1,0,2,3,4,5,6,7,8]))
 assert(not Model.valid([0,1,2,3,4,5,6,7,7]))
 assert(not Model.valid([0,1,2,3,4,5,6,7,"8"]))
 assert(not Model.valid([0,1,2,3,4,5,6,7,8.1]))
 assert(Model.valid(JSON.parse_string(JSON.stringify(Model.GOAL))))
 var gs := root.get_node("GameState")
 var saves := root.get_node("SaveManager")
 saves.save_path = "/tmp/piggy-table-slide-%s-test.json" % DisplayServer.get_name()
 gs.reset()
 var original: Dictionary = gs.to_dictionary()
 change_scene_to_file("res://scenes/cabbage_act2/table_slide_preview.tscn")
 await frames(8)
 var puzzle = current_scene.puzzle
 puzzle.completed.connect(func(): completion_count += 1)
 await create_timer(0.35).timeout
 await capture("start")
 var before: Array = puzzle.board.duplicate()
 var far := -1
 for tile in 8:
  if not puzzle.board.find(tile) in Model.neighbors(puzzle.board.find(Model.EMPTY)):
   far = tile
   break
 await tile_click(puzzle,far)
 assert(puzzle.board == before and puzzle.moves == 0)
 var neighbor := Model.neighbors(puzzle.board.find(Model.EMPTY))[0]
 var moving_tile := int(puzzle.board[neighbor])
 var start_position: Vector2 = puzzle.tiles[moving_tile].position
 await click(puzzle.tiles[moving_tile].get_global_rect().get_center())
 assert(puzzle.animating and puzzle.moves == 1,"A tile should glide rather than jump instantly")
 if DisplayServer.get_name() != "headless":
  assert(puzzle.tiles[moving_tile].position.distance_to(start_position)>0)
  assert(puzzle.tiles[moving_tile].position.distance_to(start_position)<puzzle.CELL)
  await capture("sliding")
 key(KEY_ESCAPE)
 key(KEY_ESCAPE,false)
 assert(not puzzle.resolved,"A move cannot be interrupted halfway")
 while puzzle.animating: await process_frame
 assert(puzzle.moves == 1 and puzzle.board != before)
 await click(puzzle.undo_button.get_global_rect().get_center())
 while puzzle.animating: await process_frame
 assert(puzzle.board == before and puzzle.moves == 0)
 await click(puzzle.shuffle_button.get_global_rect().get_center())
 assert(Model.valid(puzzle.board) and puzzle.moves == 0 and puzzle.undo_history.is_empty())
 var solve := solution(puzzle.board)
 for tile in solve: await tile_click(puzzle,tile)
 assert(puzzle.solved and completion_count == 1 and puzzle.reveal.visible)
 assert(puzzle.status.text == "回忆已解锁")
 await tile_click(puzzle,0)
 assert(completion_count == 1)
 await capture("complete")
 if DisplayServer.get_name() != "headless":
  for viewport_size in [Vector2i(900,560),Vector2i(560,800)]:
   root.size = viewport_size
   await frames(8)
   assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(puzzle.stage.get_global_rect()))
  await capture("small-window")
  root.size = Vector2i(1152,648)
  await frames(8)
 assert(gs.to_dictionary() == original,"Preview must not write GameState")
 # Story integration: locked before four pieces, nearby click, real aisle/E,
 # incomplete saves, JSON reload, actual UI solve, completion and repeat view.
 change_scene_to_file("res://scenes/cabbage_act2/interior.tscn")
 await frames(8)
 current_scene.table_memory_enabled = false
 current_scene.open_table_puzzle()
 assert(not is_instance_valid(current_scene.table_puzzle))
 for i in 4: gs.set_flag("wrapping_piece_%d_found" % (i+1))
 current_scene.collectibles.refresh()
 current_scene.paper.visible = false
 for i in 5: await physics_frame
 assert(current_scene.table_inlay.visible)
 var at: Vector2 = current_scene.get_global_transform_with_canvas()*current_scene.TABLE_INLAY.get_center()
 await click(at)
 assert(not is_instance_valid(current_scene.table_puzzle),"Far clicks must not open table")
 await walk(Vector2(550,810))
 await walk(Vector2(562,604))
 await capture("room")
 at = current_scene.get_global_transform_with_canvas()*current_scene.TABLE_INLAY.get_center()
 await click(at)
 puzzle = current_scene.table_puzzle
 assert(is_instance_valid(puzzle) and current_scene.busy and not current_scene.player.input_enabled)
 assert(puzzle.board == current_scene.table_visual_board,"Room inlay and full-screen board must match")
 var empty: int = puzzle.board.find(Model.EMPTY)
 var next: int = Model.neighbors(empty)[0]
 var delta := Vector2i(next%3-empty%3,next/3-empty/3)
 var code: int = KEY_LEFT if delta.x > 0 else (KEY_RIGHT if delta.x < 0 else (KEY_UP if delta.y > 0 else KEY_DOWN))
 key(code)
 key(code,false)
 await frames()
 while puzzle.animating: await process_frame
 assert(puzzle.moves == 1)
 before = puzzle.board.duplicate()
 assert(gs.flags["mushroom_table_tiles"] == before)
 assert(current_scene.table_visual_board == before)
 assert(not gs.has_flag("mushroom_table_memory_unlocked"))
 key(KEY_ESCAPE)
 key(KEY_ESCAPE,false)
 await frames(8)
 assert(not current_scene.busy and current_scene.player.input_enabled)
 assert(saves.save_game(current_scene.scene_file_path))
 gs.reset()
 var saved_scene: String = saves.load_game()
 change_scene_to_file(saved_scene)
 await frames(8)
 current_scene.table_memory_enabled = false
 # Reach the clear front of the table without walking through furniture.
 await walk(Vector2(810,830))
 await walk(Vector2(800,765))
 key(KEY_E)
 key(KEY_E,false)
 await frames(8)
 puzzle = current_scene.table_puzzle
 assert(is_instance_valid(puzzle),"E at front must reopen table; at %s" % current_scene.player.position)
 assert(puzzle.board == before,"Reloaded board differs: %s vs %s" % [puzzle.board,before])
 assert(puzzle.moves == 1,"Move count must persist")
 solve = solution(puzzle.board)
 for tile in solve: await tile_click(puzzle,tile)
 assert(gs.has_flag("mushroom_table_puzzle_completed") and gs.has_flag("mushroom_table_memory_unlocked"))
 assert(not gs.has_flag("wrapping_puzzle_completed"),"Table must not finish the paper puzzle")
 assert(gs.heart_progress == 0 and gs.gift_fragments.is_empty())
 assert(gs.cabbage_emotional_state == gs.CabbageEmotionalState.HOLLOW)
 await capture("room-complete")
 key(KEY_ESCAPE)
 key(KEY_ESCAPE,false)
 await frames(8)
 assert(saves.save_game(current_scene.scene_file_path))
 gs.reset()
 change_scene_to_file(saves.load_game())
 await frames(8)
 current_scene.table_memory_enabled = false
 await walk(Vector2(810,830))
 await walk(Vector2(800,765))
 key(KEY_E)
 key(KEY_E,false)
 await frames(8)
 assert(current_scene.table_puzzle.solved and gs.has_flag("mushroom_table_memory_unlocked"))
 print("TABLE_SLIDE_OK")
 quit()
