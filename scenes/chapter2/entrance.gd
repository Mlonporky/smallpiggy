extends "res://scenes/chapter2/forest_base.gd"
const FOREST_PATH := "res://scenes/chapter2/forest_path.tscn"
var script_lines: Dictionary
var paper: Interactable
var stick: Interactable
var blocker: StaticBody2D
var wizard: Sprite2D
var memory: TextureRect
var wizard_finished := false
var distance_shot: Node2D
var distance_shot_count := 0

func _ready() -> void:
	GameState.story_phase = GameState.StoryPhase.LITTLE_PIG_DARK_FOREST
	build(preload("res://assets/chapter2/entrance.png"),Vector2(720,715))
	script_lines = JSON.parse_string(FileAccess.get_file_as_string("res://assets/chapter2/dialogue.json"))
	# Walkable clearing and northern path; trees and foreground stay solid.
	wall(PackedVector2Array([Vector2(0,0),Vector2(625,0),Vector2(625,250),Vector2(460,400),Vector2(390,500),Vector2(390,790),Vector2(0,900)]))
	wall(PackedVector2Array([Vector2(860,0),Vector2(1448,0),Vector2(1448,1086),Vector2(1080,1086),Vector2(1080,570),Vector2(860,270)]))
	rectangle(Rect2(0,850,1448,236))
	blocker = rectangle(Rect2(550,330,450,35))
	paper = hotspot(Vector2(925,592),"调查红色包装纸",examine_paper)
	paper.name = "RedWrappingPaper"
	# The stick lies just beside where she wakes, not in the cave.
	stick = hotspot(Vector2(610,750),"捡起小树枝",take_stick,preload("res://assets/chapter2/stick.png"))
	stick.name = "Stick"
	wizard = Sprite2D.new()
	wizard.name = "EvilWizard"
	wizard.texture = preload("res://assets/chapter2/wizard.png")
	wizard.region_enabled = true
	wizard.region_rect = Rect2(399,34,303,314)
	wizard.scale = Vector2.ONE * 0.64
	wizard.texture_filter = CharacterSpriteStyle.FILTER
	wizard.offset.y = -157
	wizard.position = Vector2(750,490)
	wizard.visible = false
	world.add_child(wizard)
	trigger(Rect2(470,805,580,40),backtrack)
	trigger(Rect2(610,265,270,60),enter_forest)
	trigger(Rect2(550,365,450,30),stick_hint)
	if GameState.has_flag("s2_pig_stick_collected"): hold_stick()
	wizard_finished = GameState.has_flag("s2_pig_wizard_complete")
	if wizard_finished or GameState.has_flag("s2_pig_intro_complete"):
		wizard_finished = true
		open_path()
		refresh_objective()
		if GameState.has_flag("s2_pig_intro_complete"): player.position = Vector2(745,395)
	elif GameState.has_flag("s2_pig_wakeup_complete"):
		refresh_objective()
		if GameState.has_flag("s2_pig_wizard_scene_started"): call_deferred("run_wizard")
	else:
		lock(true)
		player.waking = true
		curtain.color.a = 1
		call_deferred("opening")

func lines(section: Variant) -> void:
	for line in script_lines[str(section)]:
		await dialogue.say(line.speaker,line.text,0,float(line.pause_after))
		if line.text == "在森林的另一端。": await reveal_manor_distance()
		if line.text == "白白菜还记不记得你。": await beat(0.8)
		if line.text in ["可是白菜一个人在那边。","他一定也会害怕。"]:
			joy(9,0.45)
			await beat(0.33)

func opening() -> void:
	await fade(0)
	await beat(1)
	await dialogue.say("小呆猪","……白菜？",0,0.5)
	await dialogue.say("小呆猪","白菜？")
	await player.wake_up()
	for line in script_lines["11"].slice(2):
		await dialogue.say(line.speaker,line.text,0,float(line.pause_after))
	player.face(paper.position-player.position)
	GameState.set_flag("s2_pig_wakeup_complete")
	refresh_objective()
	lock(false)
	checkpoint()

func take_stick() -> void:
	lock(true)
	player.face(stick.position-player.position)
	# TODO: Missing asset — no pick-up pose; she switches straight to the armed sheet.
	hold_stick()
	GameState.set_flag("s2_pig_stick_collected")
	await lines("stick")
	open_path()
	refresh_objective()
	lock(false)
	checkpoint()

func hold_stick() -> void:
	stick.visible = false
	stick.set_enabled(false)
	player.armed = true

## The northern path opens once the wizard has left and she holds the stick.
func open_path() -> void:
	if wizard_finished and GameState.has_flag("s2_pig_stick_collected") and is_instance_valid(blocker):
		blocker.queue_free()

func refresh_objective() -> void:
	if not wizard_finished: ui.set_objective("调查身旁的红色包装纸 · 靠近后按 E 或点击")
	elif not GameState.has_flag("s2_pig_stick_collected"): ui.set_objective("捡起身旁的小树枝 · 再向北穿过黑暗森林")
	else: ui.set_objective("向北穿过黑暗森林 · 回到猪猪山庄")

func stick_hint() -> void:
	if wizard_finished and not GameState.has_flag("s2_pig_stick_collected"):
		ui.set_status("身边的小树枝也许用得上 · 先把它捡起来",3)

func examine_paper() -> void:
	lock(true)
	if wizard_finished:
		await dialogue.say("小呆猪","我要把礼物找回来。")
		lock(false)
		return
	await lines(13)
	GameState.set_flag("red_wrapping_paper_examined")
	GameState.set_flag("s2_pig_wizard_scene_started")
	checkpoint()
	await run_wizard()

