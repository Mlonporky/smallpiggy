extends SceneTree
## 27-second acting excerpt, including a final still; no runtime FPS claim.
const FPS := 30
const FRAMES := 810
var film: Node
var frame := 0
func _initialize() -> void:
 RenderingServer.render_loop_enabled = false
 root.title = "正在导出重逢样片 · 完成后自动关闭"
 root.close_requested.connect(func(): print("FINALE_REUNION_RENDER_INTERRUPTED window_close frame=",frame))
 call_deferred("setup")
func setup() -> void:
 if Engine.get_write_movie_path().is_empty():
  push_error("Use --fixed-fps 30 --write-movie /an/empty/folder/frame.png")
  quit(1)
  return
 film = load("res://scenes/finale/reunion_preview.tscn").instantiate()
 root.add_child(film)
 current_scene = film
 film.set_process(false)
 film.set_process_unhandled_key_input(false)
 process_frame.connect(step)
func step() -> void:
 if not is_equal_approx(film.get_process_delta_time(), 1.0 / FPS):
  push_error("Export requires fixed 30 FPS")
  quit(1)
  return
 # Initial fade is sampled by the preview before its first draw.
 if frame > 0: film._process(1.0 / FPS)
 film.fx.queue_redraw()
 call_deferred("draw_frame")
func draw_frame() -> void:
 RenderingServer.force_draw(false, 1.0 / FPS)
 frame += 1
 if frame % 150 == 0: print("FINALE_REUNION_RENDER_PROGRESS ",frame,"/",FRAMES)
 if frame == FRAMES:
  print("FINALE_REUNION_RENDER_OK frames=", frame, " finished=", film.finished)
  quit(0 if film.finished else 1)
