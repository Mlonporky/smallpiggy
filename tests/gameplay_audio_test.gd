extends SceneTree
const Bank=preload("res://systems/audio/gameplay_audio.gd")
func _initialize() -> void:
 create_timer(30).timeout.connect(func(): push_error("GAMEPLAY_AUDIO_TIMEOUT");quit(1))
 call_deferred("run")
func run() -> void:
 await process_frame
 var host:=Node.new()
 root.add_child(host)
 var bank: Node=Bank.attach(host,"forest")
 bank.set_process(false)
 assert(bank.sounds.size()==23 and bank.voices.size()==8 and bank.ambience.size()==2)
 for voice in bank.ambience:
  assert(voice.bus=="Ambience" and voice.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)
  assert(voice.stream.format==AudioStreamWAV.FORMAT_16_BITS,"Import must preserve PCM loop boundaries")
  assert(voice.stream.loop_end==roundi(voice.stream.get_length()*voice.stream.mix_rate))
 for key in bank.sounds:
  assert(bank.sounds[key].get_length()>0 and bank.sounds[key].loop_mode==AudioStreamWAV.LOOP_DISABLED)
 var events: Array[String]=[]
 bank.sound_played.connect(func(kind: String): events.append(kind))
 assert(bank.cue("paper"))
 assert(not bank.cue("paper"),"Repeated contact must not flood the mix")
 assert(not bank.cue("unknown"),"Unknown events must not fall back to a beep")
 bank._process(.7)
 bank.set_audio_paused(true)
 var fade: float=bank.fade
 bank._process(1)
 assert(bank.fade==fade and not bank.cue("gift"))
 for voice in bank.voices+bank.ambience:
  if voice.playing: assert(voice.stream_paused)
 bank.set_audio_paused(false)
 paused=true
 assert(not bank.cue("gift"))
 paused=false
 for voice in bank.voices: voice.stop()
 bank.cooldowns.clear()
 events.clear()
 bank.footsteps(Vector2.ZERO,true)
 for i in 60:
  bank._process(1.0/60)
  bank.footsteps(Vector2((i+1)*3,0),true)
 assert(events.size()==3,"Step distance must follow movement")
 var before:=events.size()
 for i in 20: bank.footsteps(Vector2(180,0),true)
 bank.footsteps(Vector2(2000,0),true)
 bank.footsteps(Vector2(2080,0),false)
 bank.footsteps(Vector2(2080,0),true)
 assert(events.size()==before,"Idle, teleport or airborne movement made catch-up steps")
 for voice in bank.voices: voice.stop()
 bank.cooldowns.clear()
 for kind in ["step_1","swing","hit","crack","bounce","roll","chime","puff"]:
  assert(bank.cue(kind))
 assert(bank.get_child_count()==10)
 assert(bank.cue("gift"),"A pickup must be able to replace a low-priority step")
 assert(bank.get_child_count()==10,"Effect pool grew under pressure")
 for voice in bank.voices: assert(voice.bus=="Effects" and voice.volume_db<=-16)
 bank._transition_started("res://scenes/bootstrap/main.tscn")
 bank._process(.3)
 assert(bank.fade==0 and not bank.cue("hit"))
 for voice in bank.voices+bank.ambience: assert(voice.volume_db<-70)
 var refs: Array=[]
 for voice in bank.voices+bank.ambience: refs.append(weakref(voice))
 host.queue_free()
 await process_frame
 for ref in refs: assert(ref.get_ref()==null,"Scene-owned player survived its scene")
 print("GAMEPLAY_AUDIO_OK loops buses pause footsteps throttle priority fixed_pool exit_cleanup")
 quit()
