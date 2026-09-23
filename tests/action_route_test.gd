extends "res://tests/action_level_test.gd"
var room: Node2D
var frame_times: Array[float] = []
func go(goal: Vector2) -> void:
 var p = room.player
 var deadline := Time.get_ticks_msec()+8000
 var jump_end := 0
 var next_jump := 0
 var attack_end := 0
 var next_attack := 0
 while Time.get_ticks_msec()<deadline:
  if p.is_on_floor() and absf(p.position.x-goal.x)<28 and absf(p.position.y-goal.y)<8: break
  var dx: float = goal.x-p.position.x
  var direction := signf(dx)
  key(KEY_D,dx>12)
  key(KEY_A,dx < -12)
  var now := Time.get_ticks_msec()
  var floor_rect := Rect2()
  for rect in room.platforms:
   if absf(p.position.y-rect.position.y)<5 and p.position.x>=rect.position.x-10 and p.position.x<=rect.end.x+10:
    floor_rect = rect
    break
  var near_edge: bool = p.position.x>floor_rect.end.x-42 if direction>0 else p.position.x<floor_rect.position.x+42
  var need_jump: bool = p.is_on_wall() or (goal.y<p.position.y-35 and (absf(dx)<140 or near_edge)) or (near_edge and absf(dx)>80 and goal.y<=p.position.y+35)
  if p.is_on_floor() and need_jump and now>next_jump:
   jump_end = now+600
   next_jump = now+900
  key(KEY_SPACE,now<jump_end)
  if now>next_attack:
   attack_end = now+70
   next_attack = now+400
  key(KEY_J,now<attack_end)
  await create_timer(0.025).timeout
 key(KEY_D,false)
 key(KEY_A,false)
 key(KEY_SPACE,false)
 key(KEY_J,false)
 if not (absf(p.position.x-goal.x)<45 and absf(p.position.y-goal.y)<12):
  push_error("Route waypoint unreachable: %s at %s" % [goal,p.position])
  quit(1)
  await process_frame
 await create_timer(0.12).timeout
func run() -> void:
 await process_frame
 var before: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/action_test/test_level.tscn")
 await create_timer(0.3).timeout
 room = current_scene
 process_frame.connect(func(): frame_times.append(root.get_process_delta_time()))
 await go(Vector2(345,900))
 await tap(KEY_E)
 assert(room.player.combat.weapon.kind=="sword")
 for goal in [Vector2(730,840),Vector2(975,750),Vector2(1245,660),Vector2(1590,570)]: await go(goal)
 await tap(KEY_E)
 assert(room.player.combat.weapon.kind=="dagger")
 await capture("upper-route")
 for goal in [Vector2(1850,590),Vector2(2140,660),Vector2(2390,580),Vector2(2620,490)]: await go(goal)
 await tap(KEY_E)
 assert(room.player.combat.weapon.kind=="hammer" and room.secrets_found)
 await capture("secret")
 await go(Vector2(2860,650))
 await go(Vector2(2380,900))
 assert(room.checkpoint_active)
 await capture("camp")
 for goal in [Vector2(3020,900),Vector2(3480,900),Vector2(3790,820),Vector2(4040,735),Vector2(4300,820),Vector2(4600,900)]: await go(goal)
 assert(room.finished and room.player.health.hp>0)
 await capture("exit")
 # Return to checkpoint via normal retry, then descend into the recoverable lower path.
 await tap(KEY_R)
 await go(Vector2(2160,1030))
 await go(Vector2(1640,1120))
 await capture("lower-route")
 await go(Vector2(1200,1120))
 await go(Vector2(1085,1030))
 await go(Vector2(955,900))
 assert(root.get_node("GameState").to_dictionary()==before)
 frame_times.sort()
 print("ACTION_ROUTES_OK p95_ms=",frame_times[int(frame_times.size()*0.95)]*1000)
 quit()
