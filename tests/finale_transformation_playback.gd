extends SceneTree
## Normal-speed runtime coverage, independent of Movie Maker's fixed clock.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var original: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/transformation_preview.tscn")
 for i in 3: await process_frame
 var film := current_scene
 var times: Array[float] = []
 var progress: Array[Dictionary] = []
 var start := Time.get_ticks_usec()
 var last := start
 var next_check := .25
 while not film.finished and Time.get_ticks_usec() - start < 15000000:
  await process_frame
  var now := Time.get_ticks_usec()
  times.append((now - last) / 1000.0)
  last = now
  if film.current_id() == "remember_you" and film.beat_time >= next_check and next_check < 1.5:
   progress.append({"time": film.beat_time, "progress": film.cabbage.transformation.progress})
   next_check += .25
 assert(film.finished and progress.size() >= 5)
 assert(progress[0].progress < .1 and progress[-1].progress > .98)
 assert(root.get_node("GameState").to_dictionary() == original)
 times.sort()
 var report := {"seconds": (Time.get_ticks_usec() - start) / 1000000.0, "samples": times.size(), "p95_ms": times[int(times.size() * .95)], "max_ms": times.back(), "transformation": progress, "preview_isolation": true}
 var file := FileAccess.open("res://docs/art_direction/finale/transformation_v1/playback.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(report, "  "))
 file.close()
 print("FINALE_TRANSFORMATION_PLAYBACK_OK ", report)
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 quit()
