extends "res://tests/underground_combat_test.gd"
## End-to-end fight through the authored spawn positions: no teleports or health edits.
func run() -> void:
 await process_frame
 var original: Dictionary = root.get_node("GameState").to_dictionary()
 var scene = await fresh()
 var pig = scene.pig
 var combat = scene.combat
 await tap(KEY_E)
 await tap(KEY_3)
 assert(pig.weapon==3)
 key(KEY_J,true)
 var deadline := Time.get_ticks_msec()+35000
 var jump_until := 0
 var next_jump := 0
 while combat.kills<3 and pig.hp>0 and Time.get_ticks_msec()<deadline:
  var target: CharacterBody2D = null
  var distance := INF
  for enemy in combat.enemies:
   if enemy.hp<=0: continue
   var gap: float = pig.position.distance_to(enemy.position)
   if gap<distance:
    target = enemy
    distance = gap
  if target==null: break
  var dx: float = target.position.x-pig.position.x
  var dy: float = target.position.y-pig.position.y
  var direction := signf(dx)
  var should_walk: bool = absf(dx)>65 or dy>65 or direction!=pig.facing
  # When below a target, move close enough to rise onto its platform.
  key(KEY_D,should_walk and direction>=0)
  key(KEY_A,should_walk and direction<0)
  var now := Time.get_ticks_msec()
  if pig.is_on_floor() and (dy < -45 or pig.is_on_wall()) and now>next_jump:
   jump_until = now+620
   next_jump = now+1000
  key(KEY_SPACE,now<jump_until)
  await create_timer(0.04).timeout
 key(KEY_J,false)
 key(KEY_D,false)
 key(KEY_A,false)
 key(KEY_SPACE,false)
 assert(combat.kills==3 and pig.hp>0,"Authored route must be clearable using movement/jump/attack; kills=%d hp=%d pos=%s" % [combat.kills,pig.hp,pig.position])
 await create_timer(0.7).timeout
 assert(combat.result.text.contains("已清理"))
 await capture("route-clear")
 assert(root.get_node("GameState").to_dictionary()==original)
 print("UNDERGROUND_ROUTE_OK hp=",pig.hp)
 quit()
