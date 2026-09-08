class_name HitBox2D
extends Area2D

@export var damage := 1
@export var team := "neutral"


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func activate(duration := 0.1) -> void:
	monitoring = true
	await get_tree().physics_frame
	for area in get_overlapping_areas():
		_on_area_entered(area)
	await get_tree().create_timer(duration).timeout
	monitoring = false


func _on_area_entered(area: Area2D) -> void:
	if area is HurtBox2D:
		area.receive_hit(self)

