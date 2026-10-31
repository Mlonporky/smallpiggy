extends "res://scenes/chapter2/cave.gd"
## F6 playable sample. Existing save/state isolation also catches F5 and pause-save.
func _ready() -> void:
	SaveManager.begin_preview()
	GameState.reset()
	allow_save = false
	super._ready()
	player.position = Vector2(735,650)
	player.reset_physics_interpolation()
	encounter_started = true
	slime.active = true
	ui.set_objective("实时战斗试玩 · R 重新试打 · 不影响正式存档")
	ui.set_status("边走边挥击，Shift 接闪避；Q 想起白菜（满血也能放）",8)

func start_encounter() -> void:
	pass

func collect_fragment() -> void:
	ui.set_status("试打完成 · 按 R 再试一次",10)

func _unhandled_input(event: InputEvent) -> void:
	if not busy and not get_tree().paused and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_viewport().set_input_as_handled()
		SceneRouter.change_scene(scene_file_path)
		return
	super._unhandled_input(event)

func _exit_tree() -> void:
	SaveManager.end_preview()
