extends SceneTree
## Godot --path . --resolution 1152x648 --fixed-fps 30
## --write-movie /tmp/acorn-final/frame.png --script tools/render_acorn_memory.gd
## Uses the real film, including every line and its return to the room.
func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 await process_frame
 var film := preload("res://scenes/cabbage_act2/acorn_memory.gd").new()
 film.preview_mode = true
 film.auto_advance = true
 film.auto_duration = 3.8
 root.add_child(film)
 await film.finished
 await create_timer(0.8).timeout
 print("ACORN_FINAL_RENDER_OK")
 quit()
