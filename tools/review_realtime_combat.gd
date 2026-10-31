extends SceneTree
## Real physics/input demonstration. Movie mode is offline, never timing evidence.
const Meter = preload("res://tests/finale_render_meter.gd")
const OUT = "res://docs/verification/combat_2026-10-31/"
var scene: Node
var clock := 0.0
var frame := 0
var export_mode := false
var capture_mode := false
var meter: RefCounted
var held: Dictionary = {}
var skill_count := 0
var attack_count := 0
var last_swing := -1.0
var image_index := 0
var original: Dictionary
func _initialize() -> void:
	export_mode = not Engine.get_write_movie_path().is_empty()
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	if export_mode: RenderingServer.render_loop_enabled = false
	else: Engine.max_fps = 60
	call_deferred("setup")
func setup() -> void:
	original = root.get_node("GameState").to_dictionary().duplicate(true)
	change_scene_to_file("res://scenes/chapter2/combat_preview.tscn")
	await process_frame
	await process_frame
	scene = current_scene
	scene.player.joy_released.connect(func(_at): skill_count += 1)
	scene.player.attack_started.connect(func(): attack_count += 1)
	root.title = "实时战斗 · 自动按键演示"
	if not export_mode:
		DisplayServer.window_move_to_foreground()
		for i in 5: await process_frame
		meter = Meter.new()
		meter.start(self)
	process_frame.connect(step)
func key(code: int, down: bool) -> void:
	if held.get(code,false) == down: return
	held[code] = down
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func step() -> void:
	clock += 1.0/30 if export_mode else root.get_process_delta_time()
	var p = scene.player
	var s = scene.slime
	var direction := Vector2.ZERO
	if is_instance_valid(s) and not s._dead:
		var gap: Vector2 = s.position-p.position
		direction = Vector2(signf(gap.x) if absf(gap.x)>40 else 0,signf(gap.y) if absf(gap.y)>80 else 0)
		if clock < 1.0: direction = Vector2.RIGHT
		var evade: bool = s.state == "windup" and s.state_time > 0.4 and p.roll_cooldown <= 0 and gap.length() < 220
		if evade: direction = Vector2.RIGHT if p.position.x < 800 else Vector2.LEFT
		for pair in [[KEY_A,direction.x<0],[KEY_D,direction.x>0],[KEY_W,direction.y<0],[KEY_S,direction.y>0]]: key(pair[0],pair[1])
		p.face(gap)
		key(KEY_SHIFT,evade)
		var swing: bool = clock-last_swing > 0.38 and gap.length() < 160
		if swing: last_swing = clock
		key(KEY_J,swing)
		key(KEY_Q,clock > 2.0 and p.joy_cooldown <= 0 and gap.length() <= p.JOY_RADIUS)
	else:
		for code in held.keys(): key(code,false)
	if export_mode: call_deferred("draw_frame")
	else:
		meter.sample("combat" if not scene.won else "won")
		frame += 1
		if capture_mode and image_index < 3 and clock > [0.3,2.4,5.0][image_index]:
			image_index += 1
			capture(image_index)
		if clock >= 14: finish()
func capture(index: int) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"combat_%d.png" % index)
func draw_frame() -> void:
	RenderingServer.force_draw(false,1.0/30)
	frame += 1
	if frame == 420: finish()
func finish() -> void:
	process_frame.disconnect(step)
	for code in held.keys(): key(code,false)
	if not export_mode:
		var report: Dictionary = meter.finish()
		report["attacks"] = attack_count
		report["skills"] = skill_count
		report["hp"] = scene.player.health.current_health
		report["won"] = scene.won
		report["contains_screenshot_readback"] = capture_mode
		FileAccess.open(OUT+("capture.json" if capture_mode else "playback.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
		print("REALTIME_COMBAT_PLAYBACK_OK attacks=",attack_count," skills=",skill_count," coverage=",report.render_coverage_valid," p95=",report.draw_intervals.p95_ms," max=",report.draw_intervals.max_ms)
		assert(report.render_coverage_valid)
	else: print("REALTIME_COMBAT_MOVIE_OK frames=",frame," attacks=",attack_count," skills=",skill_count)
	scene.queue_free()
	await process_frame
	assert(root.get_node("GameState").to_dictionary() == original)
	quit()
