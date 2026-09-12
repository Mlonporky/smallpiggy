extends "res://scenes/chapter2/forest_base.gd"
var discovered := false
var cave_door: Interactable

func _ready() -> void:
	GameState.story_phase = GameState.StoryPhase.FOREST_EXPLORATION
	build(preload("res://assets/chapter2/forest_path_v1.png"), Vector2(690,960))
	player.armed = true
	# Follow the painted S-shaped path; the cliff and trees stay solid, even in a jump.
	wall(PackedVector2Array([Vector2(0,0),Vector2(1448,0),Vector2(1448,160),Vector2(1010,160),Vector2(975,255),Vector2(825,335),Vector2(655,470),Vector2(555,650),Vector2(490,850),Vector2(450,1086),Vector2(0,1086)]))
	wall(PackedVector2Array([Vector2(1448,160),Vector2(1240,160),Vector2(1250,265),Vector2(1130,390),Vector2(1030,470),Vector2(915,650),Vector2(910,820),Vector2(1010,1086),Vector2(1448,1086)]))
	rectangle(Rect2(0,1040,1448,46))
	discovered = GameState.has_flag("s2_cave_discovered")
	cave_door = hotspot(Vector2(1130,230), "进入发光的山洞", enter_cave)
	cave_door.set_enabled(discovered)
	trigger(Rect2(790,350,350,200), discover_cave)
	ui.set_objective("沿着林间小路前进 · 寻找礼物碎片")
	ui.set_status("方向键 / WASD 移动 · 空格跳跃 · E 调查",6)
	if discovered: ui.set_objective("靠近发光的洞口 · 按 E 进入山洞")

func discover_cave() -> void:
	if discovered: return
	discovered = true
	lock(true)
	player.face(cave_door.position - player.position)
	await dialogue.say("小呆猪", "那边的山洞……在发光？")
	await dialogue.say("小呆猪", "礼物的碎片，会不会就在里面？")
	GameState.set_flag("s2_cave_discovered")
	cave_door.set_enabled(true)
	ui.set_objective("靠近发光的洞口 · 按 E 进入山洞")
	lock(false)
	checkpoint()

func enter_cave() -> void:
	if not discovered: return
	lock(true)
	SceneRouter.change_scene("res://scenes/chapter2/cave.tscn")
