extends SceneTree
## SaveManager writes through a temporary file and keeps the previous save as a backup.
func _initialize() -> void: call_deferred("run")

func run() -> void:
	await process_frame
	var state = root.get_node("GameState")
	var saves = root.get_node("SaveManager")
	# Never touch the player's real save.
	saves.save_path = "/tmp/piggy-save-manager-test.json"
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
	# A syntactically valid JSON object may still be unusable. Try the backup
	# before changing any live state, including when the scene no longer exists.
	for bad in [{"flags":[]}, {"scene_path":"res://missing.tscn"}, {"story_phase":99}, {"gift_fragments":"bad"}, {"heart_progress":1.5}]:
		var malformed: Dictionary=state.to_dictionary()
		malformed["scene_path"]="res://scenes/chapter2/cave.tscn"
		malformed.merge(bad,true)
		var file:=FileAccess.open(paths[0],FileAccess.WRITE)
		file.store_string(JSON.stringify(malformed))
		file.close()
		state.reset()
		assert(saves.load_game()=="res://scenes/chapter1/bedroom.tscn")
		assert(state.has_flag("first"))
	# Saving after fallback must not replace the valid backup with bad JSON.
	assert(saves.save_game("res://scenes/chapter2/cave.tscn"))
	DirAccess.remove_absolute(paths[0])
	state.reset()
	assert(saves.load_game()=="res://scenes/chapter1/bedroom.tscn")
	assert(state.has_flag("first"))
	var duplicate: Dictionary=state.to_dictionary()
	duplicate["gift_fragments"]=["fragment_red_wrap_01","fragment_red_wrap_01"]
	state.load_dictionary(duplicate)
	assert(state.gift_fragments.size()==1 and not state.add_gift_fragment("fragment_red_wrap_01"))
	# Interrupted between keeping the backup and the rename: only the backup remains.
	DirAccess.remove_absolute(paths[0])
	assert(saves.has_save() and saves.load_game() == "res://scenes/chapter1/bedroom.tscn")
	# No valid copy: report failure without partially resetting the current run.
	DirAccess.remove_absolute(paths[2])
	var unusable:=FileAccess.open(paths[0],FileAccess.WRITE)
	unusable.store_string("{\"flags\":[]}")
	unusable.close()
	var live_before: Dictionary=state.to_dictionary()
	assert(saves.load_game().is_empty() and state.to_dictionary()==live_before)
	assert(not saves.save_game("res://missing-scene.tscn"))
	for path in paths: DirAccess.remove_absolute(path)
	saves.save_path = saves.SAVE_PATH
	print("SAVE_MANAGER_OK: atomic write, schema/scene validation, corrupt/missing fallback, good backup preserved after recovery, reward deduplication")
	quit()
