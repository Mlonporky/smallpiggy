extends SceneTree
## Run with a real renderer, not --headless. Captures and a normal-speed sample.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	root.size = Vector2i(1152, 648)
	var scene = load("res://scenes/prologue/prologue.tscn").instantiate()
	scene.autoplay = false
	scene.route_on_finish = false
	scene.muted = true
	root.add_child(scene)
	await process_frame
	var folder := "user://opening_review_v3"
	DirAccess.make_dir_recursive_absolute(folder)
	for sample in [[0, 1.5], [2, 4.0], [5, 1.0], [6, 3.8], [6, 6.0], [8, 3.0], [8, 5.0], [9, 3.5], [10, 1.5]]:
		scene.set_shot(sample[0], sample[1])
		await process_frame
		await RenderingServer.frame_post_draw
		var file := folder + "/shot_%s_%s.png" % [sample[0], sample[1]]
		root.get_texture().get_image().save_png(file)
		print("CAPTURE: " + ProjectSettings.globalize_path(file))
	# Normal-speed rendering sample across the transformation; warm shader first.
	scene.set_shot(6, 0.0)
	var times: Array[float] = []
	var before := Time.get_ticks_usec()
	var start := before
	while Time.get_ticks_usec() - start < 8000000:
		await process_frame
		var now := Time.get_ticks_usec()
		var delta := float(now - before) / 1000000.0
		before = now
		times.append(delta * 1000.0)
		scene.advance(delta)
	times.sort()
	print("RENDER_SAMPLE: frames=%s median_ms=%.2f p95_ms=%.2f max_ms=%.2f" % [times.size(), times[times.size() / 2], times[int(times.size() * 0.95)], times[-1]])
	scene.queue_free()
	await process_frame
	quit()
