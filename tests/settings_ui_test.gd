extends SceneTree
## End-to-end input, persistence, nested pause and responsive UI regression.
var settings: Node
var saves: Node
var output := "/tmp/piggy-phase12-ui"

func _initialize() -> void: call_deferred("run")

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
	await process_frame

func frames(count := 3) -> void:
	for i in count: await process_frame

func save_key() -> void:
	# Physics polling needs the global Input state, not only Viewport GUI delivery.
	var event := InputEventKey.new()
	event.keycode = KEY_F5
	event.physical_keycode = KEY_F5
	event.pressed = true
	Input.parse_input_event(event)
	for i in 2: await physics_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames()
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func scene(path: String) -> void:
	change_scene_to_file(path)
	await frames()

func run() -> void:
	await process_frame
	settings = root.get_node("AppSettings")
	saves = root.get_node("SaveManager")
	assert(settings.settings_path.begins_with("/tmp/") or settings.settings_path.begins_with("/private/tmp/"),"Test requires isolated settings")
	saves.save_path = "/tmp/piggy-phase12-ui-save-%s.json" % DisplayServer.get_name()
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(saves.save_path+suffix)
	DirAccess.make_dir_recursive_absolute(output)
	settings.restore_defaults()
	await scene("res://scenes/bootstrap/main.tscn")
	var extents := [Vector2i(1152,648)] if DisplayServer.get_name() == "headless" else [Vector2i(800,600),Vector2i(1152,648),Vector2i(1440,900)]
	for extent in extents:
		root.size = extent
		await create_timer(.15).timeout
		await frames(6)
		print("WINDOW_CHECK window=",root.size," logical=",root.get_visible_rect().size)
		var menu := current_scene
		for name in ["NewGameButton","ContinueButton","SettingsButton","PreviewsButton"]:
			var button: Control = menu.get_node("%"+name)
			assert(root.get_visible_rect().encloses(button.get_global_rect()),"Menu cropped: "+name)
		assert(not menu.get_node("%ChapterOneButton").is_visible_in_tree())
		await capture("menu-%dx%d" % [extent.x,extent.y])
		await key(KEY_F1)
		assert(paused and is_instance_valid(settings.panel))
		assert(root.get_visible_rect().encloses(settings.panel.get_global_rect()))
		await capture("settings-%dx%d" % [extent.x,extent.y])
		settings.panel.tabs.current_tab = 1
		await capture("controls-%dx%d" % [extent.x,extent.y])
		settings.panel.tabs.current_tab = 0
		settings.panel.mute.grab_focus()
		await key(KEY_TAB)
		assert(root.gui_get_focus_owner() is HSlider,"Tab should reach the music slider")
		await key(KEY_LEFT)
		assert(settings.volumes.Music < 1.0,"Keyboard slider must change the actual bus preference")
		settings.set_volume("Music",1.0)
		await key(KEY_ESCAPE)
		assert(not paused and settings.overlay == null)
	root.size = Vector2i(1152,648)
	current_scene.get_node("%PreviewsButton").pressed.emit()
	await capture("preview-menu")
	assert(current_scene.get_node("%ChapterOneButton").is_visible_in_tree())
	await key(KEY_ESCAPE)
	assert(not current_scene.get_node("%ChapterOneButton").is_visible_in_tree())
	# New-game confirmation protects existing progress; isolated chapter testing does too.
	assert(saves.save_game("res://scenes/chapter1/bedroom.tscn"))
	var original := FileAccess.get_file_as_string(saves.save_path)
	current_scene._on_new_game_pressed()
	assert(current_scene.new_game_confirmation.visible)
	current_scene.new_game_confirmation.hide()
	assert(current_scene.scene_file_path.ends_with("main.tscn"))
	var state: Dictionary = root.get_node("GameState").to_dictionary()
	current_scene._on_chapter_one_pressed()
	await root.get_node("SceneRouter").transition_finished
	assert(saves.preview_mode and current_scene.scene_file_path.ends_with("bedroom.tscn"))
	root.get_node("GameState").set_flag("ui_test_preview")
	assert(saves.save_game(current_scene.scene_file_path))
	root.get_node("SceneRouter").change_scene("res://scenes/bootstrap/main.tscn")
	await root.get_node("SceneRouter").transition_finished
	assert(not saves.preview_mode)
	assert(FileAccess.get_file_as_string(saves.save_path) == original)
	assert(root.get_node("GameState").to_dictionary() == state)
	# Settings persist and route each category independently.
	await key(KEY_F1)
	settings.panel.sliders.Music.value = 35
	settings.panel.sliders.Effects.value = 60
	settings.panel.sliders.Ambience.value = 0
	await key(KEY_M)
	assert(settings.muted and AudioServer.is_bus_mute(0))
	await key(KEY_ESCAPE)
	settings.load_preferences()
	assert(settings.muted and is_equal_approx(settings.volumes.Music,.35))
	assert(is_equal_approx(settings.volumes.Effects,.6) and settings.volumes.Ambience == 0)
	await scene("res://scenes/finale/final_chapter_preview.tscn")
	assert(current_scene.audio.muted,"Mute must survive the transition into the finale")
	for voice in current_scene.audio.music: assert(voice.bus == "Music")
	for voice in current_scene.audio.ambience: assert(voice.bus == "Ambience")
	for voice in current_scene.audio.effects: assert(voice.bus == "Effects")
	await key(KEY_M)
	assert(not current_scene.audio.muted and not root.get_node("MusicDirector").muted)
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")))
	await scene("res://scenes/prologue/prologue.tscn")
	await create_timer(.15).timeout
	await key(KEY_ESCAPE)
	assert(current_scene.paused,"Esc must pause, not skip the opening")
	await key(KEY_ESCAPE)
	assert(not current_scene.paused)
	await key(KEY_F1)
	var shot_time: float = current_scene.shot_time
	await create_timer(.3).timeout
	assert(current_scene.shot_time == shot_time)
	assert(root.get_node("MusicDirector").active.stream_paused)
	await key(KEY_ESCAPE)
	assert(not root.get_node("MusicDirector").active.stream_paused)
	# A nested settings panel must return to the original forest pause menu.
	await scene("res://scenes/chapter2/cave.tscn")
	await key(KEY_ESCAPE)
	assert(paused and current_scene.busy)
	current_scene.find_child("settings",true,false).pressed.emit()
	await frames()
	assert(settings.overlay != null)
	await key(KEY_ESCAPE)
	assert(paused and current_scene.busy and settings.overlay == null)
	await key(KEY_ESCAPE)
	assert(not paused and not current_scene.busy)
	# Close-up Esc consumes the key; the room menu must not open behind it.
	root.get_node("GameState").set_flag("ch1_opening_done")
	await scene("res://scenes/chapter1/bedroom.tscn")
	current_scene.ui.inspect(preload("res://assets/prologue/bigidea_after.png"))
	await frames()
	await key(KEY_ESCAPE)
	assert(not current_scene.ui.inspecting and not current_scene.ui.choosing)
	current_scene.dialogue.say("测试","设置面板打开时，对白和停顿都应暂停。")
	await frames()
	await key(KEY_F1)
	var ratio: float = current_scene.dialogue.text_label.visible_ratio
	await create_timer(.3).timeout
	assert(current_scene.dialogue.text_label.visible_ratio == ratio)
	await key(KEY_ESCAPE)
	await key(KEY_E)
	await key(KEY_E)
	# Actual F5 and pause-menu failures preserve the live room and support a retry.
	var good_path: String = saves.save_path
	saves.save_path = "/tmp/piggy-phase12-missing-directory/save.json"
	var room := current_scene
	await frames()
	await save_key()
	assert(settings.toast.visible and "保存失败" in settings.toast_text.text)
	await key(KEY_ESCAPE)
	assert(room.ui.choosing)
	room.ui.menu.get_node("save").pressed.emit()
	await frames(8)
	assert(current_scene == room and not room.routing and not room.busy)
	await capture("save-failure")
	saves.save_path = good_path
	await save_key()
	assert(settings.toast_text.text == "进度已保存")
	await key(KEY_ESCAPE)
	room.ui.menu.get_node("save").pressed.emit()
	await root.get_node("SceneRouter").transition_finished
	assert(current_scene.scene_file_path.ends_with("main.tscn"))
	# Invalid preferences are bounded, and an unwritable preference file is visible/retryable.
	var config := ConfigFile.new()
	config.set_value("audio","Music",99)
	config.set_value("audio","Effects","bad")
	config.set_value("audio","muted","bad")
	config.save(settings.settings_path)
	settings.load_preferences()
	assert(settings.volumes.Music == 1 and settings.volumes.Effects == 1 and not settings.muted)
	var settings_path: String = settings.settings_path
	settings.settings_path = "/tmp/piggy-phase12-missing-directory/settings.cfg"
	await key(KEY_F1)
	settings.set_muted(true)
	assert(settings.persistence_error and settings.panel.retry.visible)
	await capture("settings-failure")
	settings.settings_path = settings_path
	settings.panel.retry.pressed.emit()
	assert(not settings.persistence_error and not settings.panel.retry.visible)
	settings.restore_defaults()
	await key(KEY_ESCAPE)
	print("SETTINGS_UI_OK responsive_menu=",extents.size()," settings=",extents.size()," persistence mute nested_pause dialogue_freeze closeup_escape preview_isolation save_failure_retry")
	quit()
