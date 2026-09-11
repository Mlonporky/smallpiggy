extends "res://scenes/chapter2/forest_base.gd"
var slime: ForestSlime
var stick: Interactable
var fragment: Interactable
var won := false
var weapon_gate: StaticBody2D

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
	weapon_gate = rectangle(Rect2(560,715,430,20))
	stick = hotspot(Vector2(800,815),"拾起木棍",take_stick,preload("res://assets/chapter2/stick.png"))
	fragment = hotspot(Vector2(748,410),"拾取红色礼物碎片",collect_fragment,preload("res://assets/chapter1/gift_fragment_hd.png"))
	fragment.visible = false
	fragment.set_enabled(false)
	player.health_changed.connect(ui.set_health)
	player.player_died.connect(defeated)
	ui.set_health(3,3)
	won = GameState.has_flag("forest_slime_defeated")
	if won:
		weapon_gate.queue_free()
		stick.visible = false
		stick.set_enabled(false)
		player.armed = true
		ui.set_objective("已找回红色礼物碎片 · 继续寻找白白菜")
		ui.set_status("本段完成 · Esc 返回菜单",6)
	else:
		slime = preload("res://actors/slime/forest_slime.tscn").instantiate()
		slime.set_script(preload("res://scenes/chapter2/slime.gd"))
		slime.position = Vector2(735,480)
		world.add_child(slime)
		slime.set_target(player)
		slime.defeated.connect(slime_defeated)
		if GameState.has_flag("s2_pig_stick_collected"):
			equip()
		else:
			ui.set_objective("穿过山洞 · 先拾起入口旁的木棍")
			ui.set_status("WASD / 方向键移动 · 靠近木棍按 E 或点击",6)
	trigger(Rect2(350,600,800,75),start_encounter)

func take_stick() -> void:
	GameState.set_flag("s2_pig_stick_collected")
	equip()
	checkpoint()

func equip() -> void:
	if is_instance_valid(weapon_gate): weapon_gate.queue_free()
	stick.visible = false
	stick.set_enabled(false)
	player.armed = true
	player.combat_enabled = true
	ui.set_objective("穿过山洞 · 击退挡路的变异史莱姆")
	ui.set_status("J / Z 挥动木棍 · 史莱姆压低身体时，向侧面躲开",7)
	if player.position.y < 680: slime.active = true

func start_encounter() -> void:
	if won or not is_instance_valid(slime): return
	if not player.armed:
		ui.set_status("入口旁有一根可以防身的木棍。",3)
		player.position.y = 705
		return
	slime.active = true

func slime_defeated() -> void:
	won = true
	fragment.visible = true
	fragment.set_enabled(true)
	player.combat_enabled = false
	ui.set_objective("拾取史莱姆留下的红色礼物碎片")
	ui.set_status("山洞安静下来了。",3)

func collect_fragment() -> void:
	if not won: return
	fragment.visible = false
	fragment.set_enabled(false)
	GameState.add_gift_fragment("fragment_red_wrap_01")
	GameState.set_flag("forest_slime_defeated")
	ui.set_objective("已找回红色礼物碎片 · 继续寻找白白菜")
	ui.set_status("礼物碎片已保存 · 本段完成 · Esc 返回菜单",8)
	checkpoint()

func defeated() -> void:
	lock(true)
	if is_instance_valid(slime):
		slime.active = false
		slime.process_mode = Node.PROCESS_MODE_DISABLED
	await fade(0.8)
	title.text = "先喘口气，再试一次。"
	await beat(1.5)
	SceneRouter.change_scene(scene_file_path)
