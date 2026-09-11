extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	await process_frame
	root.size = Vector2i(1152,648)
	var state = root.get_node("GameState")
	state.reset()
	state.set_flag("s2_pig_wakeup_complete")
	var entrance = load("res://scenes/chapter_02_dark_forest/forest_clearing.tscn").instantiate()
	entrance.allow_save = false
	root.add_child(entrance)
	await create_timer(1).timeout
	await capture("/tmp/pig-entrance.png")
	for facing in [Vector2.DOWN,Vector2.LEFT,Vector2.UP,Vector2.RIGHT]:
		entrance.player.face(facing)
		await create_timer(0.15).timeout
		await capture("/tmp/pig-cape-%s-%s.png" % [int(facing.x),int(facing.y)])
	entrance.player.face(Vector2.UP)
	entrance.wizard.visible = true
	entrance.joy(10,0.4)
	await create_timer(0.2).timeout
	await capture("/tmp/pig-wizard.png")
	entrance.queue_free()
	await process_frame
	var cave = load("res://scenes/chapter2/cave.tscn").instantiate()
	cave.allow_save = false
	root.add_child(cave)
	await create_timer(0.7).timeout
	await capture("/tmp/pig-cave.png")
	cave.take_stick()
	cave.player.position = Vector2(740,650)
	cave.player.reset_physics_interpolation()
	await create_timer(0.6).timeout
	await capture("/tmp/pig-armed.png")
	# Normal-speed movement across all four facing rows; report frame pacing.
	var samples: Array[float] = []
	for direction in ["move_right","move_up","move_left","move_down"]:
		Input.action_press(direction)
		var before := Time.get_ticks_usec()
		for i in 40:
			await process_frame
			var now := Time.get_ticks_usec()
			samples.append((now-before)/1000.0)
			before = now
		Input.action_release(direction)
	samples.sort()
	print("CHAPTER2_VISUAL_OK frame_ms p50=",samples[samples.size()/2]," p95=",samples[int(samples.size()*0.95)])
	quit()
