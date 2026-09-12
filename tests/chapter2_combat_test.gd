extends SceneTree
var scene
var space_interactions := 0
func _initialize() -> void: call_deferred("run")
func _process(_delta: float) -> bool:
	if is_instance_valid(scene): scene.dialogue._advance_requested = true
	return false
func run() -> void:
	await process_frame
	root.get_node("GameState").reset()
	root.get_node("SaveManager").save_path = "/tmp/piggy_chapter2_combat_test.json"
	scene = load("res://scenes/chapter2/cave.tscn").instantiate()
	scene.allow_save = false
	root.add_child(scene)
	await process_frame
	assert(scene.player.health.current_health == 100)
	# Early real attacks cannot skip the injury/awakening sequence.
	scene.lock(true)
	scene.player.position = scene.slime.position + Vector2(0,95)
	scene.player.face(Vector2.UP)
	scene.player.attack()
	await create_timer(0.7).timeout
	assert(scene.slime.health.current_health == 3 and not scene.awakened)
	scene.lock(false)
	scene.player.position = Vector2(735,700)
	scene.start_encounter()
	var deadline := Time.get_ticks_msec() + 15000
	while not scene.awakened and Time.get_ticks_msec() < deadline: await process_frame
	assert(scene.awakened,"Real scripted lunge must land and trigger joy at 40 percent")
	assert(scene.player.health.current_health == 40 and scene.player.joy_power)
	assert(scene.slime.health.current_health == 2 and not scene.slime.shielded)
	assert(scene.player.input_enabled and scene.player.combat_enabled)
	# Real Space input starts a jump, retains the feet collider and avoids an overlapping hit.
	scene.hotspot(scene.player.position + Vector2(0,-46),"test interaction",func(): space_interactions += 1)
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	assert(space.is_action("jump"))
	Input.parse_input_event(space)
	await physics_frame
	await physics_frame
	space.pressed = false
	Input.parse_input_event(space)
	await create_timer(0.22).timeout
	assert(space_interactions == 0,"Space jumps without also interacting")
	assert(scene.player.jump_height > 40 and scene.player.visual_root.position.y < -40)
	var before: int = scene.player.health.current_health
	scene.player.hurt_box.receive_hit(scene.slime.hit_box)
	assert(scene.player.health.current_health == before,"Airborne player dodges slime hits")
	await create_timer(0.8).timeout
	assert(scene.player.jump_height == 0 and scene.player.visual_root.position.y == 0)
	# Grounded hit does damage, then invulnerability prevents a duplicate.
	scene.player.hurt_box.receive_hit(scene.slime.hit_box)
	assert(scene.player.health.current_health == 20)
	scene.player.hurt_box.receive_hit(scene.slime.hit_box)
	assert(scene.player.health.current_health == 20)
	# One enhanced real hit now finishes the wounded slime.
	scene.slime.stop_attack()
	scene.player.position = scene.slime.position + Vector2(0,95)
	scene.player.face(Vector2.UP)
	scene.player.attack()
	await create_timer(1.0).timeout
	assert(scene.won and scene.fragment.enabled)
	assert(root.get_node("GameState").has_flag("s2_joy_awakened"))
	print("CHAPTER2_COMBAT_OK: intro hit 100 -> 40, one-time joy, jump dodge, grounded hurt, powered finishing blow")
	quit()
