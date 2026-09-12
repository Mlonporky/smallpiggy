extends Node

signal transition_started(path: String)
signal transition_finished(path: String)

var _busy := false


func is_busy() -> bool:
	return _busy


func change_scene(path: String, fade_duration := 0.28) -> void:
	if _busy:
		return
	_busy = true
	transition_started.emit(path)

	var overlay := ColorRect.new()
	overlay.color = Color(0.035, 0.027, 0.055, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.add_child(overlay)
	get_tree().root.add_child(layer)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, fade_duration)
	await tween.finished
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("SceneRouter could not load %s (error %s)" % [path, error])
		layer.queue_free()
		_busy = false
		return

	await get_tree().process_frame
	var fade_in := create_tween()
	fade_in.tween_property(overlay, "color:a", 0.0, fade_duration)
	await fade_in.finished
	layer.queue_free()
	_busy = false
	transition_finished.emit(path)

