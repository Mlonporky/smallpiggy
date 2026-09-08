extends Node

const SAVE_PATH := "user://piggy_manor_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(scene_path: String = "") -> bool:
	var payload := GameState.to_dictionary()
	payload["scene_path"] = scene_path if not scene_path.is_empty() else get_tree().current_scene.scene_file_path
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(payload, "  "))
	return true


func load_game() -> String:
	if not has_save():
		return ""
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return ""
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Save data is not a dictionary")
		return ""
	GameState.load_dictionary(parsed)
	return str(parsed.get("scene_path", ""))

