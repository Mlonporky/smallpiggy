extends "res://tests/action_movement_test.gd"
func run() -> void:
 await process_frame
 change_scene_to_file("res://scenes/action_test/combat_room.tscn")
 await create_timer(0.3).timeout
 var room = current_scene
 var enemy = load("res://scenes/action_test/enemies/base_enemy.gd").new()
 enemy.position = Vector2(250,900)
 enemy.target = room.player
 enemy.room = room
 room.world.add_child(enemy)
 room.enemies.append(enemy)
 await create_timer(0.1).timeout
 key(KEY_J,true)
 await create_timer(0.02).timeout
 assert(enemy.hp==48,"Windup must not damage before active frames")
 await create_timer(0.21).timeout
 key(KEY_J,false)
 assert(enemy.hp==20,"Each swing must hit once")
 await create_timer(0.35).timeout
 key(KEY_J,true)
 await create_timer(0.25).timeout
 key(KEY_J,false)
 assert(enemy.hp==0)
 print("ACTION_SWORD_OK")
 quit()
