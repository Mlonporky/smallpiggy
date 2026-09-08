extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_check(ResourceLoader.exists("res://scenes/bootstrap/main.tscn"), "bootstrap scene exists")
	_check(ResourceLoader.exists("res://scenes/prologue/prologue.tscn"), "prologue scene exists")
	_check(ResourceLoader.exists("res://scenes/chapter_01_hollow_heart/cabbage_home.tscn"), "cabbage slice exists")
	_check(ResourceLoader.exists("res://scenes/chapter_02_dark_forest/forest_clearing.tscn"), "forest slice exists")
	await _check_scene("res://scenes/bootstrap/main.tscn", ["NewGameButton", "ChapterOneButton", "ContinueButton"])
	await _check_scene("res://scenes/prologue/prologue.tscn", ["CastlePanel", "GiftPanel", "ManorPanel", "TitlePanel", "CrystalBall", "MagicCircle", "DialogueUI"])
	await _check_scene("res://scenes/chapter_01_hollow_heart/cabbage_home.tscn", ["Player", "BreakfastPuzzle", "MemoryEcho", "DialogueUI"])
	await _check_scene("res://scenes/chapter_02_dark_forest/forest_clearing.tscn", ["Player", "ForestSlime", "GiftFragment", "PurpleFog", "JoyBurst"])
	_check_json("res://data/dialogue/chapter_01.json")
	_check_json("res://data/dialogue/chapter_02.json")
	_check_json("res://data/dialogue/prologue.json")

	if failures.is_empty():
		print("SMOKE_TEST_OK: scenes, required nodes, scripts, and dialogue data loaded")
		quit(0)
	else:
		for failure in failures:
			push_error("SMOKE_TEST_FAILED: " + failure)
		quit(1)


func _check_scene(path: String, required_nodes: Array[String]) -> void:
	var packed := load(path) as PackedScene
	_check(packed != null, "%s loads" % path)
	if packed == null:
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	for node_name in required_nodes:
		_check(instance.find_child(node_name, true, false) != null, "%s contains %s" % [path, node_name])
	instance.queue_free()
	await process_frame


func _check_json(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "%s opens" % path)
	if file:
		_check(JSON.parse_string(file.get_as_text()) is Dictionary, "%s parses as a dictionary" % path)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
