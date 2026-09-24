extends "res://scenes/action_test/combat_room.gd"
## 苔根小径 · action test level (v2). Standalone: nothing here touches GameState or the save file.
## 入口 (sword, first slime, thorn gap) → 蘑菇崖 (bounce up) → 摆渡石板 over the optional 坑底萤穴
## (dagger, golden mushroom back up) → 荆棘回廊 (burr hog, crumbling slabs) → 升降石台 to the
## 树冠 (leaf-curtain nook with the hammer) or down to the 林下 path → 出口 climb.
## Monsters (scenes/action_test/enemies): each section introduces one idea — hop-and-stomp slime,
## spore-lobbing puffcap, splitting big slime and a swooping moth in the cavern, the charging burr
## hog, the armoured snail, a moth over the canopy gaps, an acorn spider dropping on the ground path.
const Pickup = preload("res://scenes/action_test/components/pickup.gd")
const Sound = preload("res://scenes/action_test/components/sound_fx.gd")
const Mover = preload("res://scenes/action_test/level/moving_platform.gd")
const Crumble = preload("res://scenes/action_test/level/crumble_platform.gd")
const Art = preload("res://scenes/action_test/level/level_art.gd")
const Sword = preload("res://scenes/action_test/weapons/sword.tres")
const Dagger = preload("res://scenes/action_test/weapons/dagger.tres")
const Hammer = preload("res://scenes/action_test/weapons/hammer.tres")
const START := Vector2(160, 1000)
const LEVEL_BOUNDS := Rect2(0, 0, 7600, 1700)
const SOLIDS := [
	Rect2(0, 1000, 760, 700), Rect2(470, 940, 140, 60), Rect2(760, 1130, 200, 570), Rect2(960, 1000, 940, 700),
	Rect2(1900, 700, 700, 1000), Rect2(2600, 1320, 850, 380), Rect2(3450, 700, 650, 1000), Rect2(4100, 790, 420, 910),
	Rect2(4520, 700, 480, 1000), Rect2(5000, 1000, 1530, 700), Rect2(5190, 430, 300, 28), Rect2(5640, 400, 240, 28),
	Rect2(6030, 430, 560, 28), Rect2(6530, 880, 200, 820), Rect2(6730, 760, 200, 940), Rect2(6930, 640, 670, 1060)]
const BRANCHES := [Rect2(1360, 880, 150, 16), Rect2(1540, 770, 150, 16)]
const THORNS := [Rect2(760, 1100, 200, 30), Rect2(4100, 760, 420, 30)]
const MUSHROOMS := [{"at": Vector2(1810, 1000), "big": false}, {"at": Vector2(3392, 1320), "big": true}, {"at": Vector2(7060, 640), "big": false}]
const MOVERS := [
	{"from": Vector2(2620, 700), "to": Vector2(3270, 700), "size": Vector2(160, 24), "travel": 2.6, "hold": 0.9, "one_way": true},
	{"from": Vector2(5020, 700), "to": Vector2(5020, 430), "size": Vector2(150, 24), "travel": 2.4, "hold": 1.0, "one_way": false}]
const CRUMBLES := [Rect2(4150, 640, 110, 22), Rect2(4320, 620, 110, 22)]
const CAMPFIRES := [Vector2(2030, 700), Vector2(5300, 1000)]
const EXIT := Vector2(7470, 640)
const NOOK := Rect2(6400, 250, 190, 190)
const CAVERN := Rect2(2600, 1150, 850, 170)
const SIGNS := [
	{"at": Vector2(250, 1000), "text": "A/D 移动 · 空格跳，按住跳更高"},
	{"at": Vector2(1080, 1000), "text": "树枝可从下方穿过 · S+空格落下"},
	{"at": Vector2(1700, 1000), "text": "踩蘑菇 ↑"},
	{"at": Vector2(2520, 700), "text": "乘石板 → 掉下去也没关系"},
	{"at": Vector2(2160, 700), "text": "孢子可以用武器打散"},
	{"at": Vector2(3530, 700), "text": "栗刺球冲撞 → Shift 翻滚 · 晕了再踩"},
	{"at": Vector2(4040, 700), "text": "碎石板会塌"},
	{"at": Vector2(4600, 700), "text": "蜗牛正面坚硬 · 打背后或用锤"},
	{"at": Vector2(5240, 430), "text": "夜蛾展翅发光 → 要俯冲了"},
	{"at": Vector2(5480, 1000), "text": "小心头顶"},
	{"at": Vector2(4930, 700), "text": "↑ 升降石台 · ↓ 林下小路"}]
