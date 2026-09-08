extends Node2D

@onready var player: PiggyPlayer = %Player
@onready var dialogue: DialogueUI = %DialogueUI
@onready var ui: GameUI = %GameUI
@onready var puzzle: BreakfastPuzzleController = %BreakfastPuzzle
@onready var memory_echo: MemoryEcho = %MemoryEcho
@onready var pink_slot: PropInteractable = %PinkSlot
@onready var placed_cup: PropInteractable = %PlacedCup
@onready var placed_tableware: PropInteractable = %PlacedTableware
@onready var coffee_machine: PropInteractable = $World/Props/CoffeeMachine
@onready var pig_cup: PropInteractable = $World/Props/PigCup
@onready var pink_tableware: PropInteractable = $World/Props/PinkTableware
@onready var green_slot: PropInteractable = %GreenSlot

var dialogue_data: Dictionary = {}
var _dialogue_busy := false


func _ready() -> void:
	GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART
	dialogue_data = _load_dialogue("res://data/dialogue/chapter_01.json")
	player.character_id = "white_cabbage"
	player.combat_enabled = false
	player.prompt_changed.connect(ui.set_prompt)
	puzzle.feedback_requested.connect(_on_feedback_requested)
	puzzle.item_inspected.connect(_on_item_inspected)
	puzzle.item_placed.connect(_on_item_placed)
	puzzle.puzzle_solved.connect(_on_puzzle_solved)
	ui.set_objective("在安静的家里，先给自己弄一杯咖啡")
	ui.set_heart_visible(true)
	ui.heart.text = "♡"
	placed_cup.visible = false
	placed_tableware.visible = false
	_configure_camera()
	if GameState.has_flag("breakfast_puzzle_solved"):
		_restore_completed_state()
	else:
		call_deferred("_play_intro")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _dialogue_busy:
		SceneRouter.change_scene("res://scenes/bootstrap/main.tscn")


func _play_intro() -> void:
	await _play_dialogue_key("wake_up")
	ui.set_status("这个男孩记得家，却感觉不到家的温度。", 3.4)


func _on_feedback_requested(text: String) -> void:
	if text == "COFFEE_FIRST":
		call_deferred("_play_coffee_dialogue")
	else:
		ui.set_status(text)


func _play_coffee_dialogue() -> void:
	await _play_dialogue_key("coffee")
	ui.set_objective("调查粉色猪猪杯和双人餐具，再复原早餐位")


func _on_item_inspected(item_id: String) -> void:
	call_deferred("_play_dialogue_key", "pig_cup" if item_id == "pig_cup" else "tableware")


func _on_item_placed(item_id: String) -> void:
	if item_id == "pig_cup":
		placed_cup.visible = true
	else:
		placed_tableware.visible = true


func _on_puzzle_solved() -> void:
	call_deferred("_play_memory_echo")


func _play_memory_echo() -> void:
	_dialogue_busy = true
	player.set_input_enabled(false)
	ui.set_prompt("")
	pink_slot.visible = false
	GameState.cabbage_resonance_progress = 1
	GameState.set_flag("breakfast_puzzle_solved")
	await memory_echo.play()
	await dialogue.say_lines(dialogue_data.get("memory_echo", []))
	await memory_echo.fade_out()
	ui.heart.text = "♥"
	ui.set_objective("样板完成：白白菜仍未恢复记忆，只产生了一次共鸣")
	ui.set_status("共鸣留在了心里。进度已自动保存。", 4.0)
	SaveManager.save_game(scene_file_path)
	player.set_input_enabled(true)
	_dialogue_busy = false


func _play_dialogue_key(key: String) -> void:
	if _dialogue_busy:
		return
	_dialogue_busy = true
	player.set_input_enabled(false)
	ui.set_prompt("")
	await dialogue.say_lines(dialogue_data.get(key, []))
	player.set_input_enabled(true)
	_dialogue_busy = false


func _load_dialogue(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing dialogue data: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _configure_camera() -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = -576
	camera.limit_right = 576
	camera.limit_top = -324
	camera.limit_bottom = 324
	camera.limit_smoothed = false
	camera.reset_smoothing()


func _restore_completed_state() -> void:
	puzzle.completed = true
	puzzle.coffee_made = true
	puzzle.placed["pig_cup"] = true
	puzzle.placed["pink_tableware"] = true
	for prop in [coffee_machine, pig_cup, pink_tableware, green_slot, pink_slot]:
		prop.set_enabled(false)
	pig_cup.visible = false
	pink_tableware.visible = false
	green_slot.visible = false
	pink_slot.visible = false
	placed_cup.visible = true
	placed_tableware.visible = true
	ui.heart.text = "♥"
	ui.set_objective("样板完成：早餐位已复原，白白菜产生了一次共鸣")
	ui.set_status("已载入白白菜篇存档。", 2.5)
