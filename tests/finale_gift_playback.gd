extends SceneTree
## Normal-speed local repetitions, including each entry cost and actual draws.
const Story=preload("res://scenes/finale/finale_story.gd")
const Meter=preload("res://tests/finale_render_meter.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
 DisplayServer.window_move_to_foreground()
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn")
 for i in 4: await process_frame
 var film:=current_scene
 film.set_process(false)
 var entries: Array[Dictionary]=[]
 var meter:=Meter.new()
 meter.start(self)
 for trial in 5:
  for id in ["remember_cups","remember_gift","remember_you","reunion_close"]:
   meter.segment=id
   var before:=Time.get_ticks_usec()
   film.enter_beat(Story.index_of(id))
   entries.append({"trial":trial,"beat":id,"entry_ms":(Time.get_ticks_usec()-before)/1000.0})
   var data: Array=Story.BEATS[film.beat]
   var duration: float=maxf(float(data[1]),1.8+str(data[3]).length()*.16) if not str(data[3]).is_empty() else float(data[1])
   var start:=Time.get_ticks_usec()
   var last:=start
   while (Time.get_ticks_usec()-start)/1000000.0<duration:
    await process_frame
    var now:=Time.get_ticks_usec()
    var dt: float=(now-last)/1000000.0
    last=now
    film.beat_time=(now-start)/1000000.0
    film.elapsed+=dt
    film._animate(dt)
    film.fx.queue_redraw()
    meter.sample(id)
 var render:=meter.finish()
 var isolated: bool=root.get_node("GameState").to_dictionary()==state
 var report: Dictionary={"trials":5,"entries":entries,"rendering":render,"preview_isolation":isolated}
 var output := "res://docs/art_direction/finale/render_diagnostics/gift_repetitions.json"
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--report="): output=argument.trim_prefix("--report=")
 var file:=FileAccess.open(output,FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 file.close()
 assert(isolated and render.render_coverage_valid)
 print("FINALE_GIFT_PLAYBACK_OK trials=5 draw_p95=",render.draw_intervals.p95_ms," max=",render.draw_intervals.max_ms," long_draws=",render.long_draw_intervals.size())
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 quit()