## Kinds are listed in combat_room.gd (ENEMY_KINDS); extra keys set script properties.
## Spiders are placed at the ceiling point they hang from; moths at the roost they circle.
const ENEMIES := [
	{"kind": "slime", "at": Vector2(1430, 1000)},
	{"kind": "puffcap", "at": Vector2(2400, 700)},
	{"kind": "big_slime", "at": Vector2(3050, 1320)},
	{"kind": "moth", "at": Vector2(3200, 1150)},
	{"kind": "burr_hog", "at": Vector2(3820, 700), "patrol_width": 170.0},
	{"kind": "moss_snail", "at": Vector2(4760, 700), "patrol_width": 100.0},
	{"kind": "moth", "at": Vector2(5955, 250)},
	{"kind": "acorn_spider", "at": Vector2(5720, 428)},
	{"kind": "slime", "at": Vector2(5980, 1000)},
	{"kind": "burr_hog", "at": Vector2(6250, 1000), "patrol_width": 150.0},
	{"kind": "puffcap", "at": Vector2(7160, 640)},
	{"kind": "moss_snail", "at": Vector2(7340, 640), "patrol_width": 90.0}]
const WEAPON_SPAWNS := [{"at": Vector2(410, 1000), "kind": "sword"}, {"at": Vector2(2800, 1320), "kind": "dagger"}, {"at": Vector2(6500, 430), "kind": "hammer"}]
const HEALS := [{"at": Vector2(1615, 770), "amount": 20}, {"at": Vector2(2700, 1320), "amount": 20}, {"at": Vector2(4600, 700), "amount": 20}, {"at": Vector2(6440, 430), "amount": 40}, {"at": Vector2(6790, 760), "amount": 20}]
var pickups: Array[Node2D] = []
var movers: Array = []
var crumbles: Array = []
var mushrooms: Array[Dictionary] = []
var fireflies: Array[Dictionary] = []
var sparkles: Array[Dictionary] = []
var checkpoint := START
var checkpoint_active := false
var checkpoint_weapon: Resource = null
var lit_campfires: Array[int] = []
var death_timer := 0.0
var notice := "向右探索 · 靠近武器按 E 拾取"
var notice_time := 4.0
var prompt: Label
var status: Label
var results: Label
var results_panel: Panel
var audio_fx: Node
var finished := false
var secrets: Dictionary = {}
var secrets_found := false
var nook_reveal := 0.0
var nearby: Node2D
var kills := 0
var deaths := 0
var firefly_count := 0
var elapsed := 0.0
var finish_time := 0.0
var weapon_icon: Node2D
var props: Node2D
var glow_layer: Node2D
var curtain: Node2D
var e_was_down := false


func room_bounds() -> Rect2:
	return LEVEL_BOUNDS


func room_platforms() -> Array:
	return SOLIDS.duplicate()


func build_platforms() -> void:
	for rect in platforms:
		solid(rect)
	solid(Rect2(bounds.position.x - 60, bounds.position.y - 400, 60, bounds.size.y + 800))
	solid(Rect2(bounds.end.x, bounds.position.y - 400, 60, bounds.size.y + 800))
	for rect in BRANCHES:
		var body := solid(rect)
		body.collision_layer = player_one_way_layer()
		body.get_child(0).one_way_collision = true


