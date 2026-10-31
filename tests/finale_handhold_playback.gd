extends SceneTree
var film: Node
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var original: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/handhold_preview.tscn")
 for i in 3: await process_frame
 film=current_scene
 var times: Array[float]=[]
 var start:=Time.get_ticks_usec()
 var last:=start
 while not film.finished and Time.get_ticks_usec()-start<20000000:
  await process_frame
  var now:=Time.get_ticks_usec()
  times.append((now-last)/1000.0)
  last=now
 assert(film.finished)
 assert(root.get_node("GameState").to_dictionary()==original)
 times.sort()
 var report: Dictionary={"seconds":(Time.get_ticks_usec()-start)/1000000.0,"samples":times.size(),"p95_ms":times[int(times.size()*0.95)],"max_ms":times.back(),"preview_isolation":true}
 var output:=FileAccess.open("res://docs/art_direction/finale/handhold_v2/playback.json",FileAccess.WRITE)
 output.store_string(JSON.stringify(report,"  "))
 output.close()
 # Real replay input starts the same isolated sequence again.
 var event:=InputEventKey.new()
 event.keycode=KEY_SPACE
 event.pressed=true
 root.push_input(event,true)
 await process_frame
 assert(not film.finished and film.current_id()=="joy_failing")
 print("FINALE_HANDHOLD_PLAYBACK_OK ",report)
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 3: await process_frame
 quit()
