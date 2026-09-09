extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var texture := load("res://assets/chapter1/boy.png") as Texture2D
	var source := texture.get_image()
	var start := -1
	var spans: Array[Vector2i] = []
	for y in source.get_height():
		var occupied := false
		for x in source.get_width():
			if source.get_pixel(x,y).a > 0.01:
				occupied = true
				break
		if occupied and start < 0:
			start = y
		elif not occupied and start >= 0:
			spans.append(Vector2i(start,y))
			start = -1
	if start >= 0: spans.append(Vector2i(start,source.get_height()))
	print("BOY_ALPHA_ROW_SPANS: ",spans)
	var edges := PackedInt32Array([0,368,694,1028,1448])
	var fixed := SpriteAtlas.bounds(texture,3,4,edges,0.01)
	var uniform := SpriteAtlas.bounds(texture,3,4)
	check(uniform[9].position.y > spans[3].x,"fixture reproduces old back-hair clipping")
	check(fixed.size() == 12,"all twelve poses have regions")
	# Every meaningful source pixel must occur in its own frame, not its neighbour.
	for row in 4:
		for column in 3:
			var frame := fixed[row*3+column]
			check(frame.position.y > edges[row],"transparent margin above row %d pose %d" % [row,column])
			check(frame.end.y < edges[row+1],"no neighbouring-row bleed in row %d pose %d" % [row,column])
			var missing := 0
			for y in range(edges[row],edges[row+1]):
				for x in range(column*362,(column+1)*362):
					if source.get_pixel(x,y).a > 0.01 and not frame.has_point(Vector2(x,y)):
						missing += 1
			check(missing == 0,"no clipped source pixels in pose %d" % (row*3+column))
	await process_frame
	var state = root.get_node("GameState")
	state.set_flag("ch1_opening_done")
	var room = load("res://scenes/chapter1/bedroom.tscn").instantiate()
	root.add_child(room)
	await process_frame
	room.player.set_physics_process(false)
	check(room.player._frame_bounds == fixed,"actual room uses corrected atlas, not only the test")
	for index in 12:
		room.player._show_frame(index)
		var sprite: Sprite2D = room.player.sprite
		check(sprite.region_rect == fixed[index],"runtime region matches full pose")
		check(is_zero_approx(sprite.position.y+sprite.region_rect.size.y*sprite.scale.y),"feet stay anchored for every pose")
	room.queue_free()
	await process_frame
	if failures.is_empty():
		print("BOY_ATLAS_TEST_OK: 12 complete poses, no clipped alpha pixels, runtime integration, stable feet")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
