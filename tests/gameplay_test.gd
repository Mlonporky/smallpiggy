extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _test_player_movement_and_combat()
	await _test_breakfast_puzzle()
	_test_persistent_state()
	if failures.is_empty():
		print("GAMEPLAY_TEST_OK: movement, combat, puzzle, and persistent state")
		quit(0)
	else:
		for failure in failures:
			push_error("GAMEPLAY_TEST_FAILED: " + failure)
		quit(1)


func _test_player_movement_and_combat() -> void:
	var player_scene := load("res://actors/shared/player.tscn") as PackedScene
	_check(player_scene != null, "player scene loads")
	if player_scene == null:
		return
	var player := player_scene.instantiate() as PiggyPlayer
	_check(player != null, "player scene instantiates as PiggyPlayer")
	if player == null:
		return
	player.character_id = "little_pig"
	player.combat_enabled = true
	root.add_child(player)
	await process_frame
	var start_x := player.global_position.x
	Input.action_press("move_right")
	for i in 12:
		await physics_frame
	Input.action_release("move_right")
	_check(player.global_position.x > start_x + 2.0, "player moves continuously with input")
	_check(player.velocity.x > 0.0, "player accelerates instead of staying still")

	var slime := (load("res://actors/slime/forest_slime.tscn") as PackedScene).instantiate() as ForestSlime
	slime.global_position = player.global_position + Vector2(70, 0)
	root.add_child(slime)
	await physics_frame
	player.face(Vector2.RIGHT)
	player.attack()
	await create_timer(0.27).timeout
	var slime_health := slime.get_node("Health") as HealthComponent
	_check(slime_health.current_health == 2, "player attack damages slime exactly once")

	var enemy_hit_box := slime.get_node("HitBox") as HitBox2D
	var player_hurt_box := player.get_node("HurtBox") as HurtBox2D
	player_hurt_box.receive_hit(enemy_hit_box)
	await process_frame
	var player_health := player.get_node("Health") as HealthComponent
	_check(player_health.current_health == 2, "enemy hit damages player")
	player.queue_free()
	slime.queue_free()
	await process_frame


func _test_breakfast_puzzle() -> void:
	var holder := Node.new()
	holder.name = "PuzzleFixture"
	var names := ["Coffee", "Cup", "Tableware", "GreenSlot", "PinkSlot"]
	for item_name in names:
		var prop := (load("res://systems/interaction/prop_interactable.tscn") as PackedScene).instantiate()
		prop.name = item_name
		holder.add_child(prop)
	var puzzle := BreakfastPuzzleController.new()
	puzzle.name = "Puzzle"
	puzzle.coffee_path = NodePath("../Coffee")
	puzzle.cup_path = NodePath("../Cup")
	puzzle.tableware_path = NodePath("../Tableware")
	puzzle.green_slot_path = NodePath("../GreenSlot")
	puzzle.pink_slot_path = NodePath("../PinkSlot")
	holder.add_child(puzzle)
	root.add_child(holder)
	await process_frame
	puzzle._on_coffee(null)
	puzzle._on_item("pig_cup", holder.get_node("Cup"))
	puzzle._on_item("pig_cup", holder.get_node("Cup"))
	puzzle._on_slot(false)
	_check(not puzzle.placed["pig_cup"], "wrong breakfast slot does not consume held item")
	puzzle._on_slot(true)
	puzzle._on_item("pink_tableware", holder.get_node("Tableware"))
	puzzle._on_item("pink_tableware", holder.get_node("Tableware"))
	puzzle._on_slot(true)
	_check(puzzle.completed, "breakfast puzzle completes after both correct placements")
	holder.queue_free()
	await process_frame


func _test_persistent_state() -> void:
	# Standalone --script tests do not register project autoload names at compile time.
	var state = load("res://autoload/game_state.gd").new()
	state.reset()
	_check(state.add_gift_fragment("fragment_red_wrap_01"), "first gift fragment add succeeds")
	_check(not state.add_gift_fragment("fragment_red_wrap_01"), "duplicate gift fragment is rejected")
	state.cabbage_resonance_progress = 1
	var snapshot: Dictionary = state.to_dictionary()
	state.reset()
	state.load_dictionary(snapshot)
	_check(state.cabbage_resonance_progress == 1, "resonance survives serialization")
	_check(state.gift_fragments == ["fragment_red_wrap_01"], "gift fragment survives serialization")
	state.free()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
