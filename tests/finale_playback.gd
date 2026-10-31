extends SceneTree
const RenderMeter=preload("res://tests/finale_render_meter.gd")
var times: Array[float]=[]
var last:=0
var elapsed:=0.0
var film: Node
var visited: Array[String]=[]
var long_frames: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 if DisplayServer.get_name()!="headless":
  DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
  DisplayServer.window_move_to_foreground()
 var original: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn")
 for i in 4: await process_frame
 film=current_scene
 film.auto_advance=true
 film.beat_changed.connect(func(id): visited.append(id))
 last=Time.get_ticks_usec()
 var start:=last
 var meter:=RenderMeter.new()
 meter.start(self)
 film.beat_changed.connect(func(id): meter.segment=id)
 while film.current_id()!="credits" and Time.get_ticks_usec()-start<300000000:
  if film.mode.ends_with("path") or film.mode=="reunion_walk" or film.current_id()=="return_home":
   Input.action_press("move_right")
  else: Input.action_release("move_right")
  await process_frame
  meter.sample(film.current_id())
  var now:=Time.get_ticks_usec()
  var frame_ms:=(now-last)/1000.0
  times.append(frame_ms)
  if frame_ms>35.0: long_frames.append({"beat":film.current_id(),"beat_time":film.beat_time,"frame_ms":frame_ms,"engine_process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
  last=now
 Input.action_release("move_right")
 assert(film.current_id()=="credits")
 assert(root.get_node("GameState").to_dictionary()==original)
 var rendering:=meter.finish()
 var duration: float=(Time.get_ticks_usec()-start)/1000000.0
 times.sort()
 var report: Dictionary={"seconds":duration,"samples":times.size(),"p50_ms":times[times.size()/2],"p95_ms":times[int(times.size()*0.95)],"max_ms":times.back(),"beats":visited,"preview_isolation":true,"rendered_frames":rendering.engine_drawn,"rendering":rendering,"frames_over_35ms":long_frames}
 var report_path:="res://docs/art_direction/finale/playback.json"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--report="): report_path=arg.trim_prefix("--report=")
 var out:=FileAccess.open(report_path,FileAccess.WRITE)
 out.store_string(JSON.stringify(report,"  "))
 out.close()
 print("FINALE_PLAYBACK_OK ",duration,"s process_p95=",report.p95_ms," process_max=",report.max_ms)
 print("FINALE_RENDER_COVERAGE valid=",rendering.render_coverage_valid," draws=",rendering.frame_post_draw_count," draw_p95=",rendering.draw_intervals.get("p95_ms",-1)," nondrawable_seconds=",rendering.window_nondrawable_seconds)
 # Do not call a completed storyline a valid rendering-performance capture.
 var require_coverage:=OS.get_cmdline_user_args().has("--require-draw-coverage")
 var result:=0 if not require_coverage or rendering.render_coverage_valid else 2
 film.queue_free()
 await process_frame
 quit(result)
