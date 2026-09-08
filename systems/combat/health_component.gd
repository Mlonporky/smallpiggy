class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal died

@export var max_health := 3
var current_health := 3


func _ready() -> void:
	current_health = max_health


func damage(amount: int) -> bool:
	if current_health <= 0:
		return false
	current_health = maxi(0, current_health - maxi(0, amount))
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	current_health = mini(max_health, current_health + maxi(0, amount))
	health_changed.emit(current_health, max_health)


func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

