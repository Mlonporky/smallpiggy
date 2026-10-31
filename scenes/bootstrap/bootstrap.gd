extends Control

@onready var continue_button: Button = %ContinueButton
@onready var save_note: Label = %SaveNote
var new_game_confirmation: ConfirmationDialog

func _ready() -> void:
	SaveManager.end_preview()
	continue_button.disabled = not SaveManager.has_save()
	save_note.text = "找到存档，可以继续上次的旅程。" if SaveManager.has_save() else "第一次来山庄？选择「新游戏」开始故事。"
	%NewGameButton.grab_focus()
	%SettingsButton.pressed.connect(AppSettings.open_panel)
	%PreviewsButton.pressed.connect(func(): show_previews(true))
	%BackButton.pressed.connect(func(): show_previews(false))
	%FinaleButton.pressed.connect(func():
		SaveManager.begin_preview()
		SceneRouter.change_scene("res://scenes/finale/final_chapter_preview.tscn"))
	new_game_confirmation = ConfirmationDialog.new()
	new_game_confirmation.title = "开始新的旅程？"
	new_game_confirmation.dialog_text = "已有正式存档。开始新游戏后，下一次保存将替换原进度。"
	new_game_confirmation.ok_button_text = "开始新游戏"
	new_game_confirmation.cancel_button_text = "继续保留原进度"
	new_game_confirmation.confirmed.connect(_start_new_game)
	add_child(new_game_confirmation)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	%Panel.custom_minimum_size.x = minf(570,get_viewport_rect().size.x-32)

func show_previews(value: bool) -> void:
	%MainActions.visible = not value
	%PreviewActions.visible = value
	%SaveNote.visible = not value
	%Panel.size.y = 0
	if value: %ChapterOneButton.grab_focus()
	else: %PreviewsButton.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and %PreviewActions.visible:
		show_previews(false)
		get_viewport().set_input_as_handled()

func _on_new_game_pressed() -> void:
	if SaveManager.has_save():
		new_game_confirmation.popup_centered(Vector2i(580,160))
	else: _start_new_game()

func _start_new_game() -> void:
	GameState.reset()
	SceneRouter.change_scene("res://scenes/prologue/prologue.tscn")

func _on_chapter_one_pressed() -> void:
	SaveManager.begin_preview()
	GameState.reset()
	GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART
	SceneRouter.change_scene("res://scenes/chapter1/bedroom.tscn")

func _on_chapter_two_pressed() -> void:
	SaveManager.begin_preview()
	GameState.reset()
	GameState.story_phase = GameState.StoryPhase.LITTLE_PIG_DARK_FOREST
	SceneRouter.change_scene("res://scenes/chapter_02_dark_forest/forest_clearing.tscn")

func _on_continue_pressed() -> void:
	var path := SaveManager.load_game()
	if path.is_empty() or not ResourceLoader.exists(path):
		save_note.text = "暂时无法读取存档。原文件已保留，可重试「继续游戏」。"
		return
	SceneRouter.change_scene(path)
