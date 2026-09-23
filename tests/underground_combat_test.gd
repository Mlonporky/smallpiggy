extends SceneTree
var before: Dictionary

func _initialize() -> void:
 call_deferred("run")

func key(code: int, pressed: bool) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = pressed
 Input.parse_input_event(event)

func tap(code: int) -> void:
 key(code,true)
 await create_timer(0.05).timeout
 key(code,false)
 await create_timer(0.05).timeout

func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/underground-combat-"+name+".png")

func fresh():
 change_scene_to_file("res://scenes/chapter2/underground/landing.tscn")
 await create_timer(1.5).timeout
 return current_scene

func run() -> void:
 await process_frame
 before = root.get_node("GameState").to_dictionary()
 var scene = await fresh()
 var combat = scene.combat
 var pig = scene.pig
 assert(pig.landed_once and pig.weapon==0)
 await tap(KEY_1)
 assert(pig.weapon==0,"Cannot equip a weapon before collecting it")
 # Actual horizontal input reaches the nearby rack.
 key(KEY_D,true)
 await create_timer(0.36).timeout
 key(KEY_D,false)
 await create_timer(0.2).timeout
 assert(combat.near_rack())
 for kind in range(1,4):
  await tap(KEY_E)
  assert(combat.menu.visible and pig.paused)
  if kind==1: await capture("rack")
  var time: float = scene.elapsed
  await create_timer(0.2).timeout
  assert(scene.elapsed==time,"Choosing equipment pauses all simulation")
  await tap(KEY_0+kind)
  assert(not combat.menu.visible and pig.weapon==kind and kind in combat.owned)
 await tap(KEY_1)
 assert(pig.weapon==1 and combat.owned.size()==3)
 # Local combat fixtures use actual attack keys and normal enemy AI.
 # Every weapon must independently damage and kill a living enemy.
 for kind in range(1,4):
  await tap(KEY_0+kind)
  pig.position = Vector2(365,730)
  pig.velocity = Vector2.ZERO
  pig.facing = 1
  var enemy = combat.enemies[kind-1]
  enemy.position = Vector2(462,730)
  enemy.velocity = Vector2.ZERO
  enemy.reset_physics_interpolation()
  pig.reset_physics_interpolation()
  var initial: int = enemy.hp
  key(KEY_J,true)
  await create_timer(0.13).timeout
  await capture("weapon-"+str(kind))
  var deadline := Time.get_ticks_msec()+5000
  while enemy.hp>0 and pig.hp>0 and Time.get_ticks_msec()<deadline: await process_frame
  key(KEY_J,false)
  assert(enemy.hp==0 and combat.hits[kind]>0,"Weapon %d must defeat a slime; hp %d from %d" % [kind,enemy.hp,initial])
  await create_timer(0.65).timeout
  assert(enemy.modulate.a==0,"Defeated slime must dissolve")
 assert(combat.kills==3 and pig.hp>0)
 await capture("clear")
 assert(combat.result.text.contains("已清理"))
 # Input is blocked and projectiles/enemy clocks freeze during pause.
 await tap(KEY_2)
 key(KEY_J,true)
 await create_timer(0.05).timeout
 key(KEY_J,false)
 await tap(KEY_ESCAPE)
 var count: int = combat.attacks[2]
 var time: float = scene.elapsed
 var pos: Vector2 = pig.position
 var shot_pos: Vector2 = combat.shots[0].pos if not combat.shots.is_empty() else Vector2.ZERO
 key(KEY_J,true)
 key(KEY_D,true)
 await create_timer(0.3).timeout
 assert(scene.elapsed==time and pig.position==pos and combat.attacks[2]==count)
 if not combat.shots.is_empty(): assert(combat.shots[0].pos==shot_pos)
 key(KEY_J,false)
 key(KEY_D,false)
 await tap(KEY_ESCAPE)
 # A new run resets health, pickups, kills, shots and menu state.
 await tap(KEY_R)
 scene = current_scene
 combat = scene.combat
 pig = scene.pig
 assert(pig.hp==100 and pig.weapon==0 and combat.owned.is_empty() and combat.kills==0)
 await create_timer(1.4).timeout
 # Acquire bow and gun, then fire from ground into the raised stone block.
 for kind in [1,2]:
  await tap(KEY_E)
  await tap(KEY_0+kind)
 pig.position = Vector2(520,730)
 pig.facing = 1
 pig.reset_physics_interpolation()
 for enemy in combat.enemies:
  enemy.position = Vector2(1000+combat.enemies.find(enemy)*130,730)
  enemy.velocity = Vector2.ZERO
  enemy.reset_physics_interpolation()
 for kind in [1,2]:
  await tap(KEY_0+kind)
  key(KEY_J,true)
  await create_timer(1.1).timeout
  key(KEY_J,false)
  assert(combat.hits[kind]==0,"Projectiles must stop at stone instead of passing through")
 # Test telegraph, jumping over a real hop, damage protection and defeat.
 pig.position = Vector2(300,730)
 pig.velocity = Vector2.ZERO
 pig.reset_physics_interpolation()
 var attacker = combat.enemies[0]
 attacker.position = Vector2(415,730)
 attacker.velocity = Vector2.ZERO
 attacker.state = attacker.State.IDLE
 attacker.clock = 0
 attacker.reset_physics_interpolation()
 var deadline := Time.get_ticks_msec()+3000
 while attacker.state!=attacker.State.WINDUP and Time.get_ticks_msec()<deadline: await process_frame
 assert(attacker.state==attacker.State.WINDUP)
 await capture("windup")
 await create_timer(0.38).timeout
 key(KEY_SPACE,true)
 await create_timer(0.45).timeout
 key(KEY_SPACE,false)
 assert(pig.hp==100,"Jump can avoid a telegraphed hop")
 await create_timer(0.6).timeout
 # Controlled overlap with an active attack checks one hit and i-frames.
 attacker.position = pig.position+Vector2(20,0)
 attacker.velocity = Vector2.ZERO
 attacker.state = attacker.State.HOP
 attacker.clock = 0
 await create_timer(0.05).timeout
 assert(pig.hp==84,"Real enemy contact must reduce health")
 var hurt_hp: int = pig.hp
 pig.take_damage(16,1)
 assert(pig.hp==hurt_hp,"Repeated contact cannot bypass the damage grace period")
 await capture("hurt")
 # Exhaust health through repeated valid attacks, without waiting an entire playthrough.
 for i in 6:
  pig.invulnerable = 0
  pig.take_damage(16,1)
 await create_timer(0.1).timeout
 assert(pig.hp==0 and not pig.enabled)
 assert(combat.result.text.contains("倒下"))
 var attacks_before: Array = combat.attacks.duplicate()
 await tap(KEY_J)
 assert(combat.attacks==attacks_before)
 await capture("defeat")
 await tap(KEY_R)
 assert(current_scene.pig.hp==100 and current_scene.combat.kills==0)
 assert(root.get_node("GameState").to_dictionary()==before)
 print("UNDERGROUND_COMBAT_OK")
 quit()
