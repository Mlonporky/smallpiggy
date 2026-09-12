extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	root.get_node("GameState").reset()
	var scene = load("res://scenes/chapter2/cave.tscn").instantiate()
	scene.allow_save=false
	root.add_child(scene)
	await process_frame
	# Direct cave entry hands over the stick normally picked up in the clearing.
	assert(scene.player.armed and scene.player.combat_enabled)
	scene.lock(true)
	scene.slime.active=false
	for i in 3:
		scene.player.position=scene.slime.position+Vector2(0,70)
		scene.player.face(Vector2.UP)
		scene.player.attack()
		await create_timer(0.6).timeout
		if i < 2: assert(scene.slime.health.current_health == 2-i)
	await create_timer(1).timeout
	assert(scene.won and scene.fragment.enabled)
	print("CHAPTER2_COMBAT_OK")
	quit()
