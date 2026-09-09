extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var packed := load("res://scenes/prologue/prologue.tscn") as PackedScene
	var scene = packed.instantiate()
	scene.autoplay = false
	scene.route_on_finish = false
	root.add_child(scene)
	await process_frame
	var expected := ["castle", "alarm", "discovery", "gift", "arrival", "bedroom", "transform", "pig_panic", "teleport", "gift_torn", "empty", "title"]
	_check(scene.shots.size() == expected.size(), "twelve opening beats")
	for i in expected.size():
		_check(scene.shots[i]["id"] == expected[i], "ordered beat: " + expected[i])
		_check(scene.textures[scene.shots[i]["image"]] != null, "texture loads: " + expected[i])
	_check(scene.shots[0]["image"] == "castle_exterior", "castle starts the story")
	scene.set_shot(2, 3.0)
	_check(scene.crystal_vision.visible, "wizard sees pig in crystal before gift scene")
	_check(scene.caption.text.contains("呆呆猪"), "alarm target explicitly identified")
	scene.set_shot(5, 1.0)
	_check(scene.painting_before.visible and is_zero_approx(scene.painting_blend), "original before painting while cabbage")
	_check(scene.painting_before.texture.resource_path.ends_with("bigidea_before.png"), "uses supplied before file")
	scene.set_shot(6, 3.5)
	_check(scene.painting_blend > 0.0 and scene.painting_blend < 1.0, "painting changes with curse")
	scene.set_shot(6, 6.0)
	_check(is_equal_approx(scene.painting_blend, 1.0), "after painting when curse complete")
	_check(scene.painting_after.texture.resource_path.ends_with("bigidea_after.png"), "uses supplied after file")
	_check(scene.shots[8]["after"] == "gift_empty_v3" and scene.shots[8].has("focus2"), "pig and gift share one disappearance clock")
	_check(scene.shots[10]["image"] == "gift_empty_v3", "empty room does not restore gift")
	for i in [6, 8]:
		scene.set_shot(i, 0.0)
		_check(is_zero_approx(scene.transition_progress), "transition starts before")
		scene.set_shot(i, 3.5)
		_check(scene.transition_progress > 0.0 and scene.transition_progress < 1.0, "transition has intermediate state")
		scene.set_shot(i, 5.7)
		_check(is_equal_approx(scene.transition_progress, 1.0), "transition reaches after")
	scene.set_shot(0, 2.0)
	scene.paused = true
	scene._process(3.0)
	_check(is_equal_approx(scene.shot_time, 2.0), "pause freezes timeline")
	scene.paused = false
	scene.advance(3.5)
	_check(scene.shot_index == 1 and is_equal_approx(scene.shot_time, 2.0), "frame overflow carries into next shot")
	scene.set_shot(0)
	scene.advance(1000.0)
	_check(scene.finished, "natural completion")
	var state = root.get_node("GameState")
	var natural: Dictionary = state.to_dictionary()
	_check(state.story_phase == 1 and state.cabbage_emotional_state == 0, "enters hollow boy investigation")
	_check(state.has_flag("pig_teleported") and state.has_flag("cabbage_forgot_pig"), "curse flags set")
	_check(state.has_flag("gift_teleported") and state.has_flag("gift_torn_by_wizard") and state.has_flag("gift_fragments_scattered"), "gift fragment story flags set")
	scene.queue_free()
	await process_frame
	state.reset()
	scene = packed.instantiate()
	scene.autoplay = false
	scene.route_on_finish = false
	root.add_child(scene)
	await process_frame
	scene.skip_to_chapter()
	scene.skip_to_chapter()
	_check(state.to_dictionary() == natural, "skip has same state as natural ending and is idempotent")
	scene.queue_free()
	await process_frame
	# Verify the shared finish path really loads chapter one, not the forest.
	scene = packed.instantiate()
	scene.autoplay = false
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.skip_to_chapter()
	await create_timer(1.1).timeout
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/chapter1/bedroom.tscn", "router hands off to cabbage investigation")
	if failures.is_empty():
		print("OPENING_TEST_OK: order, assets, dissolve endpoints, pause, timing, natural/skip parity")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
