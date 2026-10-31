extends SceneTree
## Silent 30 fps editorial excerpt. Omitted beats are cuts, never sped-up motion.
const Story=preload("res://scenes/finale/finale_story.gd")
const SHOTS:=[["wizard_return",3.2],["protect",1.5],["final_curse",3.5],["shared_joy",1.6],["joy_burst",4.0],["wizard_dissolve",3.5],["curse_broken",1.0]]
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn")
 for i in 3: await process_frame
 var film:=current_scene
 film.set_process(false)
 for shot in SHOTS:
  film.enter_beat(Story.index_of(shot[0]))
  for i in int(shot[1]*30):
   film.beat_time=i/30.0
   film.elapsed+=1.0/30.0
   film._animate(1.0/30.0)
   film.fx.queue_redraw()
   film.hint.text="最终章 · 巫师演出片段"
   await process_frame
 print("FINALE_WIZARD_RENDER_OK")
 quit()
