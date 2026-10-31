extends SceneTree
## Real-time audio mixer capture, not frame-accelerated simulation or a listening verdict.
const Bank=preload("res://systems/audio/gameplay_audio.gd")
const OUT="res://docs/audio/phase5_2026-10-31/"
var capture: AudioEffectRecord
var slot: int
var film: Node
var settings: Node
var events: Array[Dictionary]=[]
var started:=0
func _initialize() -> void:
 Engine.max_fps=60
 create_timer(65).timeout.connect(func(): push_error("AUDIO_MIX_TIMEOUT");quit(1))
 call_deferred("run")
func record_clip(name: String, seconds: float) -> void:
 await create_timer(.15).timeout
 capture.set_recording_active(true)
 await create_timer(seconds).timeout
 capture.set_recording_active(false)
 var clip:=capture.get_recording()
 assert(clip!=null and clip.get_length()>seconds-.1)
 assert(clip.save_to_wav(OUT+name+".wav")==OK)
 print("AUDIO_MIX_CAPTURE ",name," seconds=",clip.get_length())
func run() -> void:
 await process_frame
 var original: Dictionary=root.get_node("GameState").to_dictionary()
 settings=root.get_node("AppSettings")
 assert(settings.settings_path.begins_with("/tmp/") or settings.settings_path.begins_with("/private/tmp/"))
 settings.restore_defaults()
 change_scene_to_file("res://scenes/audio_studies/gameplay_audio_preview.tscn")
 for i in 4: await process_frame
 film=current_scene
 film.set_process(false)
 film.start_section(0)
 capture=AudioEffectRecord.new()
 capture.format=AudioStreamWAV.FORMAT_16_BITS
 AudioServer.add_bus_effect(0,capture)
 slot=AudioServer.get_bus_effect_count(0)-1
 await create_timer(.8).timeout
 await record_clip("mix_ambience",.8)
 settings.set_volume("Ambience",0)
 await record_clip("mix_ambience_off",.6)
 film.audio.cue("complete")
 await record_clip("mix_effect",.6)
 settings.set_volume("Effects",0)
 film.audio.cooldowns.clear()
 film.audio.cue("complete")
 await record_clip("mix_effects_off",.6)
 settings.set_volume("Ambience",1)
 settings.set_volume("Effects",1)
 settings.set_muted(true)
 await record_clip("mix_muted",.6)
 settings.set_muted(false)
 film.audio.set_audio_paused(true)
 await record_clip("mix_local_paused",.6)
 film.audio.set_audio_paused(false)
 settings.open_panel()
 assert(paused)
 await record_clip("mix_settings_paused",.6)
 settings.close_panel()
 assert(not paused)
 await record_clip("mix_resumed",.6)
 # Capture the complete audition at gameplay gain, with its real scheduling.
 film.start_section(0)
 film.set_process(true)
 started=Time.get_ticks_usec()
 capture.set_recording_active(true)
 var bank_id:=0
 while not film.finished:
  if bank_id!=film.audio.get_instance_id():
   bank_id=film.audio.get_instance_id()
   film.audio.sound_played.connect(func(kind: String): events.append({"kind":kind,"seconds":(Time.get_ticks_usec()-started)/1000000.0}))
  await process_frame
 capture.set_recording_active(false)
 var sample:=capture.get_recording()
 assert(sample.get_length()>31.8 and sample.get_length()<32.8)
 assert(sample.save_to_wav(OUT+"gameplay_audio_sample.wav")==OK)
 AudioServer.remove_bus_effect(0,slot)
 if DisplayServer.get_name()!="headless":
  film.start_section(0)
  film.set_process(false)
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png(OUT+"preview.png")
 var report:=FileAccess.open(OUT+"playback_events.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"seconds":sample.get_length(),"events":events,"state_unchanged":root.get_node("GameState").to_dictionary()==original,"max_fps":Engine.max_fps},"  "))
 report.close()
 assert(root.get_node("GameState").to_dictionary()==original)
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 # Mixer shutdown and a scene without gameplay audio must leave no tail.
 capture=AudioEffectRecord.new()
 capture.format=AudioStreamWAV.FORMAT_16_BITS
 AudioServer.add_bus_effect(0,capture)
 slot=AudioServer.get_bus_effect_count(0)-1
 await record_clip("mix_menu",.6)
 AudioServer.remove_bus_effect(0,slot)
 print("GAMEPLAY_AUDIO_MIX_OK sample_seconds=",sample.get_length()," events=",events.size())
 quit()
