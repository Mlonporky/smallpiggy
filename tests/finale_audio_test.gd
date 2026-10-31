extends SceneTree
const Story=preload("res://scenes/finale/finale_story.gd")
var events: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var original: Dictionary=root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn")
 for i in 4: await process_frame
 var film:=current_scene
 film.set_process(false)
 var audio: Node=film.audio
 audio.sound_played.connect(func(key):events.append(key))
 audio.set_process(false)
 # Every replaced sketch is a full arrangement with the intended loop length.
 var lengths := {"path":48.0,"reunion":48.0,"memory":32.0,"curse":24.0,"joy":32.0,"home":32.0,"restored":48.0}
 for key in lengths:
  assert(is_equal_approx(audio.loops[key].get_length(),lengths[key]))
  audio.set_mood(key)
  audio._process(.9)
  var player: AudioStreamPlayer=audio.music[audio.active_music]
  assert(player.playing and is_equal_approx(player.volume_db,audio.MUSIC_GAIN_DB[key]))
  var same_player: AudioStreamPlayer=player
  audio.set_mood(key)
  assert(audio.music[audio.active_music]==same_player and audio.fade_time==1.0)
 film.enter_beat(Story.index_of("someone"))
 audio.timeline("someone",.13,.016)
 audio.timeline("someone",.65,.016)
 audio.timeline("someone",.7,.016)
 assert(events==["step_1","step_2"],"Offscreen steps must precede the boy")
 assert(audio.music_duck_target<.2)
 film.enter_beat(Story.index_of("remember_pause"))
 assert(audio.music_duck_target==.65)
 film.enter_beat(Story.index_of("remember_you"))
 assert(audio.music_duck_target==1.0)
 film.enter_beat(Story.index_of("memory_house"))
 assert(audio.music_duck_target==0 and audio.environment[1]<.04)
 events.clear()
 film.enter_beat(Story.index_of("final_curse"))
 audio.timeline("final_curse",.2,.016)
 assert(events.is_empty())
 audio.timeline("final_curse",.4,.016)
 audio.timeline("final_curse",1.0,.016)
 assert(events==["cast"])
 film.enter_beat(Story.index_of("final_curse"))
 audio.timeline("final_curse",.4,.016)
 assert(events==["cast","cast"],"Replay lost the effect")
 film.enter_beat(Story.index_of("manor_restore"))
 audio.timeline("manor_restore",9.3,.016)
 assert(audio.mood=="home" and audio.environment[2]>.2)
 audio.timeline("manor_restore",9.4,.016)
 assert(audio.mood=="restored")
 audio._process(.9)
 var song: AudioStreamPlayer=audio.music[audio.active_music]
 var stream: AudioStream=song.stream
 assert(song.playing and song.volume_db>-11)
 film.enter_beat(Story.index_of("return_home"))
 film.enter_beat(Story.index_of("home_here"))
 assert(audio.music[audio.active_music]==song and song.stream==stream,"Home dialogue restarted the music")
 for loop in audio.loops.values():
  assert(loop.loop_end==roundi(loop.get_length()*loop.mix_rate))
  assert(loop.loop_mode==AudioStreamWAV.LOOP_FORWARD)
 audio.set_muted(true)
 audio.play_sound("wave",-9)
 audio._process(.1)
 for player in audio.players: assert(player.volume_db<=-79)
 audio.pause(true)
 var fade: float=audio.fade_time
 audio._process(.2)
 assert(audio.fade_time==fade)
 assert(song.stream_paused)
 for player in audio.players:
  if player.playing: assert(player.stream_paused)
 var count:=events.size()
 audio.play_sound("cast",-12)
 assert(events.size()==count)
 audio.set_muted(false)
 assert(song.volume_db>-11)
 audio.pause(false)
 for player in audio.players: assert(not player.stream_paused)
 # Walking creates contacts, stopping and a shot jump do not create steps.
 events.clear()
 film.enter_path("pig_path")
 audio.footsteps(film.pig,"pig")
 for i in 120:
  film.pig.distance+=1.4
  film.pig.pose(true)
  audio.footsteps(film.pig,"pig")
 var steps:=events.size()
 assert(steps>2 and steps<15)
 film.pig.pose(false)
 for i in 30: audio.footsteps(film.pig,"pig")
 assert(events.size()==steps)
 audio.begin_scene("reunion_close")
 film.pig.distance+=1000
 film.pig.pose(true)
 audio.footsteps(film.pig,"pig")
 assert(events.size()==steps,"Teleport produced catch-up footsteps")
 audio.timeline("credits",0,.016)
 assert(audio.environment==[0.0,0.0,0.0])
 assert(root.get_node("GameState").to_dictionary()==original)
 print("FINALE_AUDIO_OK steps=",steps," replay/mute/pause/continuity/isolation")
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 for i in 4: await process_frame
 # AudioServer retires stopped playbacks on its mixer thread, not on a scene tick.
 await create_timer(.12).timeout
 quit()
