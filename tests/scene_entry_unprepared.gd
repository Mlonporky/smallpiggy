extends "res://scenes/finale/final_chapter.gd"
## Measurement control only: same production scene without its offscreen draw.
func _prepare_presentation() -> void:
 rendering_ready=true
 presentation_ready.emit()
