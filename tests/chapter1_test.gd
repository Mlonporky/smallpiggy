extends SceneTree
var failures: Array[String] = []
var state: Node

func _initialize() -> void:
	call_deferred("_run")

func room(id: String) -> Node:
	var instance = load("res://scenes/chapter1/%s.tscn" % id).instantiate()
	instance.test_mode = true
	instance.route_on_exit = false
	root.add_child(instance)
	await process_frame
	await create_timer(0.15).timeout
	return instance

func _run() -> void:
	await process_frame
	state = root.get_node("GameState")
	state.reset()
	var scene = await room("bedroom")
	while scene.busy: await process_frame
	check(state.has_flag("ch1_opening_done"),"one-time wake intro completed")
	check(state.heart_progress == 0,"empty heart on waking")
	await scene.interact("door")
	check(scene.last_route.is_empty(),"bedroom exit locked before memory")
	await scene.interact("painting")
	check(state.heart_progress == 1,"first painting memory gives one heart stage")
	await scene.interact("painting")
	check(state.heart_progress == 1,"repeated painting cannot farm heart")
	await scene.interact("door")
	check(scene.last_route.ends_with("kitchen.tscn"),"bedroom exits into kitchen")
	var actor = scene.player
	actor.position = Vector2(810,730)
	actor.reset_physics_interpolation()
	var before: Vector2 = actor.position
	Input.action_press("move_up")
	var frames := {}
	for i in 50:
		await physics_frame
		if actor._facing == Vector2.UP and actor._travelled > 0.05:
			frames[str(actor.sprite.region_rect)] = true
	Input.action_release("move_up")
	check(actor.position.y < before.y-70,"boy walks continuously")
	check(frames.size() == 3,"all three supplied poses used in the walk cycle")
	check(is_equal_approx(actor.sprite.position.y+actor.sprite.region_rect.size.y*actor.sprite.scale.y,0.0),"feet remain anchored to the ground")
	actor.set_input_enabled(false)
	check(await actor.walk_to(Vector2(810,620)),"scripted movement reaches nearby point without teleport")
	scene.queue_free()
	await process_frame
	scene = await room("kitchen")
	await scene.interact("cup")
	check(not state.has_flag("pig_cup_checked"),"cup unavailable before coffee")
	await scene.interact("tableware")
	check(state.heart_progress == 1,"one clue alone does not trigger kitchen memory")
	await scene.interact("coffee")
	check(state.has_flag("coffee_made") and scene.steam.visible,"coffee unlocks cup and steam")
	await scene.interact("cup")
	check(state.heart_progress == 2 and state.has_flag("kitchen_memory_complete"),"cup and tableware trigger memory")
	await scene.interact("cup")
	check(state.heart_progress == 2,"repeat cup does not advance heart")
	# Furniture blocks the feet; walking into it must not animate a stationary actor.
	actor = scene.player
	actor.position = Vector2(710,840)
	actor.reset_physics_interpolation()
	Input.action_press("move_up")
	for i in 45: await physics_frame
	Input.action_release("move_up")
	check(actor.position.y >= 809,"kitchen table collision blocks movement")
	scene.queue_free()
	await process_frame
	scene = await room("living")
	for id in ["blanket","basket","window"]:
		await scene.interact(id)
	check(state.heart_progress == 2,"ordinary household objects do not advance heart")
	await scene.interact("door")
	check(scene.last_route.is_empty(),"home exit locked before paper")
	await scene.interact("pillow")
	check(state.heart_progress == 3,"third memory gives only third stage, not a full heart")
	check(state.has_flag("red_paper_spawned") and scene.paper.visible,"physical paper drifts inside after memory")
	check(not state.has_flag("ch1_can_leave_home"),"must investigate paper before leaving")
	check(scene.paper.get_parent() is Node2D and scene.hotspots.paper.enabled,"paper is a world object with enabled area")
	await scene.interact("paper")
	check(state.has_flag("ch1_can_leave_home"),"paper inspection unlocks home exit")
	var snapshot: Dictionary = state.to_dictionary()
	state.reset()
	state.load_dictionary(snapshot)
	check(state.heart_progress == 3 and state.has_flag("red_paper_spawned"),"heart and paper persist without writing user save")
	await scene.interact("pillow")
	check(state.heart_progress == 3,"repeated pillow cannot advance beyond third stage")
	scene.queue_free()
	await process_frame
	scene = await room("living")
	check(scene.paper.visible and scene.hotspots.paper.enabled and not scene.busy,"room reload restores physical paper without replaying memory")
	await scene.interact("door")
	check(scene.last_route.ends_with("forest_clearing.tscn") and state.story_phase == 2,"confirmed exit hands off to pig, not cabbage exterior")
	scene.queue_free()
	await process_frame
	scene = await room("bedroom")
	check(not scene.busy and scene.player.visible,"return to bedroom does not replay wake")
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("CHAPTER1_TEST_OK: rooms, gates, memories, persistence, walking, collision, pig handoff")
		quit(0)
	else:
		for message in failures: push_error(message)
		quit(1)

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