func handle_fall() -> void:
	pass # Falling out of the level counts as a knock-out; see _tick_hazards.


func player_one_way_layer() -> int:
	return 16


func build_terrain() -> void:
	for rect in THORNS:
		add_terrain_piece(func(canvas: CanvasItem): Art.thorns(canvas, rect))
	super.build_terrain()
	for rect in BRANCHES:
		add_terrain_piece(func(canvas: CanvasItem): Terrain.paint_branch(canvas, rect))
	for sign_data in SIGNS:
		add_terrain_piece(func(canvas: CanvasItem): Art.sign(canvas, sign_data.at, sign_data.text))


func _ready() -> void:
	super._ready()
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	player.combat.weapon = null
	player.dodge_enabled = true
	player.health.died.connect(_died)
	player.health.healed.connect(_healed)
	audio_fx = Sound.new()
	add_child(audio_fx)
	player.combat.swung.connect(func(): audio_fx.cue("swing"))
	player.movement_fx.connect(func(kind: String, _at: Vector2, _amount: float):
		if kind == "bounce":
			audio_fx.cue("bounce"))
	props = Node2D.new()
	props.name = "Props"
	props.z_index = -1
	world.add_child(props)
	props.draw.connect(_draw_props)
	glow_layer = Node2D.new()
	glow_layer.name = "Fireflies"
	glow_layer.z_index = 5
	world.add_child(glow_layer)
	glow_layer.draw.connect(_draw_fireflies)
	curtain = Node2D.new()
	curtain.name = "LeafCurtain"
	curtain.z_index = 30
	world.add_child(curtain)
	curtain.draw.connect(func(): Art.leaf_curtain(curtain, NOOK, 1.0))
	for data in MOVERS:
		var mover := Mover.new()
		mover.z_index = -1
		world.add_child(mover)
		mover.setup(data.from, data.to, data.size, data.travel, data.hold, data.one_way)
		movers.append(mover)
	for rect in CRUMBLES:
		var slab := Crumble.new()
		slab.z_index = -1
		world.add_child(slab)
		slab.setup(rect)
		crumbles.append(slab)
	for data in MUSHROOMS:
		mushrooms.append({"at": data.at, "big": data.big, "squash": 0.0})
	for at in firefly_positions():
		fireflies.append({"pos": at, "taken": false, "phase": randf() * TAU})
	weapon_icon = Pickup.new()
	weapon_icon.kind = "weapon"
	weapon_icon.position = Vector2(1430, 97)
	weapon_icon.scale = Vector2.ONE * 0.65
	stage.add_child(weapon_icon)
	prompt = label("", Vector2(44, 795), 23)
	status = label("", Vector2(560, 126), 25)
	results_panel = Panel.new()
	results_panel.position = Vector2(478, 282)
	results_panel.size = Vector2(580, 250)
	results_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.08, 0.06, 0.78)
	panel_style.border_color = Color("8fae5c")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(18)
	panel_style.anti_aliasing = true
	results_panel.add_theme_stylebox_override("panel", panel_style)
	results_panel.visible = false
	stage.add_child(results_panel)
	results = label("", Vector2(468, 300), 30)
	results.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results.size = Vector2(600, 0)
	results.visible = false
	seed_room()
	player.reset_at(START)
	snap_view()
	hud.text = hud_text()


