extends SceneTree
## SaveManager writes through a temporary file and keeps the previous save as a backup.
func _initialize() -> void: call_deferred("run")

func run() -> void:
	await process_frame
	var state = root.get_node("GameState")
	var saves = root.get_node("SaveManager")
	# Never touch the player's real save.
	saves.save_path = "user://save_manager_test.json"
	var paths: Array[String] = [saves.save_path, saves.save_path + ".tmp", saves.save_path + ".bak"]
	for path in paths: DirAccess.remove_absolute(path)
	assert(not saves.has_save())
	state.reset()
	state.set_flag("first")
	assert(saves.save_game("res://scenes/chapter1/bedroom.tscn"))
	assert(not FileAccess.file_exists(paths[1]), "Temporary file is renamed into place")
	state.set_flag("second")
	assert(saves.save_game("res://scenes/chapter2/cave.tscn"))
	assert(FileAccess.file_exists(paths[2]), "Previous save is kept as a backup")
	state.reset()
	assert(saves.load_game() == "res://scenes/chapter2/cave.tscn" and state.has_flag("second"))
	# A save cut off mid-write falls back to the previous good one.
	var broken := FileAccess.open(paths[0], FileAccess.WRITE)
	broken.store_string("{\"version\": 1, \"fla")
	broken.close()
	state.reset()
	assert(saves.has_save())
	assert(saves.load_game() == "res://scenes/chapter1/bedroom.tscn", "Corrupt save falls back to the backup")
	assert(state.has_flag("first") and not state.has_flag("second"))
	# Interrupted between keeping the backup and the rename: only the backup remains.
	DirAccess.remove_absolute(paths[0])
	assert(saves.has_save() and saves.load_game() == "res://scenes/chapter1/bedroom.tscn")
	for path in paths: DirAccess.remove_absolute(path)
	saves.save_path = saves.SAVE_PATH
	print("SAVE_MANAGER_OK: temporary-file write, backup kept, corrupt or missing save falls back")
	quit()
