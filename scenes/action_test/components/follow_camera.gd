extends Camera2D
## Calm platformer camera.
## - Horizontal look-ahead drifts slowly toward the facing side, so turning never whips the view.
## - Vertical framing holds the last ground height while airborne; ordinary jumps do not bob the screen.
## - Both axes use critically damped smoothing (no sudden starts), then a hard safety box keeps the
##   player on screen during long falls or mushroom launches.
@export var look_distance := 110.0
@export var look_rate := 1.5
@export var horizontal_time := 0.30
@export var vertical_time := 0.45
@export var fall_time := 0.16
@export var frame_height := 150.0
@export var launch_room := 250.0
@export var max_shake := 7.0
var target: CharacterBody2D
var bounds := Rect2(0, 0, 4800, 1400)
var view := Vector2(1536, 864)
var trauma := 0.0
var look := 0.0
var anchor_y := 0.0
var smooth_velocity := Vector2.ZERO
var shake_clock := 0.0


func _init() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func follow(delta: float) -> void:
	if target == null:
		return
	var feet: Vector2 = target.position
	var ratio := clampf(absf(target.velocity.x) / 330.0, 0.35, 1.0)
	look = move_toward(look, target.facing * look_distance * ratio, look_distance * look_rate * delta)
	if target.is_on_floor():
		anchor_y = feet.y
	elif feet.y > anchor_y + 12:
		anchor_y = feet.y
	elif feet.y < anchor_y - launch_room:
		anchor_y = feet.y + launch_room
	var goal := _clamp_center(Vector2(feet.x + look, anchor_y - frame_height))
	var y_time := fall_time if target.velocity.y > 650 else vertical_time
	var next := Vector2(
		_damp(position.x, goal.x, 0, horizontal_time, delta),
		_damp(position.y, goal.y, 1, y_time, delta))
	# Safety box: never let fast motion carry the player outside a comfortable frame.
	next.x = clampf(next.x, feet.x - view.x * 0.30, feet.x + view.x * 0.30)
	next.y = clampf(next.y, feet.y - view.y * 0.5 + 70, feet.y + view.y * 0.5 - 140)
	position = _clamp_center(next)
	trauma = maxf(0, trauma - delta * 2.4)
	shake_clock += delta
	var amount := trauma * trauma * max_shake
	offset = Vector2(sin(shake_clock * 47.0) + sin(shake_clock * 29.0) * 0.5, cos(shake_clock * 41.0)) * amount * 0.66


func add_trauma(value: float) -> void:
	trauma = minf(1.0, trauma + value)


func snap_to_target() -> void:
	if target == null:
		return
	anchor_y = target.position.y
	look = target.facing * look_distance * 0.35
	smooth_velocity = Vector2.ZERO
	position = _clamp_center(Vector2(target.position.x + look, anchor_y - frame_height))
	offset = Vector2.ZERO
	trauma = 0
	reset_physics_interpolation()


func _clamp_center(at: Vector2) -> Vector2:
	var half := view * 0.5
	return Vector2(
		clampf(at.x, bounds.position.x + half.x, maxf(bounds.position.x + half.x, bounds.end.x - half.x)),
		clampf(at.y, bounds.position.y + half.y, maxf(bounds.position.y + half.y, bounds.end.y - half.y)))


func _damp(current: float, goal: float, axis: int, smooth_time: float, delta: float) -> float:
	# Critically damped spring (same form as Unity's SmoothDamp): continuous velocity, no overshoot.
	var omega := 2.0 / maxf(0.0001, smooth_time)
	var x := omega * delta
	var decay := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := current - goal
	var temp := (smooth_velocity[axis] + omega * change) * delta
	smooth_velocity[axis] = (smooth_velocity[axis] - omega * temp) * decay
	return goal + (change + temp) * decay