static func firefly_positions() -> Array:
	var points: Array = []
	points.append_array(arc(Vector2(500, 900), Vector2(580, 900), 18, 3))
	points.append_array(arc(Vector2(795, 955), Vector2(925, 955), 70, 5))
	points.append_array(arc(Vector2(1070, 960), Vector2(1170, 960), 0, 3))
	points.append_array([Vector2(1435, 830), Vector2(1600, 720), Vector2(1650, 720)])
	points.append_array([Vector2(1815, 910), Vector2(1828, 830), Vector2(1845, 755), Vector2(1872, 690)])
	points.append_array(arc(Vector2(2150, 650), Vector2(2260, 650), 0, 3))
	points.append_array(arc(Vector2(2800, 640), Vector2(3250, 640), 0, 4))
	points.append_array(arc(Vector2(2660, 1265), Vector2(2760, 1265), 12, 3))
	points.append_array(arc(Vector2(2920, 1250), Vector2(3120, 1250), 40, 3))
	points.append_array([Vector2(3392, 1180), Vector2(3398, 1020), Vector2(3405, 860)])
	points.append_array([Vector2(3900, 600), Vector2(3960, 600)])
	points.append_array([Vector2(4205, 585), Vector2(4375, 565)])
	points.append_array([Vector2(5095, 640), Vector2(5095, 565), Vector2(5095, 490)])
	points.append_array(arc(Vector2(5505, 370), Vector2(5625, 340), 40, 3))
	points.append_array(arc(Vector2(5895, 340), Vector2(6015, 370), 40, 3))
	points.append_array(arc(Vector2(6430, 385), Vector2(6560, 385), 25, 4))
	points.append_array(arc(Vector2(5550, 950), Vector2(5650, 950), 0, 3))
	points.append_array([Vector2(6630, 830), Vector2(6830, 710)])
	points.append_array([Vector2(7060, 540), Vector2(7062, 460), Vector2(7064, 385), Vector2(7066, 320)])
	return points


static func arc(from: Vector2, to: Vector2, height: float, count: int) -> Array:
	var points: Array = []
	for i in count:
		var t := float(i) / maxf(1, count - 1)
		points.append(from.lerp(to, t) + Vector2(0, -sin(t * PI) * height))
	return points


func seed_room() -> void:
	for data in ENEMIES:
		var options: Dictionary = data.duplicate()
		options.erase("kind")
		options.erase("at")
		spawn_enemy(data.kind, data.at, options)
	for data in WEAPON_SPAWNS:
		spawn_pickup("weapon", data.at, {"sword": Sword, "dagger": Dagger, "hammer": Hammer}[data.kind])
	for data in HEALS:
		spawn_pickup("heal", data.at).amount = data.amount


func spawn_pickup(kind: String, at: Vector2, weapon: Resource = null) -> Node2D:
	var item := Pickup.new()
	item.kind = kind
	item.position = at
	item.weapon = weapon
	world.add_child(item)
	pickups.append(item)
	return item


func enemy_added(enemy: CharacterBody2D) -> void:
	enemy.defeated.connect(_enemy_dead)


func _enemy_dead(at: Vector2) -> void:
	kills += 1
	burst("hit", at + Vector2(0, -25), 1.4)
	if randf() < 0.25:
		spawn_pickup("heal", at).lock_time = 0.25


func _healed(amount: int) -> void:
	notice = "+%d HP" % amount
	notice_time = 1.8
	burst("heal", player.position + Vector2(0, -45), 1.3)
	audio_fx.cue("heal")


func _died() -> void:
	if death_timer > 0:
		return
	deaths += 1
	death_timer = 0.85
	notice = "稍作休息 · 返回最近营火"
	notice_time = 1.5


func respawn() -> void:
	# Only the campfire position and collected fireflies persist within this run.
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	for item in pickups:
		item.queue_free()
	pickups.clear()
	for slab in crumbles:
		slab.reset_slab()
	nearby = null
	particles.clear()
	notice = "已从营火继续" if checkpoint_active else "从起点重新出发"
	notice_time = 1.8
	player.reset_at(checkpoint)
	player.combat.weapon = (checkpoint_weapon if checkpoint_weapon else Sword) if checkpoint_active else null
	snap_view()
	seed_room()
	death_timer = 0
	hit_stop = 0


func hit_feedback(at: Vector2, duration: float) -> void:
	super.hit_feedback(at, duration)
	if audio_fx:
		audio_fx.cue("hit")


