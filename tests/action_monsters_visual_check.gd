extends SceneTree
## Rendered look of the monsters in 怪物试炼场 (run WITHOUT --headless, e.g. with --always-on-top).
## Poses each monster in its telegraph / attack / recovery states and saves zoomed screenshots to
## /private/tmp/pig-monsters-*.png. Static frames only: judge motion by playing the room.
var room: Node2D
var p: CharacterBody2D
var zoom := 1.0
var center := Vector2.ZERO


func _initialize() -> void:
	call_deferred("run")


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func wait_until(condition: Callable, limit: int) -> void:
	var n := 0
	while not condition.call() and n < limit:
		await physics_frame
		n += 1


func only(kind: String, at: Vector2, options := {}) -> CharacterBody2D:
	for enemy in room.enemies:
		enemy.queue_free()
	room.enemies.clear()
	return room.spawn_enemy(kind, at, options)


func frame_view() -> void:
	# Runs after the physics step, so it wins over the room's own camera fit for this frame.
	var size := root.get_visible_rect().size
	var fit := minf(size.x / 1536.0, size.y / 864.0)
	room.camera.zoom = Vector2.ONE * fit * zoom
	room.camera.position = center
	room.camera.offset = Vector2.ZERO
	# Physics interpolation would otherwise render the camera where the last physics tick left it.
	room.camera.reset_physics_interpolation()
	room.backdrop.follow(center)
	room.midground.follow(center)
	room.backdrop.reset_physics_interpolation()
	room.midground.reset_physics_interpolation()


func shot(name: String, at: Vector2, amount: float) -> void:
	center = at
	zoom = amount
	var drawn := {"done": false}
	RenderingServer.frame_post_draw.connect(func(): drawn.done = true, CONNECT_ONE_SHOT)
	var n := 0
	while not drawn.done and n < 30:
		await process_frame
		n += 1
	if not drawn.done:
		print("  %s skipped: window not drawing" % name)
		return
	root.get_texture().get_image().save_png("/private/tmp/pig-monsters-%s.png" % name)
	print("  saved %s" % name)


func run() -> void:
	await process_frame
	change_scene_to_file("res://scenes/action_test/bestiary_room.tscn")
	while current_scene == null or not current_scene.has_method("reset_monsters"):
		await process_frame
	await frames(5)
	room = current_scene
	p = room.player
	room.camera.target = null
	process_frame.connect(func(): if room: frame_view())
	room.hud.get_parent().visible = false
	# Line-up: every kind at rest, the pig far away.
	p.reset_at(Vector2(2600, 900))
	only("slime", Vector2(3980, 900))
	room.spawn_enemy("big_slime", Vector2(4150, 900))
	room.spawn_enemy("burr_hog", Vector2(4330, 900), {"patrol_width": 10.0})
	room.spawn_enemy("puffcap", Vector2(4500, 900))
	room.spawn_enemy("acorn_spider", Vector2(4480, 528))
	room.spawn_enemy("moth", Vector2(4640, 720))
	room.spawn_enemy("moss_snail", Vector2(4790, 900), {"patrol_width": 10.0})
	await frames(40)
	await shot("lineup", Vector2(4390, 790), 1.55)
	# Slime: crouch, then mid-hop.
	var slime := only("slime", Vector2(3860, 900))
	p.reset_at(Vector2(3640, 900))
	p.facing = 1
	await wait_until(func(): return slime.state == "CROUCH" and slime.state_time > 0.2, 120)
	await shot("slime_crouch", Vector2(3760, 850), 3.0)
	await wait_until(func(): return slime.state == "AIR" and slime.velocity.y > -150, 60)
	await shot("slime_hop", Vector2(3760, 830), 3.0)
	# Burr hog: warning, rolling ball, dizzy.
	var burr := only("burr_hog", Vector2(2300, 900), {"patrol_width": 120.0})
	p.reset_at(Vector2(2060, 900))
	p.health.invulnerable = 60
	await wait_until(func(): return burr.state == "NOTICE" and burr.state_time > 0.3, 90)
	await shot("burr_notice", Vector2(2200, 850), 3.0)
	await wait_until(func(): return burr.state == "ROLL" and burr.state_time > 0.1, 60)
	await shot("burr_roll", burr.position + Vector2(-20, -40), 3.0)
	await wait_until(func(): return burr.state == "DIZZY" and burr.state_time > 0.3, 200)
	await shot("burr_dizzy", burr.position + Vector2(0, -50), 3.0)
	# Puffcap: swelling, spores in the air.
	var puff := only("puffcap", Vector2(3000, 900))
	p.reset_at(Vector2(2800, 900))
	p.health.invulnerable = 0
	await wait_until(func(): return puff.state == "SWELL" and puff.state_time > 0.45, 90)
	await shot("puff_swell", Vector2(2920, 840), 3.0)
	await wait_until(func(): return puff.spores.size() == 3 and puff.spores[0].age > 0.45, 90)
	await shot("puff_spores", Vector2(2890, 800), 2.2)
	# Moth: wings spread before the swoop, then diving.
	var moth := only("moth", Vector2(3750, 690))
	p.reset_at(Vector2(3640, 900))
	await wait_until(func(): return moth.state == "LOCK" and moth.state_time > 0.3, 150)
	await shot("moth_lock", moth.position + Vector2(-40, 70), 2.6)
	await wait_until(func(): return moth.state == "SWOOP" and moth.state_time > swoop_mid(moth), 60)
	await shot("moth_swoop", moth.position + Vector2(0, -30), 2.6)
	# Acorn spider dangling in the way.
	var spider := only("acorn_spider", Vector2(4480, 528))
	p.reset_at(Vector2(4400, 900))
	p.facing = 1
	await wait_until(func(): return spider.state == "DANGLE" and spider.state_time > 0.3, 120)
	await shot("spider_dangle", Vector2(4450, 760), 2.4)
	# Snail: a blade glances off the shell; the hammer breaks it.
	var snail := only("moss_snail", Vector2(5250, 900))
	p.combat.weapon = room.WEAPONS[0]
	p.reset_at(Vector2(5160, 900))
	p.facing = 1
	await frames(2)
	_key(KEY_J, true)
	await wait_until(func(): return snail.tucked > 0, 30)
	_key(KEY_J, false)
	await frames(2)
	await shot("snail_clang", Vector2(5220, 860), 3.0)
	snail = only("moss_snail", Vector2(5250, 900))
	p.combat.weapon = room.WEAPONS[2]
	p.reset_at(Vector2(5140, 900))
	p.facing = 1
	await frames(2)
	_key(KEY_J, true)
	await wait_until(func(): return not snail.shell, 40)
	_key(KEY_J, false)
	await frames(40)
	await shot("snail_broken", snail.position + Vector2(0, -40), 3.0)
	# Purify: the curse leaves a defeated slime.
	slime = only("slime", Vector2(3860, 900))
	p.reset_at(Vector2(3600, 900))
	await frames(2)
	slime.take_hit(100, 0)
	await wait_until(func(): return slime.death_time > 0.45, 60)
	await shot("purify_wisp", Vector2(3860, 840), 3.0)
	await wait_until(func(): return slime.death_time > 0.95, 60)
	await shot("purify_sparks", Vector2(3860, 830), 3.0)
	print("MONSTERS_VISUAL_DONE")
	quit()


func swoop_mid(moth: Node) -> float:
	return moth.swoop_time * 0.4


func _key(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()
