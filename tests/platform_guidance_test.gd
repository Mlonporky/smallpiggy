extends SceneTree
## Input regression and localized guidance checks, not a human difficulty test.
var room
var output := "/tmp/piggy-phase3-platform"
func _initialize() -> void: call_deferred("run")
func key(code: int) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = true
 Input.parse_input_event(event)
 await physics_frame
 event = event.duplicate()
 event.pressed = false
 Input.parse_input_event(event)
 await physics_frame
func check(value: bool, message: String) -> void:
 if not value:
  push_error("PLATFORM_GUIDANCE_FAILED: " + message)
  quit(1)
  await process_frame
func capture(label: String) -> void:
 if DisplayServer.get_name() == "headless": return
 DirAccess.make_dir_recursive_absolute(output)
 await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
 await process_frame
 root.get_node("GameState").reset()
 for path in ["res://scenes/action_test/test_level.tscn", "res://scenes/finale/story_cave.tscn"]:
  change_scene_to_file(path)
  while not is_instance_valid(current_scene) or current_scene.scene_file_path != path:
   await process_frame
  for i in 6: await physics_frame
  room = current_scene
  room.player.reset_at(Vector2(500,940))
  for i in 6: await physics_frame
  await key(KEY_ESCAPE)
  await check(room.paused, "Esc pauses the room")
  var before: Vector2 = room.player.position
  var time_before: float = room.elapsed
  await key(KEY_R)
  await check(room.player.position == before, "R must not move or reset the player while paused: " + path)
  await check(room.elapsed == time_before, "Pause freezes the play clock")
  await key(KEY_ESCAPE)
  await key(KEY_R)
  await check(room.player.position.distance_to(room.START) < 3, "R still returns to the start when playing")
  room.player.reset_at(room.CAMPFIRES[0])
  for i in 8: await physics_frame
  await check(room.checkpoint_active, "Camp lights on landing")
  # A collected ID and a discovered secret survive an actual R input.
  room.fireflies[0].taken = true
  room.firefly_count = room.fireflies.filter(func(fly): return fly.taken).size()
  room.secrets["cavern"] = true
  var collected: int = room.firefly_count
  room.player.reset_at(Vector2(550,940))
  await key(KEY_R)
  await check(room.player.position.distance_to(room.CAMPFIRES[0]) < 3, "R returns to the lit camp")
  await check(room.firefly_count >= collected and room.fireflies[0].taken and room.secrets.has("cavern"), "R preserves collections even if another firefly is picked up during input delivery")
  room.player.reset_at(Vector2(2500,700))
  for i in 4: await physics_frame
  room.notice_time = 0
  await check("坑底" in room.exploration_hint(), "Lower branch has localized guidance")
  room.player.reset_at(Vector2(4930,700))
  for i in 4: await physics_frame
  await check("岔路" in room.exploration_hint(), "Elevator junction explains both paths")
  var story: bool = "story_cave" in path
  var extents := [Vector2i(1152,648)] if DisplayServer.get_name() == "headless" else [Vector2i(800,600),Vector2i(1152,648)]
  for extent in extents:
   root.size = extent
   room.player.reset_at(Vector2(7010,640))
   room.snap_view()
   room.notice_time = 0
   for i in 8: await physics_frame
   await check(not room.finished, "Exit guidance appears before the irreversible story transition")
   await check("R" in room.prompt.text, "Visible prompt explains returning before exit")
   await check(room.stage.size.x-room.prompt.position.x >= room.prompt.get_minimum_size().x, "Exit prompt must fit the logical canvas")
   if story: await check("无需集齐" in room.prompt.text and "剧情" in room.prompt.text, "Story exit is explicit about optional collection")
   await capture(("story" if story else "standalone")+"-exit-%dx%d" % [extent.x,extent.y])
 print("PLATFORM_GUIDANCE_OK")
 quit()
