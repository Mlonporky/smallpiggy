extends SceneTree
## Real scene clocks, live changes, nested pause, dialogue and audio position.
var settings: Node
var value := 0.0
var seen_sounds: Array[String] = []

func _initialize() -> void: call_deferred("run")

func frames(count := 3) -> void:
	for i in count: await process_frame

func run() -> void:
	await process_frame
	settings = root.get_node("AppSettings")
	assert(settings.settings_path.begins_with("/tmp/") or settings.settings_path.begins_with("/private/tmp/"))
	assert(settings.story_speed == 1.5)
	var gs := root.get_node("GameState")
	var original: Dictionary = gs.to_dictionary()
	settings.open_panel()
	settings.panel.tabs.current_tab = 2
	assert(settings.panel.story_speed.selected == 1)
	settings.panel.story_speed.item_selected.emit(0)
	assert(settings.story_speed == 1.0)
	settings.close_panel()
	settings.load_preferences()
	assert(settings.story_speed == 1.0 and gs.to_dictionary() == original)
	settings.set_story_speed(99)
	assert(settings.story_speed == 1.0)
	var host := Node.new()
	root.add_child(host)
	var tween: Tween = settings.story_tween(host)
	tween.tween_property(self,"value",12.0,12.0)
	tween.pause()
	tween.custom_step(1.0)
	assert(is_equal_approx(value,1.0))
	settings.set_story_speed(1.5)
	tween.custom_step(1.0)
	assert(is_equal_approx(value,2.5),"Changing speed must affect an existing story tween")
	tween.play()
	settings.open_panel()
	var frozen := value
	await create_timer(.25).timeout
	assert(value == frozen)
	settings.close_panel()
	host.queue_free()
	await frames()
	assert(not tween.is_valid(),"Changing scenes must cancel owned story tweens")
	# _process accepts real time; advance/set_shot continue to accept authored time.
	var opening = load("res://scenes/prologue/prologue.tscn").instantiate()
	opening.autoplay = false
	opening.route_on_finish = false
	root.add_child(opening)
	var music := root.get_node("MusicDirector")
	for speed in [1.0,1.5]:
		settings.set_story_speed(speed)
		opening.set_shot(0)
		opening._process(1.0)
		assert(is_equal_approx(opening.shot_time,speed))
		opening.set_shot(3,5.0)
		assert(is_equal_approx(music.opening_story_time,27.0))
		assert(absf(music.active.get_playback_position()-27.0/speed)<.08)
		assert(music.active.pitch_scale == 1.0)
		assert(absf(music.active.stream.get_length()-88.5/speed)<.01)
		opening._toggle_pause()
		var at: float = opening.shot_time
		opening._process(1.0)
		assert(opening.shot_time == at and music.active.stream_paused)
		settings.open_panel()
		settings.set_story_speed(1.5 if speed == 1.0 else 1.0)
		settings.close_panel()
		assert(opening.paused and music.active.stream_paused)
		opening._toggle_pause()
	# 88.5 seconds of source timeline finishes at 59 real seconds.
	settings.set_story_speed(1.5)
	opening.set_shot(0)
	opening._process(58.9)
	assert(not opening.finished)
	opening._process(.11)
	assert(opening.finished)
	opening.queue_free()
	await frames()
	gs.load_dictionary(original)
	change_scene_to_file("res://scenes/finale/final_chapter_preview.tscn")
	await frames()
	var finale := current_scene
	finale.set_process(false)
	finale.audio.sound_played.connect(func(key): seen_sounds.append(key))
	for speed in [1.0,1.5]:
		settings.set_story_speed(speed)
		finale.enter_path("reunion_walk")
		assert(finale.playback_speed() == 1.0,"Player-controlled approach must stay at normal speed")
		for id in ["reunion_silence","remember_name","remember_pause","remember_you","hold_hands"]:
			finale.enter_beat(finale.Story.index_of(id))
			finale._process(.2)
			assert(is_equal_approx(finale.beat_time,.2))
		finale.enter_beat(finale.Story.index_of("manor_restore"))
		finale._process(.2)
		assert(is_equal_approx(finale.beat_time,.2*speed))
		finale.enter_beat(finale.Story.index_of("final_curse"))
		seen_sounds.clear()
		finale._process(.34/speed)
		assert(seen_sounds.is_empty())
		finale._process(.02/speed)
		assert(seen_sounds == ["cast"])
		finale._process(.1)
		assert(seen_sounds == ["cast"],"Sound cue must fire only once")
		for player in finale.audio.players: assert(player.pitch_scale == 1.0)
	# Manual dialogue waits indefinitely; automatic reading keeps its real duration.
	settings.set_story_speed(1.5)
	finale.auto_advance = false
	finale.enter_beat(finale.Story.index_of("things_remain"))
	finale._process(20)
	assert(finale.current_id() == "things_remain")
	finale.auto_advance = true
	finale.enter_beat(finale.Story.index_of("things_remain"))
	var reading: float = 1.8 + str(finale.Story.BEATS[finale.beat][3]).length()*.16
	finale._process(reading-.1)
	assert(finale.current_id() == "things_remain")
	finale._process(.11)
	assert(finale.current_id() == "memory_objects")
	assert(Engine.time_scale == 1.0 and gs.to_dictionary() == original)
	print("STORY_SPEED_OK settings persistence live_tween pause cancellation opening_59s audio_mapping pitch dialogue_reading protected_beats movement cue_once")
	quit()
