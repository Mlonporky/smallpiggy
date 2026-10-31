extends SceneTree
## Fixed 30fps movie export; this is not a runtime performance measurement.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 change_scene_to_file("res://scenes/finale/handhold_preview.tscn")
 for i in 3: await process_frame
 while not current_scene.finished: await process_frame
 await create_timer(0.6).timeout
 print("FINALE_HANDHOLD_RENDER_OK")
 quit()
