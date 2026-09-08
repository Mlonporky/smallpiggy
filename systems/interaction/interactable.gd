class_name Interactable
extends Area2D

signal interacted(actor: Node)

@export var interaction_id := ""
@export var prompt_text := "调查"
@export var enabled := true


func interact(actor: Node) -> void:
	if enabled:
		interacted.emit(actor)


func set_enabled(value: bool) -> void:
	enabled = value
	monitorable = value

