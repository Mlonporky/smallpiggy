extends SceneTree
const RenderMeter=preload("res://tests/finale_render_meter.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Playback needs a graphics window")
  quit(1)
  return
 # Bound the test to a normal desktop frame budget, without changing project settings.
 Engine.max_fps=60
 change_scene_to_file("res://scenes/animation_studies/phase4_character_study.tscn")
 for i in 10: await process_frame
 assert(current_scene.calibrated)
 DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
 DisplayServer.window_move_to_foreground()
 await create_timer(.5).timeout
 current_scene.set_view(1)
 var meter:=RenderMeter.new()
 meter.start(self)
 while current_scene.clock<current_scene.DURATION:
  await process_frame
  meter.sample("side_walk")
 var report:=meter.finish()
 var out:=FileAccess.open("res://docs/art_direction/phase4_boy_v1/playback_rendering.json",FileAccess.WRITE)
 out.store_string(JSON.stringify(report,"  "))
 out.close()
 print("PHASE4_PLAYBACK_OK seconds=",report.seconds," coverage_valid=",report.render_coverage_valid," p95_ms=",report.draw_intervals.get("p95_ms",-1))
 await create_timer(.2).timeout
 quit(0 if report.render_coverage_valid else 1)
