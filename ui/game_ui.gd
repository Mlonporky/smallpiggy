class_name GameUI
extends CanvasLayer

@onready var prompt: Label = %InteractionPrompt
@onready var objective: Label = %Objective
@onready var status: Label = %Status
@onready var heart: Label = %Heart


func _ready() -> void:
	prompt.visible = false
	status.visible = false
	var prompt_panel := prompt.get_parent() as Control
	prompt_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_panel.offset_left = 24
	prompt_panel.offset_right = -24
	prompt_panel.offset_top = -76
	prompt_panel.offset_bottom = -20
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_left = 24
	status.offset_right = -24
	status.offset_top = -140
	status.offset_bottom = -90
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	objective.offset_left = 24
	objective.offset_right = -24
	objective.offset_top = 22
	objective.offset_bottom = 62
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_panel.hide()


func set_prompt(text: String) -> void:
	prompt.text = "[ E ]  %s" % text
	prompt.visible = not text.is_empty()
	prompt.get_parent().visible = prompt.visible


func set_objective(text: String) -> void:
	objective.text = text
	objective.visible = not text.is_empty()


func set_status(text: String, duration := 2.0) -> void:
	status.text = text
	status.visible = true
	var token := Time.get_ticks_msec()
	status.set_meta("token", token)
	await get_tree().create_timer(duration, false).timeout
	if status.get_meta("token", 0) == token:
		status.visible = false


func set_heart_visible(value: bool) -> void:
	heart.visible = value


func set_health(current: int, maximum: int) -> void:
	heart.visible = true
	heart.text = "生命  " + "● ".repeat(current) + "○ ".repeat(maximum - current)

