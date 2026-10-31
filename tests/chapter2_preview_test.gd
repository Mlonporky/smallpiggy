extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var state = root.get_node("GameState")
	var saves = root.get_node("SaveManager")
	state.reset()
	state.set_flag("preview_must_keep")
	state.add_gift_fragment("existing_fragment")
	var original: Dictionary = state.to_dictionary()
	var save_path: String = saves.save_path
	var original_bytes := FileAccess.get_file_as_bytes(save_path) if FileAccess.file_exists(save_path) else PackedByteArray()
	change_scene_to_file("res://scenes/chapter2/combat_preview.tscn")
	await process_frame
	await process_frame
	assert(saves.preview_mode and saves.save_path != save_path)
	assert(current_scene.player.health.current_health == 100 and not current_scene.busy)
	assert(saves.save_game(),"F5 destination stays in preview")
	current_scene.slime.health.damage(99)
	await create_timer(0.6).timeout
	current_scene.collect_fragment()
	assert(state.gift_fragments.is_empty(),"Preview completion never grants story rewards")
	change_scene_to_file("res://scenes/bootstrap/main.tscn")
	await process_frame
	await process_frame
	assert(not saves.preview_mode and saves.save_path == save_path and state.to_dictionary() == original)
	assert(not FileAccess.file_exists(save_path+".preview"))
	var after := FileAccess.get_file_as_bytes(save_path) if FileAccess.file_exists(save_path) else PackedByteArray()
	assert(after == original_bytes)
	print("CHAPTER2_PREVIEW_OK state restored, F5 isolated, no rewards, original save untouched")
	quit()
