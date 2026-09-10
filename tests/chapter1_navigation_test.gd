extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var state = root.get_node("GameState")
	state.set_flag("ch1_opening_done")
	state.set_flag("coffee_made")
	var routes := {
		"bedroom":[[Vector2(600,465),"painting"],[Vector2(610,570),""],[Vector2(1120,610),""]],
		"kitchen":[[Vector2(285,940),""],[Vector2(725,940),"tableware"],[Vector2(1120,940),""],[Vector2(1120,535),"coffee"],[Vector2(1010,535),"cup"],[Vector2(1120,560),""],[Vector2(1250,600),""]],
		"living":[[Vector2(410,570),"pillow"],[Vector2(410,875),""],[Vector2(710,875),""],[Vector2(710,945),""]]
	}
	for id in routes:
		var scene = load("res://scenes/chapter1/%s.tscn" % id).instantiate()
		scene.auto_exit_enabled = false
		root.add_child(scene)
		await process_frame
		scene.player.set_input_enabled(false)
		scene.player.move_speed = 400
		for stop in routes[id]:
			var reached: bool = await scene.player.walk_to(stop[0],4.0)
			if not reached: failures.append("blocked route %s %s" % [id,stop[0]])
			if not stop[1].is_empty():
				scene.player.face(scene.hotspots[stop[1]].position-scene.player.position)
				for i in 4: await physics_frame
				var nearest = scene.player._nearest_interactable
				if nearest == null or nearest.interaction_id != stop[1]:
					failures.append("unreachable prompt %s %s" % [id,stop[1]])
		scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("CHAPTER1_NAVIGATION_OK: physical routes reach every required clue and door")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
