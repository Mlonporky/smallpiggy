extends "res://tests/action_movement_test.gd"
func tap(code: int) -> void:
 key(code,true)
 await create_timer(0.05).timeout
 key(code,false)
 await create_timer(0.05).timeout
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/action-level-"+name+".png")
func run() -> void:
 await process_frame
 var before: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/action_test/test_level.tscn")
 await create_timer(0.4).timeout
 var room = current_scene
 var p = room.player
 key(KEY_D,true)
 await create_timer(0.57).timeout
 key(KEY_D,false)
 await create_timer(0.15).timeout
 await tap(KEY_E)
 assert(p.combat.weapon and p.combat.weapon.kind=="sword")
 await capture("start")
 # Deterministic pickup fixtures test swapping, healing and checkpoint semantics.
 var dagger = room.spawn_pickup("weapon",p.position,load("res://scenes/action_test/weapons/dagger.tres"))
 await create_timer(0.1).timeout
 await tap(KEY_E)
 assert(p.combat.weapon.kind=="dagger" and dagger.consumed)
 assert(room.pickups.any(func(i): return not i.consumed and i.kind=="weapon" and i.weapon.kind=="sword"))
 var apple = room.spawn_pickup("heal",p.position)
 await create_timer(0.1).timeout
 assert(not apple.consumed,"Full HP leaves the apple available")
 p.health.invulnerable = 0
 p.health.take_damage(40,1)
 await create_timer(0.12).timeout
 assert(p.health.hp==80 and apple.consumed)
 p.health.invulnerable = 0
 p.health.take_damage(40,1)
 var large = room.spawn_pickup("heal",p.position)
 large.amount = 40
 await create_timer(0.12).timeout
 assert(p.health.hp==80 and large.consumed,"Large healing item restores 40 HP")
 p.reset_at(Vector2(2380,900))
 await create_timer(0.2).timeout
 assert(room.checkpoint_active and room.checkpoint==Vector2(2380,900))
 await capture("checkpoint")
 p.health.invulnerable = 0
 p.health.take_damage(100,1)
 await create_timer(1.15).timeout
 assert(p.health.hp==100 and absf(p.position.x-2380)<5)
 assert(p.combat.weapon.kind=="sword","Checkpoint restarts with a basic usable weapon")
 var enemy = room.enemies[3]
 p.reset_at(enemy.position+Vector2(0,-140))
 p.health.invulnerable = 0
 p.velocity.y = 480
 await create_timer(0.4).timeout
 assert(enemy.hp==72 and p.health.hp<100,"Spiked patrol cannot be stomped")
 await tap(KEY_F3)
 assert(room.debug_label.visible and room.debug_label.text.contains("Enemy HP"))
 await capture("debug")
 await tap(KEY_ESCAPE)
 var at: Vector2 = p.position
 var enemy_at: Vector2 = enemy.position
 await create_timer(0.2).timeout
 assert(p.position==at and enemy.position==enemy_at)
 await tap(KEY_ESCAPE)
 assert(root.get_node("GameState").to_dictionary()==before)
 print("ACTION_LEVEL_OK")
 quit()
