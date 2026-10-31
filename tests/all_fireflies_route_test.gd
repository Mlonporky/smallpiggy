extends "res://tests/action_route_test.gd"
## Physical input route for every collectible. No positions, rewards or health are injected.
## STORY_FIREFLIES=1 verifies the story adapter; turn back before its automatic exit.
## R is the existing campfire-return control; collected IDs survive that return.
func _process(_delta: float) -> bool:
 if Engine.get_physics_frames() > 30000:
  push_error("ALL_FIREFLIES_TIMEOUT")
  quit(1)
 return false

func run() -> void:
 await process_frame
 var story_mode := OS.get_environment("STORY_FIREFLIES") == "1"
 if story_mode:
  root.get_node("GameState").reset()
  root.get_node("SaveManager").save_path = "/tmp/piggy-story-all-flies-%s.json" % DisplayServer.get_name()
 var before: Dictionary = root.get_node("GameState").to_dictionary()
 change_scene_to_file("res://scenes/finale/story_cave.tscn" if story_mode else "res://scenes/action_test/test_level.tscn")
 while current_scene == null or not current_scene.has_method("seed_room"):
  await process_frame
 # Count physics frames from here on, so platform phases and enemy moves repeat exactly.
 await step(20)
 room = current_scene
 p = room.player
 process_frame.connect(func(): frame_times.append(root.get_process_delta_time()))
 if OS.get_environment("ROUTE_DEBUG") != "":
  var beat := Timer.new()
  beat.wait_time = 5.0
  beat.autostart = true
  beat.timeout.connect(func():
   if not is_instance_valid(p): return
   print("  heartbeat physics=%d pig=%s" % [Engine.get_physics_frames(), p.position.round()]))
  root.add_child(beat)
 await settle()
 # 入口: sword, the small step, the first thorn gap and the first slime.
 await walk_to(410)
 await tap(KEY_E)
 check(p.combat.weapon != null and p.combat.weapon.kind == "sword", "sword pickup")
 await jump_to(540, 8)
 await walk_to(580)
 await walk_to(700)
 await run_jump(745, 1, 7)
 check(p.is_on_floor() and p.position.x > 960 and absf(p.position.y - 1000) < 2, "thorn gap cleared")
 check(p.health.hp == 100, "landing zone after the gap is safe")
 await capture("gap")
 await fight(enemy_near(1430))
 await walk_to(1320)
 await jump_to(1435,30)
 await jump_to(1620,30)
 await walk_to(1600)
 await walk_to(1650)
 await walk_to(1730)
 stage("mushroom")
 # 蘑菇崖: the mushroom launches the pig onto the upper cliff.
 steer(1)
 await wait_until(func(): return p.position.y < 900, 400, "mushroom launch")
 await wait_until(func(): return p.is_on_floor(), 200, "landing after mushroom")
 await walk_to(1970)
 check(absf(p.position.y - 700) < 2, "mushroom reaches the cliff")
 await capture("cliff")
 await walk_to(2030)
 check(room.checkpoint_active and room.checkpoint == room.CAMPFIRES[0], "first campfire")
 await fight(enemy_near(2260), 80.0, Vector2(1900, 2580))
 stage("ferry")
 # 摆渡石板: board at the left end, ride across, step off onto the far ledge.
 await walk_to(2575)
 var ferry: Node2D = room.movers[0]
 await wait_until(func(): return ferry.position.x < 2622 and ferry.progress_at(ferry.clock + 0.35) < 0.01, 800, "ferry at the near end")
 await walk_to(ferry.position.x + 70)
 check(absf(p.position.y - 700) < 2 and p.get_floor_normal().y < -0.9, "standing on the ferry")
 await wait_until(func(): return ferry.position.x > 3268, 500, "ferry reaches the far end")
 await capture("ferry")
 await walk_to(3520)
 check(absf(p.position.y - 700) < 2, "stepped off the ferry")
 stage("patrol")
 # 荆棘回廊: the spiked patrol cannot be stomped; roll through it.
 var patrol: Node2D = enemy_near(3820)
 var hp_before: int = p.health.hp
 steer(1)
 await wait_until(func(): return patrol.position.x - p.position.x < 104, 400, "approach patrol")
 await tap(KEY_SHIFT)
 steer(1)
 await wait_until(func(): return p.position.x > patrol.position.x + 60, 120, "rolled past patrol")
 await step(10)
 check(p.health.hp == hp_before, "roll protects against the spikes")
 stage("thorn bed")
 await walk_to(3890)
 await jump_to(3960,10)
 await walk_to(4075)
 # Crumbling slabs over the thorn bed.
 await jump_to(4205, 16)
 check(absf(p.position.y - 640) < 2, "landed on first slab")
 await jump_to(4375, 14)
 check(absf(p.position.y - 620) < 2, "landed on second slab")
 await jump_to(4580, 18)
 check(p.position.x > 4520 and absf(p.position.y - 700) < 2, "crossed the thorn bed")
 check(room.crumbles.any(func(slab): return slab.state != "SOLID"), "a slab gave way behind the pig")
 stage("snail")
 await fight_snail(enemy_near(4760), Vector2(4530, 4940))
 stage("lift")
 # 升降石台 up to the canopy.
 await walk_to(4975)
 var lift: Node2D = room.movers[1]
 await wait_until(func(): return lift.position.y > 699 and lift.progress_at(lift.clock + 0.4) < 0.01, 800, "lift at the bottom")
 await walk_to(5095)
 await wait_until(func(): return lift.position.y < 431, 400, "lift reaches the canopy")
 check(absf(p.position.y - 430) < 3, "rode the lift")
 await walk_to(5440)
 await run_jump(5470, 1, 6)
 check(absf(p.position.y - 400) < 2, "canopy gap one")
 stage("canopy moth")
 await walk_to(5760)
 await fight_moth(monster("moth", 5955), Vector2(5680, 5840))
 check(absf(p.position.y - 400) < 2, "stayed on the canopy while fighting the moth")
 await run_jump(5860, 1, 5)
 check(absf(p.position.y - 430) < 2, "canopy gap two")
 # Touch the near ledge after landing: a long landing can skim fly 46 by <1 px.
 await walk_to(6035)
 await capture("canopy")
 stage("nook")
 # The leaf curtain hides the hammer.
 await walk_to(6500)
 check(room.secrets.has("nook"), "nook secret found")
 await tap(KEY_E)
 check(p.combat.weapon.kind == "hammer", "hammer pickup")
 await capture("nook")
 stage("exit climb")
 # 出口: drop to the steps and climb to the exit.
 steer(1)
 await wait_until(func(): return p.is_on_floor() and p.position.y > 700, 300, "drop from the canopy")
 steer(0)
 if story_mode:
  await walk_to(6670)
  await jump_to(6820,30)
  await walk_to(6875)
  await jump_to(6980,30)
 else:
  await run_jump(6700,1,30)
  await run_jump(6900,1,30)
 check(absf(p.position.y - 640) < 2, "final plateau")
 await fight(enemy_near(7160), 110, Vector2(6940, 7590))
 await fight(enemy_near(7340), 110, Vector2(6940, 7590))
 await walk_to(7060)
 await step(160)
 if not story_mode:
  await walk_to(7470)
  check(room.finished and room.results.visible, "results shown at the exit")
  await capture("exit")
 var route_a_flies: int = room.firefly_count
 stage("route B")
 # Route B: R returns to the lit campfire; drop into the cavern and climb out with the golden mushroom.
 await tap(KEY_R)
 await step(5)
 check(absf(p.position.x - 2030) < 2, "R respawns at the campfire")
 await walk_to(2500)
 await wait_until(func(): return ferry.position.x > 2900, 900, "ferry away from the edge")
 steer(1)
 await wait_until(func(): return p.is_on_floor() and p.position.y > 1300, 300, "fell into the cavern")
 steer(0)
 check(room.secrets.has("cavern"), "cavern secret")
 await walk_to(2660)
 await walk_to(2800)
 await tap(KEY_E)
 check(p.combat.weapon.kind == "dagger", "dagger swap")
 check(room.pickups.any(func(i): return not i.consumed and i.kind == "weapon" and i.weapon.kind == "sword"), "old weapon dropped nearby")
 await clear_near(3050, 420, 70.0, Vector2(2610, 3380))
 check(room.kills >= 3, "big slime and both halves defeated")
 await fight_moth(monster("moth", 3200), Vector2(2700, 3300))
 await walk_to(3020)
 await jump_to(3020,12)
 await capture("cavern")
 steer(1)
 await wait_until(func(): return p.position.y < 1100, 400, "golden mushroom launch")
 await wait_until(func(): return p.is_on_floor(), 200, "landing after golden mushroom")
 await walk_to(3500)
 check(absf(p.position.y - 700) < 2, "golden mushroom climbs out of the cavern")
 stage("ground path")
 # Ground path: walk past the lift shaft down to the 林下 path and on to the exit.
 var patrol_b: Node2D = enemy_near(3820)
 steer(1)
 await wait_until(func(): return patrol_b.position.x - p.position.x < 104, 400, "approach patrol again")
 await tap(KEY_SHIFT)
 steer(1)
 await wait_until(func(): return p.position.x > patrol_b.position.x + 60, 120, "rolled past patrol again")
 await walk_to(3890)
 await jump_to(3960,10)
 await walk_to(4075)
 await jump_to(4205, 16)
 await jump_to(4375, 14)
 await jump_to(4580, 18)
 check(p.position.x > 4520 and absf(p.position.y - 700) < 2, "crossed the thorn bed again")
 await walk_to(4960)
 await wait_until(func(): return lift.position.y < 600, 600, "lift away")
 steer(1)
 await wait_until(func(): return p.is_on_floor() and p.position.y > 990, 300, "dropped to the ground path")
 steer(0)
 await walk_to(5300)
 check(room.checkpoint == room.CAMPFIRES[1], "second campfire")
 var ground := func(stompable: bool) -> Node2D:
  for enemy in room.enemies:
   if enemy.hp > 0 and enemy.stompable == stompable and enemy.position.x > 5000 and enemy.position.x < 6530 and absf(enemy.position.y - 1000) < 5:
    return enemy
  return null
 stage("spider")
 var spider: Node2D = monster("acorn_spider", 5720)
 await walk_to(spider.anchor.x - 160)
 await fight(spider, 70.0, Vector2(5010, spider.anchor.x - 40))
 await fight(ground.call(true), 70.0, Vector2(5010, 6520))
 var patrol_c: Node2D = ground.call(false)
 check(patrol_c != null, "ground patrol present")
 steer(1)
 await wait_until(func(): return patrol_c.position.x - p.position.x < 104, 600, "approach ground patrol")
 await tap(KEY_SHIFT)
 steer(1)
 await wait_until(func(): return p.position.x > patrol_c.position.x + 60, 120, "rolled past ground patrol")
 await walk_to(6480)
 await run_jump(6500, 1, 30)
 if story_mode:
  await walk_to(6670)
  await jump_to(6820,30)
  await walk_to(6875)
  await jump_to(6980,30)
 else:
  await run_jump(6700,1,30)
  await run_jump(6900,1,30)
 check(absf(p.position.y - 640) < 2, "final plateau via the ground path")
 await fight(enemy_near(7160), 70, Vector2(6940, 7590))
 await fight_snail(enemy_near(7340), Vector2(6940, 7590))
 await walk_to(7060)
 await step(160)
 if not story_mode:
  await walk_to(7470)
  check(room.finished and p.health.hp > 0, "exit via the ground path")
  check(root.get_node("GameState").to_dictionary() == before, "GameState untouched")
 check(room.firefly_count > route_a_flies, "cavern and ground fireflies add to the count")
 if failed: return
 frame_times.sort()
 for i in room.fireflies.size():
  if not room.fireflies[i].taken: print("MISSING ",i," ",room.fireflies[i].pos," nearest=",nearest.get(i))
 check(room.firefly_count == room.fireflies.size(), "all fireflies collected")
 if failed: return
 await capture("all-60")
 print("ALL_FIREFLIES_OK fireflies=%d/%d secrets=%d deaths=%d game_time=%.1fs" % [room.firefly_count, room.fireflies.size(), room.secrets.size(), room.deaths, room.elapsed])
 var proof: Array = []
 for i in room.fireflies.size():
  proof.append({"id":i,"position":[room.fireflies[i].pos.x,room.fireflies[i].pos.y],"taken":room.fireflies[i].taken,"nearest_distance":nearest[i].distance})
 var file := FileAccess.open("/tmp/piggy-fireflies-"+("story" if story_mode else "standalone")+".json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"collected":room.firefly_count,"total":room.fireflies.size(),"deaths":room.deaths,"secrets":room.secrets.size(),"physics_input_only":true,"flies":proof},"  "))
 file.close()
 if story_mode:
  check(room.save_checkpoint(),"all collected rewards save")
  var saved: Dictionary = root.get_node("GameState").flags["story_cave_checkpoint"]
  check(saved.flies.size()==60,"all 60 IDs saved before exit")
  var state = root.get_node("GameState")
  state.reset()
  check(root.get_node("SaveManager").load_game()==room.scene_file_path,"checkpoint reads from disk")
  check(state.flags["story_cave_checkpoint"].flies.size()==60,"all 60 IDs reload from JSON")
  steer(1)
  while is_instance_valid(p) and p.position.x < 7440: await step()
  steer(0)
  while current_scene == room or root.get_node("SceneRouter").is_busy(): await process_frame
  assert(root.get_node("GameState").has_flag("cave_level_completed"))
  assert(current_scene.scene_file_path.ends_with("final_chapter.tscn"))
  print("STORY_ALL_FIREFLIES_EXIT_OK")

 quit()

var nearest: Dictionary = {}
func step(count := 1) -> void:
 for j in count:
  await super.step()
  if not is_instance_valid(room) or not is_instance_valid(p): continue
  for i in room.fireflies.size():
   var distance = p.body_box().get_center().distance_to(room.fireflies[i].pos)
   if distance < nearest.get(i,{"distance":INF}).distance:
    nearest[i] = {"distance":distance,"feet":p.position}
