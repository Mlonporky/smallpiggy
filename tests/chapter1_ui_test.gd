extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var state = root.get_node("GameState")
	state.reset()
	state.set_flag("ch1_opening_done")
	var scene = load("res://scenes/chapter1/bedroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.interact("painting")
	await process_frame
	if not scene.ui.inspecting or not scene.busy:
		push_error("inspection did not lock input")
		quit(1)
		return
	await press_e()
	var started := Time.get_ticks_msec()
	while scene.busy and Time.get_ticks_msec()-started < 12000:
		await create_timer(0.25).timeout
		await press_e()
	if scene.busy or not scene.player.input_enabled or state.heart_progress != 1:
		push_error("manual E flow failed to dismiss inspection, finish dialogue, or restore control")
		quit(1)
		return
	scene.queue_free()
	await process_frame
	print("CHAPTER1_UI_OK: real E events dismiss inspection and dialogue, restore player input")
	quit(0)

func press_e() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.keycode = KEY_E
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
