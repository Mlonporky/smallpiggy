extends Node

signal save_completed(success: bool, notify_success: bool)

const SAVE_PATH := "user://piggy_manor_save.json"
# Tests point this elsewhere so they never touch the player's real save.
var save_path := SAVE_PATH
var preview_mode := false
var _original_save_path := ""
var _preview_original_state: Dictionary = {}


func _ready() -> void:
	var override := OS.get_environment("PIGGY_SAVE_PATH")
	if not override.is_empty(): save_path = override


func begin_preview() -> void:
	if preview_mode: return
	_original_save_path = save_path
	_preview_original_state = GameState.to_dictionary().duplicate(true)
	save_path += ".preview"
	preview_mode = true
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save_path + suffix)


func end_preview() -> void:
	if not preview_mode: return
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save_path + suffix)
	save_path = _original_save_path
	preview_mode = false
	GameState.load_dictionary(_preview_original_state)
	_preview_original_state.clear()


func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(_backup_path())


func save_game(scene_path: String = "", notify_success := false) -> bool:
	var success := _write_game(scene_path)
	save_completed.emit(success, notify_success)
	return success


func _write_game(scene_path: String) -> bool:
	var payload := GameState.to_dictionary()
	var scene := get_tree().current_scene
	payload["scene_path"] = scene_path if not scene_path.is_empty() else (scene.scene_file_path if scene else "")
	if not _valid_payload(payload):
		push_error("Cannot save invalid state or scene")
		return false
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
	# After recovering from a corrupt primary, never overwrite the good backup
	# with that corrupt file on the next save.
	if not _read(save_path).is_empty():
		if DirAccess.copy_absolute(save_path, _backup_path()) != OK:
			push_error("Could not preserve previous save")
			DirAccess.remove_absolute(temp_path)
			return false
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
	if not parsed is Dictionary or not _valid_payload(parsed):
		push_warning("Ignoring invalid save: %s" % path)
		return {}
	return parsed


func _whole(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum and value == int(value)


func _valid_payload(data: Dictionary) -> bool:
	var scene: Variant = data.get("scene_path", "")
	if not scene is String or not scene.begins_with("res://") or not scene.ends_with(".tscn"):
		return false
	if not ResourceLoader.exists(scene, "PackedScene"):
		return false
	# Optional fields default for older saves; malformed fields must not mutate
	# live GameState or prevent fallback to the previous valid save.
	if not _whole(data.get("version", 1), 1, 1): return false
	if not _whole(data.get("story_phase", 0), 0, GameState.StoryPhase.COMPLETED): return false
	if not _whole(data.get("cabbage_emotional_state", 0), 0, GameState.CabbageEmotionalState.MEMORY_RETURNED): return false
	if not _whole(data.get("heart_progress", 0), 0, 3): return false
	if not _whole(data.get("cabbage_resonance_progress", 0), 0, 2147483647): return false
	if not data.get("flags", {}) is Dictionary: return false
	var fragments: Variant = data.get("gift_fragments", [])
	if not fragments is Array: return false
	for fragment in fragments:
		if not fragment is String or fragment.is_empty(): return false
	return true


func _backup_path() -> String:
	return save_path + ".bak"
