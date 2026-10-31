extends SceneTree
func _initialize() -> void:
 create_timer(45).timeout.connect(func(): push_error("AUDIO_PREVIEW_TIMEOUT");quit(1))
 call_deferred("run")
func key(code: int) -> void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.pressed=true
 root.push_input(event,true)
func run() -> void:
 await process_frame
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/audio_studies/gameplay_audio_preview.tscn")
 for i in 4: await process_frame
 var film:=current_scene
 film.set_process(false)
 key(KEY_SPACE)
 assert(film.paused and film.audio.audio_paused)
 var time: float=film.section_time
 film._process(1)
 assert(film.section_time==time)
 key(KEY_F1)
 assert(paused)
 key(KEY_F1)
 assert(not paused and film.paused and film.audio.audio_paused)
 for code in [KEY_1,KEY_2,KEY_3,KEY_4]:
  key(code)
  assert(film.section==code-KEY_1 and not film.paused)
 key(KEY_R)
 for i in 1930:
  film._process(1.0/60)
  film.audio._process(1.0/60)
 assert(film.finished and film.total_time==32 and film.audio.audio_paused)
 key(KEY_ESCAPE)
 key(KEY_ESCAPE)
 assert(film.audio.audio_paused,"Closing a finished sample pause resumed sound")
 key(KEY_R)
 assert(not film.finished and film.section==0)
 assert(root.get_node("GameState").to_dictionary()==state)
 print("GAMEPLAY_AUDIO_PREVIEW_OK sections pause F1 finish replay state_isolation")
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 await create_timer(.15).timeout
 quit()
