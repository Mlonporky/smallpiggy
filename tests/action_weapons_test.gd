extends "res://tests/action_movement_test.gd"
func run() -> void:
 await process_frame
 change_scene_to_file("res://scenes/action_test/combat_room.tscn")
 await create_timer(0.3).timeout
 var room = current_scene
 var p = room.player
 assert(p.health.heal(20)==0,"Full health must not waste a heal")
 p.health.take_damage(40,1)
 assert(p.health.heal(20)==20 and p.health.hp==80)
 var damages := []
 var impulse := []
 for kind in ["sword","dagger","hammer"]:
  p.reset_at(Vector2(160,900))
  p.combat.weapon = load("res://scenes/action_test/weapons/"+kind+".tres")
  var dummy = load("res://scenes/action_test/enemies/base_enemy.gd").new()
  dummy.max_hp = 100
  dummy.position = Vector2(225,900)
  dummy.target = p
  dummy.room = room
  room.world.add_child(dummy)
  await create_timer(0.1).timeout
  key(KEY_J,true)
  await create_timer(0.3).timeout
  key(KEY_J,false)
  damages.append(100-dummy.hp)
  impulse.append(absf(dummy.velocity.x))
  dummy.queue_free()
  await create_timer(0.4).timeout
 assert(damages==[28,16,52],"Every weapon needs its own damage profile")
 assert(impulse[2]>impulse[0] and impulse[0]>impulse[1])
 p.dodge_enabled = true
 key(KEY_SHIFT,true)
 await create_timer(0.06).timeout
 key(KEY_SHIFT,false)
 assert(p.roll_time>0 and p.roll_cooldown>0)
 p.health.invulnerable = 0
 assert(not p.health.take_damage(20,1),"Roll window must protect against damage")
 await create_timer(0.25).timeout
 assert(p.roll_time==0)
 key(KEY_SHIFT,true)
 await create_timer(0.03).timeout
 key(KEY_SHIFT,false)
 assert(p.roll_time==0,"Cooldown prevents repeated roll spam")
 print("ACTION_WEAPONS_DODGE_OK")
 quit()
