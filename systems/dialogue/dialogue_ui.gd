class_name DialogueUI
extends CanvasLayer

signal line_started(line: Dictionary)
signal line_finished(line: Dictionary)

@onready var panel: PanelContainer = %Panel
@onready var speaker_label: Label = %Speaker
@onready var text_label: Label = %Text
@onready var hint_label: Label = %Hint

var _line_active := false
var _typing := false
var _advance_requested := false


func _ready() -> void:
	panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _line_active:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance_requested = true


func say(
	speaker: String,
	text: String,
	pause_before := 0.0,
	pause_after := 0.0,
	auto_advance := false,
	auto_duration := 1.5
) -> void:
	if pause_before > 0.0:
		await get_tree().create_timer(pause_before).timeout
	var line := {"speaker": speaker, "text": text}
	line_started.emit(line)
	_line_active = true
	_advance_requested = false
	panel.visible = true
	speaker_label.text = speaker
	text_label.text = text
	text_label.visible_ratio = 0.0
	hint_label.visible = false
	_typing = true

	var duration := clampf(text.length() * 0.025, 0.18, 1.5)
	var elapsed := 0.0
	while elapsed < duration and not _advance_requested:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		text_label.visible_ratio = elapsed / duration
	_typing = false
	text_label.visible_ratio = 1.0
	_advance_requested = false
	hint_label.visible = true

	var auto_elapsed := 0.0
	while not _advance_requested:
		await get_tree().process_frame
		if auto_advance:
			auto_elapsed += get_process_delta_time()
			if auto_elapsed >= auto_duration:
				break
	_advance_requested = false
	if pause_after > 0.0:
		await get_tree().create_timer(pause_after).timeout
	_line_active = false
	panel.visible = false
	line_finished.emit(line)


func say_lines(lines: Array) -> void:
	for entry in lines:
		await say(
			str(entry.get("speaker", "")),
			str(entry.get("text", "")),
			float(entry.get("pause_before", 0.0)),
			float(entry.get("pause_after", 0.0)),
			bool(entry.get("auto_advance", false)),
			float(entry.get("auto_duration", 1.5))
		)
