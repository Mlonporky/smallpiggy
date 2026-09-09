extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	root.size = Vector2i(1152,648)
	var state = root.get_node("GameState")
	state.reset()
	state.set_flag("ch1_opening_done")
	var folder := "user://chapter1_review"
	DirAccess.make_dir_recursive_absolute(folder)
	for id in ["bedroom","kitchen","living"]:
		var scene = load("res://scenes/chapter1/%s.tscn" % id).instantiate()
		scene.route_on_exit = false
		root.add_child(scene)
		await process_frame
		scene.player.position = {"bedroom":Vector2(620,565),"kitchen":Vector2(1040,470),"living":Vector2(390,555)}[id]
		scene.player.reset_physics_interpolation()
		await create_timer(0.4).timeout
		await capture(folder+"/"+id+".png")
		if id == "bedroom":
			scene.ui.show_closeup(preload("res://assets/prologue/bigidea_after.png"))
			await process_frame
			await capture(folder+"/painting_closeup.png")
			scene.ui.hide_closeup()
			var frames: Array[float] = []
			var before := Time.get_ticks_usec()
			var start := before
			scene.player.position = Vector2(820,720)
			scene.player.reset_physics_interpolation()
			Input.action_press("move_up")
			var down := false
			while Time.get_ticks_usec()-start < 8000000:
				await process_frame
				var now := Time.get_ticks_usec()
				frames.append(float(now-before)/1000)
				before = now
				if not down and scene.player.position.y < 495:
					Input.action_release("move_up")
					Input.action_press("move_down")
					down = true
				elif down and scene.player.position.y > 810:
					Input.action_release("move_down")
					Input.action_press("move_up")
					down = false
			Input.action_release("move_up")
			Input.action_release("move_down")
			frames.sort()
			print("WALK_RENDER_SAMPLE: frames=%d median_ms=%.2f p95_ms=%.2f max_ms=%.2f" % [frames.size(),frames[frames.size()/2],frames[int(frames.size()*0.95)],frames[-1]])
		if id == "living":
			# Actual memory sequence, captured while its first line awaits player input.
			state.gain_chapter_heart("bedroom_memory_complete")
			state.gain_chapter_heart("kitchen_memory_complete")
			scene.lock(true)
			scene.memory_beat(3)
			await create_timer(1.5).timeout
			await capture(folder+"/memory_03.png")
		scene.queue_free()
		await process_frame
	var opening = load("res://scenes/prologue/prologue.tscn").instantiate()
	opening.autoplay = false
	opening.route_on_finish = false
	opening.muted = true
	root.add_child(opening)
	await process_frame
	opening.set_shot(3,14.2)
	await process_frame
	await capture(folder+"/joy_burst.png")
	opening.queue_free()
	await process_frame
	quit()

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("CAPTURE: "+ProjectSettings.globalize_path(path))