func run_wizard() -> void:
	lock(true)
	player.face(wizard.position-player.position)
	fog()
	await beat(0.5)
	wizard.visible = true
	wizard.modulate.a = 0
	var appear := create_tween()
	appear.tween_property(wizard,"modulate:a",1.0,0.6)
	await appear.finished
	await lines(15)
	await lines(16)
	await memory_flash(false)
	await lines(17)
	await beat(1.5)
	await lines(18)
	await memory_flash(true)
	await beat(0.5)
	await lines(20)
	joy(8,0.35)
	await recoil(25)
	await lines(22)
	await shake()
	await lines(23)
	await beat(0.67)
	await lines(24)
	await shake()
	await lines(25)
	joy(10,0.4)
	await beat(0.17)
	joy(24,0.85)
	await beat(0.17)
	joy(60,1.5)
	curtain.color = Color(1,0.94,0.65,0.45)
	await recoil(95)
	await fade(0,0.25)
	curtain.color = Color(0.025,0.018,0.05,0)
	await lines(26)
	fog()
	await lines(27)
	var vanish := create_tween()
	vanish.tween_property(wizard,"modulate:a",0.0,0.7)
	await vanish.finished
	wizard.visible = false
	await beat(1)
	await lines(28)
	wizard_finished = true
	GameState.set_flag("s2_pig_wizard_complete")
	open_path()
	refresh_objective()
	lock(false)
	checkpoint()

func memory_flash(warm: bool) -> void:
	# Read-only existing art: never instantiate or mutate the Act I scenes.
	# TODO: Missing asset — exact cup/hidden-gift memory poses; existing memories stand in.
	memory = TextureRect.new()
	memory.texture = load("res://assets/chapter1/memory_02.png" if warm else "res://assets/prologue/bedroom_boy.png")
	memory.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	memory.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	memory.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	memory.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(memory)
	memory.modulate = Color(1,0.88,0.75,0) if warm else Color(0.75,0.8,1,0)
	var tween := create_tween()
	tween.tween_property(memory,"modulate:a",0.85,0.4)
	await tween.finished
	if warm: await lines(19)
	else: await beat(1.2)
	var out := create_tween()
	out.tween_property(memory,"modulate:a",0.0,0.4)
	await out.finished
	memory.queue_free()

func particles(texture: Texture2D, count: int, size: float, color: Color, at: Vector2) -> void:
	var fx := CPUParticles2D.new()
	fx.texture = texture
	fx.amount = count
	fx.lifetime = 1.4
	fx.one_shot = true
	fx.explosiveness = 0.95
	fx.direction = Vector2.UP
	fx.spread = 180
	fx.initial_velocity_min = 30 * size
	fx.initial_velocity_max = 120 * size
	fx.gravity = Vector2(0,-15)
	fx.scale_amount_min = 0.35 * size
	fx.scale_amount_max = 0.7 * size
	fx.color = color
	fx.position = at
	add_child(fx)
	fx.finished.connect(fx.queue_free)
	fx.emitting = true

func joy(count: int, size: float) -> void:
	# TODO: Missing asset — use the existing individual Joy particle, not an entire effect sheet.
	particles(preload("res://assets/placeholders/joy_particle.svg"),count,size,Color(1,0.91,0.6,0.85),player.position+Vector2(0,-60))

func fog() -> void:
	# TODO: Missing asset — reuse project's fog placeholder until authored fog is supplied.
	particles(preload("res://assets/placeholders/fog_particle.svg"),35,8,Color(0.7,0.3,0.9,0.4),wizard.position+Vector2(0,-70))

func recoil(distance: float) -> void:
	var tween := create_tween()
	tween.tween_property(wizard,"position:x",wizard.position.x-distance,0.45)
	await tween.finished

func backtrack() -> void:
	if not wizard_finished or GameState.has_flag("forest_backtrack_hint_shown"): return
	lock(true)
	GameState.set_flag("forest_backtrack_hint_shown")
	await lines(29)
	lock(false)
	checkpoint()

func enter_forest() -> void:
	if not wizard_finished or not GameState.has_flag("s2_pig_stick_collected"): return
	lock(true)
	if not GameState.has_flag("s2_pig_intro_complete"):
		await shake()
		await dialogue.say("小呆猪","……")
		await dialogue.say("小呆猪","我还是很害怕。",0,0.67)
		await player.walk_to(player.position+Vector2(0,-35),2)
		await dialogue.say("小呆猪","但是——",0,0.33)
		await dialogue.say("小呆猪","害怕也可以往前走。")
		ui.set_objective("回到猪猪山庄\n穿过黑暗森林。找到白白菜。")
		# Interface only: preserve the cabbage's existing 0–3 Heart progress.
		GameState.set_flag("heart_ui_unlocked")
		await fade(0.8)
		title.text = "第二幕 · 小呆猪篇\n\n「为了你，我会走过最害怕的地方。」"
		await beat(2)
		await fade(1)
		GameState.set_flag("s2_pig_intro_complete")
		checkpoint()
	SceneRouter.change_scene(FOREST_PATH)

func reveal_manor_distance() -> void:
	distance_shot_count += 1
	distance_shot = preload("res://scenes/chapter2/manor_distance_shot.gd").new()
	add_child(distance_shot)
	await distance_shot.play(self,get_child(0) as Sprite2D)
	distance_shot = null

func fit_camera() -> void:
	if is_instance_valid(distance_shot) and distance_shot.camera != null:
		distance_shot.apply_camera()
	else:
		super.fit_camera()
