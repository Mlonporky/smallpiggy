extends CanvasLayer
## Direct F6 film preview, isolated from player saves and GameState.
var memory: Control
var replay: Button
@export var automatic := false

func _ready() -> void:
 start()

func start() -> void:
 if is_instance_valid(replay): replay.queue_free()
 if is_instance_valid(memory): memory.queue_free()
 memory = preload("res://scenes/cabbage_act2/acorn_memory.gd").new()
 memory.preview_mode = true
 memory.auto_advance = automatic
 memory.auto_duration = 3.8 if automatic else 2.8
 add_child(memory)
 memory.finished.connect(func():
  replay = Button.new()
  replay.text = "再看一次橡子回忆"
  replay.position = Vector2(30,30)
  replay.size = Vector2(250,56)
  replay.pressed.connect(start)
  add_child(replay))
