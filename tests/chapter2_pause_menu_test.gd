extends SceneTree
## Act II Esc pauses the forest; saving returns to the menu, and a fallen slime stays saved.
func _initialize() -> void: call_deferred("run")

func run() -> void:
	await process_frame
	var state = root.get_node("GameState")
	var saves = root.get_node("SaveManager")
	var router = root.get_node("SceneRouter")
	# Never touch the player's real save.
	saves.save_path = "/tmp/piggy_chapter2_pause_menu_test.json"
	clear(saves.save_path)
	state.reset()
	change_scene_to_file("res://scenes/chapter2/cave.tscn")
	await process_frame
	await process_frame
	var cave = current_scene
	cave.slime.active = true
	await create_timer(0.3).timeout
	assert(cave.slime.position != Vector2(735,480), "The slime is moving before the pause")
	escape()
	await process_frame
	assert(paused and cave.busy and not cave.player.input_enabled, "Esc pauses the cave")
	var slime_at: Vector2 = cave.slime.position
	await create_timer(0.5).timeout
	assert(cave.slime.position == slime_at, "The slime stays frozen behind the menu")
	escape()
	await process_frame
	assert(not paused and not cave.busy and cave.player.input_enabled, "Esc again resumes")
	assert(cave.find_child("save", true, false) == null, "The menu is removed")
	# Pause in the dash itself: neither movement, timer nor active hitbox may expire.
	cave.slime.attack_lunge()
	await create_timer(0.95).timeout
	assert(cave.slime.state == "dash")
	escape()
	await process_frame
	var dash_at: Vector2 = cave.slime.position
	var dash_time: float = cave.slime.state_time
	await create_timer(0.7).timeout
	assert(cave.slime.position == dash_at and cave.slime.state_time == dash_time)
	assert(cave.slime.hit_box.monitoring)
	escape()
	await process_frame
	# The slime falls: progress is saved before the fragment is picked up.
	cave.slime.health.damage(99)
	await create_timer(0.8).timeout
	assert(state.has_flag("s2_fragment_dropped") and FileAccess.file_exists(saves.save_path))
	escape()
	await process_frame
	cave.find_child("save", true, false).pressed.emit()
	await router.transition_finished
	assert(not paused and current_scene.scene_file_path == "res://scenes/bootstrap/main.tscn")
	# Continue: the slime stays gone and the fragment still lies on the floor.
	state.reset()
	var path: String = saves.load_game()
	assert(path == "res://scenes/chapter2/cave.tscn")
	change_scene_to_file(path)
	await process_frame
	await process_frame
	cave = current_scene
	assert(cave.won and not is_instance_valid(cave.slime) and cave.fragment.enabled and cave.fragment.visible)
	cave.collect_fragment()
	assert(state.has_flag("forest_slime_defeated") and state.gift_fragments.count("fragment_red_wrap_01") == 1)
	await router.transition_finished
	assert(current_scene.scene_file_path.ends_with("cabbage_act2/villa.tscn"))
	assert(saves.load_game() == "res://scenes/cabbage_act2/villa.tscn")
	assert(state.story_phase == state.StoryPhase.CABBAGE_HOLLOW_HEART)
	# Going home and leaving again must not restart the pig's forest chapter.
	current_scene.travel("living")
	await router.transition_finished
	state.set_flag("ch1_can_leave_home")
	current_scene.test_mode = true
	current_scene.travel("outside")
	await router.transition_finished
	assert(current_scene.scene_file_path.ends_with("cabbage_act2/villa.tscn"))
	clear(saves.save_path)
	saves.save_path = saves.SAVE_PATH
	print("CHAPTER2_PAUSE_MENU_OK: Esc pauses and resumes, save returns to menu, fallen slime stays saved")
	quit()

func escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key)
	var release: InputEventKey = key.duplicate()
	release.pressed = false
	root.push_input(release)

func clear(path: String) -> void:
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(path + suffix)
