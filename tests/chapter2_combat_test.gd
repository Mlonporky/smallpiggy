extends SceneTree
var scene
func _initialize() -> void:
	create_timer(80).timeout.connect(func(): push_error("COMBAT_TIMEOUT");quit(1))
	call_deferred("run")
func _process(_delta: float) -> bool:
	if is_instance_valid(scene): scene.dialogue._advance_requested = true
	return false
func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func press(code: int) -> void:
	key(code,true)
	await physics_frame
	await physics_frame
	key(code,false)
func fresh() -> void:
	if is_instance_valid(scene):
		scene.queue_free()
		await process_frame
	root.get_node("GameState").reset()
	scene = load("res://scenes/chapter2/cave.tscn").instantiate()
	scene.allow_save = false
	root.add_child(scene)
	await process_frame
	scene.start_encounter()
	while scene.busy: await process_frame
	scene.slime.stop_attack()
func run() -> void:
	await process_frame
	await fresh()
	var p = scene.player
	var s = scene.slime
	p.position = Vector2(735,640)
	s.position = Vector2(735,480)
	# Full health active skill, no dialogue/lock, nearby enemy stagger and bounded hit.
	await press(KEY_Q)
	assert(p.health.current_health == 100 and p.joy_power and not scene.busy)
	assert(s.health.current_health == 22 and s.state == "stagger")
	await press(KEY_Q)
	assert(s.health.current_health == 22,"Cooldown rejects repeated damage")
	var cooldown: float = p.joy_cooldown
	var buff: float = p.joy_time
	scene.open_pause_menu()
	await process_frame
	await create_timer(0.3).timeout
	assert(p.joy_cooldown == cooldown and p.joy_time == buff,"Pause freezes skill timers")
	scene.menu_chosen.emit("stay")
	await process_frame
	# Movement continues during a real attack; one buffered press produces one follow-up.
	p.face(Vector2.RIGHT)
	var before: Vector2 = p.position
	key(KEY_D,true)
	await press(KEY_J)
	await create_timer(0.19).timeout
	assert(p._attacking and p.position.x > before.x+20,"Attack must allow movement")
	var serial: int = p.attack_serial
	await press(KEY_J)
	await create_timer(0.16).timeout
	assert(p.attack_serial == serial+1,"Recovery input is buffered")
	key(KEY_D,false)
	# Shift buffered before recovery cancels the recovery without a ghost hitbox.
	await press(KEY_SHIFT)
	await create_timer(0.18).timeout
	assert(p.roll_time > 0 and not p._attacking and not p.hit_box.monitoring, "Evade state %s %s %s %s" % [p.roll_time,p._attacking,p.attack_time,p.dodge_buffer])
	assert(p.visual_root.scale == Vector2.ONE and absf(p.visual_root.rotation)<0.15)
	await create_timer(0.07).timeout
	p.hurt_box.receive_hit(s.hit_box)
	assert(p.health.current_health == 100,"Middle of evade is invulnerable")
	await create_timer(0.5).timeout
	# One ordinary swing can only damage an enemy once while overlapping it.
	p.position = Vector2(735,575)
	s.position = Vector2(735,480)
	p.face(Vector2.UP)
	var hp: int = s.health.current_health
	await press(KEY_J)
	await create_timer(0.35).timeout
	assert(s.health.current_health == hp-2,"One enhanced strike, not per-frame damage")
	# No automatic low-health awakening. Timer expiry truly ends the enhancement.
	await create_timer(4.0).timeout
	assert(not p.joy_power)
	p.health.current_health = 40
	scene.on_health_changed(40,100)
	await create_timer(0.1).timeout
	assert(not scene.busy and not p.joy_power)
	await create_timer(4.0).timeout
	s.position = p.position + Vector2(0,-150)
	hp = s.health.current_health
	await press(KEY_Q)
	assert(p.joy_power and s.health.current_health == hp-2,"Skill is repeatable")
	# Old awakening saves are valid but no longer force low HP or a permanent buff.
	root.get_node("GameState").set_flag("s2_joy_awakened")
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/chapter2/cave.tscn").instantiate()
	scene.allow_save = false
	root.add_child(scene)
	await process_frame
	assert(scene.player.health.current_health == 100 and not scene.player.joy_power)
	assert(scene.player.joy_cooldown == 0 and scene.slime.health.current_health == 24)
	# Ordinary attacks alone now finish the encounter without taking any damage.
	await fresh()
	p = scene.player
	s = scene.slime
	for i in 24:
		p.position = Vector2(735,575)
		s.position = Vector2(735,480)
		p.face(Vector2.UP)
		await press(KEY_J)
		await create_timer(0.37).timeout
		assert(s.health.current_health == 23-i,"Every ordinary swing registers")
	await create_timer(0.6).timeout
	assert(scene.won and scene.fragment.enabled and p.health.current_health == 100)
	print("CHAPTER2_COMBAT_OK: full-HP Q, cooldown/reuse, pause, movement, buffer, recovery evade, one hit per swing, legacy save, ordinary no-damage victory")
	quit()
