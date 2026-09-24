extends SceneTree
## Rule checks for every monster in 怪物试炼场 (bestiary_room.tscn). Each case clears the room,
## spawns one monster and places the pig directly to isolate one behaviour; the key-only level
## playthrough lives in action_route_test.gd.
var room: Node2D
var p: CharacterBody2D
var failed := false


func _initialize() -> void:
	call_deferred("run")


func key(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func check(condition: bool, message: String) -> void:
	if condition or failed:
		return
	failed = true
	push_error("MONSTER CHECK FAILED: " + message)
	quit(1)


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func wait_until(condition: Callable, limit: int) -> bool:
	var n := 0
	while not condition.call() and n < limit:
		await physics_frame
		n += 1
	return condition.call()


func only(kind: String, at: Vector2, options := {}) -> CharacterBody2D:
	for enemy in room.enemies:
		enemy.queue_free()
	room.enemies.clear()
	return room.spawn_enemy(kind, at, options)


func place(at: Vector2, facing := 1.0, shield := 99.0) -> void:
	p.reset_at(at)
	p.facing = facing
	p.previous_feet = at
	p.health.hp = 100
	p.health.invulnerable = shield


func swing() -> void:
	key(KEY_J, true)
	await frames(2)
	key(KEY_J, false)
	await frames(24)


func run() -> void:
	await process_frame
	var before: Dictionary = root.get_node("GameState").to_dictionary()
	change_scene_to_file("res://scenes/action_test/bestiary_room.tscn")
	while current_scene == null or not current_scene.has_method("reset_monsters"):
		await process_frame
	await frames(5)
	room = current_scene
	p = room.player
	check(room.enemies.size() == 7, "bestiary spawns one of each of the 7 kinds")
	await slime_cases()
	await burr_cases()
	await puffcap_cases()
	await moth_cases()
	await spider_cases()
	await snail_cases()
	check(root.get_node("GameState").to_dictionary() == before, "GameState untouched")
	if not failed:
		print("ACTION_MONSTERS_OK")
		quit()


func slime_cases() -> void:
	# Crouches (telegraph) before every hop and hops toward the pig.
	var slime := only("slime", Vector2(800, 900))
	place(Vector2(560, 900))
	check(await wait_until(func(): return slime.state == "CROUCH", 120), "slime crouches before hopping")
	var start: float = slime.position.x
	check(await wait_until(func(): return slime.state == "AIR", 40), "slime hops after its crouch")
	check(slime.velocity.x < 0 and slime.velocity.y < 0, "slime hops toward the pig")
	check(await wait_until(func(): return slime.state == "REST", 90), "slime lands and rests")
	check(slime.position.x < start - 40, "hop covers ground toward the pig")
	# The big slime splits into two little ones when defeated.
	var big := only("big_slime", Vector2(1500, 900))
	place(Vector2(1100, 900))
	await frames(2)
	check(big.max_hp == 80 and big.size.x > 80, "big slime is bigger and tougher")
	big.take_hit(200, 0)
	await frames(3)
	var smalls: Array = room.enemies.filter(func(e): return e.get("variant") == "small" and e.hp > 0)
	check(smalls.size() == 2, "big slime splits into two small slimes")
	if smalls.size() == 2:
		check(smalls[0].position.x != smalls[1].position.x and smalls[0].max_hp == 18, "the halves pop out to either side")
	check(big.death_time > 0 and big.collision_layer == 0, "defeated slime stops colliding and purifies")


func burr_cases() -> void:
	var burr := only("burr_hog", Vector2(2300, 900), {"patrol_width": 120.0})
	place(Vector2(2050, 900), 1.0, 0.0)
	check(await wait_until(func(): return burr.state == "NOTICE", 60), "burr hog notices the pig level with it")
	check(not burr.stompable, "its spikes are up while it notices")
	check(await wait_until(func(): return burr.state == "ROLL", 40), "burr hog curls and rolls after the warning")
	await frames(1)
	check(burr.velocity.x < -400, "rolls fast toward the pig")
	# Rolling through it with Shift avoids the spikes.
	check(await wait_until(func(): return burr.position.x - p.position.x < 100, 60), "ball reaches the pig")
	key(KEY_SHIFT, true)
	await frames(2)
	key(KEY_SHIFT, false)
	await frames(20)
	check(p.health.hp == 100, "a dodge roll passes through the rolling ball")
	check(await wait_until(func(): return burr.state == "DIZZY", 120), "ball stops at the end and sits dizzy")
	check(burr.stompable, "dizzy burr hog can be stomped")
	var hp_before: int = burr.hp
	place(burr.position + Vector2(0, -120))
	p.velocity.y = 500
	check(await wait_until(func(): return burr.hp < hp_before, 40), "stomp lands on the dizzy burr hog")
	check(hp_before - burr.hp == 48 and p.velocity.y < 0, "dizzy stomp deals bonus damage and bounces the pig")
	# Spikes up: a stomp outside the dizzy window hurts the pig instead.
	burr = only("burr_hog", Vector2(2300, 900), {"patrol_width": 120.0})
	await frames(2)
	place(burr.position + Vector2(0, -120), 1.0, 0.0)
	p.velocity.y = 500
	check(await wait_until(func(): return p.health.hp < 100, 40), "spiky back hurts a stomping pig")
	check(burr.hp == burr.max_hp and p.velocity.y < 0, "spikes throw the pig back up without hurting the burr")
	# A hit on the rolling ball knocks it dizzy.
	burr = only("burr_hog", Vector2(2300, 900), {"patrol_width": 120.0})
	place(Vector2(2060, 900))
	check(await wait_until(func(): return burr.state == "ROLL", 90), "second burr rolls")
	burr.take_hit(28, 180)
	check(burr.state == "DIZZY" and burr.hp == 44, "hitting the ball stops it dizzy")


func puffcap_cases() -> void:
	var puff := only("puffcap", Vector2(3000, 900))
	place(Vector2(2780, 900), 1.0, 0.0)
	check(await wait_until(func(): return puff.state == "SWELL", 70), "puffcap swells before puffing")
	check(await wait_until(func(): return puff.spores.size() == 3, 50), "puffcap puffs three spores")
	check(await wait_until(func(): return p.health.hp < 100, 120), "a spore lobbed at a standing pig lands")
	check(p.health.hp == 88, "spores sting for 12")
	# A live weapon swing pops a spore in the air.
	await frames(10)
	p.combat.weapon = room.WEAPONS[0]
	place(Vector2(2780, 900))
	key(KEY_J, true)
	check(await wait_until(func(): return p.combat.state == "ACTIVE", 20), "swing goes live")
	key(KEY_J, false)
	var box: Rect2 = puff.swing_rect()
	puff.spores.clear()
	puff.spores.append({"pos": box.get_center(), "vel": Vector2(-60, 0), "age": 0.0, "spin": 0.0})
	await frames(1)
	check(puff.spores.is_empty(), "weapon swing pops the spore")
	await frames(20)
	# Stomping springs the pig up like a bounce mushroom.
	puff = only("puffcap", Vector2(3000, 900))
	await frames(2)
	place(puff.position + Vector2(0, -150))
	p.velocity.y = 500
	check(await wait_until(func(): return puff.hp < puff.max_hp, 40), "stomp lands on the puffcap")
	check(puff.hp == 8 and p.launched and p.velocity.y < -800, "puffcap stomp launches the pig high")


func moth_cases() -> void:
	var moth := only("moth", Vector2(3750, 690))
	place(Vector2(3700, 900), 1.0, 0.0)
	check(await wait_until(func(): return moth.state == "LOCK", 120), "moth locks on with its wings spread")
	check(await wait_until(func(): return moth.state == "SWOOP", 50), "moth swoops after the telegraph")
	var lowest := 0.0
	while moth.state == "SWOOP":
		lowest = maxf(lowest, moth.position.y)
		await physics_frame
	check(absf(lowest - 860) < 8, "swoop bottoms out at the pig's middle, not the floor (%.1f)" % lowest)
	check(p.health.hp == 84, "the swoop hits a pig that stands still")
	check(moth.state == "RECOVER" and moth.position.y < 760, "moth climbs back out")
	# Stompable in mid-air.
	moth = only("moth", Vector2(3750, 690))
	await frames(2)
	place(moth.position + Vector2(0, -100))
	p.velocity.y = 500
	check(await wait_until(func(): return moth.hp < moth.max_hp, 40), "stomp reaches the hovering moth")
	check(moth.hp == 4 and p.velocity.y < 0, "moth stomp bounces the pig")


func spider_cases() -> void:
	var spider := only("acorn_spider", Vector2(4480, 528))
	place(Vector2(4720, 900), 1.0, 0.0)
	await frames(30)
	check(spider.state == "HANG" and absf(spider.position.y - 572) < 4, "spider waits under its ledge")
	p.reset_at(Vector2(4500, 900))
	check(await wait_until(func(): return spider.state == "TREMBLE", 10), "spider trembles when the pig passes below")
	check(await wait_until(func(): return spider.state == "DANGLE", 60), "spider drops")
	check(absf(spider.position.y - 846) < 4, "spider dangles at head height")
	check(await wait_until(func(): return p.health.hp < 100, 10), "dangling spider blocks the way")
	check(await wait_until(func(): return spider.state == "HANG", 300), "spider climbs back up")
	check(absf(spider.position.y - 572) < 4, "spider back under its ledge")


func snail_cases() -> void:
	var snail := only("moss_snail", Vector2(5250, 900))
	p.combat.weapon = room.WEAPONS[0]
	place(Vector2(5160, 900), 1.0)
	await frames(2)
	await swing()
	check(snail.hp == 60 and snail.shell, "the sword glances off the shell's front")
	check(p.velocity.x < 0 or p.position.x < 5150, "the clang pushes the pig back")
	snail.tucked = 0
	place(Vector2(snail.position.x + 80, 900), -1.0)
	await frames(2)
	await swing()
	check(snail.hp == 32, "a blow to the soft back does full damage")
	# The hammer cracks the shell off.
	snail = only("moss_snail", Vector2(5250, 900))
	p.combat.weapon = room.WEAPONS[2]
	place(Vector2(5140, 900), 1.0)
	await frames(2)
	key(KEY_J, true)
	await frames(2)
	key(KEY_J, false)
	await frames(40)
	check(not snail.shell and snail.hp == 8, "hammer breaks the shell and hurts")
	# Stomping the shell only bounces.
	snail = only("moss_snail", Vector2(5250, 900))
	await frames(2)
	place(snail.position + Vector2(0, -120))
	p.velocity.y = 500
	check(await wait_until(func(): return p.velocity.y < 0, 40), "pig bounces off the shell")
	check(snail.hp == 60 and snail.tucked > 0, "shell stomp does no damage and the snail tucks in")
