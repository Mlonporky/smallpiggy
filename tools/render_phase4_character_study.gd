extends SceneTree
## Silent 18-second comparison: 4 seconds still + 14 seconds motion, 30 fps export.
## Offline export is not a runtime smoothness measurement.
const FPS := 30
const FRAMES := 540
var film: Node
var frame := 0
func _initialize() -> void:
 RenderingServer.render_loop_enabled=false
 root.title="正在导出第四阶段角色样片"
 call_deferred("setup")
func setup() -> void:
 if Engine.get_write_movie_path().is_empty():
  push_error("Use --fixed-fps 30 --write-movie /an/empty/folder/frame.png")
  quit(1)
  return
 film=load("res://scenes/animation_studies/phase4_character_study.tscn").instantiate()
 root.add_child(film)
 current_scene=film
 film.set_process(false)
 film.set_process_unhandled_key_input(false)
 # Calibration draws are included in the first still, never extra movie frames.
 process_frame.connect(step)
func step() -> void:
 if not is_equal_approx(film.get_process_delta_time(),1.0/FPS):
  push_error("Export requires fixed 30 FPS")
  quit(1)
  return
 if frame==120: film.set_view(1)
 if frame>=120: film.sample((frame-120)/float(FPS))
 call_deferred("draw_frame")
func draw_frame() -> void:
 RenderingServer.force_draw(false,1.0/FPS)
 frame+=1
 if frame%150==0: print("PHASE4_RENDER_PROGRESS ",frame,"/",FRAMES)
 if frame==FRAMES:
  print("PHASE4_RENDER_OK frames=",frame," calibrated=",film.calibrated)
  quit(0 if film.calibrated else 1)
