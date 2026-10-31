extends SceneTree
## Normal-speed engine mix recording; editorial jumps are explicitly logged.
const Story=preload("res://scenes/finale/finale_story.gd")
var events: Array[Dictionary]=[]
var start := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var original: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn")
 for i in 4: await process_frame
 var film:=current_scene
 film.set_process(false)
 var capture:=AudioEffectRecord.new()
 capture.format=AudioStreamWAV.FORMAT_16_BITS
 AudioServer.add_bus_effect(0,capture)
 var slot:=AudioServer.get_bus_effect_count(0)-1
 start=Time.get_ticks_usec()
 film.audio.sound_played.connect(func(key): events.append({"sound":key,"seconds":(Time.get_ticks_usec()-start)/1000000.0}))
 capture.set_recording_active(true)
 for shot in [["final_curse",3.5],["joy_burst",4.0],["wizard_dissolve",3.5],["curse_broken",3.0],["manor_restore",18.0],["return_home",2.5]]:
  film.enter_beat(Story.index_of(shot[0]))
  var at:=Time.get_ticks_usec()
  var last:=at
  while (Time.get_ticks_usec()-at)/1000000.0<float(shot[1]):
   await process_frame
   var now:=Time.get_ticks_usec()
   var delta: float=(now-last)/1000000.0
   last=now
   film.beat_time=(now-at)/1000000.0
   film.elapsed+=delta
   if shot[0]=="return_home": Input.action_press("move_right")
   film._animate(delta)
   film.audio.footsteps(film.pig,"pig")
   film.audio.footsteps(film.cabbage,"cabbage")
   film.fx.queue_redraw()
 Input.action_release("move_right")
 capture.set_recording_active(false)
 var recording:=capture.get_recording()
 assert(recording!=null and recording.get_length()>34)
 assert(recording.save_to_wav("res://docs/art_direction/finale/residents_v1/sound_excerpt.wav")==OK)
 AudioServer.remove_bus_effect(0,slot)
 var report:=FileAccess.open("res://docs/art_direction/finale/residents_v1/sound_events.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"seconds":recording.get_length(),"events":events,"preview_isolation":root.get_node("GameState").to_dictionary()==original},"  "))
 report.close()
 assert(root.get_node("GameState").to_dictionary()==original)
 print("FINALE_SOUND_PLAYBACK_OK seconds=",recording.get_length()," effects=",events.size())
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 quit()
