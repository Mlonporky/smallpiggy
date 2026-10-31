extends SceneTree
const Story = preload("res://scenes/finale/finale_story.gd")
func _initialize() -> void: call_deferred("run")
func key(code: int) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.pressed = true
 root.push_input(event, true)
func run() -> void:
 await process_frame
 var state: Dictionary = root.get_node("GameState").to_dictionary()
 for entry in [["restoration", "manor_restore", 18.0], ["transformation", "close_name", 2.4], ["handhold", "shared_joy", 3.2], ["wizard", "curse_broken", 3.0]]:
  change_scene_to_file("res://scenes/finale/" + entry[0] + "_preview.tscn")
  for i in 3: await process_frame
  var film := current_scene
  film.set_process(false)
  film.enter_beat(Story.index_of(entry[1]))
  film._process(entry[2] + .01)
  assert(film.finished and film.audio.paused)
  var time: float = film.beat_time
  key(KEY_ESCAPE)
  assert(film.paused and film.menu.visible)
  key(KEY_ESCAPE)
  assert(not film.paused and not film.menu.visible)
  assert(film.audio.paused, "Closing the finished-preview menu resumed music: " + entry[0])
  film._process(.25)
  assert(film.beat_time == time)
  key(KEY_SPACE)
  assert(not film.finished and not film.audio.paused and film.beat_time == 0.0)
 assert(root.get_node("GameState").to_dictionary() == state)
 print("FINALE_PREVIEW_MENU_OK finished_pause_and_replay=4")
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 await create_timer(.12).timeout
 quit()
