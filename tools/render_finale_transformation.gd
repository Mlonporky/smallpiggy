extends SceneTree
## 7-second continuous excerpt: original dialogue, transformation, approach.
const FPS := 30
const FRAMES := 210
var film: Node
var frame := 0
func _initialize() -> void:
 RenderingServer.render_loop_enabled = false
 call_deferred("setup")
func setup() -> void:
 if Engine.get_write_movie_path().is_empty():
  push_error("Use --fixed-fps 30 --write-movie /an/empty/folder/frame.png")
  quit(1)
  return
 film = load("res://scenes/finale/transformation_preview.tscn").instantiate()
 root.add_child(film)
 current_scene = film
 film.set_process(false)
 process_frame.connect(step)
func step() -> void:
 if not is_equal_approx(film.get_process_delta_time(), 1.0 / FPS):
  push_error("Export requires fixed 30 FPS")
  quit(1)
  return
 # Process after the first frame so t=0 contains the intact boy.
 if frame > 0: film._process(1.0 / FPS)
 film.fx.queue_redraw()
 call_deferred("draw_frame")
func draw_frame() -> void:
 RenderingServer.force_draw(false, 1.0 / FPS)
 frame += 1
 if frame == FRAMES:
  print("FINALE_TRANSFORMATION_RENDER_OK frames=", frame, " finished=", film.finished)
  quit(0 if film.finished else 1)
