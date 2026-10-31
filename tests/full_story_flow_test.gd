extends "res://tests/action_route_test.gd"
## Continuous new game: no seeded story flags, teleports, health edits or scene shortcuts.
## Dialogue is advanced automatically; movement uses existing collision-aware walk_to.
var gs: Node
var phase_label := "boot"
var auto_talk := true
var started := 0
var events: Array = []
var last_scene := ""

func _process(_delta: float) -> bool:
 if Engine.get_process_frames()%1800==0 and is_instance_valid(current_scene): print("FLOW_HEARTBEAT ",phase_label," busy=",current_scene.get("busy")," pos=",current_scene.get("player").position if current_scene.get("player") else Vector2.ZERO)
 if Time.get_ticks_msec()-started > 900000 and started > 0:
  push_error("FULL_STORY_TIMEOUT " + phase_label)
  quit(1)
 if is_instance_valid(current_scene):
  if current_scene.scene_file_path != last_scene:
   last_scene = current_scene.scene_file_path
   print("FLOW_SCENE ",last_scene)
   events.append(last_scene)
  if auto_talk:
   for node in current_scene.find_children("*", "", true, false):
    if node.get_script() != null and node.get_script().resource_path.ends_with("dialogue_ui.gd") and node._line_active: node._advance_requested = true
   for node in current_scene.find_children("*", "", true, false):
    if node.get_script() != null and node.get_script().resource_path.ends_with("chapter_presentation.gd") and node.inspecting: node.inspecting = false
 return false

func note(value: String) -> void:
 phase_label = value
 print("FLOW_STAGE ",value)

func require(value: bool, message: String) -> void:
 if not value:
  push_error("FULL_STORY_FAILED " + phase_label + ": " + message)
  quit(1)
  await process_frame

func idle() -> void:
 await process_frame
 if current_scene.get("ui") != null and current_scene.ui.get("choosing") == true and current_scene.ui.choosing:
  var cancel = current_scene.ui.menu.get_node_or_null("cancel")
  if cancel: cancel.pressed.emit()
 while current_scene.get("busy") == true: await process_frame

func arrived(suffix: String) -> void:
 for i in 18000:
  if is_instance_valid(current_scene) and current_scene.scene_file_path.ends_with(suffix) and not root.get_node("SceneRouter").is_busy():
   await process_frame
   return
  await process_frame
 await require(false,"scene never arrived: " + suffix)

func walk(points: Array) -> void:
 for point in points:
  await require(await current_scene.player.walk_to(point,12),"blocked at %s toward %s" % [current_scene.player.position,point])
  await idle()

func investigate(id: String) -> void:
 await require(current_scene.can_reach(id,current_scene.player.position),"clue out of reach: "+id)
 await current_scene.interact(id)

func travel_to(target: String, suffix: String) -> void:
 current_scene.travel(target)
 await arrived(suffix)

