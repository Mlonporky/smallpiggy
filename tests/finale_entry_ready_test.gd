extends SceneTree
## Real routed entry: preparation must stay covered and not consume story time.
const Meter=preload("res://tests/finale_render_meter.gd")
var film: Node
var prepared_under_cover:=false
var frozen_frames:=0
var sampled:=false
var meter: RefCounted

func _initialize() -> void: call_deferred("run")

func observe() -> void:
 if film==null or film.rendering_ready: return
 assert(film.beat_time==0 and film.elapsed==0)
 assert(root.get_node("SceneTransition").get_child(0).color.a==1)
 frozen_frames+=1

func drawn() -> void:
 # On the first revealed frame start measuring, without screenshot/readback.
 if film!=null and film.rendering_ready and not sampled:
  var cover:=root.get_node_or_null("SceneTransition")
  if cover==null or cover.get_child(0).color.a<.99:
   sampled=true
   meter.start(self)

func run() -> void:
 assert(DisplayServer.get_name()!="headless")
 Engine.max_fps=60
 await process_frame
 var state:=root.get_node("GameState")
 state.reset()
 for key in ["cave_level_completed","mushroom_house_completed","finale_pig_path_done","finale_cabbage_path_done"]: state.set_flag(key)
 state.flags["finale_checkpoint"]="first_reunion"
 var dummy:=Node2D.new()
 root.add_child(dummy)
 current_scene=dummy
 meter=Meter.new()
 process_frame.connect(observe)
 RenderingServer.frame_post_draw.connect(drawn)
 scene_changed.connect(func():
  film=current_scene
  assert(not film.rendering_ready)
  film.presentation_ready.connect(func():
   assert(root.get_node("SceneTransition").get_child(0).color.a==1)
   assert(film.beat_time==0 and film.elapsed==0)
   prepared_under_cover=true))
 var router:=root.get_node("SceneRouter")
 DisplayServer.window_move_to_foreground()
 router.change_scene("res://scenes/finale/final_chapter.tscn",.28)
 while not sampled: await process_frame
 var began:=Time.get_ticks_usec()
 while Time.get_ticks_usec()-began<3000000:
  meter.sample(film.current_id())
  await process_frame
 assert(not router.is_busy() and root.get_node_or_null("SceneTransition")==null)
 assert(prepared_under_cover and frozen_frames>0 and film.rendering_ready)
 assert(film.beat_time>0 and not film.audio.paused)
 var report: Dictionary=meter.finish()
 report["prepared_under_cover"]=prepared_under_cover
 report["story_frozen_frames"]=frozen_frames
 report["preparation"]=film.rendering_preparation
 FileAccess.open("res://docs/verification/entry_2026-10-31/routed_entry.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("FINALE_ENTRY_READY_OK covered=",prepared_under_cover," frozen_frames=",frozen_frames," draw_max=",report.draw_intervals.max_ms)
 quit(0 if report.render_coverage_valid else 1)
