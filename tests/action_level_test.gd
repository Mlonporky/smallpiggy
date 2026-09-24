extends "res://tests/action_movement_test.gd"
## Deterministic fixture checks for the test level's systems. Positions are placed directly here to
## isolate each rule; the full key-only playthrough lives in action_route_test.gd.
func tap(code: int) -> void:
 key(code,true)
 await create_timer(0.05).timeout
 key(code,false)
 await create_timer(0.05).timeout
func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/private/tmp/pig-level-"+name+".png")
func run() -> void:
 await process_frame
 var before: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/action_test/test_level.tscn")
 await create_timer(0.4).timeout
 var room = current_scene
 var p = room.player
 key(KEY_D,true)
 var deadline := Time.get_ticks_msec()+3000
 while p.position.x<400 and Time.get_ticks_msec()<deadline: await physics_frame
 key(KEY_D,false)
 await create_timer(0.2).timeout
 await tap(KEY_E)
 assert(p.combat.weapon and p.combat.weapon.kind=="sword")
 await capture("start")
 # Weapon swap leaves the old weapon nearby.
 var dagger = room.spawn_pickup("weapon",p.position,load("res://scenes/action_test/weapons/dagger.tres"))
 await create_timer(0.1).timeout
 await tap(KEY_E)
 assert(p.combat.weapon.kind=="dagger" and dagger.consumed)
 assert(room.pickups.any(func(i): return not i.consumed and i.kind=="weapon" and i.weapon.kind=="sword"))
 # Healing: full HP keeps the apple; small and large apples restore 20 / 40.
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
 # Thorns hurt and throw the pig upward; they never kill instantly.
 p.reset_at(Vector2(860,1130))
 p.health.invulnerable = 0
 await create_timer(0.08).timeout
 assert(p.health.hp==80 and p.velocity.y<0,"Thorn pit damages and bounces")
 await create_timer(0.9).timeout
 # Mushrooms launch higher than a jump, and letting go of jump does not cut the launch.
 p.reset_at(Vector2(1810,990))
 await create_timer(0.05).timeout
 assert(p.launched and p.velocity.y<-800,"Mushroom launch")
 key(KEY_SPACE,true)
 await create_timer(0.03).timeout
 key(KEY_SPACE,false)
 await create_timer(0.03).timeout
 assert(p.velocity.y<-700,"Releasing jump keeps the mushroom launch")
 await create_timer(1.2).timeout
 # Jump-through branch: pass up from below, stand on it, drop with S + Space.
 room.enemies[0].take_hit(100,0)
 p.reset_at(Vector2(1435,1000))
 await create_timer(0.1).timeout
 key(KEY_SPACE,true)
 await create_timer(0.6).timeout
 key(KEY_SPACE,false)
 deadline = Time.get_ticks_msec()+2000
 while not p.is_on_floor() and Time.get_ticks_msec()<deadline: await physics_frame
 assert(absf(p.position.y-880)<2,"Jumped up through the branch and landed on it")
 key(KEY_S,true)
 await tap(KEY_SPACE)
 key(KEY_S,false)
 deadline = Time.get_ticks_msec()+2000
 while (p.position.y<990 or not p.is_on_floor()) and Time.get_ticks_msec()<deadline: await physics_frame
 assert(absf(p.position.y-1000)<2,"S + Space drops through the branch")
 # Crumbling slab: shakes, breaks, then returns.
 var slab = room.crumbles[0]
 p.reset_at(slab.rect.get_center()-Vector2(0,slab.rect.size.y*0.5+1))
 p.health.invulnerable = 5
 await create_timer(0.2).timeout
 assert(slab.state=="SHAKING")
 await create_timer(0.45).timeout
 assert(slab.state=="FALLEN" and p.position.y>650,"Slab gives way")
 p.reset_at(Vector2(3600,700))
 await create_timer(2.8).timeout
 assert(slab.state=="SOLID","Slab grows back")
 # Fireflies count once each.
 var fly: Dictionary = room.fireflies.filter(func(f): return not f.taken and f.pos.x>5500 and f.pos.x<5650)[0]
 var count: int = room.firefly_count
 p.reset_at(fly.pos+Vector2(0,47))
 await create_timer(0.1).timeout
 assert(fly.taken and room.firefly_count==count+1)
 # Campfire remembers the weapon; knock-out returns there with it.
 p.reset_at(room.CAMPFIRES[0])
 await create_timer(0.2).timeout
 assert(room.checkpoint_active and room.checkpoint==room.CAMPFIRES[0])
 assert(room.checkpoint_weapon and room.checkpoint_weapon.kind=="dagger")
 await capture("checkpoint")
 p.health.invulnerable = 0
 p.health.take_damage(100,1)
 await create_timer(1.15).timeout
 assert(p.health.hp==100 and absf(p.position.x-room.CAMPFIRES[0].x)<5 and room.deaths==1)
 assert(p.combat.weapon.kind=="dagger","Respawn keeps the weapon held at the campfire")
 # The burr hog's spikes cannot be stomped (only while it sits dizzy).
 var enemy = room.enemies.filter(func(e): return e.get_script().resource_path.ends_with("burr_hog.gd"))[0]
 assert(not enemy.stompable)
 p.reset_at(enemy.position+Vector2(0,-140))
 p.health.invulnerable = 0
 p.velocity.y = 480
 await create_timer(0.4).timeout
 assert(enemy.hp==72 and p.health.hp<100,"Burr hog spikes cannot be stomped")
 # The level fields every monster kind.
 var kinds := {}
 for e in room.enemies: kinds[e.get_script().resource_path.get_file()+str(e.get("variant"))] = true
 assert(kinds.size()>=7,"Level uses every monster kind: %s"%str(kinds.keys()))
 # The leaf curtain fades while the pig is inside the nook.
 p.reset_at(Vector2(6480,430))
 await create_timer(0.5).timeout
 assert(room.nook_reveal>0.5 and room.secrets.has("nook"))
 await tap(KEY_F3)
 assert(room.debug_label.visible and room.debug_label.text.contains("Enemy HP"))
 await capture("debug")
 # Pause freezes the pig, enemies and moving platforms.
 await tap(KEY_ESCAPE)
 var at: Vector2 = p.position
 var ferry_at: Vector2 = room.movers[0].position
 await create_timer(0.3).timeout
 assert(p.position==at and room.movers[0].position==ferry_at)
 await tap(KEY_ESCAPE)
 await create_timer(0.3).timeout
 assert(room.movers[0].clock>0)
 assert(root.get_node("GameState").to_dictionary()==before)
 print("ACTION_LEVEL_OK")
 quit()