func run() -> void:
 await process_frame
 started = Time.get_ticks_msec()
 gs = root.get_node("GameState")
 root.get_node("SaveManager").save_path = "/tmp/piggy-full-story-2026-10-30-%s.json" % DisplayServer.get_name()
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 await arrived("main.tscn")
 current_scene.get_node("%NewGameButton").pressed.emit()
 if current_scene.new_game_confirmation.visible: current_scene.new_game_confirmation.confirmed.emit()
 await arrived("prologue.tscn")
 note("natural opening")
 await arrived("bedroom.tscn")
 await idle()
 note("bedroom investigation")
 await walk([Vector2(600,465)])
 await investigate("painting")
 await walk([Vector2(610,570),Vector2(1120,610)])
 await travel_to("kitchen","kitchen.tscn")
 note("kitchen investigation")
 await walk([Vector2(285,940),Vector2(725,940)])
 await investigate("tableware")
 await walk([Vector2(1120,940),Vector2(1120,535)])
 await investigate("coffee")
 await walk([Vector2(1010,535)])
 await investigate("cup")
 await walk([Vector2(1120,560),Vector2(1250,600)])
 await travel_to("living","living.tscn")
 note("living investigation")
 await walk([Vector2(410,570)])
 await investigate("pillow")
 await walk([Vector2(410,875),Vector2(710,875)])
 await investigate("paper")
 await walk([Vector2(710,945)])
 await travel_to("outside","forest_clearing.tscn")
 await idle()
 note("forest wake and wizard")
 await walk([Vector2(840,630)])
 current_scene.paper.interact(current_scene.player)
 await idle()
 await walk([Vector2(660,730)])
 current_scene.stick.interact(current_scene.player)
 await idle()
 await walk([Vector2(740,500),Vector2(740,345)])
 Input.action_press("move_up")
 await arrived("forest_path.tscn")
 Input.action_release("move_up")
 note("find cave")
 await walk([Vector2(700,810),Vector2(740,650),Vector2(835,490),Vector2(965,380),Vector2(1090,275)])
 current_scene.enter_cave()
 await arrived("cave.tscn")
 await walk([Vector2(735,690)])
 Input.action_press("move_up")
 while not current_scene.encounter_started: await physics_frame
 Input.action_release("move_up")
 await idle()
 note("real slime combat")
 # Let the actual lunges trigger the authored 40% awakening, then fight via inputs.
 while not current_scene.awakened: await physics_frame
 await idle()
 for i in 18000:
  if current_scene.won or not is_instance_valid(current_scene.slime) or current_scene.slime._dead: break
  var actor = current_scene.player
  var enemy = current_scene.slime
  var gap: Vector2 = enemy.position-actor.position
  for pair in [["move_left",gap.x < -45],["move_right",gap.x > 45],["move_up",gap.y < -75],["move_down",gap.y > 75]]:
   if pair[1]: Input.action_press(pair[0])
   else: Input.action_release(pair[0])
  actor.face(gap)
  if i%24==0: press(KEY_J,true)
  if i%24==2: press(KEY_J,false)
  await physics_frame
 for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
 press(KEY_J,false)
 await idle()
 for i in 240:
  if current_scene.fragment.enabled: break
  await physics_frame
 await require(current_scene.fragment.enabled,"slime did not drop fragment")
 await walk([Vector2(748,485)])
 current_scene.fragment.interact(current_scene.player)
 await arrived("cabbage_act2/villa.tscn")
 note("boy exterior route")
 await walk([Vector2(1080,570),Vector2(850,650),Vector2(1030,765),Vector2(1260,835)])
 await travel_to("path","cabbage_act2/path.tscn")
 await walk([Vector2(360,520),Vector2(510,670),Vector2(760,755),Vector2(1050,795),Vector2(1145,755)])
 await travel_to("mushroom","mushroom.tscn")
 await walk([Vector2(700,710),Vector2(835,710)])
 note("mushroom password")
 current_scene.travel("door")
 while not is_instance_valid(current_scene.mushroom_story.lock_panel): await process_frame
 for code in [KEY_2,KEY_1,KEY_2,KEY_9,KEY_ENTER]: await tap(code)
 await arrived("interior.tscn")
 note("collect four paper scraps")
 await walk([Vector2(550,810),Vector2(562,604)])
 await tap(KEY_E)
 await idle()
 await walk([Vector2(558,350),Vector2(704,345)])
 await tap(KEY_E)
 await idle()
 await walk([Vector2(558,350),Vector2(550,810),Vector2(810,830),Vector2(895,830)])
 await tap(KEY_E)
 await idle()
 await walk([Vector2(750,825),Vector2(550,810),Vector2(510,803)])
 await tap(KEY_E)
 await idle()
 await require(current_scene.collectibles.collected_count()==4,"missing scraps")
 note("paper jigsaw")
 await walk([Vector2(560,790),Vector2(562,604)])
 await tap(KEY_E)
 while not is_instance_valid(current_scene.puzzle): await process_frame
 var paper = current_scene.puzzle
 for index in [2,0,3,1]: await drag_piece(paper,index,paper.target(index))
 await paper.flip()
 paper.close()
 await idle()
 await walk([Vector2(550,810),Vector2(800,765)])
 note("table slide and acorn memory")
 await tap(KEY_E)
 while not is_instance_valid(current_scene.table_puzzle): await process_frame
 var puzzle = current_scene.table_puzzle
 var solution: Array = solve_board(puzzle.board)
 for tile in solution:
  await click_at(puzzle.tiles[tile].get_global_rect().get_center())
  while is_instance_valid(puzzle) and puzzle.animating: await process_frame
 while not gs.has_flag("mushroom_acorn_memory_seen"): await process_frame
 await idle()
 await tap(KEY_E)
 await idle()
 await require(gs.has_flag("mushroom_house_completed"),"red fibre did not complete investigation")
 await walk([Vector2(810,830),Vector2(720,970)])
 await tap(KEY_E)
 await arrived("final_chapter.tscn")
 note("boy final forest path")
 Input.action_press("move_right")
 await arrived("dark_path.tscn")
 note("pig dark path and natural fall")
 await arrived("story_cave.tscn")
 Input.action_release("move_right")
 note("physical platform route")
 room = current_scene
 p = room.player
 await step(20)
 await settle()
 await platform_route()
 steer(1)
 while is_instance_valid(p) and p.position.x < 7440: await step()
 steer(0)
 await arrived("final_chapter.tscn")
 note("reunion through credits")
 for code in [KEY_A,KEY_D,KEY_J,KEY_SPACE,KEY_SHIFT]: press(code,false)
 current_scene.auto_advance = true
 Input.action_press("move_right")
 while not gs.has_flag("ending_completed"):
  Input.action_press("move_right")
  if Engine.get_process_frames()%600==0: print("FINALE_PROGRESS ",current_scene.mode," ",current_scene.current_id()," distance=",current_scene.path_distance," axis=",Input.get_axis("move_left","move_right"))
  await process_frame
 Input.action_release("move_right")
 await require(gs.has_flag("curse_broken") and gs.has_flag("cabbage_memory_restored"),"ending state incomplete")
 var snapshot: Dictionary = gs.to_dictionary()
 var saves = root.get_node("SaveManager")
 gs.reset()
 var saved_path: String = saves.load_game()
 var restored: Dictionary = gs.to_dictionary()
 # JSON numbers deserialize as floats; compare normalized payloads, not Variant types.
 await require(JSON.parse_string(JSON.stringify(restored))==JSON.parse_string(JSON.stringify(snapshot)),"ending save changed progress")
 change_scene_to_file(saved_path)
 await arrived("final_chapter.tscn")
 await require(current_scene.current_id()=="credits","continue does not restore credits")
 print("FULL_STORY_OK scenes=",events," fragments=",gs.gift_fragments)
 quit()

