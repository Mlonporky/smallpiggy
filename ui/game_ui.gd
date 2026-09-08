class_name GameUI
extends CanvasLayer

@onready var prompt: Label = %InteractionPrompt
@onready var objective: Label = %Objective
@onready var status: Label = %Status
@onready var heart: Label = %Heart


func _ready() -> void:
	prompt.visible = false
	status.visible = false


func set_prompt(text: String) -> void:
	prompt.text = "[ E ]  %s" % text
	prompt.visible = not text.is_empty()


func set_objective(text: String) -> void:
	objective.text = text
	objective.visible = not text.is_empty()


func set_status(text: String, duration := 2.0) -> void:
	status.text = text
	status.visible = true
	var token := Time.get_ticks_msec()
	status.set_meta("token", token)
	await get_tree().create_timer(duration).timeout
	if status.get_meta("token", 0) == token:
		status.visible = false


func set_heart_visible(value: bool) -> void:
	heart.visible = value


func set_health(current: int, maximum: int) -> void:
	heart.visible = true
	heart.text = "生命  " + "● ".repeat(current) + "○ ".repeat(maximum - current)

