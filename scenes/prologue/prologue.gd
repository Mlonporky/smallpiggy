extends Node2D
# Legacy v1 controller retained as reference. prologue.tscn now uses opening.gd.

@onready var stage: Control = %Stage
@onready var castle_panel: Control = %CastlePanel
@onready var gift_panel: Control = %GiftPanel
@onready var manor_panel: Control = %ManorPanel
@onready var title_panel: Control = %TitlePanel
@onready var black_overlay: ColorRect = %BlackOverlay
@onready var white_flash: ColorRect = %WhiteFlash
@onready var curse_overlay: ColorRect = %CurseOverlay
@onready var system_message: Label = %SystemMessage
@onready var dialogue: DialogueUI = %DialogueUI
@onready var crystal: Sprite2D = %CrystalBall
@onready var wizard: Sprite2D = %Wizard
@onready var pig: Sprite2D = %LittlePig
@onready var joy_image: Sprite2D = %JoyImage
@onready var joy_particles: GPUParticles2D = %JoyParticles
@onready var magic_circle: PrologueMagicCircle = %MagicCircle
@onready var manor_lights: PrologueArt = %ManorLights
@onready var purple_fog: GPUParticles2D = %PurpleFog
@onready var title_group: Control = %TitleGroup

var dialogue_data: Dictionary = {}
var skipping := false


func _ready() -> void:
	GameState.story_phase = GameState.StoryPhase.PROLOGUE
	dialogue_data = _load_dialogue("res://data/dialogue/prologue.json")
	for panel in [castle_panel, gift_panel, manor_panel, title_panel]:
		panel.visible = false
	black_overlay.color.a = 1.0
	white_flash.color.a = 0.0
	curse_overlay.color.a = 0.0
	system_message.modulate.a = 0.0
	joy_image.modulate.a = 0.0
	joy_particles.emitting = false
	purple_fog.emitting = false
	title_group.modulate.a = 0.0
	dialogue.line_started.connect(_on_line_started)
	call_deferred("_play")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		skip_to_chapter()


func skip_to_chapter() -> void:
	if skipping:
		return
	skipping = true
	GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART
	SceneRouter.change_scene("res://scenes/chapter_01_hollow_heart/cabbage_home.tscn", 0.18)


func _play() -> void:
	await _show_system_message("滴……", 0.65)
	await get_tree().create_timer(0.38).timeout
	await _show_system_message("滴……", 0.65)
	await get_tree().create_timer(0.26).timeout
	await _show_system_message("滴滴滴滴——！", 0.7)
	if skipping:
		return

	castle_panel.visible = true
	await _fade_black(false, 0.9)
	await dialogue.say_lines(dialogue_data.get("castle_opening", []))
	if skipping:
		return
	await _white_flash(0.24)
	castle_panel.visible = false
	gift_panel.visible = true
	await dialogue.say_lines(dialogue_data.get("gift_wrapping", []))
	if skipping:
		return

	# Hard cut back to the castle as the crystal alarm peaks.
	gift_panel.visible = false
	castle_panel.visible = true
	system_message.text = "滴滴滴滴滴滴滴滴——！！"
	system_message.modulate.a = 1.0
	await get_tree().create_timer(0.8).timeout
	system_message.modulate.a = 0.0
	await dialogue.say_lines(dialogue_data.get("wizard_discovery", []))
	if skipping:
		return

	magic_circle.activate()
	await dialogue.say_lines(dialogue_data.get("curse", []))
	magic_circle.surge()
	await _camera_shake(0.62, 18.0)
	await _white_flash(0.42)
	castle_panel.visible = false
	manor_panel.visible = true
	purple_fog.emitting = true
	for count in range(4, -1, -1):
		manor_lights.active_lights = count
		await get_tree().create_timer(0.34).timeout
	if skipping:
		return

	await _white_flash(0.18)
	manor_panel.visible = false
	gift_panel.visible = true
	var curse_tween := create_tween()
	curse_tween.tween_property(curse_overlay, "color:a", 0.62, 1.0)
	await dialogue.say_lines(dialogue_data.get("curse_hits", []))
	black_overlay.color.a = 1.0 # The cut after "白菜——！" must be immediate.
	gift_panel.visible = false
	await get_tree().create_timer(1.4).timeout
	if skipping:
		return

	curse_overlay.color.a = 0.0
	title_panel.visible = true
	await _fade_black(false, 1.2)
	var title_tween := create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(title_group, "modulate:a", 1.0, 1.2)
	title_tween.tween_property(title_group, "scale", Vector2.ONE, 1.2).from(Vector2(0.92, 0.92)).set_trans(Tween.TRANS_SINE)
	await title_tween.finished
	GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART
	GameState.cabbage_emotional_state = GameState.CabbageEmotionalState.HOLLOW
	await get_tree().create_timer(3.6).timeout
	if not skipping:
		SceneRouter.change_scene("res://scenes/chapter_01_hollow_heart/cabbage_home.tscn", 0.8)


func _on_line_started(line: Dictionary) -> void:
	var text := str(line.get("text", ""))
	var speaker := str(line.get("speaker", ""))
	if speaker == "水晶球":
		_pulse_node(crystal, 1.055)
	if text.contains("白菜") and gift_panel.visible:
		_joy_pulse(1.0 if text.contains("一定会很开心") else 0.7)
	if text == "白菜……":
		_joy_pulse(1.35)
		_pulse_node(crystal, 1.10)
	if text in ["快乐。", "期待。", "思念。"]:
		_pulse_node(wizard, 1.04)
	if text == "遗忘之咒！":
		magic_circle.surge()


func _joy_pulse(strength: float) -> void:
	joy_image.modulate.a = 0.0
	joy_image.scale = Vector2.ONE * (0.17 * strength)
	joy_particles.amount = maxi(10, int(22 * strength))
	joy_particles.restart()
	joy_particles.emitting = true
	var tween := create_tween()
	tween.tween_property(joy_image, "modulate:a", minf(0.9, 0.52 * strength), 0.18)
	tween.parallel().tween_property(joy_image, "scale", Vector2.ONE * (0.23 * strength), 0.5)
	tween.tween_property(joy_image, "modulate:a", 0.0, 0.65)


func _pulse_node(node: Node2D, amount: float) -> void:
	var original := node.scale
	var tween := create_tween()
	tween.tween_property(node, "scale", original * amount, 0.13)
	tween.tween_property(node, "scale", original, 0.23).set_trans(Tween.TRANS_BACK)


func _show_system_message(text: String, duration: float) -> void:
	system_message.text = text
	var tween := create_tween()
	tween.tween_property(system_message, "modulate:a", 1.0, 0.12)
	tween.tween_interval(duration)
	tween.tween_property(system_message, "modulate:a", 0.0, 0.18)
	await tween.finished


func _fade_black(to_black: bool, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(black_overlay, "color:a", 1.0 if to_black else 0.0, duration)
	await tween.finished


func _white_flash(duration: float) -> void:
	white_flash.color.a = 0.0
	var tween := create_tween()
	tween.tween_property(white_flash, "color:a", 0.96, duration * 0.4)
	tween.tween_property(white_flash, "color:a", 0.0, duration * 0.6)
	await tween.finished


func _camera_shake(duration: float, strength: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		stage.position = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	stage.position = Vector2.ZERO


func _load_dialogue(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing dialogue data: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
