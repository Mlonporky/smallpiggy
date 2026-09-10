@tool
extends Sprite2D
## Scene-authoring reference only; the runtime room builds its own presentation.
func _ready() -> void:
 visible = Engine.is_editor_hint()
