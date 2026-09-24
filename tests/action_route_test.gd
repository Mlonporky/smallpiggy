extends SceneTree
## Plays the redesigned test level with key presses only (no teleporting, no HP edits).
## Inputs are injected on physics frames and flushed immediately, so every run is repeatable.
## Route A (canopy): sword → thorn gap → mushroom cliff → campfire → ferry → roll past the spiked
## patrol → crumbling slabs → elevator → canopy → leaf-curtain nook (hammer) → exit.
## Route B (after R): campfire → drop into the cavern → dagger → golden mushroom → ground path → exit.
## Monsters are met the way a player would: hop over the snail to hit its soft back, swing at a
## swooping moth, wait for the acorn spider to drop, and roll through a charging burr hog (a reflex
## in step(), like a player reacting to the rolling ball).
var room: Node2D
var p: CharacterBody2D
var frame_times: Array[float] = []
var failed := false


func _initialize() -> void:
	call_deferred("run")


var held: Dictionary = {}


func press(code: int, down: bool) -> void:
	if down:
		held[code] = true
	else:
		held.erase(code)
	_send(code, down)


func _send(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func steer(direction: int) -> void:
	press(KEY_D, direction > 0)
	press(KEY_A, direction < 0)


var reflex_release := 0


func step(count := 1) -> void:
	for i in count:
		await physics_frame
		# A window focus change releases every pressed key; keep held keys held, like a finger would.
		for code in held:
			if not Input.is_physical_key_pressed(code):
				_send(code, true)
		_dodge_reflex()


## Rolls through a burr hog ball that is about to hit, the way a player reacts to it.
func _dodge_reflex() -> void:
	if reflex_release > 0:
		reflex_release -= 1
		if reflex_release == 0:
			_send(KEY_SHIFT, false)
		return
	if p == null or not p.alive() or not p.is_on_floor() or p.roll_time > 0 or p.roll_cooldown > 0:
		return
	for enemy in room.enemies:
		if enemy.hp > 0 and enemy.state == "ROLL" and absf(enemy.position.y - p.position.y) < 40:
			var gap: float = p.position.x - enemy.position.x
			if signf(gap) == enemy.facing and absf(gap) < 120:
				_send(KEY_SHIFT, true)
				reflex_release = 2
				return


func check(condition: bool, message: String) -> void:
	if condition or failed:
		return
	failed = true
	push_error("ROUTE FAILED: %s (pig at %s, hp %d, velocity %s, right %s, control %s, paused %s/%s, hit_stop %.2f, dying %.2f)" % [message, p.position, p.health.hp, p.velocity, Input.is_action_pressed("move_right"), p.control_enabled, p.paused, room.paused, room.hit_stop, room.death_timer])
	quit(1)


func tap(code: int) -> void:
	press(code, true)
	await step(2)
	press(code, false)
	await step(2)


func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	# macOS stops drawing a covered window; skip the screenshot instead of waiting forever.
	var drawn := {"done": false}
	RenderingServer.frame_post_draw.connect(func(): drawn.done = true, CONNECT_ONE_SHOT)
	var frames := 0
	while not drawn.done and frames < 30:
		await process_frame
		frames += 1
	if drawn.done:
		root.get_texture().get_image().save_png("/private/tmp/pig-route-%s.png" % name)
	else:
		print("  capture %s skipped: window not drawing" % name)


func settle() -> void:
	steer(0)
	var frames := 0
	while (not p.is_on_floor() or absf(p.velocity.x) > 5) and frames < 180:
		await step()
		frames += 1


## Walks to x on the current floor; releases early enough to stop close to the target.
func walk_to(x: float, tolerance := 10.0) -> void:
	var frames := 0
	while frames < 900 and not failed:
		var gap := x - p.position.x
		var stopping: float = p.velocity.x * p.velocity.x / (2.0 * p.deceleration)
		if absf(gap) <= tolerance + (stopping if signf(p.velocity.x) == signf(gap) else 0.0):
			break
		steer(1 if gap > 0 else -1)
		await step()
		frames += 1
	await settle()
	check(absf(p.position.x - x) < tolerance + 30, "walk_to %.0f" % x)


## Runs toward `direction`, jumps when crossing `at_x`, holds jump for `hold` frames, steers until landing.
func run_jump(at_x: float, direction: int, hold: int, air_limit := 150) -> void:
	var frames := 0
	steer(direction)
	while (p.position.x - at_x) * direction < 0 and frames < 600:
		await step()
		frames += 1
	press(KEY_SPACE, true)
	await step(hold)
	press(KEY_SPACE, false)
	await step(3)
	frames = 0
	while not p.is_on_floor() and frames < air_limit:
		await step()
		frames += 1
	steer(0)
	await step(2)


## Jumps now and steers in the air toward `target` (x centre of the landing spot), like a player would.
func jump_to(target_x: float, hold: int, air_limit := 150) -> void:
	press(KEY_SPACE, true)
	var frames := 0
	while frames < air_limit and not failed:
		if frames == hold:
			press(KEY_SPACE, false)
		var gap := target_x - p.position.x
		steer(0 if absf(gap) < 10 else (1 if gap > 0 else -1))
		await step()
		frames += 1
		if frames > 3 and p.is_on_floor():
			break
	press(KEY_SPACE, false)
	steer(0)
	await step(2)


func stage(name: String) -> void:
	if OS.get_environment("ROUTE_DEBUG") != "":
		print("  [%s] pig %s hp %d  t=%.1fs" % [name, p.position.round(), p.health.hp, Time.get_ticks_msec() / 1000.0])


## Fights like a careful player: keeps between contact range (51 px) and weapon reach, backs off
## when too close, turns to face the enemy before each swing.
func fight(enemy: Node2D, reach := 80.0, stay := Vector2(-INF, INF)) -> void:
	if enemy == null:
		return
	var frames := 0
	var cooldown := 0
	var release_at := -1
	while is_instance_valid(enemy) and enemy.hp > 0 and frames < 900 and not failed and p.alive():
		var gap: float = enemy.position.x - p.position.x
		var toward := 1 if gap > 0 else -1
		var ahead: float = p.position.x + toward * 40
		if absf(gap) > reach:
			steer(toward if ahead > stay.x and ahead < stay.y else 0)
		elif absf(gap) < 60 and p.position.x - toward * 40 > stay.x and p.position.x - toward * 40 < stay.y:
			steer(-toward)
		elif p.facing != toward:
			steer(toward)
		else:
			steer(0)
			if cooldown <= 0:
				press(KEY_J, true)
				release_at = frames + 2
				cooldown = 16
		if frames == release_at:
			press(KEY_J, false)
		cooldown -= 1
		await step()
		frames += 1
	press(KEY_J, false)
	steer(0)
	check(not is_instance_valid(enemy) or enemy.hp <= 0, "enemy not defeated")
	await step(20)


## Nearest living ground monster to x (moths and spiders are handled on their own).
func enemy_near(x: float, radius := 320.0) -> Node2D:
	var best: Node2D = null
	for enemy in room.enemies:
		if enemy.hp > 0 and not enemy.flying and absf(enemy.position.x - x) < radius and (best == null or absf(enemy.position.x - x) < absf(best.position.x - x)):
			best = enemy
	return best


func monster(kind: String, near_x: float) -> Node2D:
	var best: Node2D = null
	for enemy in room.enemies:
		if enemy.hp > 0 and enemy.get_script().resource_path.get_file() == kind + ".gd" and (best == null or absf(enemy.home.x - near_x) < absf(best.home.x - near_x)):
			best = enemy
	return best


## Fights every ground monster around x (a big slime's halves included).
func clear_near(x: float, radius: float, reach: float, stay: Vector2) -> void:
	var rounds := 0
	while enemy_near(x, radius) != null and rounds < 6 and not failed:
		await fight(enemy_near(x, radius), reach, stay)
		rounds += 1


## The snail's shell front turns blades: hop over it and strike its soft back; hop again if it
## turns round. With the hammer, just break the shell.
func fight_snail(enemy: Node2D, stay: Vector2) -> void:
	if enemy == null:
		return
	if p.combat.weapon.kind == "hammer":
		await fight(enemy, 110, stay)
		return
	var frames := 0
	var cooldown := 0
	var release_at := -1
	var reach: float = p.combat.weapon.reach + 12
	while is_instance_valid(enemy) and enemy.hp > 0 and frames < 1500 and not failed and p.alive():
		var gap: float = enemy.position.x - p.position.x
		var toward := 1 if gap > 0 else -1
		if signf(-gap) == enemy.facing:
			# In front of the shell: run in and jump over, landing behind it.
			var behind := clampf(enemy.position.x + toward * 95, stay.x + 20, stay.y - 20)
			if absf(gap) > 130:
				steer(toward)
				await step()
				frames += 1
				continue
			await jump_to(behind, 22)
			frames += 40
			continue
		if absf(gap) > reach:
			steer(toward)
		elif absf(gap) < 62:
			steer(-toward)
		elif p.facing != toward:
			steer(toward)
		else:
			steer(0)
			if cooldown <= 0:
				press(KEY_J, true)
				release_at = frames + 2
				cooldown = 14
		if frames == release_at:
			press(KEY_J, false)
		cooldown -= 1
		await step()
		frames += 1
	press(KEY_J, false)
	steer(0)
	check(not is_instance_valid(enemy) or enemy.hp <= 0, "snail not defeated")
	await step(20)


## Stands and faces the moth; swings as it swoops through.
func fight_moth(enemy: Node2D, stay: Vector2) -> void:
	if enemy == null:
		return
	var frames := 0
	var cooldown := 0
	var release_at := -1
	var reach: float = p.combat.weapon.reach + 40
	while is_instance_valid(enemy) and enemy.hp > 0 and frames < 2400 and not failed and p.alive():
		var gap: Vector2 = enemy.position - (p.position + Vector2(0, -40))
		var toward := 1 if gap.x > 0 else -1
		if p.position.x < stay.x:
			steer(1)
		elif p.position.x > stay.y:
			steer(-1)
		elif p.facing != toward and absf(gap.x) > 8:
			steer(toward)
		else:
			steer(0)
		if enemy.state == "SWOOP" and absf(gap.x) < reach and gap.y < 70 and gap.y > -90 and cooldown <= 0 and p.facing == toward:
			press(KEY_J, true)
			release_at = frames + 2
			cooldown = 16
		if frames == release_at:
			press(KEY_J, false)
		cooldown -= 1
		await step()
		frames += 1
	press(KEY_J, false)
	steer(0)
	check(not is_instance_valid(enemy) or enemy.hp <= 0, "moth not defeated")
	await step(10)


func wait_until(condition: Callable, limit: int, message: String) -> void:
	var frames := 0
	while not condition.call() and frames < limit:
		await step()
		frames += 1
	check(condition.call(), message)


func run() -> void:
	await process_frame
	var before: Dictionary = root.get_node("GameState").to_dictionary()
	change_scene_to_file("res://scenes/action_test/test_level.tscn")
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
		beat.timeout.connect(func(): print("  heartbeat physics=%d pig=%s" % [Engine.get_physics_frames(), p.position.round()]))
		root.add_child(beat)
	await settle()
	# 入口: sword, the small step, the first thorn gap and the first slime.
	await walk_to(410)
	await tap(KEY_E)
	check(p.combat.weapon != null and p.combat.weapon.kind == "sword", "sword pickup")
	await run_jump(430, 1, 30)
	await run_jump(735, 1, 40)
	check(p.is_on_floor() and p.position.x > 960 and absf(p.position.y - 1000) < 2, "thorn gap cleared")
	check(p.health.hp == 100, "landing zone after the gap is safe")
	await capture("gap")
	await fight(enemy_near(1430))
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
	await run_jump(5470, 1, 30)
	check(absf(p.position.y - 400) < 2, "canopy gap one")
	stage("canopy moth")
	await walk_to(5760)
	await fight_moth(monster("moth", 5955), Vector2(5680, 5840))
	check(absf(p.position.y - 400) < 2, "stayed on the canopy while fighting the moth")
	await run_jump(5860, 1, 26)
	check(absf(p.position.y - 430) < 2, "canopy gap two")
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
	await run_jump(6700, 1, 30)
	await run_jump(6900, 1, 30)
	check(absf(p.position.y - 640) < 2, "final plateau")
	await fight(enemy_near(7160), 110, Vector2(6940, 7590))
	await fight(enemy_near(7340), 110, Vector2(6940, 7590))
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
	await walk_to(2800)
	await tap(KEY_E)
	check(p.combat.weapon.kind == "dagger", "dagger swap")
	check(room.pickups.any(func(i): return not i.consumed and i.kind == "weapon" and i.weapon.kind == "sword"), "old weapon dropped nearby")
	await clear_near(3050, 420, 70.0, Vector2(2610, 3380))
	check(room.kills >= 3, "big slime and both halves defeated")
	await fight_moth(monster("moth", 3200), Vector2(2700, 3300))
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
	await run_jump(6700, 1, 30)
	await run_jump(6900, 1, 30)
	check(absf(p.position.y - 640) < 2, "final plateau via the ground path")
	await fight(enemy_near(7160), 70, Vector2(6940, 7590))
	await fight_snail(enemy_near(7340), Vector2(6940, 7590))
	await walk_to(7470)
	check(room.finished and p.health.hp > 0, "exit via the ground path")
	check(room.firefly_count > route_a_flies, "cavern and ground fireflies add to the count")
	check(root.get_node("GameState").to_dictionary() == before, "GameState untouched")
	if failed:
		return
	frame_times.sort()
	print("ACTION_ROUTES_OK fireflies=%d/%d secrets=%d deaths=%d time=%.1fs p95_ms=%.2f" % [room.firefly_count, room.fireflies.size(), room.secrets.size(), room.deaths, room.elapsed, frame_times[int(frame_times.size() * 0.95)] * 1000])
	quit()
