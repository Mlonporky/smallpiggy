extends Node

const SAVE_PATH := "user://piggy_manor_save.json"
# Tests point this elsewhere so they never touch the player's real save.
var save_path := SAVE_PATH


func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(_backup_path())


func save_game(scene_path: String = "") -> bool:
	var payload := GameState.to_dictionary()
	payload["scene_path"] = scene_path if not scene_path.is_empty() else get_tree().current_scene.scene_file_path
	# Write a complete temporary file first: a crash mid-write must not destroy the last good save.
	var temp_path := save_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % FileAccess.get_open_error())
		return false
	var written := file.store_string(JSON.stringify(payload, "  "))
	file.close()
	if not written:
		push_error("Could not write save file")
		DirAccess.remove_absolute(temp_path)
		return false
	# Keep the previous save; it also covers platforms where rename is not atomic.
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, _backup_path())
	var error := DirAccess.rename_absolute(temp_path, save_path)
	if error != OK:
		push_error("Could not replace save file (error %s)" % error)
		return false
	return true


func load_game() -> String:
	# A missing or unreadable latest save falls back to the previous one.
	for path in [save_path, _backup_path()]:
		var data := _read(path)
		if not data.is_empty():
			GameState.load_dictionary(data)
			return str(data.get("scene_path", ""))
	return ""


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Save data is not a dictionary: %s" % path)
		return {}
	return parsed


func _backup_path() -> String:
	return save_path + ".bak"
