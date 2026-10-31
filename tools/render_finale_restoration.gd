extends SceneTree
## Export 540 explicitly drawn frames and exactly 18 seconds of engine audio.
## Use --fixed-fps 30 --write-movie /an/empty/folder/frame.png.
## Automatic rendering may skip an occluded window. Each process iteration must
## therefore draw once; waiting for frame_post_draw can record duplicate frames.
const FPS := 30
const FRAME_COUNT := 18 * FPS
var film: Node
var frame := 0
var checks: Array[Dictionary] = []

func _initialize() -> void:
 RenderingServer.render_loop_enabled = false
 call_deferred("setup")

func setup() -> void:
 if Engine.get_write_movie_path().is_empty():
  push_error("Use --fixed-fps 30 --write-movie /an/empty/folder/frame.png")
  quit(1)
  return
 film = load("res://scenes/finale/restoration_preview.tscn").instantiate()
 root.add_child(film)
 current_scene = film
 film.set_process(false)
 process_frame.connect(step)

func step() -> void:
 if not is_equal_approx(film.get_process_delta_time(), 1.0 / FPS):
  push_error("Export requires a fixed 30 FPS clock")
  quit(1)
  return
 film.beat_time = float(frame) / FPS
 film.elapsed = film.beat_time
 film._animate(1.0 / FPS)
 film.fx.queue_redraw()
 # Flush CanvasItem's queued draw notifications before capturing the viewport.
 call_deferred("draw_frame")

func draw_frame() -> void:
 RenderingServer.force_draw(false, 1.0 / FPS)
 if frame in [0, 90, 195, 234, 300, FRAME_COUNT - 1]:
  var pixel: Vector2 = film.background.to_global(Vector2(.46, .13) * film.MANOR.get_size())
  var brightness := root.get_texture().get_image().get_pixelv(Vector2i(pixel)).get_luminance()
  checks.append({"frame": frame, "seconds": float(frame) / FPS, "sky": brightness})
 frame += 1
 if frame == FRAME_COUNT:
  print("RESTORATION_RENDER_CHECKS ", JSON.stringify(checks))
  if checks[-1].sky < .7 or checks[-1].sky < checks[0].sky + .25:
   push_error("Export did not restore the background")
   quit(1)
  else:
   print("FINALE_RESTORATION_RENDER_OK frames=", frame)
   quit()
