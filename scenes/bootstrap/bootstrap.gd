extends Control

@onready var continue_button: Button = %ContinueButton
@onready var save_note: Label = %SaveNote


func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save()
	save_note.text = "找到存档，可以继续。" if SaveManager.has_save() else "还没有存档；先选择一个玩法样板。"
	%ChapterOneButton.grab_focus()


func _on_chapter_one_pressed() -> void:
	GameState.reset()
	GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART
	SceneRouter.change_scene("res://scenes/chapter_01_hollow_heart/cabbage_home.tscn")


func _on_chapter_two_pressed() -> void:
	GameState.reset()
	GameState.story_phase = GameState.StoryPhase.LITTLE_PIG_DARK_FOREST
	SceneRouter.change_scene("res://scenes/chapter_02_dark_forest/forest_clearing.tscn")


func _on_continue_pressed() -> void:
	var path := SaveManager.load_game()
	if path.is_empty() or not ResourceLoader.exists(path):
		save_note.text = "存档中的场景不可用，请选择玩法样板。"
		return
	SceneRouter.change_scene(path)

