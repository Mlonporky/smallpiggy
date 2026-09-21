extends CanvasLayer
## Isolated F6 jigsaw preview; never writes story flags or player saves.
var puzzle: Control
var replay: Button
func _ready() -> void:
 start()
func start() -> void:
 if is_instance_valid(replay): replay.queue_free()
 if is_instance_valid(puzzle):
  remove_child(puzzle)
  puzzle.queue_free()
 puzzle = preload("res://scenes/cabbage_act2/wrapping_puzzle.gd").new()
 add_child(puzzle)
 puzzle.closed.connect(func():
  puzzle.queue_free()
  replay = Button.new()
  replay.text = "重新拼一次"
  replay.position = Vector2(30,30)
  replay.size = Vector2(180,60)
  replay.pressed.connect(start)
  add_child(replay))
