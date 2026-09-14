extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 await process_frame
 root.get_node("GameState").reset()
 change_scene_to_file("res://scenes/cabbage_act2/villa.tscn")
 await process_frame
 await process_frame
 var routes := [["path","path"],["mushroom","mushroom"],["path","path"],["villa","villa"]]
 assert(current_scene.player.character_id == "white_cabbage")
 for step in routes:
  assert(Geometry2D.is_point_in_polygon(current_scene.player.position,current_scene.floor_polygon),"Spawn outside path")
  current_scene.travel(step[0])
  await root.get_node("SceneRouter").transition_finished
  assert(current_scene.location == step[1])
  assert(current_scene.player.input_enabled)
 # Physics movement into a border must remain inside the authored walkable area.
 current_scene.player.position = Vector2(1120,535)
 current_scene.player.reset_physics_interpolation()
 Input.action_press("move_up")
 for i in 100: await physics_frame
 Input.action_release("move_up")
 assert(current_scene.player.position.y > 500,"House boundary failed")
 assert(Geometry2D.is_point_in_polygon(current_scene.player.position,current_scene.floor_polygon))
 current_scene.travel("living")
 await root.get_node("SceneRouter").transition_finished
 assert(current_scene.room_id == "living")
 assert(current_scene.player.position.distance_to(Vector2(710,875)) < 3)
 print("CABBAGE_EXTERIOR_OK")
 quit()