func click_at(point: Vector2) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.position = point
 event.pressed = true
 root.push_input(event,true)
 await process_frame
 event.pressed = false
 root.push_input(event,true)
 await process_frame

func drag_piece(puzzle: Control,index: int,destination: Vector2) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.position = puzzle.stage.get_global_transform()*puzzle.pieces[index].position
 event.pressed = true
 root.push_input(event,true)
 await process_frame
 var motion := InputEventMouseMotion.new()
 motion.position = puzzle.stage.get_global_transform()*destination
 root.push_input(motion,true)
 await process_frame
 event.position = motion.position
 event.pressed = false
 root.push_input(event,true)
 while puzzle.animating: await process_frame
 await require(puzzle.placed[index],"paper drag failed")

func platform_route() -> void:
 # 入口: sword, the small step, the first thorn gap and the first slime.
 await walk_to(410)
 await tap(KEY_E)
 check(p.combat.weapon != null and p.combat.weapon.kind == "sword", "sword pickup")
 await run_jump(430, 1, 30)
 await run_jump(735, 1, 40)
 check(p.is_on_floor() and p.position.x > 960 and absf(p.position.y - 1000) < 2, "thorn gap cleared")
 check(p.health.hp == 100, "landing zone after the gap is safe")
 await capture("gap")
 await fight(enemy_near(1430))
 stage("mushroom")
 # 蘑菇崖: the mushroom launches the pig onto the upper cliff.
 steer(1)
 await wait_until(func(): return p.position.y < 900, 400, "mushroom launch")
 await wait_until(func(): return p.is_on_floor(), 200, "landing after mushroom")
 await walk_to(1970)
 check(absf(p.position.y - 700) < 2, "mushroom reaches the cliff")
 await capture("cliff")
 await walk_to(2030)
 check(room.checkpoint_active and room.checkpoint == room.CAMPFIRES[0], "first campfire")
 await fight(enemy_near(2260), 80.0, Vector2(1900, 2580))
 stage("ferry")
 # 摆渡石板: board at the left end, ride across, step off onto the far ledge.
 await walk_to(2575)
 var ferry: Node2D = room.movers[0]
 await wait_until(func(): return ferry.position.x < 2622 and ferry.progress_at(ferry.clock + 0.35) < 0.01, 800, "ferry at the near end")
 await walk_to(ferry.position.x + 70)
 check(absf(p.position.y - 700) < 2 and p.get_floor_normal().y < -0.9, "standing on the ferry")
 await wait_until(func(): return ferry.position.x > 3268, 500, "ferry reaches the far end")
 await capture("ferry")
 await walk_to(3520)
 check(absf(p.position.y - 700) < 2, "stepped off the ferry")
 stage("patrol")
 # 荆棘回廊: the spiked patrol cannot be stomped; roll through it.
 var patrol: Node2D = enemy_near(3820)
 var hp_before: int = p.health.hp
 steer(1)
 await wait_until(func(): return patrol.position.x - p.position.x < 104, 400, "approach patrol")
 await tap(KEY_SHIFT)
 steer(1)
 await wait_until(func(): return p.position.x > patrol.position.x + 60, 120, "rolled past patrol")
 await step(10)
 check(p.health.hp == hp_before, "roll protects against the spikes")
 stage("thorn bed")
 await walk_to(4075)
 # Crumbling slabs over the thorn bed.
 await jump_to(4205, 16)
 check(absf(p.position.y - 640) < 2, "landed on first slab")
 await jump_to(4375, 14)
 check(absf(p.position.y - 620) < 2, "landed on second slab")
 await jump_to(4580, 18)
 check(p.position.x > 4520 and absf(p.position.y - 700) < 2, "crossed the thorn bed")
 check(room.crumbles.any(func(slab): return slab.state != "SOLID"), "a slab gave way behind the pig")
 stage("snail")
 await fight_snail(enemy_near(4760), Vector2(4530, 4940))
 stage("lift")
 # 升降石台 up to the canopy.
 await walk_to(4975)
 var lift: Node2D = room.movers[1]
 await wait_until(func(): return lift.position.y > 699 and lift.progress_at(lift.clock + 0.4) < 0.01, 800, "lift at the bottom")
 await walk_to(5095)
 await wait_until(func(): return lift.position.y < 431, 400, "lift reaches the canopy")
 check(absf(p.position.y - 430) < 3, "rode the lift")
 await walk_to(5440)
 await run_jump(5470, 1, 30)
 check(absf(p.position.y - 400) < 2, "canopy gap one")
 stage("canopy moth")
 await walk_to(5760)
 await fight_moth(monster("moth", 5955), Vector2(5680, 5840))
 check(absf(p.position.y - 400) < 2, "stayed on the canopy while fighting the moth")
 await run_jump(5860, 1, 26)
 check(absf(p.position.y - 430) < 2, "canopy gap two")
 await capture("canopy")
 stage("nook")
 # The leaf curtain hides the hammer.
 await walk_to(6500)
 check(room.secrets.has("nook"), "nook secret found")
 await tap(KEY_E)
 check(p.combat.weapon.kind == "hammer", "hammer pickup")
 await capture("nook")
 stage("exit climb")
 # 出口: drop to the steps and climb to the exit.
 steer(1)
 await wait_until(func(): return p.is_on_floor() and p.position.y > 700, 300, "drop from the canopy")
 steer(0)
 await run_jump(6700, 1, 30)
 await run_jump(6900, 1, 30)
 check(absf(p.position.y - 640) < 2, "final plateau")

func _send(code: int, down: bool) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.unicode = code if code >= KEY_0 and code <= KEY_9 else 0
 event.pressed = down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

const Model = preload("res://scenes/cabbage_act2/table_slide_model.gd")
var solution_path: Array[int] = []
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
  solution_path.append(tile)
  var result := search(board,depth+1,bound,empty)
  board[next] = tile
  board[empty] = Model.EMPTY
  if result == -1: return -1
  solution_path.pop_back()
  best = mini(best,result)
 return best

func solve_board(board: Array) -> Array[int]:
 solution_path.clear()
 var bound := Model.distance(board)
 while bound <= 32:
  var next := search(board.duplicate(),0,bound,-1)
  if next == -1: return solution_path.duplicate()
  bound = next
 assert(false,"Legal shuffle should have a solution")
 return []
