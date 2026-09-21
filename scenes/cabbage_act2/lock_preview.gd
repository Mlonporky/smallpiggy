extends CanvasLayer
## F6 preview, no GameState or save mutation.
var lock: Control
var replay: Button

func _ready() -> void:
 var backdrop := ColorRect.new()
 backdrop.color = Color("211b17")
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(backdrop)
 start()

func start() -> void:
 if is_instance_valid(replay): replay.queue_free()
 if is_instance_valid(lock):
  remove_child(lock)
  lock.queue_free()
 lock = preload("res://scenes/cabbage_act2/combination_lock.gd").new()
 add_child(lock)
 lock.finished.connect(func(_accepted):
  replay = Button.new()
  replay.text = "重新试一次"
  replay.position = Vector2(18,18)
  replay.size = Vector2(150,46)
  replay.pressed.connect(start)
  add_child(replay)
  replay.grab_focus())
