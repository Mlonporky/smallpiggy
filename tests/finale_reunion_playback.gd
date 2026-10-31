extends SceneTree
const Meter=preload("res://tests/finale_render_meter.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
 DisplayServer.window_move_to_foreground()
 var state: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/reunion_preview.tscn")
 await process_frame
 var film:=current_scene
 var recording: AudioEffectRecord
 var slot: int
 var events: Array[Dictionary]=[]
 var start:=Time.get_ticks_usec()
 if OS.get_cmdline_user_args().has("--record"):
  recording=AudioEffectRecord.new()
  recording.format=AudioStreamWAV.FORMAT_16_BITS
  AudioServer.add_bus_effect(0,recording)
  slot=AudioServer.get_bus_effect_count(0)-1
  recording.set_recording_active(true)
  film.audio.sound_played.connect(func(key): events.append({"sound":key,"seconds":(Time.get_ticks_usec()-start)/1000000.0}))
 var meter:=Meter.new()
 meter.start(self)
 while not film.finished:
  await process_frame
  meter.sample(film.current_id())
 var rendering:=meter.finish()
 if recording!=null:
  recording.set_recording_active(false)
  assert(recording.get_recording().save_to_wav("res://docs/art_direction/finale/reunion_v2/engine_mix.wav")==OK)
  AudioServer.remove_bus_effect(0,slot)
 assert(rendering.render_coverage_valid and root.get_node("GameState").to_dictionary()==state)
 var output:="res://docs/art_direction/finale/reunion_v2/playback.json"
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--report="): output=argument.trim_prefix("--report=")
 var file:=FileAccess.open(output,FileAccess.WRITE)
 file.store_string(JSON.stringify({"rendering":rendering,"preview_isolation":true,"sound_events":events},"  "))
 file.close()
 print("FINALE_REUNION_PLAYBACK_OK ",rendering.seconds,"s draw_p95=",rendering.draw_intervals.p95_ms," max=",rendering.draw_intervals.max_ms)
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 quit()