func _physics_process(delta: float) -> void:
	layout()
	if paused:
		return
	if death_timer > 0:
		death_timer -= delta
		if death_timer <= 0:
			respawn()
		return
	super._physics_process(delta)
	if hit_stop > 0:
		return
	elapsed += delta
	for mover in movers:
		mover.tick(delta)
	for slab in crumbles:
		var event: String = slab.tick(delta, player)
		if event == "crack":
			audio_fx.cue("crack")
		elif event == "break":
			burst("land", slab.rect.get_center(), 1.0)
	_tick_hazards(delta)
	_tick_fireflies(delta)
	_tick_places(delta)
	_tick_pickups(delta)
	notice_time = maxf(0, notice_time - delta)
	weapon_icon.visible = player.combat.weapon != null
	weapon_icon.weapon = player.combat.weapon
	weapon_icon.queue_redraw()
	var name: String = player.combat.weapon.display_name if player.combat.weapon else "空手"
	hud.text = hud_text()
	prompt.text = "E 拾取 %s（替换当前武器）" % nearby.weapon.display_name if nearby else (notice if notice_time > 0 else "寻找出口 · 高处和坑底都有东西")
	status.text = ""
	debug_label.text = "Player %s | Velocity %s | Grounded %s\nHP %d | Weapon %s | Attack %s\nDodge %.2f / CD %.2f | Invincible %.2f\nEnemy HP %s" % ["GROUND" if player.is_on_floor() else "AIR", player.velocity, player.is_on_floor(), player.health.hp, name, player.combat.state, player.roll_time, player.roll_cooldown, player.health.invulnerable, str(enemies.map(func(e): return e.hp))]
	props.queue_redraw()
	glow_layer.queue_redraw()
	# The curtain is drawn once; fading it is only a modulate change.
	curtain.modulate.a = 1.0 - nook_reveal


func hud_text() -> String:
	var name: String = player.combat.weapon.display_name if player.combat.weapon else "空手"
	return "苔根小径  ·  萤火 %d / %d  ·  生命 %d / 100  ·  武器：%s  ·  营火：%s\nA/D 移动  空格跳  J 攻击  Shift 翻滚  E 拾取  S+空格 穿下树枝  Esc 暂停  R 营火重来  F3 调试" % [firefly_count, fireflies.size(), player.health.hp, name, "已点亮 %d" % lit_campfires.size() if checkpoint_active else "起点"]


func _player_box() -> Rect2:
	return player.body_box()


func _tick_hazards(delta: float) -> void:
	if not player.alive():
		return
	if player.position.y > bounds.end.y - 60:
		player.control_enabled = false
		_died()
		return
	var box := _player_box()
	for rect in THORNS:
		if rect.grow(-3).intersects(box):
			var away := signf(player.position.x - rect.get_center().x)
			if player.health.take_damage(20, away if away != 0 else -1.0):
				player.velocity.y = -560
				burst("hit", player.position + Vector2(0, -10), 0.8)
	for m in mushrooms:
		m.squash = move_toward(m.squash, 0.0, delta * 3.2)
		var s := 1.3 if m.big else 1.0
		var zone := Rect2(m.at + Vector2(-40 * s, -50 * s), Vector2(80 * s, 54 * s))
		if player.velocity.y >= 0 and zone.has_point(player.position):
			player.launch(1400.0 if m.big else 1000.0)
			m.squash = 1.0


func _tick_fireflies(delta: float) -> void:
	var center: Vector2 = player.body_box().get_center()
	for fly in fireflies:
		fly.phase += delta
		if not fly.taken and center.distance_to(fly.pos) < 44:
			fly.taken = true
			firefly_count += 1
			sparkles.append({"pos": fly.pos, "t": 0.0})
			audio_fx.cue("chime")
	for i in range(sparkles.size() - 1, -1, -1):
		sparkles[i].t += delta * 2.5
		if sparkles[i].t >= 1:
			sparkles.remove_at(i)


