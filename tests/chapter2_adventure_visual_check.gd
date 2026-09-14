extends SceneTree
## Normal-speed scripted preview. Screenshots verify composition, not animation acceptance.
var scene
var samples: Array[float] = []
var last_tick := 0
func _initialize() -> void: call_deferred("run")
func _process(_delta: float) -> bool:
	if is_instance_valid(scene): scene.dialogue._advance_requested = true
	var now := Time.get_ticks_usec()
	if last_tick > 0: samples.append((now-last_tick)/1000.0)
	last_tick = now
	return false
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/piggy-"+name+".png")
func run() -> void:
	await process_frame
	root.size = Vector2i(1152,648)
	root.get_node("GameState").reset()
	scene = load("res://scenes/chapter2/forest_path.tscn").instantiate()
	scene.allow_save = false
	root.add_child(scene)
	await create_timer(0.5).timeout
	await capture("path-start")
	for point in [Vector2(700,810),Vector2(740,650),Vector2(835,490)]:
		assert(await scene.player.walk_to(point,4))
	while scene.busy: await process_frame
	await capture("path-cave")
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/chapter2/cave.tscn").instantiate()
	scene.allow_save = false
	root.add_child(scene)
	await create_timer(0.5).timeout
	scene.start_encounter()
	while scene.busy: await process_frame
	scene.slime.stop_attack()
	scene.player.roll()
	await create_timer(0.2).timeout
	await capture("roll")
	await create_timer(0.4).timeout
	scene.player.face(Vector2.UP)
	scene.player.parry()
	await create_timer(0.12).timeout
	await capture("parry")
	await create_timer(0.5).timeout
	for i in 5:
		scene.player.hurt_box.receive_hit(scene.slime.hit_box)
		await create_timer(1).timeout
	await capture("injury")
	await create_timer(1.4).timeout
	await capture("joy")
	while scene.busy: await process_frame
	scene.slime.stop_attack()
	scene.player.jump()
	await create_timer(0.3).timeout
	await capture("jump")
	await create_timer(0.7).timeout
	scene.player.position = scene.slime.position + Vector2(0,95)
	scene.player.reset_physics_interpolation()
	scene.player.face(Vector2.UP)
	scene.player.attack()
	await create_timer(0.20).timeout
	await capture("attack")
	await create_timer(1.0).timeout
	scene.slime.stop_attack()
	for i in 5:
		scene.player.position = scene.slime.position + Vector2(0,95)
		scene.player.face(Vector2.UP)
		scene.player.attack()
		await create_timer(0.8).timeout
	await capture("win")
	samples.sort()
	print("CHAPTER2_ADVENTURE_VISUAL_OK frame_ms p50=",samples[samples.size()/2]," p95=",samples[int(samples.size()*0.95)])
	quit()
