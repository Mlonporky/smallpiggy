extends "res://tests/wrapping_puzzle_test.gd"
## Same room/save integration as the mouse regression, but all paper placement uses keys.
var output := "/tmp/piggy-phase3-keyboard"

func tap(code: int) -> void:
 key(code,true)
 for i in 2: await process_frame
 key(code,false)
 for i in 2: await process_frame

func move_piece(puzzle: Control, index: int, destination: Vector2) -> void:
 for i in 1800:
  var offset: Vector2 = destination-puzzle.pieces[index].position
  if offset.length() < 8: break
  key(KEY_LEFT,offset.x < -4)
  key(KEY_RIGHT,offset.x > 4)
  key(KEY_UP,offset.y < -4)
  key(KEY_DOWN,offset.y > 4)
  await process_frame
 for code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: key(code,false)
 assert(puzzle.pieces[index].position.distance_to(destination) < 12,"Keyboard must physically move the fragment to the requested position")

func drag(puzzle: Control, index: int, destination: Vector2) -> void:
 await tap(KEY_1+index)
 assert(puzzle.keyboard_piece == index)
 await move_piece(puzzle,index,destination)
 await tap(KEY_ENTER)
 while puzzle.animating: await process_frame

func capture(label: String) -> void:
 if DisplayServer.get_name() == "headless": return
 DirAccess.make_dir_recursive_absolute(output)
 # These are layout snapshots, not frame-cadence measurements. A covered macOS
 # window may not draw; explicitly render once instead of waiting indefinitely.
 await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(output.path_join(label+".png"))

func run() -> void:
 await process_frame
 change_scene_to_file("res://scenes/cabbage_act2/wrapping_preview.tscn")
 for i in 5: await process_frame
 var puzzle = current_scene.puzzle
 assert(root.gui_get_focus_owner() == puzzle.piece_buttons[0])
 await tap(KEY_TAB)
 assert(root.gui_get_focus_owner() == puzzle.piece_buttons[1])
 await tap(KEY_ENTER)
 assert(puzzle.keyboard_piece == 1,"Tab and Enter must select a piece without number shortcuts")
 await move_piece(puzzle,1,Vector2(650,350))
 await tap(KEY_F1)
 assert(paused)
 var before: Vector2 = puzzle.pieces[1].position
 key(KEY_RIGHT,true)
 for i in 12: await process_frame
 key(KEY_RIGHT,false)
 assert(puzzle.pieces[1].position == before,"Settings pause must freeze the carried paper")
 await tap(KEY_ESCAPE)
 assert(not paused and puzzle.keyboard_piece == 1)
 # Switching to the mouse grabs the visible carried fragment without teleporting it.
 var carried: Vector2 = puzzle.pieces[1].position
 await mouse_button(puzzle,carried,true)
 assert(puzzle.dragging == 1 and puzzle.keyboard_piece == -1)
 assert(puzzle.pieces[1].position.distance_to(carried) < 1)
 await mouse_button(puzzle,carried,false)
 while puzzle.animating: await process_frame
 await tap(KEY_2)
 await tap(KEY_TAB)
 assert(puzzle.keyboard_piece == -1 and puzzle.pieces[1].position == puzzle.HOMES[1])
 var extents := [Vector2i(1152,648)] if DisplayServer.get_name() == "headless" else [Vector2i(800,600),Vector2i(1152,648),Vector2i(1440,900)]
 for extent in extents:
  root.size = extent
  for i in 6: await process_frame
  await capture("keyboard-%dx%d" % [extent.x,extent.y])
  await tap(KEY_1)
  await move_piece(puzzle,0,Vector2(670,360))
  await capture("carried-%dx%d" % [extent.x,extent.y])
  for button in puzzle.piece_buttons:
   assert(root.get_visible_rect().encloses(button.get_global_rect()),"Selector must remain onscreen")
  puzzle.layout()
  assert(puzzle.keyboard_piece == -1 and puzzle.pieces[0].position == puzzle.HOMES[0],"Resize safely returns unfinished work to tray")
 root.size = Vector2i(1152,648)
 await tap(KEY_1)
 await tap(KEY_ESCAPE)
 for i in 4: await process_frame
 assert(is_instance_valid(current_scene.replay),"Esc closes a carried piece without solving it")
 # Exercise completion, focus handoff, and both sides using only keys.
 current_scene.start()
 for i in 5: await process_frame
 puzzle = current_scene.puzzle
 for i in 4: await drag(puzzle,i,puzzle.target(i))
 assert(root.gui_get_focus_owner() == puzzle.flip_button)
 await tap(KEY_ENTER)
 while puzzle.animating: await process_frame
 assert(puzzle.showing_back)
 await capture("keyboard-message")
 await tap(KEY_SPACE)
 while puzzle.animating: await process_frame
 assert(not puzzle.showing_back)
 print("WRAPPING_KEYBOARD_INPUT_OK: selection, movement, pause, resize, completion and flip")
 await super.run()
