extends SceneTree
var cave
func _initialize() -> void:
	create_timer(40).timeout.connect(func(): push_error("DEFENSE_TIMEOUT");quit(1))
	call_deferred("run")
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	await physics_frame
	event.pressed = false
	Input.parse_input_event(event)
func run() -> void:
	await process_frame
	root.get_node("GameState").reset()
	cave = load("res://scenes/chapter2/cave.tscn").instantiate()
	cave.allow_save = false
	root.add_child(cave)
	await process_frame
	cave.encounter_started = true
	var p = cave.player
	var s = cave.slime
	p.position = Vector2(650,900)
	p.face(Vector2.LEFT)
	await key(KEY_SHIFT)
	await create_timer(0.4).timeout
	assert(p.position.x >= 629,"Evade respects cave walls")
	p.position = Vector2(735,750)
	s.position = p.position+Vector2(0,-90)
	p.face(Vector2.UP)
	await key(KEY_K)
	p.hurt_box.receive_hit(s.hit_box)
	assert(p.health.current_health == 97,"Front timed parry retains 75 percent damage reduction")
	p.hurt_box.receive_hit(s.hit_box)
	assert(p.health.current_health == 97,"Damage immunity prevents duplicate damage")
	await create_timer(1).timeout
	p.face(Vector2.DOWN)
	await key(KEY_K)
	p.hurt_box.receive_hit(s.hit_box)
	assert(p.health.current_health == 85,"Back-facing parry takes damage")
	await create_timer(1).timeout
	p.face(Vector2.UP)
	await key(KEY_K)
	await create_timer(0.34).timeout
	p.hurt_box.receive_hit(s.hit_box)
	assert(p.health.current_health == 73,"Late parry takes damage")
	await create_timer(1).timeout
	await key(KEY_SPACE)
	await create_timer(0.2).timeout
	p.hurt_box.receive_hit(s.hit_box)
	assert(p.jump_height > 40 and p.health.current_health == 73,"Jump dodges contact")
	# Scene lock prevents Q from firing or setting a cooldown.
	cave.lock(true)
	await key(KEY_Q)
	assert(p.joy_cooldown == 0)
	cave.lock(false)
	await create_timer(0.7).timeout
	p.position = Vector2(735,750)
	s.position = Vector2(735,480)
	await key(KEY_Q)
	assert(p.joy_power and s.health.current_health == 24,"Out-of-range pulse never hits remotely")
	await create_timer(8.1).timeout
	p.position = Vector2(735,650)
	s.attack_lunge()
	s.active = true
	await create_timer(s.WINDUP+0.05).timeout
	assert(s.state == "dash" and s.hit_box.monitoring)
	await key(KEY_Q)
	await physics_frame
	assert(s.state == "stagger" and not s.hit_box.monitoring,"Skill cancels the real dash hitbox")
	print("CHAPTER2_DEFENSE_OK wall collision, front/back/late parry, jump, locks, skill range, dash interruption")
	quit()
