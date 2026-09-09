extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	root.size = Vector2i(1152,648)
	var state = root.get_node("GameState")
	state.set_flag("ch1_opening_done")
	var scene = load("res://scenes/chapter1/bedroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.player.position = Vector2(790,700)
	scene.player.reset_physics_interpolation()
	scene.player.set_physics_process(false)
	var folder := "user://boy_atlas_review"
	DirAccess.make_dir_recursive_absolute(folder)
	for index in 12:
		scene.player._show_frame(index)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"/pose_%02d.png" % index)
	print("BOY_ATLAS_CAPTURES: "+ProjectSettings.globalize_path(folder))
	scene.queue_free()
	await process_frame
	quit()
