extends SceneTree
## Real imported textures, directional frame selection, and a fixed floor anchor.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var state = root.get_node("GameState")
	state.reset()
	state.set_flag("s2_pig_wakeup_complete")
	var scene = load("res://scenes/chapter_02_dark_forest/forest_clearing.tscn").instantiate()
	scene.allow_save = false
	root.add_child(scene)
	await process_frame
	var pig = scene.player
	assert(pig.sprite.texture_filter == CharacterSpriteStyle.FILTER)
	var origin: Vector2 = pig.sprite.position
	for armed in [false, true]:
		pig.armed = armed
		var count := 3 if armed else 4
		for row in 4:
			pig.face([Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT][row])
			pig._update_visual(0.0)
			assert(pig.sprite.region_rect.position.y == row * 320)
			for col in count:
				pig._show_frame(row * count + col)
				assert(pig.sprite.texture.resource_path.contains("pig_unified/"))
				assert(pig.sprite.position == origin, "Equipment/animation must not move foot anchor")
				var image: Image = pig.sprite.texture.get_image().get_region(Rect2i(pig.sprite.region_rect))
				var used := image.get_used_rect()
				assert(used.end.y == 300, "Every frame lands at authored foot baseline")
				assert(used.position.x > 0 and used.end.x < 320, "No clipped cape/stick")
				assert(image.get_pixel(0,0).a == 0.0 and image.get_pixel(160,319).a == 0.0, "Real transparent alpha")
	pig.waking = true
	for i in 6:
		pig.wake_frame = i
		pig._show_frame(0)
		assert(pig.sprite.texture.resource_path.ends_with("pig_unified/wake.png"))
		assert(pig.sprite.position == origin)
	scene.queue_free()
	await process_frame
	var opening = load("res://scenes/prologue/prologue.tscn").instantiate()
	opening.autoplay = false
	opening.route_on_finish = false
	root.add_child(opening)
	await process_frame
	for i in [3,7,8]:
		opening.set_shot(i,0.0)
		assert(opening.picture.texture.resource_path.ends_with("gift_wrapping_unified.png"))
	assert(opening.crystal_vision.texture == opening.textures["gift_wrapping_unified"])
	opening.queue_free()
	await process_frame
	print("PIG_PIXEL_OK: 28 walk frames, alpha, floor anchors, wake, opening/crystal replacement")
	quit()
