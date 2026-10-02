extends CanvasLayer
## F6 preview is isolated from GameState and SaveManager.
var puzzle: Control
var replay: Button

func _ready() -> void:
 start()

func start() -> void:
 if is_instance_valid(replay): replay.queue_free()
 puzzle = preload("res://scenes/cabbage_act2/table_slide_puzzle.gd").new()
 add_child(puzzle)
 puzzle.closed.connect(func():
  puzzle.queue_free()
  replay = Button.new()
  replay.text = "再试一次桌面拼图"
  replay.position = Vector2(30,30)
  replay.size = Vector2(250,60)
  replay.pressed.connect(start)
  add_child(replay))
