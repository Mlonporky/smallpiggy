extends SceneTree
## Normal wall-clock playback, audio drift and settings screenshots. Never fixed-fps.
var settings: Node
var opening: Node
var output := "/tmp/piggy-story-speed-visual"
var measurements: Array[Dictionary] = []

func _initialize() -> void: call_deferred("run")

func frames(count := 4) -> void:
	for i in count: await process_frame

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event,true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await frames()

func capture(name: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	assert(root.get_texture().get_image().save_png(output.path_join(name+".png")) == OK)

func observe(seconds: float) -> void:
	var start := Time.get_ticks_usec()
	var story: float = opening.score_time()
	var speed: float = settings.story_speed
	var music := root.get_node("MusicDirector")
	var max_drift := 0.0
	var seeks := 0
	var last_seek: float = music.last_seek
	while (Time.get_ticks_usec()-start)/1000000.0 < seconds:
		await process_frame
		max_drift = maxf(max_drift,absf(music.active.get_playback_position()-opening.score_time()/speed))
		if music.last_seek != last_seek: seeks += 1
		last_seek = music.last_seek
	var elapsed := (Time.get_ticks_usec()-start)/1000000.0
	var progress: float = opening.score_time()-story
	print("SPEED_TIMING ",speed," real=",elapsed," story=",progress," drift=",max_drift," seeks=",seeks)
	assert(absf(progress-elapsed*speed)<.15,"Story must follow the selected real-time rate")
	assert(max_drift<.20 and seeks<=1,"Steady playback must not keep seeking the score")
	measurements.append({"speed":speed,"real_seconds":elapsed,"story_seconds":progress,"max_audio_drift_seconds":max_drift,"score_seeks":seeks})

func run() -> void:
	await process_frame
	assert(DisplayServer.get_name() != "headless")
	Engine.max_fps = 60
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	DisplayServer.window_move_to_foreground()
	settings = root.get_node("AppSettings")
	assert(settings.settings_path.contains("/tmp/"))
	settings.set_story_speed(1.5)
	var state: Dictionary = root.get_node("GameState").to_dictionary()
	DirAccess.make_dir_recursive_absolute(output)
	opening = load("res://scenes/prologue/prologue.tscn").instantiate()
	opening.route_on_finish = false
	root.add_child(opening)
	current_scene = opening
	await frames()
	for extent in [Vector2i(800,600),Vector2i(1152,648),Vector2i(1440,900)]:
		root.size = extent
		await create_timer(.15).timeout
		await key(KEY_F1)
		settings.panel.tabs.current_tab = 2
		await frames()
		print("SPEED_PANEL ",root.get_visible_rect()," panel=",settings.panel.get_global_rect()," min=",settings.panel.get_combined_minimum_size())
		await capture("settings-%dx%d" % [extent.x,extent.y])
		assert(root.get_visible_rect().encloses(settings.panel.get_global_rect()))
		assert(settings.panel.get_global_rect().encloses(settings.panel.story_speed.get_global_rect()))
		await capture("settings-%dx%d" % [extent.x,extent.y])
		var at: float = opening.score_time()
		await create_timer(.2).timeout
		assert(opening.score_time() == at)
		await key(KEY_ESCAPE)
	root.size = Vector2i(1152,648)
	await create_timer(.6).timeout
	opening.set_shot(0)
	await frames()
	await observe(7)
	await capture("opening-fast")
	await key(KEY_F1)
	settings.panel.tabs.current_tab = 2
	settings.panel.story_speed.grab_focus()
	await key(KEY_ENTER)
	await key(KEY_UP)
	await key(KEY_ENTER)
	assert(settings.story_speed == 1.0,"Keyboard selection must change the actual speed")
	await key(KEY_ESCAPE)
	await observe(5)
	await key(KEY_P)
	var at: float = opening.score_time()
	await key(KEY_F1)
	settings.set_story_speed(1.5)
	await key(KEY_ESCAPE)
	await create_timer(.3).timeout
	assert(opening.score_time() == at and opening.paused and root.get_node("MusicDirector").active.stream_paused)
	await key(KEY_P)
	await observe(3)
	await key(KEY_R)
	assert(opening.score_time()<.25)
	await observe(3)
	opening.queue_free()
	await frames()
	root.get_node("GameState").load_dictionary(state)
	change_scene_to_file("res://scenes/finale/reunion_preview.tscn")
	await frames()
	var film := current_scene
	var began := Time.get_ticks_usec()
	while not film.finished and Time.get_ticks_usec()-began<35000000:
		await process_frame
	assert(film.finished)
	await capture("reunion-fast-end")
	assert(root.get_node("GameState").to_dictionary() == state)
	var file := FileAccess.open(output.path_join("playback.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"opening":measurements,"reunion_seconds":(Time.get_ticks_usec()-began)/1000000.0,"keyboard_switch":true,"pause_replay":true,"preview_isolation":true},"  "))
	file.close()
	print("STORY_SPEED_PLAYBACK_OK ",measurements)
	change_scene_to_file("res://scenes/bootstrap/main.tscn")
	await frames()
	quit()
