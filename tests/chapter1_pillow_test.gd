extends SceneTree
## Walk the actual sofa aisle, then open the close-up through real key/click input.
const OUT="res://docs/verification/pillow_2026-10-31/"
var room: Node
var observations: Array[Dictionary]=[]

func _initialize() -> void: call_deferred("run")

func key_press() -> void:
 var key:=InputEventKey.new()
 key.keycode=KEY_E
 key.physical_keycode=KEY_E
 key.pressed=true
 Input.parse_input_event(key)
 for i in 2: await physics_frame
 key=key.duplicate()
 key.pressed=false
 Input.parse_input_event(key)
 await process_frame

func click_pillow() -> void:
 var click:=InputEventMouseButton.new()
 click.button_index=MOUSE_BUTTON_LEFT
 click.position=room.get_global_transform_with_canvas()*Vector2(690,435)
 click.global_position=click.position
 click.pressed=true
 click.button_mask=MOUSE_BUTTON_MASK_LEFT
 root.push_input(click,true)
 await process_frame
 click=click.duplicate()
 click.pressed=false
 click.button_mask=0
 root.push_input(click,true)
 await process_frame

func settle() -> void:
 for i in 240:
  if not room.busy: return
  await process_frame
 assert(false,"Pillow sequence did not release player input")

func walk(at: Vector2) -> void:
 room.player.set_input_enabled(false)
 assert(await room.player.walk_to(at,4.0),"Furniture blocked approach: "+str(at))
 room.player.set_input_enabled(true)
 for i in 3: await physics_frame

func screenshot(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT+name+".png")

func run() -> void:
 await process_frame
 var state:=root.get_node("GameState")
 state.reset()
 state.set_flag("ch1_opening_done")
 state.gain_chapter_heart("bedroom_memory_complete")
 state.gain_chapter_heart("kitchen_memory_complete")
 room=load("res://scenes/chapter1/living.tscn").instantiate()
 room.test_mode=true
 room.auto_exit_enabled=false
 room.route_on_exit=false
 root.add_child(room)
 room.ui.test_mode=false
 await process_frame
 for at in [Vector2(410,570),Vector2(440,600),Vector2(560,600),Vector2(690,600),Vector2(820,600),Vector2(910,600)]:
  await walk(at)
  for facing in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
   room.player.face(facing)
   await physics_frame
   assert(room.player._nearest_interactable==room.hotspots.pillow)
   assert(room.interaction_hint=="猪猪抱枕")
  if at==Vector2(690,600): await screenshot("front_approach")
  for method in ["keyboard","mouse"]:
   if method=="keyboard": await key_press()
   else: await click_pillow()
   assert(room.ui.inspecting and room.ui.closeup.visible,"No pillow close-up: "+str(at)+method)
   assert(room.ui.closeup.texture.resource_path.ends_with("pillow_plush_hd.png"))
   observations.append({"feet":str(room.player.position),"input":method,"closeup":true})
   if at==Vector2(690,600) and method=="mouse": await screenshot("pillow_closeup")
   await key_press()
   await settle()
   assert(state.heart_progress==3 and state.has_flag("red_paper_spawned"))
   assert(not state.has_flag("ch1_can_leave_home"),"Pillow bypassed the paper clue")
 # Return around the table and try from below it: no remote click or competing
 # pillow prompt is allowed at the paper, basket, or exit.
 await walk(Vector2(490,600))
 await walk(Vector2(490,875))
 await walk(Vector2(710,875))
 assert(room.player._nearest_interactable==room.hotspots.paper)
 assert(not room.can_reach("pillow",room.player.position))
 await click_pillow()
 assert(not room.ui.inspecting and not room.busy)
 assert(not room.can_reach("pillow",Vector2(1225,875)))
 assert(not room.can_reach("pillow",Vector2(710,950)))
 FileAccess.open(OUT+"approaches.json",FileAccess.WRITE).store_string(JSON.stringify(observations,"  "))
 print("CHAPTER1_PILLOW_OK 6 physical approaches, 24 facing checks, 12 real inputs; remote click rejected; memory/paper gates preserved")
 room.queue_free()
 await process_frame
 quit()