func _tick_places(delta: float) -> void:
	for i in CAMPFIRES.size():
		if i in lit_campfires or not player.is_on_floor() or player.position.distance_to(CAMPFIRES[i]) > 70:
			continue
		lit_campfires.append(i)
		checkpoint = CAMPFIRES[i]
		checkpoint_active = true
		checkpoint_weapon = player.combat.weapon
		player.health.heal(100)
		notice = "营火已点亮 · 倒下后从这里继续"
		notice_time = 3
		audio_fx.cue("heal")
	if CAVERN.has_point(player.position) and not secrets.has("cavern"):
		_found_secret("cavern", "发现坑底萤穴")
	var in_nook := NOOK.grow_individual(0, 0, 0, 10).has_point(player.position)
	nook_reveal = move_toward(nook_reveal, 0.85 if in_nook else 0.0, delta * 3.0)
	if in_nook and not secrets.has("nook"):
		_found_secret("nook", "发现树冠暗格")
	if not finished and player.position.x > EXIT.x - 40 and player.is_on_floor():
		finished = true
		finish_time = elapsed
		audio_fx.cue("heal")
	results.visible = finished and player.position.x > EXIT.x - 260
	results_panel.visible = results.visible
	if results.visible:
		results.text = "抵达出口！\n用时 %d:%02d   萤火 %d / %d\n秘密 %d / 2   净化怪物 %d   倒下 %d 次\n\n可以回头探索 · R 从营火重来" % [int(finish_time) / 60, int(finish_time) % 60, firefly_count, fireflies.size(), secrets.size(), kills, deaths]


func _found_secret(key: String, text: String) -> void:
	secrets[key] = true
	secrets_found = true
	notice = text
	notice_time = 3
	audio_fx.cue("chime")


func _tick_pickups(delta: float) -> void:
	nearby = null
	var distance := 88.0
	for item in pickups:
		item.tick(delta)
		if item.consumed or item.lock_time > 0:
			continue
		var gap: float = player.position.distance_to(item.position)
		if item.kind == "heal" and gap < 44 and player.health.hp > 0:
			if player.health.heal(item.amount) > 0:
				item.consumed = true
				item.visible = false
		elif item.kind == "weapon" and gap < distance:
			nearby = item
			distance = gap
	if Input.is_physical_key_pressed(KEY_E) and not e_was_down and nearby and player.alive():
		swap_weapon(nearby)
	e_was_down = Input.is_physical_key_pressed(KEY_E)


func swap_weapon(item: Node2D) -> void:
	var old: Resource = player.combat.weapon
	player.combat.reset_attack()
	player.combat.weapon = item.weapon
	item.consumed = true
	item.visible = false
	if old:
		var drop := spawn_pickup("weapon", player.position - Vector2(player.facing * 36, 0), old)
		drop.lock_time = 0.45
	notice = "装备了" + player.combat.weapon.display_name
	notice_time = 1.5
	audio_fx.cue("heal")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_R:
		respawn()
		return
	super._unhandled_key_input(event)


func _draw_props() -> void:
	var time := elapsed
	for i in CAMPFIRES.size():
		Art.campfire(props, CAMPFIRES[i], i in lit_campfires, time + i)
	Art.exit_light(props, EXIT, time)
	for m in mushrooms:
		Art.mushroom(props, m.at, m.squash, m.big)


func _draw_fireflies() -> void:
	var view := Rect2(camera.position - camera.view * 0.5, camera.view).grow(40)
	for fly in fireflies:
		if not fly.taken and view.has_point(fly.pos):
			Art.firefly(glow_layer, fly.pos + Vector2(sin(fly.phase * 1.3) * 4, sin(fly.phase * 2.1) * 5), fly.phase)
	for spark in sparkles:
		Art.sparkle(glow_layer, spark.pos, spark.t)
