extends "res://tests/action_movement_test.gd"
func run() -> void:
 await process_frame
 change_scene_to_file("res://scenes/action_test/combat_room.tscn")
 await create_timer(0.4).timeout
 var room = current_scene
 var p = room.player
 var enemy = room.enemies[0]
 p.position = enemy.position+Vector2(0,-140)
 p.velocity = Vector2(0,480)
 var deadline := Time.get_ticks_msec()+2000
 while enemy.hp==48 and Time.get_ticks_msec()<deadline: await physics_frame
 assert(enemy.hp==16 and p.velocity.y<0 and p.health.hp==100,"Downward stomp must bounce without touching damage")
 await create_timer(0.2).timeout
 p.position = enemy.position+Vector2(12,0)
 p.previous_feet = p.position
 p.velocity = Vector2.ZERO
 await create_timer(0.1).timeout
 assert(p.health.hp==80,"Side contact must cause damage")
 print("ACTION_SLIME_OK")
 quit()
