extends SceneTree
var scene
var auto_dialogue := true
var seen: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func _process(_delta: float) -> bool:
	if auto_dialogue and is_instance_valid(scene) and is_instance_valid(scene.dialogue):
		scene.dialogue._advance_requested = true
	return false
func load_scene(path: String) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
		await process_frame
	scene = load(path).instantiate()
	scene.allow_save = false
	root.add_child(scene)
	current_scene = scene
	scene.dialogue.line_started.connect(func(line: Dictionary): seen.append(line.text))
	await process_frame
func until_idle() -> void:
	var elapsed := 0.0
	while scene.busy and elapsed < 180:
		await process_frame
		elapsed += 1.0/60.0
	assert(not scene.busy,"Cutscene failed to restore input")
func run() -> void:
	await process_frame
	var state = root.get_node("GameState")
	state.reset()
	state.heart_progress = 3
	await load_scene("res://scenes/chapter_02_dark_forest/forest_clearing.tscn")
	assert(not scene.player.input_enabled and not scene.player.combat_enabled)
	await until_idle()
	assert(state.has_flag("s2_pig_wakeup_complete"))
	# Physical blocker must hold before the wizard conversation.
	scene.player.position = Vector2(740,400)
	Input.action_press("move_up")
	await create_timer(0.6).timeout
	Input.action_release("move_up")
	assert(scene.player.position.y > 365)
	scene.player.position = Vector2(840,630)
	scene.paper.interact(scene.player)
	await until_idle()
	assert(state.has_flag("s2_pig_wizard_complete"))
	assert(not scene.wizard.visible)
	assert(scene.player.input_enabled)
	assert("因为我要去找白菜。" in seen and "刚才是什么？" in seen)
	var count := seen.count("你醒了。")
	scene.paper.interact(scene.player)
	await until_idle()
	assert(seen.count("你醒了。") == count)
	assert(seen.back() == "我要把礼物找回来。")
	var snapshot = state.to_dictionary()
	state.reset()
	state.load_dictionary(snapshot)
	await load_scene("res://scenes/chapter_02_dark_forest/forest_clearing.tscn")
	assert(scene.wizard_finished and not scene.busy)
	assert(state.heart_progress == 3)
	# The stick lies beside the wake-up spot; the northern path stays shut until she holds it.
	assert(scene.stick.visible and not scene.player.armed)
	assert(scene.stick.position.distance_to(Vector2(720,715)) < 150)
	scene.player.position = Vector2(740,400)
	Input.action_press("move_up")
	await create_timer(0.6).timeout
	Input.action_release("move_up")
	assert(scene.player.position.y > 365,"Must pick up the stick before leaving the clearing")
	scene.stick.interact(scene.player)
	await until_idle()
	assert(scene.player.armed and not scene.stick.visible)
	assert(state.has_flag("s2_pig_stick_collected"))
	assert("还好有一个小树枝。" in seen and seen.back() == "至少现在我不会太害怕了……")
	# Crossing the real exit triggers title, saved flag and the router.
	scene.player.position = Vector2(740,390)
	Input.action_press("move_up")
	var old_scene = scene
	while not state.has_flag("s2_pig_intro_complete"):
		await process_frame
	Input.action_release("move_up")
	while current_scene == old_scene or current_scene == null: await process_frame
	scene = current_scene
	scene.allow_save = false
	await create_timer(0.8).timeout
	assert(scene.scene_file_path.ends_with("cave.tscn"))
	# She arrives holding the stick from the clearing.
	assert(scene.player.armed and scene.player.combat_enabled and not scene.slime.active)
	assert(state.has_flag("heart_ui_unlocked") and state.heart_progress == 3)
	# Use real hitbox and timing: face upward from below the enemy.
	scene.slime.active = false
	scene.lock(true) # Prevent the entrance trigger from starting AI during hitbox assertions.
	for hit in 3:
		scene.player.position = scene.slime.position + Vector2(0,70)
		scene.player.face(Vector2.UP)
		scene.player.attack()
		await create_timer(0.6).timeout
	var defeat_deadline := Time.get_ticks_msec()+2500
	while not scene.won and Time.get_ticks_msec()<defeat_deadline: await process_frame
	assert(scene.won,"Three real stick attacks should defeat the slime")
	assert(scene.fragment.enabled)
	scene.lock(false)
	scene.fragment.interact(scene.player)
	assert(state.has_flag("forest_slime_defeated"))
	assert(state.gift_fragments.count("fragment_red_wrap_01") == 1)
	scene.fragment.interact(scene.player)
	assert(state.gift_fragments.size() == 1)
	await load_scene("res://scenes/chapter2/cave.tscn")
	assert(scene.won and not is_instance_valid(scene.slime))
	# Death reloads the cave, retaining weapon and story but restoring health.
	state.set_flag("forest_slime_defeated",false)
	await load_scene("res://scenes/chapter2/cave.tscn")
	assert(scene.player.armed)
	var dying_scene = scene
	scene.player.health.damage(3)
	await process_frame
	assert(scene.busy and not scene.player.input_enabled)
	while current_scene == dying_scene or current_scene == null: await process_frame
	scene = current_scene
	scene.allow_save = false
	await create_timer(0.6).timeout
	assert(scene.player.health.current_health == 3 and scene.player.input_enabled)
	assert(scene.player.armed and state.has_flag("s2_pig_intro_complete"))
	print("CHAPTER2_FLOW_OK")
	quit()
