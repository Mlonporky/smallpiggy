extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 root.get_node("GameState").set_flag("ch1_opening_done")
 var scene = load("res://scenes/chapter1/bedroom.tscn").instantiate()
 scene.test_mode = true
 scene.auto_exit_enabled = false
 root.add_child(scene)
 await process_frame
 assert(not scene.get_node("MemoryAnchor").visible)
 assert(not scene.get_node("EditorBackground").visible)
 scene.get_node("MemoryAnchor").position = Vector2(820,720)
 scene.get_node("MemoryAnchor").scale = Vector2(0.2,0.2)
 scene.memory_beat(1)
 assert(scene.memory.position == Vector2(820,720))
 assert(scene.memory.scale == Vector2(0.2,0.2))
 await create_timer(0.3).timeout
 print("MEMORY_ANCHOR_OK: edited position/scale drive runtime; editor previews hidden")
 quit()
