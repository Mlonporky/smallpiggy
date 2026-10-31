extends RefCounted
## Render submission telemetry, not display scanout or GPU presentation timing.
## No screenshots, force_draw, file I/O or focus changes while measuring.
var tree: SceneTree
var started := 0
var last_process := 0
var last_draw := 0
var engine_start := 0
var post_count := 0
var process_count := 0
var drawable_usec := 0
var blocked_usec := 0
var previous_can_draw := false
var previous_state := ""
var draw_intervals: Array[float] = []
var visible_draw_intervals: Array[float] = []
var process_intervals: Array[float] = []
var long_draws: Array[Dictionary] = []
var transitions: Array[Dictionary] = []
var windows: Array[Dictionary] = []
var segment := ""
var block_since_draw := false

func start(owner: SceneTree) -> void:
 tree=owner
 started=Time.get_ticks_usec()
 last_process=started
 engine_start=Engine.get_frames_drawn()
 previous_can_draw=DisplayServer.window_can_draw()
 RenderingServer.frame_post_draw.connect(_drawn)
 _state(started)

func sample(label: String) -> void:
 segment=label
 var now:=Time.get_ticks_usec()
 var dt:=now-last_process
 if previous_can_draw: drawable_usec+=dt
 else: blocked_usec+=dt
 process_intervals.append(dt/1000.0)
 last_process=now
 process_count+=1
 _state(now)
 previous_can_draw=DisplayServer.window_can_draw()
 if not previous_can_draw: block_since_draw=true
 var index:=int((now-started)/1000000)
 while windows.size()<=index:
  windows.append({"second":windows.size(),"process":0,"post_draw":0,"blocked_process":0})
 windows[index].process+=1
 if not previous_can_draw: windows[index].blocked_process+=1

func _state(now: int) -> void:
 var state:=str([DisplayServer.window_can_draw(),DisplayServer.window_is_focused(),DisplayServer.window_get_mode(),RenderingServer.render_loop_enabled,OS.low_processor_usage_mode])
 if state==previous_state: return
 previous_state=state
 transitions.append({"seconds":(now-started)/1000000.0,"beat":segment,"can_draw":DisplayServer.window_can_draw(),"focused":DisplayServer.window_is_focused(),"mode":DisplayServer.window_get_mode(),"render_loop":RenderingServer.render_loop_enabled,"low_processor":OS.low_processor_usage_mode})

func _drawn() -> void:
 var now:=Time.get_ticks_usec()
 post_count+=1
 var index:=int((now-started)/1000000)
 while windows.size()<=index:
  windows.append({"second":windows.size(),"process":0,"post_draw":0,"blocked_process":0})
 windows[index].post_draw+=1
 if last_draw>0:
  var gap:=(now-last_draw)/1000.0
  draw_intervals.append(gap)
  if not block_since_draw: visible_draw_intervals.append(gap)
  if gap>35:
   long_draws.append({"seconds":(now-started)/1000000.0,"beat":segment,"gap_ms":gap,"crossed_nondrawable_window":block_since_draw})
 last_draw=now
 block_since_draw=false

static func stats(values: Array[float]) -> Dictionary:
 if values.is_empty(): return {"samples":0}
 var sorted:=values.duplicate()
 sorted.sort()
 return {"samples":sorted.size(),"p50_ms":sorted[sorted.size()/2],"p95_ms":sorted[int(sorted.size()*.95)],"max_ms":sorted.back()}

func finish() -> Dictionary:
 RenderingServer.frame_post_draw.disconnect(_drawn)
 var end:=Time.get_ticks_usec()
 var seconds:=(end-started)/1000000.0
 var counter:=Engine.get_frames_drawn()-engine_start
 # A boundary may be sampled before the engine increments its draw counter.
 var counters_agree:=absi(counter-post_count)<=1
 var coverage:=float(post_count)/maxi(1,process_count)
 return {"seconds":seconds,"process_frames":process_count,"engine_drawn":counter,"frame_post_draw_count":post_count,"counters_agree":counters_agree,"draw_submissions_per_second":post_count/seconds,"draw_to_process_ratio":coverage,"window_drawable_seconds":drawable_usec/1000000.0,"window_nondrawable_seconds":blocked_usec/1000000.0,"process_intervals":stats(process_intervals),"draw_intervals":stats(draw_intervals),"drawable_only_draw_intervals":stats(visible_draw_intervals),"long_draw_intervals":long_draws,"window_transitions":transitions,"per_second":windows,"render_coverage_valid":DisplayServer.get_name()!="headless" and counters_agree and blocked_usec<10000 and coverage>=.95,"rendering_method":RenderingServer.get_current_rendering_method(),"rendering_driver":RenderingServer.get_current_rendering_driver_name(),"vsync":DisplayServer.window_get_vsync_mode(),"screen_hz":DisplayServer.screen_get_refresh_rate(),"max_fps":Engine.max_fps,"note":"Render submissions, not monitor presentation FPS; coverage validity is not a smoothness pass."}
