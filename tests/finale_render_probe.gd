extends SceneTree
## Bounded live diagnostic; never force-draw or alter the scene's clock.
const RenderMeter=preload("res://tests/finale_render_meter.gd")
var film: Node
var start := 0
var last_draw := 0
var draws: Array[float] = []
var process_count := 0
var post_count := 0
var blocked := 0
var bins: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var previous_state := ""
var duration := 12.0
var variant := "foreground"
var subject := "restoration"
var counter_start := 0
func _initialize() -> void: call_deferred("run")
func on_draw() -> void:
 if start == 0: return
 var now := Time.get_ticks_usec()
 if last_draw > 0: draws.append((now-last_draw)/1000.0)
 last_draw = now
 post_count += 1
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--variant="): variant=arg.trim_prefix("--variant=")
  if arg.begins_with("--subject="): subject=arg.trim_prefix("--subject=")
 if DisplayServer.get_name()=="headless":
  push_error("This diagnostic needs a real graphics window")
  quit(1)
  return
 if subject=="empty":
  var rect := ColorRect.new()
  rect.size=Vector2(300,300)
  rect.color=Color.CORAL
  root.add_child(rect)
  film=rect
 else:
  var path := "res://scenes/finale/restoration_preview.tscn" if subject=="restoration" else "res://scenes/finale/final_chapter_preview.tscn"
  change_scene_to_file(path)
  for i in 4: await process_frame
  film=current_scene
  if subject=="trail": film.enter_beat(film.Story.index_of("memory_trail")); film.auto_advance=false
 if variant in ["foreground","cycle","no_vsync"]:
  DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
  DisplayServer.window_move_to_foreground()
 if variant=="no_vsync": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 await create_timer(.5).timeout
 RenderingServer.frame_post_draw.connect(on_draw)
 counter_start=Engine.get_frames_drawn()
 start=Time.get_ticks_usec()
 var meter:=RenderMeter.new()
 meter.start(self)
 var phase:=0
 while (Time.get_ticks_usec()-start)/1000000.0<duration:
  await process_frame
  var t: float=(Time.get_ticks_usec()-start)/1000000.0
  if subject=="empty": film.position.x=100+sin(t*3)*70
  if variant=="cycle":
   if phase==0 and t>=4:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
    phase=1
   elif phase==1 and t>=8:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_move_to_foreground()
    phase=2
  meter.sample(subject)
  process_count+=1
  var can_draw:=DisplayServer.window_can_draw()
  if not can_draw: blocked+=1
  var index:=int(t)
  while bins.size()<=index: bins.append({"second":bins.size(),"process":0,"post_draw":0,"counter":0,"blocked":0})
  bins[index].process+=1
  bins[index].post_draw=post_count
  bins[index].counter=Engine.get_frames_drawn()-counter_start
  if not can_draw: bins[index].blocked+=1
  var state:=str([can_draw,DisplayServer.window_is_focused(),DisplayServer.window_get_mode()])
  if state!=previous_state:
   samples.append({"seconds":t,"can_draw":can_draw,"focused":DisplayServer.window_is_focused(),"mode":DisplayServer.window_get_mode()})
   previous_state=state
 var measured:=meter.finish()
 RenderingServer.frame_post_draw.disconnect(on_draw)
 var seconds: float=(Time.get_ticks_usec()-start)/1000000.0
 draws.sort()
 var report: Dictionary={"subject":subject,"variant":variant,"seconds":seconds,"process_frames":process_count,"engine_drawn":Engine.get_frames_drawn()-counter_start,"post_draw":post_count,"blocked_process_frames":blocked,"draw_p95_ms":draws[int(draws.size()*.95)] if not draws.is_empty() else -1,"draw_max_ms":draws.back() if not draws.is_empty() else -1,"draw_fps":post_count/seconds,"transitions":samples,"bins":bins,"low_processor":OS.low_processor_usage_mode,"render_loop":RenderingServer.render_loop_enabled,"vsync":DisplayServer.window_get_vsync_mode(),"screen_hz":DisplayServer.screen_get_refresh_rate(),"max_fps":Engine.max_fps}
 report["rendering"]=measured
 var path:="res://docs/art_direction/finale/render_diagnostics/"+subject+"_"+variant+".json"
 var out:=FileAccess.open(path,FileAccess.WRITE)
 out.store_string(JSON.stringify(report,"  "))
 out.close()
 assert(measured.counters_agree,"Draw counters disagree")
 if variant=="cycle":
  assert(not measured.render_coverage_valid and measured.window_nondrawable_seconds>2,"Minimization did not invalidate rendering coverage")
 elif variant=="foreground":
  assert(measured.render_coverage_valid,"Foreground rendering coverage invalid")
 print("RENDER_PROBE_OK ",subject," ",variant," draws=",post_count," process=",process_count," blocked=",blocked," p95=",report.draw_p95_ms," max=",report.draw_max_ms," coverage_valid=",measured.render_coverage_valid)
 quit()
