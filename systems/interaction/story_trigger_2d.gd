class_name StoryTrigger2D
extends Area2D

signal triggered(trigger_id: String)

@export var trigger_id := ""
@export var one_shot := true
var consumed := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node2D) -> void:
	if consumed:
		return
	triggered.emit(trigger_id)
	if one_shot:
		consumed = true
		monitoring = false

