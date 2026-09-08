class_name HurtBox2D
extends Area2D

signal damaged(hit_box: HitBox2D)

@export var team := "neutral"
var invulnerable := false


func receive_hit(hit_box: HitBox2D) -> void:
	if not invulnerable and hit_box.team != team:
		damaged.emit(hit_box)

