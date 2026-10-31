extends "res://scenes/chapter2/forest_base.gd"
const FX = preload("res://scenes/chapter2/combat_fx.gd")
var encounter_started := false
var health_bar: ProgressBar
var skill_label: Label
var slime: ForestSlime
var fragment: Interactable
var won := false
var handing_off := false
const CABBAGE_EXTERIOR := "res://scenes/cabbage_act2/villa.tscn"

func _ready() -> void:
	GameState.story_phase = GameState.StoryPhase.FOREST_EXPLORATION
	build(preload("res://assets/chapter2/cave.png"),Vector2(726,895))
	# The central floor and entrance corridor follow the supplied cave illustration.
	wall(PackedVector2Array([Vector2(0,0),Vector2(1448,0),Vector2(1448,280),Vector2(1170,280),Vector2(1080,185),Vector2(500,185),Vector2(430,300),Vector2(0,300)]))
	wall(PackedVector2Array([Vector2(0,280),Vector2(330,280),Vector2(420,510),Vector2(570,690),Vector2(615,800),Vector2(615,1086),Vector2(0,1086)]))
	wall(PackedVector2Array([Vector2(1220,240),Vector2(1448,240),Vector2(1448,1086),Vector2(900,1086),Vector2(870,780),Vector2(945,640),Vector2(1150,585)]))
	rectangle(Rect2(0,1020,1448,80))
	# Foreground rock islands remain obstacles during dodging.
	rectangle(Rect2(510,465,50,75))
	rectangle(Rect2(937,333,47,70))
	fragment =hotspot(Vector2(748,410),"拾取红色礼物碎片",collect_fragment,preload("res://assets/chapter1/gift_fragment_hd.png"))
	fragment.visible = false
	fragment.set_enabled(false)
	player.health.max_health = 100
	player.health.reset()
	build_combat_hud()
	player.health_changed.connect(on_health_changed)
	player.player_died.connect(defeated)
	player.joy_released.connect(on_joy_released)
	on_health_changed(100,100)
	won = GameState.has_flag("forest_slime_defeated")
	if won:
		player.armed = true
		ui.set_objective("已找回红色礼物碎片 · 继续寻找白白菜")
		ui.set_status("本段完成 · Esc 返回菜单",6)
		call_deferred("return_to_cabbage")
	elif GameState.has_flag("s2_fragment_dropped"):
		# Saved after the slime fell but before the fragment was picked up.
		player.armed = true
		drop_fragment()
	else:
		slime = preload("res://actors/slime/forest_slime.tscn").instantiate()
		slime.set_script(preload("res://scenes/chapter2/slime.gd"))
		slime.position = Vector2(735,480)
		world.add_child(slime)
		slime.set_target(player)
		slime.defeated.connect(slime_defeated)
		# The stick is picked up beside the wake-up spot; direct debug entry and
		# saves from before that change arrive here without it, so hand it over.
		GameState.set_flag("s2_pig_stick_collected")
		equip()
	trigger(Rect2(350,600,800,75),start_encounter)

func equip() -> void:
	player.armed = true
	player.combat_enabled = true
	ui.set_objective("穿过山洞 · 击退挡路的变异史莱姆")
	ui.set_status("J / Z 挥动树枝 · Shift 闪避 · Q 想起白菜 · K 招架 · 空格跳跃",7)

func start_encounter() -> void:
	if won or not is_instance_valid(slime) or encounter_started: return
	encounter_started = true
	lock(true)
	player.combat_enabled = false
	await beat(0.8) # Finish the entry movement before the brief story encounter.
	await player.walk_to(Vector2(735,650),4)
	player.face(slime.position-player.position)
	await dialogue.say("小呆猪", "史莱姆……挡住了去路。")
	ui.set_status("留意扑击前摇 · Shift 闪避 · K 树枝招架",3)
	# Real-time combat: both ordinary attacks and the voluntary skill can win.
	lock(false)
	player.combat_enabled = true
	slime.hit_box.damage = slime.ATTACK_DAMAGE
	slime.active = true
	slime.attack_lunge()

func build_combat_hud() -> void:
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(24,103)
	health_bar.size = Vector2(245,12)
	health_bar.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.16,0.10,0.17,0.9)
	track.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ee879d")
	fill.set_corner_radius_all(6)
	health_bar.add_theme_stylebox_override("background",track)
	health_bar.add_theme_stylebox_override("fill",fill)
	health_bar.max_value = 100
	ui.add_child(health_bar)
	skill_label = Label.new()
	skill_label.position = Vector2(24,140)
	skill_label.add_theme_font_size_override("font_size",17)
	skill_label.add_theme_color_override("font_color",Color("ffda96"))
	skill_label.text = "Q  想起白菜 · 就绪"
	ui.add_child(skill_label)
	var controls := Label.new()
	controls.position = Vector2(24,170)
	controls.add_theme_font_size_override("font_size",16)
	controls.text = "J / Z 挥击   Shift 闪避   Q 想起白菜   K 正面招架   空格跳跃"
	ui.add_child(controls)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_instance_valid(skill_label): return
	if player.joy_time > 0:
		skill_label.text = "Q  想起白菜 · 强化 %.1f 秒 · 冷却 %.1f 秒" % [player.joy_time,player.joy_cooldown]
	elif player.joy_cooldown > 0:
		skill_label.text = "Q  想起白菜 · 冷却 %.1f 秒" % player.joy_cooldown
	else:
		skill_label.text = "Q  想起白菜 · 就绪"

func on_health_changed(current: int, maximum: int) -> void:
	ui.heart.visible = true
	ui.heart.text = "生命  %d / %d" % [current,maximum]
	health_bar.value = current

func on_joy_released(at: Vector2) -> void:
	# A short effect during play, independent of HP and without a story lock.
	if is_instance_valid(slime): slime.receive_joy(at,player.JOY_RADIUS)
	ui.set_status("想到白菜，心里又有了勇气。 · 挥击强化 4 秒",3)

func slime_defeated() -> void:
	drop_fragment()
	ui.set_status("山洞安静下来了。",3)
	# Save now: leaving before picking up the fragment must not bring the slime back.
	GameState.set_flag("s2_fragment_dropped")
	checkpoint()

func drop_fragment() -> void:
	won = true
	fragment.visible = true
	fragment.set_enabled(true)
	player.combat_enabled = false
	ui.set_objective("拾取史莱姆留下的红色礼物碎片")

func collect_fragment() -> void:
	if not won or handing_off or GameState.has_flag("forest_slime_defeated"): return
	fragment.visible = false
	fragment.set_enabled(false)
	GameState.add_gift_fragment("fragment_red_wrap_01")
	gameplay_audio.cue("gift")
	GameState.set_flag("forest_slime_defeated")
	ui.set_objective("已找回红色礼物碎片 · 继续寻找白白菜")
	return_to_cabbage()

func return_to_cabbage() -> void:
	if handing_off: return
	handing_off = true
	lock(true)
	# A completed legacy cave save can load during the router fade-in.
	while SceneRouter.is_busy(): await get_tree().process_frame
	GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART
	# Continue must reopen the boy's exterior, not the completed cave.
	if allow_save and not SaveManager.save_game(CABBAGE_EXTERIOR):
		ui.set_status("自动保存失败，可在白菜外景按 F5 重试",8)
	SceneRouter.change_scene(CABBAGE_EXTERIOR)

func defeated() -> void:
	lock(true)
	if is_instance_valid(slime):
		slime.active = false
		slime.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	await fade(0.8)
	title.text = "先喘口气，再试一次。"
	await beat(1.5)
	SceneRouter.change_scene(scene_file_path)
