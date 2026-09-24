extends "res://tests/action_movement_test.gd"
## Comfort checks for the scrolling action rooms (the causes of the reported dizziness):
## 1. the far background moves the same way as the playfield, but slower (true parallax);
## 2. an ordinary jump barely moves the camera vertically;
## 3. turning around never jerks the camera (bounded per-frame acceleration);
## 4. the world renders at native resolution (no low-res SubViewport upscaled with nearest filtering).
func run() -> void:
	await process_frame
	change_scene_to_file("res://scenes/action_test/movement_room.tscn")
	await create_timer(0.4).timeout
	var room = current_scene
	var p = room.player
	var camera: Camera2D = room.camera
	assert(room.find_children("*", "SubViewport", true, false).is_empty(), "World must not render through a low-res SubViewport")
	assert(is_equal_approx(camera.zoom.x, minf(room.get_viewport_rect().size.x / 1536.0, room.get_viewport_rect().size.y / 864.0)))
	# 2. Jump in place: the camera holds the ground height.
	p.reset_at(Vector2(1300, 900))
	room.snap_view()
	await create_timer(0.3).timeout
	var low := camera.position.y
	var high := camera.position.y
	key(KEY_SPACE, true)
	for i in 70:
		await physics_frame
		low = minf(low, camera.position.y)
		high = maxf(high, camera.position.y)
		if i == 40:
			key(KEY_SPACE, false)
	var bob := high - low
	assert(bob < 3.0, "A normal jump must not bob the camera (moved %.1f px)" % bob)
	# 1 and 3. Run right, then turn left: measure parallax ratio and camera acceleration.
	await create_timer(0.3).timeout
	var samples: Array[Vector2] = []
	var backdrop_screen: Array[float] = []
	key(KEY_D, true)
	for i in 70:
		await physics_frame
		samples.append(camera.position)
		backdrop_screen.append(room.backdrop.position.x - camera.position.x)
	key(KEY_D, false)
	key(KEY_A, true)
	for i in 90:
		await physics_frame
		samples.append(camera.position)
		backdrop_screen.append(room.backdrop.position.x - camera.position.x)
	key(KEY_A, false)
	var travel := samples[60].x - samples[20].x
	var drift := backdrop_screen[60] - backdrop_screen[20]
	assert(travel > 100, "Camera should follow the run")
	var ratio := -drift / travel
	assert(ratio > 0.05 and ratio < 0.5, "Background must scroll the same way as the ground, but slower (ratio %.2f)" % ratio)
	var max_accel := 0.0
	for i in range(2, samples.size()):
		var accel := absf((samples[i].x - samples[i - 1].x) - (samples[i - 1].x - samples[i - 2].x))
		max_accel = maxf(max_accel, accel)
	assert(max_accel < 1.2, "Camera must not jerk when turning (max %.2f px/frame²)" % max_accel)
	print("ACTION_CAMERA_OK jump_bob_px=%.2f parallax_ratio=%.2f max_turn_accel=%.2f" % [bob, ratio, max_accel])
	quit()
