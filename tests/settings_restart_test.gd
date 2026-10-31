extends SceneTree
## Run once with PIGGY_RESTART_WRITE=1, then again without it using the same temp cfg.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var settings := root.get_node("AppSettings")
	assert(settings.settings_path.begins_with("/tmp/") or settings.settings_path.begins_with("/private/tmp/"))
	var state: Dictionary = root.get_node("GameState").to_dictionary()
	if OS.get_environment("PIGGY_RESTART_WRITE") == "1":
		settings.set_story_speed(1.0)
		settings.set_volume("Music",.35)
		settings.set_volume("Effects",.6)
		settings.set_volume("Ambience",0.0)
		settings.set_muted(true)
		assert(not settings.persistence_error)
		print("SETTINGS_RESTART_WRITE_OK")
	else:
		assert(settings.story_speed == 1.0)
		assert(settings.muted and root.get_node("MusicDirector").muted)
		assert(is_equal_approx(settings.volumes.Music,.35) and is_equal_approx(settings.volumes.Effects,.6))
		assert(settings.volumes.Ambience == 0 and AudioServer.is_bus_mute(0))
		assert(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),linear_to_db(.35)))
		print("SETTINGS_RESTART_READ_OK")
	assert(root.get_node("GameState").to_dictionary() == state)
	quit()
