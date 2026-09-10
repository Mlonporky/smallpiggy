extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await process_frame
 var state = root.get_node("GameState")
 state.reset()
 state.set_flag("ch1_opening_done")
 var i := 0
 var previous_alpha := 0.0
 for id in ["bedroom","kitchen","living"]:
  i += 1
  var scene = load("res://scenes/chapter1/%s.tscn" % id).instantiate()
  scene.auto_exit_enabled = false
  root.add_child(scene)
  await process_frame
  scene.lines = {}
  var pos: Vector2 = scene.get_node("MemoryAnchor").position
  var scale_value: Vector2 = scene.get_node("MemoryAnchor").scale
  var alpha: float = scene.get_node("MemoryAnchor").modulate.a
  assert(alpha > previous_alpha and alpha < 0.7)
  previous_alpha = alpha
  var zoom: Vector2 = scene.camera.zoom
  scene.lock(true)
  scene.memory_beat(i)
  var peak := 0.0
  for frame in 160:
   await physics_frame
   assert(scene.memory.position == pos,"Memory drifted")
   assert(scene.memory.scale == scale_value and scene.camera.zoom == zoom,"Memory/camera moved")
   peak = maxf(peak,scene.memory.modulate.a)
  assert(absf(peak-alpha)<0.02 and not scene.memory.visible,"Fade did not finish")
  if id == "living":
   scene.player.position = Vector2(410,600)
   scene.player.reset_physics_interpolation()
   scene.player.move_speed = 350
   assert(await scene.player.walk_to(Vector2(900,600),3),"Sofa/table corridor blocked left-to-right")
   assert(await scene.player.walk_to(Vector2(410,600),3),"Sofa/table corridor blocked right-to-left")
   scene.player.position = Vector2(700,880)
   scene.player.reset_physics_interpolation()
   Input.action_press("move_up")
   scene.player.set_input_enabled(true)
   for frame in 20: await physics_frame
   Input.action_release("move_up")
   assert(scene.player.position.y >= 834,"Table no longer solid")
  scene.queue_free()
  await process_frame
 print("POLISH_OK: fixed user anchors, three graduated fades, stable camera, corridor both directions and solid table")
 quit()
