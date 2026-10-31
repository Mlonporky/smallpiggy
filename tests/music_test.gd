extends SceneTree
func _initialize() -> void: call_deferred("run")
func key(scene: Node, code: int) -> void:
 var e := InputEventKey.new()
 e.pressed = true
 e.physical_keycode = code
 scene._unhandled_input(e)
func run() -> void:
 await process_frame
 var music := root.get_node("MusicDirector")
 var opening = load("res://scenes/prologue/prologue.tscn").instantiate()
 opening.autoplay = false
 opening.route_on_finish = false
 root.add_child(opening)
 assert(absf(music.OPENING.get_length()-88.5)<.01)
 assert(absf(music.MORNING.get_length()-54.0)<.01)
 assert(music.current_track == "opening" and music.active.stream_paused)
 var expected_times := [0.0,3.5,8.0,22.0,40.0,49.0,53.0,61.0,66.0,72.0,79.0,82.5]
 for i in expected_times.size():
  opening.set_shot(i,.8)
  assert(absf(opening.score_time()-expected_times[i]-.8)<.01)
  assert(absf(music.last_seek-opening.score_time())<.01)
 key(opening,KEY_P)
 assert(opening.paused and music.active.stream_paused)
 key(opening,KEY_P)
 assert(not opening.paused and not music.active.stream_paused)
 opening.set_shot(3,1.1)
 key(opening,KEY_SPACE)
 assert(absf(music.last_seek-27.0)<.01,"Dialogue skip must seek the soundtrack too")
 key(opening,KEY_M)
 assert(music.muted and opening.muted)
 assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
 key(opening,KEY_R)
 assert(music.last_seek==0 and not music.active.stream_paused)
 assert(music.muted,"Replay must preserve mute")
 key(opening,KEY_M)
 assert(not music.muted and not opening.muted)
 opening.skip_to_chapter()
 assert(music.current_track=="morning" and music.active.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)
 var player: AudioStreamPlayer = music.active
 await create_timer(.2).timeout
 music.play_track("morning")
 assert(music.active == player,"Room changes must retain the same playing stream")
 assert(music.active.stream.loop_end == 2381400)
 opening.queue_free()
 await process_frame
 change_scene_to_file("res://scenes/chapter1/kitchen.tscn")
 await process_frame
 await process_frame
 assert(music.active == player and music.current_track=="morning")
 change_scene_to_file("res://scenes/bootstrap/main.tscn")
 await process_frame
 await process_frame
 assert(music.current_track.is_empty(),"Leaving scored scenes must stop their score")
 await create_timer(.8).timeout
 for voice in music.voices: assert(not voice.playing)
 print("MUSIC_TEST_OK scene timing, pause, seek, restart, mute, loop, room continuity, exit")
 quit()
