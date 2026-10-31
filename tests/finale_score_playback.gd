extends SceneTree
## Real-time engine mix review with explicit editorial cuts and a loop boundary.
const Story = preload("res://scenes/finale/finale_story.gd")
const SHOTS := [["pig_path", 6.0], ["first_reunion", 6.0], ["memory_house", 6.0], ["wizard_return", 6.0], ["shared_joy", 6.0], ["curse_broken", 6.0], ["home_here", 6.0], ["path_loop_boundary", 4.0]]
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var original: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn")
 for i in 4: await process_frame
 var film := current_scene
 film.set_process(false)
 var capture := AudioEffectRecord.new()
 capture.format = AudioStreamWAV.FORMAT_16_BITS
 AudioServer.add_bus_effect(0, capture)
 var slot := AudioServer.get_bus_effect_count(0) - 1
 capture.set_recording_active(true)
 var start := Time.get_ticks_usec()
 var cuts: Array[Dictionary] = []
 for shot in SHOTS:
  if shot[0] == "pig_path" or shot[0] == "path_loop_boundary": film.enter_path("pig_path")
  else: film.enter_beat(Story.index_of(shot[0]))
  if shot[0] == "path_loop_boundary":
   film.audio.music[film.audio.active_music].seek(46.0)
  cuts.append({"shot": shot[0], "mood": film.audio.mood, "seconds": (Time.get_ticks_usec() - start) / 1000000.0})
  var at := Time.get_ticks_usec()
  var last := at
  while (Time.get_ticks_usec() - at) / 1000000.0 < shot[1]:
   await process_frame
   var now := Time.get_ticks_usec()
   var delta := (now - last) / 1000000.0
   last = now
   film.beat_time = (now - at) / 1000000.0
   film.elapsed += delta
   if film.mode == "cinematic": film._animate(delta)
   else:
    film.audio.timeline("pig_path", film.beat_time, delta)
    film.pig.distance += 80 * delta
    film.pig.pose(true)
    film.audio.footsteps(film.pig, "pig")
   film.fx.queue_redraw()
 capture.set_recording_active(false)
 var recording := capture.get_recording()
 assert(recording != null and recording.get_length() > 45.9 and recording.get_length() < 47)
 assert(recording.save_to_wav("res://docs/art_direction/finale/score_v2/engine_mix_excerpt.wav") == OK)
 AudioServer.remove_bus_effect(0, slot)
 assert(root.get_node("GameState").to_dictionary() == original)
 var report := FileAccess.open("res://docs/art_direction/finale/score_v2/engine_mix_cuts.json", FileAccess.WRITE)
 report.store_string(JSON.stringify({"seconds": recording.get_length(), "cuts": cuts, "preview_isolation": true}, "  "))
 report.close()
 print("FINALE_SCORE_PLAYBACK_OK seconds=", recording.get_length())
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 await create_timer(.12).timeout
 quit()
