extends Node2D

@onready var player: PiggyPlayer = %Player
@onready var slime: ForestSlime = %ForestSlime
@onready var gift_fragment: PropInteractable = %GiftFragment
@onready var dialogue: DialogueUI = %DialogueUI
@onready var ui: GameUI = %GameUI
@onready var joy_burst: GPUParticles2D = %JoyBurst

var dialogue_data: Dictionary = {}
var _dialogue_busy := false
var _encounter_won := false


func _ready() -> void:
	GameState.story_phase = GameState.StoryPhase.LITTLE_PIG_DARK_FOREST
	dialogue_data = _load_dialogue("res://data/dialogue/chapter_02.json")
	player.character_id = "little_pig"
	player.combat_enabled = true
	player.prompt_changed.connect(ui.set_prompt)
	player.health_changed.connect(ui.set_health)
	player.player_died.connect(_on_player_died)
	slime.set_target(player)
	slime.defeated.connect(_on_slime_defeated)
	gift_fragment.interacted.connect(_on_gift_fragment_interacted)
	gift_fragment.visible = false
	gift_fragment.set_enabled(false)
	ui.set_health(3, 3)
	ui.set_objective("寻找散落的礼物碎片 · 穿过前方空地")
	_configure_camera()
	if GameState.has_flag("forest_slime_defeated"):
		_restore_completed_state()
	else:
		call_deferred("_play_intro")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _dialogue_busy:
		SceneRouter.change_scene("res://scenes/bootstrap/main.tscn")


func _play_intro() -> void:
	_dialogue_busy = true
	player.set_input_enabled(false)
	slime.active = false
	await dialogue.say_lines(dialogue_data.get("intro", []))
	ui.set_status("史莱姆攻击前会压低身体并变亮。看准时机躲开。", 4.0)
	player.set_input_enabled(true)
	slime.active = true
	_dialogue_busy = false


func _on_slime_defeated() -> void:
	_encounter_won = true
	gift_fragment.visible = true
	gift_fragment.set_enabled(true)
	ui.set_objective("拾取史莱姆守护的红色礼物碎片")
	ui.set_status("史莱姆消失了，空地重新安静下来。", 3.0)


func _on_gift_fragment_interacted(_actor: Node) -> void:
	if not _encounter_won or _dialogue_busy:
		return
	_dialogue_busy = true
	player.set_input_enabled(false)
	gift_fragment.set_enabled(false)
	gift_fragment.visible = false
	var added := GameState.add_gift_fragment("fragment_red_wrap_01")
	GameState.set_flag("forest_slime_defeated")
	joy_burst.global_position = gift_fragment.global_position
	joy_burst.restart()
	joy_burst.emitting = true
	await dialogue.say_lines(dialogue_data.get("victory", []))
	ui.set_objective("样板完成：已找回第一块礼物碎片")
	ui.set_status("礼物碎片已保存。没有增加任何 Heart。" if added else "这块碎片已经收集过了。", 4.0)
	SaveManager.save_game(scene_file_path)
	player.set_input_enabled(true)
	_dialogue_busy = false


func _on_player_died() -> void:
	if _dialogue_busy:
		return
	_dialogue_busy = true
	slime.active = false
	await dialogue.say_lines(dialogue_data.get("defeat", []))
	SceneRouter.change_scene(scene_file_path)


func _load_dialogue(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing dialogue data: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _configure_camera() -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = -780
	camera.limit_right = 780
	camera.limit_top = -470
	camera.limit_bottom = 470
	camera.limit_smoothed = false
	camera.reset_smoothing()


func _restore_completed_state() -> void:
	_encounter_won = true
	slime.queue_free()
	gift_fragment.visible = false
	gift_fragment.set_enabled(false)
	ui.set_objective("样板完成：已找回第一块礼物碎片")
	ui.set_status("已载入小呆猪篇存档。", 2.5)
