extends SceneTree
var scene
var finished := false
var seen: Array[String] = []
var capture := false
var samples: Array[float] = []
var last_tick := 0
func _initialize() -> void: call_deferred("run")
func _process(_delta: float) -> bool:
	if is_instance_valid(scene): scene.dialogue._advance_requested = true
	var now := Time.get_ticks_usec()
	if last_tick > 0: samples.append((now-last_tick)/1000.0)
	last_tick = now
	return false
func play_section() -> void:
	await scene.lines(22)
	finished = true
func snapshot(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/piggy-manor-"+name+".png")
func run() -> void:
	await process_frame
	capture = DisplayServer.get_name() != "headless"
	root.size = Vector2i(1152,648)
	var state = root.get_node("GameState")
	state.reset()
	state.set_flag("s2_pig_wakeup_complete")
	scene = load("res://scenes/chapter_02_dark_forest/forest_clearing.tscn").instantiate()
	scene.allow_save = false
	root.add_child(scene)
	await process_frame
	scene.player.position = Vector2(840,630)
	scene.wizard.visible = true
	scene.lock(true)
	scene.dialogue.line_started.connect(func(line: Dictionary): seen.append(line.text))
	var initial_position: Vector2 = scene.camera.position
	var initial_zoom: Vector2 = scene.camera.zoom
	var player_position: Vector2 = scene.player.position
	var initial_world_color: Color = scene.world.modulate
	await snapshot("before")
	play_section()
	var deadline := Time.get_ticks_msec()+16000
	while not is_instance_valid(scene.distance_shot) and Time.get_ticks_msec()<deadline: await process_frame
	assert(is_instance_valid(scene.distance_shot))
	assert(seen.back() == "在森林的另一端。" and seen.size() == 5)
	await scene.distance_shot.fully_revealed
	assert(scene.distance_shot_count == 1)
	assert(scene.camera.zoom.is_equal_approx(initial_zoom*0.35))
	assert(scene.camera.position.y < -600)
	assert(not scene.player.input_enabled and not scene.ui.visible)
	var light: Vector2 = scene.camera.get_canvas_transform() * scene.distance_shot.MANOR_LIGHT
	assert(light.y > 30 and light.y < 150,"The tiny manor light stays near the top of the frame")
	await snapshot("far")
	# Resize while holding the shot: preserve cinematic framing and restore new fit later.
	root.size = Vector2i(1000,700)
	await create_timer(0.15).timeout
	var logical_size: Vector2 = scene.get_viewport_rect().size
	assert(is_equal_approx(scene.camera.zoom.x,minf(logical_size.x/1448,logical_size.y/1086)*0.35))
	root.size = Vector2i(1152,648)
	await create_timer(0.15).timeout
	while not finished and Time.get_ticks_msec()<deadline: await process_frame
	assert(finished)
	await process_frame
	assert(scene.distance_shot == null)
	assert(scene.camera.position == initial_position and scene.camera.offset == Vector2.ZERO)
	assert(scene.camera.zoom.is_equal_approx(initial_zoom))
	assert(scene.player.position == player_position and scene.world.modulate == initial_world_color)
	assert(scene.get_child(0).material == null and scene.ui.visible)
	assert(scene.busy and not scene.player.input_enabled,"Return to the ongoing wizard conversation, not gameplay")
	await snapshot("returned")
	samples.sort()
	print("MANOR_DISTANCE_SHOT_OK: exact dialogue cue, pullback, top light, resize, cleanup, camera/world restoration; frame_ms p50=",samples[samples.size()/2]," p95=",samples[int(samples.size()*0.95)])
	quit()
