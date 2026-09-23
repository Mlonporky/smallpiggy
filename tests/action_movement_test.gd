extends SceneTree
func _initialize() -> void: call_deferred("run")
func key(code: int, down: bool) -> void:
 var e := InputEventKey.new()
 e.keycode = code
 e.physical_keycode = code
 e.pressed = down
 Input.parse_input_event(e)
func jump_height(player: CharacterBody2D, hold: float) -> float:
 player.reset_at(Vector2(160,900))
 await create_timer(0.15).timeout
 key(KEY_SPACE,true)
 var time := 0.0
 var top := player.position.y
 while time<1.1:
  await physics_frame
  time += 1.0/60
  top = minf(top,player.position.y)
  if time>=hold: key(KEY_SPACE,false)
 return 900-top
func run() -> void:
 await process_frame
 var before: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/action_test/movement_room.tscn")
 await create_timer(0.3).timeout
 var scene = current_scene
 var p = scene.player
 var short: float = await jump_height(p,0.05)
 var high: float = await jump_height(p,0.65)
 assert(short>25 and high>short+60,"Variable height must have a useful difference")
 key(KEY_D,true)
 await create_timer(0.6).timeout
 assert(absf(p.velocity.x-p.max_speed)<1)
 key(KEY_D,false)
 await create_timer(0.13).timeout
 assert(absf(p.velocity.x)<1,"Release must not feel like ice")
 key(KEY_D,true)
 key(KEY_SPACE,true)
 await create_timer(0.18).timeout
 key(KEY_D,false)
 key(KEY_A,true)
 await create_timer(0.05).timeout
 assert(p.velocity.x>0,"Air turn must retain some momentum")
 await create_timer(0.3).timeout
 assert(p.velocity.x<0,"Air steering must reverse direction promptly")
 key(KEY_A,false)
 key(KEY_SPACE,false)
 p.reset_at(Vector2(990,900))
 await create_timer(0.15).timeout
 key(KEY_D,true)
 p.velocity.x = p.max_speed
 var deadline := Time.get_ticks_msec()+2000
 while p.is_on_floor() and Time.get_ticks_msec()<deadline: await physics_frame
 assert(not p.is_on_floor())
 await create_timer(0.03).timeout
 key(KEY_SPACE,true)
 await create_timer(0.04).timeout
 assert(p.velocity.y<0,"Coyote jump must work beyond the edge")
 key(KEY_SPACE,false)
 key(KEY_D,false)
 p.reset_at(Vector2(350,730))
 p.velocity.y = 500
 deadline = Time.get_ticks_msec()+2000
 while p.position.y<865 and Time.get_ticks_msec()<deadline: await physics_frame
 key(KEY_SPACE,true)
 await create_timer(0.13).timeout
 assert(p.velocity.y<0,"Buffered jump must fire on landing")
 key(KEY_SPACE,false)
 assert(p.get_node("CollisionShape2D").scale==Vector2.ONE)
 assert(root.get_node("GameState").to_dictionary()==before)
 print("ACTION_MOVEMENT_OK short=",short," high=",high)
 quit()
