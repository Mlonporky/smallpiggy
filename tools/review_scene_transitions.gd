extends SceneTree
## Six labelled excerpts of production cameras/cuts; silent, no saved state changes.
## Normal mode measures real rendering; Movie Maker mode writes 660 PNGs at 30 FPS.
const Story=preload("res://scenes/finale/finale_story.gd")
const Meter=preload("res://tests/finale_render_meter.gd")
const LENGTHS=[4.5,4.5,6.0,6.0,4.5,6.0]
const LABELS=["卧室 → 诅咒：同机位连续", "惊慌 → 传送：画面与光粒延续", "重逢：缓慢推近", "回忆 → 现实：短叠化（剪选）", "森林 → 山庄：接续淡入", "走远 → 对白：停在原地"]
const OUT="res://docs/verification/motion_2026-10-31/"
var film: Node
var opening: Node
var label: Label
var clock := 0.0
var clip := -1
var export_mode := false
var frames := 0
var original: Dictionary
var meter: RefCounted

func _initialize() -> void:
 export_mode=not Engine.get_write_movie_path().is_empty()
 if export_mode: RenderingServer.render_loop_enabled=false
 else: Engine.max_fps=60
 call_deferred("setup")

func setup() -> void:
 original=root.get_node("GameState").to_dictionary().duplicate(true)
 opening=load("res://scenes/prologue/prologue.tscn").instantiate()
 opening.autoplay=false
 opening.route_on_finish=false
 root.add_child(opening)
 opening.set_process_unhandled_input(false)
 root.get_node("GameState").load_dictionary(original)
 film=make_film()
 root.add_child(film)
 film.set_process(false)
 film.set_process_unhandled_key_input(false)
 await film.wait_for_presentation()
 film.audio.pause(true)
 root.get_node("MusicDirector").stop_music()
 root.title="镜头与场景衔接 · 1.5× 无声剪选"
 var overlay:=CanvasLayer.new()
 overlay.layer=200
 root.add_child(overlay)
 label=Label.new()
 label.position=Vector2(16,8)
 label.add_theme_font_size_override("font_size",19)
 label.add_theme_constant_override("outline_size",7)
 label.add_theme_color_override("font_outline_color",Color(.03,.04,.06,.95))
 overlay.add_child(label)
 sample(0)
 if not export_mode:
  DisplayServer.window_move_to_foreground()
  for i in 5: await process_frame
  meter=Meter.new()
  meter.start(self)
 process_frame.connect(step)

func make_film() -> Node:
 return load("res://scenes/finale/final_chapter_preview.tscn").instantiate()

func enter_clip(index: int) -> void:
 clip=index
 opening.visible=index<2
 film.visible=index>=2
 label.text="%d / 6  %s   ·   1.5× 无声剪选" % [index+1,LABELS[index]]
 if index==0: opening.set_shot(5,2.8)
 if index==1: opening.set_shot(7,3.8)
 if index<2: root.get_node("MusicDirector").pause_opening(true)
 if index==2: film.enter_beat(Story.index_of("reunion_silence"))
 if index==3: film.enter_beat(Story.index_of("memory_house"))
 if index==4: film.enter_beat(Story.index_of("light_travels"))
 if index==5: film.enter_beat(Story.index_of("home_seek"))
 film.audio.pause(true)

func shot(id: String, at: float) -> void:
 if film.current_id()!=id: film.enter_beat(Story.index_of(id))
 film.beat_time=at
 film._animate(0)

func sample(seconds: float) -> void:
 var t:=minf(seconds*1.5,31.5-.0001)
 var index:=0
 while index<LENGTHS.size()-1 and t>=LENGTHS[index]:
  t-=LENGTHS[index]
  index+=1
 if index!=clip: enter_clip(index)
 if index<2:
  var start:=5 if index==0 else 7
  var at:=t+(2.8 if index==0 else 3.8)
  if at>=float(opening.shots[start].duration):
   at-=float(opening.shots[start].duration)
   start+=1
  if opening.shot_index!=start:
   opening.set_shot(start,at)
   root.get_node("MusicDirector").pause_opening(true)
  opening.shot_time=at
  opening._render_shot()
  opening.location_label.visible=false
 elif index==2:
  shot("reunion_silence" if t<1 else "first_reunion",t if t<1 else t-1)
 elif index==3:
  var ids: Array[String]=["memory_house","memory_together","memory_gift","remember_name"]
  shot(ids[mini(int(t/1.5),3)],fmod(t,1.5))
 elif index==4:
  shot("light_travels" if t<.8 else "manor_restore",t+2.7 if t<.8 else t-.8)
 elif index==5:
  if t<1: shot("home_seek",t)
  elif t<4: shot("walk_away",t-1)
  else: shot("final_secret",t-4)
 film.elapsed=seconds*1.5
 film.chapter_label.visible=false
 film.hint.visible=false
 film._layout()
 film.fx.queue_redraw()

func step() -> void:
 var delta:=1.0/30 if export_mode else root.get_process_delta_time()
 if frames>0: clock+=delta
 sample(clock)
 if export_mode:
  call_deferred("draw_frame")
 else:
  meter.sample(str(clip))
  frames+=1
  if clock>=22: finish()

func draw_frame() -> void:
 RenderingServer.force_draw(false,1.0/30)
 frames+=1
 if frames==660: finish()

func finish() -> void:
 assert(root.get_node("GameState").to_dictionary()==original)
 if not export_mode:
  var report: Dictionary=meter.finish()
  FileAccess.open(OUT+"playback.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
  print("SCENE_TRANSITION_PLAYBACK_OK seconds=",report.seconds," coverage=",report.render_coverage_valid," draw_p95_ms=",report.draw_intervals.p95_ms," max_ms=",report.draw_intervals.max_ms)
  assert(report.render_coverage_valid)
 else: print("SCENE_TRANSITION_RENDER_OK frames=",frames)
 quit()
