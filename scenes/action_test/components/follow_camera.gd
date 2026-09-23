extends Camera2D
var target: CharacterBody2D
var bounds := Rect2(0,0,4800,1400)
var trauma := 0.0
func _init() -> void:
 process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
 zoom = Vector2.ONE/3
func follow(delta: float) -> void:
 var lead := Vector2(target.velocity.x*0.27,clampf(target.velocity.y*0.09,-65,85))
 var goal := target.position+Vector2(0,-150)+lead
 goal.x = clampf(goal.x,768,bounds.end.x-768)
 goal.y = clampf(goal.y,432,bounds.end.y-432)
 position = position.lerp(goal,1-exp(-5.5*delta))
 trauma = maxf(0,trauma-delta*12)
 offset = Vector2(sin(Time.get_ticks_msec()*0.07),cos(Time.get_ticks_msec()*0.083))*trauma*3
func snap_to_target() -> void:
 position = Vector2(clampf(target.position.x,768,bounds.end.x-768),clampf(target.position.y-150,432,bounds.end.y-432))
 offset = Vector2.ZERO
 reset_physics_interpolation()
