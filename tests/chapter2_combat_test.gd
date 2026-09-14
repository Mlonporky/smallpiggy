extends SceneTree
var scene
func _initialize() -> void: call_deferred("run")
func _process(_delta: float) -> bool:
	if is_instance_valid(scene): scene.dialogue._advance_requested = true
	return false
func press(key: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	await physics_frame
	event.pressed = false
	Input.parse_input_event(event)
func run() -> void:
	await process_frame
	root.get_node("GameState").reset()
	scene = load("res://scenes/chapter2/cave.tscn").instantiate()
	scene.allow_save = false
	root.add_child(scene)
	await process_frame
	scene.start_encounter()
	while not scene.encounter_started or scene.busy: await process_frame
	assert(scene.player.input_enabled and scene.player.combat_enabled)
	while scene.player.health.current_health == 100: await process_frame
	assert(scene.player.health.current_health == 88 and not scene.awakened)
	scene.slime.stop_attack()
	await create_timer(1).timeout
	# Real key mapping, collision-aware travel, and the active dodge window.
	var before: Vector2 = scene.player.position
	await press(KEY_SHIFT)
	await create_timer(0.12).timeout
	assert(scene.player.roll_time > 0.1)
	assert(scene.player.position.distance_to(before) > 10)
	scene.player.hurt_box.receive_hit(scene.slime.hit_box)
	assert(scene.player.health.current_health == 88)
	await create_timer(0.5).timeout
	assert(scene.player.visual_root.rotation == 0)
	await create_timer(0.6).timeout
	var return_position: Vector2 = scene.player.position
	scene.player.position = Vector2(650,900)
	scene.player.face(Vector2.LEFT)
	await press(KEY_SHIFT)
	await create_timer(0.5).timeout
	assert(scene.player.position.x >= 629, "Roll cannot pass through the entrance wall")
	scene.player.position = return_position
	# Face the source: the branch parry still costs 3 HP, not zero.
	scene.slime.position = scene.player.position + Vector2(0,-90)
	scene.player.face(Vector2.UP)
	await press(KEY_K)
	scene.player.hurt_box.receive_hit(scene.slime.hit_box)
	assert(scene.player.health.current_health == 85)
	scene.player.hurt_box.receive_hit(scene.slime.hit_box)
	assert(scene.player.health.current_health == 85)
	await create_timer(1).timeout
	# Facing away and late parries take the full 12 damage.
	scene.player.face(Vector2.DOWN)
	await press(KEY_K)
	scene.player.hurt_box.receive_hit(scene.slime.hit_box)
	assert(scene.player.health.current_health == 73)
	await create_timer(1).timeout
	scene.player.face(Vector2.UP)
	await press(KEY_K)
	await create_timer(0.34).timeout
	scene.player.hurt_box.receive_hit(scene.slime.hit_box)
	assert(scene.player.health.current_health == 61)
	await create_timer(1).timeout
	await press(KEY_SPACE)
	await create_timer(0.2).timeout
	assert(scene.player.jump_height > 40)
	scene.player.hurt_box.receive_hit(scene.slime.hit_box)
	assert(scene.player.health.current_health == 61)
	await create_timer(0.8).timeout
	# Multiple ordinary hits cross the threshold once; no forced one-hit injury.
	for i in 2:
		scene.player.hurt_box.receive_hit(scene.slime.hit_box)
		await create_timer(1).timeout
	while not scene.awakened: await process_frame
	assert(scene.player.health.current_health == 37 and scene.player.joy_power)
	assert(scene.slime.health.current_health == 12)
	await create_timer(2.2).timeout
	scene.slime.stop_attack()
	for i in 6:
		scene.player.position = scene.slime.position + Vector2(0,95)
		scene.player.face(Vector2.UP)
		scene.player.attack()
		await create_timer(0.8).timeout
		if i == 0: assert(not scene.won and scene.slime.health.current_health == 10)
	assert(scene.won and scene.fragment.enabled)
	print("CHAPTER2_COMBAT_OK: multi-hit injury, roll input and dodge, directional timed partial parry, jump, six enhanced hits")
	quit()
