extends Node2D
## Room lifecycle and ordered story beats. Geometry and UI live in separate modules.
@export_enum("bedroom","kitchen","living") var room_id := "bedroom"
var test_mode := false
var route_on_exit := true
var busy := false
var routing := false
var player: PiggyPlayer
var ui: ChapterPresentation
var dialogue: DialogueUI
var camera: Camera2D
var hotspots: Dictionary = {}
var memory: Sprite2D
var paper: Sprite2D
var steam: AnimatedSprite2D
var lines: Dictionary
var last_route := ""
var base_zoom := 1.0

func _ready() -> void:
	lines = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/chapter1.json"))
	ChapterRoomLayout.build(self,room_id)
	player = preload("res://actors/shared/player.tscn").instantiate()
	player.name = "Player"
	player.handpainted_room = true
	player.sheet_override = preload("res://assets/chapter1/boy.png")
	# Authored row gaps are uneven: 362 px grid cells cut off side/back hair.
	player.sheet_row_edges = PackedInt32Array([0,368,694,1028,1448])
	player.move_speed = 170.0
	player.visible_height = 157.0
	player.position = ChapterRoomLayout.DATA[room_id].spawn
	player.get_node("Camera2D").enabled = false
	$Depth.add_child(player)
	player.reset_physics_interpolation()
	camera = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = ChapterRoomLayout.SIZE*0.5
	add_child(camera)
	ui = ChapterPresentation.new()
	ui.test_mode = test_mode
	add_child(ui)
	ui.room_name.text = ChapterRoomLayout.DATA[room_id].title
	dialogue = preload("res://systems/dialogue/dialogue_ui.tscn").instantiate()
	add_child(dialogue)
	get_viewport().size_changed.connect(_fit)
	_fit()
	player.prompt_changed.connect(func(text: String):
		ui.prompt.text = ("E　"+text if not text.is_empty() else ChapterPresentation.HELP))
	for item in ChapterRoomLayout.DATA[room_id].hotspots:
		add_hotspot(item[0],item[1],item[2])
	memory = Sprite2D.new()
	memory.name = "MemoryShadow"
	memory.visible = false
	memory.z_index = 5
	var soften := ShaderMaterial.new()
	soften.shader = preload("res://scenes/chapter1/memory_soften.gdshader")
	memory.material = soften
	add_child(memory)
	if room_id == "bedroom":
		var painting := Sprite2D.new()
		painting.texture = preload("res://assets/prologue/bigidea_after.png")
		painting.position = Vector2(347,155)
		painting.scale = Vector2(137,155) / painting.texture.get_size()
		painting.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(painting)
	elif room_id == "kitchen":
		steam = AnimatedSprite2D.new()
		steam.sprite_frames = SpriteFrames.new()
		steam.sprite_frames.set_animation_speed("default",4)
		var sheet := preload("res://assets/chapter1/steam.png")
		for rect in SpriteAtlas.bounds(sheet,3,1):
			steam.sprite_frames.add_frame("default",SpriteAtlas.frame(sheet,rect))
		steam.position = Vector2(1030,233)
		steam.scale = Vector2.ONE*0.12
		steam.modulate.a = 0.48
		steam.visible = GameState.has_flag("coffee_made")
		add_child(steam)
		steam.play()
		hotspots.cup.set_enabled(GameState.has_flag("coffee_made"))
	elif room_id == "living":
		paper = Sprite2D.new()
		paper.name = "RedWrappingPaper"
		var sheet := preload("res://assets/chapter1/red_paper.png")
		paper.texture = SpriteAtlas.frame(sheet,SpriteAtlas.bounds(sheet,4,1)[0])
		paper.scale = Vector2.ONE*0.15
		paper.position = Vector2(660,850)
		paper.visible = GameState.has_flag("red_paper_spawned")
		$Depth.add_child(paper)
		add_hotspot("paper","红色包装纸",paper.position)
		hotspots.paper.set_enabled(paper.visible)
	if room_id == "bedroom" and not GameState.has_flag("ch1_opening_done"):
		call_deferred("_opening")

func _fit() -> void:
	var size := get_viewport().get_visible_rect().size
	base_zoom = minf(size.x/1448.0,size.y/1086.0)
	camera.zoom = Vector2.ONE*base_zoom
	if dialogue:
		dialogue.panel.position = Vector2(size.x*0.11,size.y-200)
		dialogue.panel.size.x = size.x*0.78

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not busy:
		get_viewport().set_input_as_handled()
		lock(true)
		var choice := await ui.choose({"stay":"继续探索", "save":"保存并回主菜单"})
		if choice == "save":
			if SaveManager.save_game(scene_file_path):
				routing = true
				SceneRouter.change_scene("res://scenes/bootstrap/main.tscn")
		await get_tree().process_frame
		if not routing: lock(false)

func add_hotspot(id: String, title: String, pos: Vector2) -> void:
	var area := Interactable.new()
	area.name = id.capitalize().replace(" ","")
	area.interaction_id = id
	area.prompt_text = title
	area.position = pos
	area.collision_layer = 4
	area.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 40
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	area.interacted.connect(func(_actor): interact(id))
	hotspots[id] = area

func lock(value: bool) -> void:
	busy = value
	player.set_input_enabled(not value)

func pause(seconds: float) -> void:
	await get_tree().create_timer(0.01 if test_mode else seconds).timeout

func say(key: String) -> void:
	for line in lines.get(key,[]):
		if test_mode:
			await get_tree().process_frame
		elif line is String:
			await dialogue.say("白白菜",line)
		else:
			await dialogue.say(line.speaker,line.text)

func _opening() -> void:
	lock(true)
	player.visible = false
	ui.heart.visible = false
	var wake := preload("res://assets/chapter1/wake.png")
	var frames := SpriteAtlas.bounds(wake,3,1)
	# An explicit close-up avoids placing the source's second bed over the room bed.
	for index in 3:
		ui.show_closeup(SpriteAtlas.frame(wake,frames[index]))
		if index == 0:
			await ui.fade_from_black(test_mode)
		await pause(1.1 if index == 0 else 0.8)
	ui.hide_closeup()
	player.position = Vector2(600,565)
	player.reset_physics_interpolation()
	player.visible = true
	await say("opening")
	ui.heart.visible = true
	GameState.set_flag("ch1_opening_done")
	lock(false)

func interact(id: String) -> void:
	if busy or not hotspots.has(id) or not hotspots[id].enabled:
		return
	lock(true)
	match id:
		"painting":
			await ui.inspect(preload("res://assets/prologue/bigidea_after.png"))
			GameState.set_flag("big_idea_checked")
			if not GameState.has_flag("bedroom_memory_complete"):
				await memory_beat(1)
				await say("bedroom_memory_after")
		"coffee":
			await say("coffee")
			steam.visible = true
			await pause(1.4)
			# Both points are in the clear counter aisle, not across the table.
			if not test_mode:
				await player.walk_to(Vector2(player.position.x,465))
				await player.walk_to(Vector2(1000,465))
				await dialogue.say("","你习惯性地伸手去拿自己的杯子。")
			GameState.set_flag("coffee_made")
			hotspots.cup.set_enabled(true)
		"cup":
			await ui.inspect(preload("res://assets/chapter1/pig_cup.png"))
			await say("cup_repeat" if GameState.has_flag("pig_cup_checked") else "cup")
			GameState.set_flag("pig_cup_checked")
			await check_kitchen_memory()
		"tableware":
			await ui.inspect(preload("res://assets/chapter1/tableware.png"))
			GameState.set_flag("double_tableware_checked")
			await check_kitchen_memory()
		"pillow":
			await ui.inspect(preload("res://assets/chapter1/pillow.png"))
			await say("pillow")
			GameState.set_flag("pig_pillow_checked")
			if not GameState.has_flag("living_room_memory_complete"):
				await memory_beat(3)
				GameState.set_flag("first_clear_flashback")
				await say("missing_someone")
				if not test_mode:
					await dialogue.say("","沙……")
				player.face(Vector2.DOWN)
				await pause(0.3)
				await paper_arrives()
		"paper":
			await ui.inspect(paper.texture)
			await say("paper")
			GameState.set_flag("red_paper_checked")
			GameState.set_flag("ch1_can_leave_home")
		"blanket", "basket", "window":
			# Only visual inspection: the finalized environmental lines were not supplied.
			var rects := {"blanket":Rect2(740,280,165,265),"basket":Rect2(1200,685,150,215),"window":Rect2(550,70,300,225)}
			await ui.inspect(SpriteAtlas.frame($Background.texture,rects[id]))
		"door":
			await door()
	# Input resumes next frame so a dialogue dismissal cannot trigger another object.
	await get_tree().process_frame
	if is_inside_tree() and not routing:
		lock(false)

func check_kitchen_memory() -> void:
	if GameState.has_flag("pig_cup_checked") and GameState.has_flag("double_tableware_checked") and not GameState.has_flag("kitchen_memory_complete"):
		await memory_beat(2)

func memory_beat(index: int) -> void:
	var flags := ["bedroom_memory_complete","kitchen_memory_complete","living_room_memory_complete"]
	memory.texture = load("res://assets/chapter1/memory_0%d.png" % index)
	(memory.material as ShaderMaterial).set_shader_parameter("blur",[0.045,0.035,0.025][index-1])
	memory.position = [Vector2(610,410),Vector2(925,600),Vector2(655,850)][index-1]
	memory.scale = Vector2.ONE*(180.0/memory.texture.get_height())
	memory.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	memory.modulate = Color(1.0,0.93,0.85,0)
	memory.visible = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(camera,"zoom",Vector2.ONE*base_zoom*1.025,0.01 if test_mode else 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(memory,"modulate:a",0.55,0.01 if test_mode else 0.65)
	tween.tween_property(memory,"position:y",memory.position.y-12,0.01 if test_mode else 2.8)
	GameState.gain_chapter_heart(flags[index-1])
	await pause(1.0)
	if index == 2:
		await say("kitchen_memory")
	elif index == 3:
		# The memory is at the doorway: keep its silhouette out of the dialogue box.
		dialogue.panel.position.y = 24
		await say("living_memory")
		dialogue.panel.position.y = get_viewport().get_visible_rect().size.y-200
	await pause(0.4)
	await ui.flash(test_mode,0.65 if index == 3 else 0.22)
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(memory,"modulate:a",0,0.01 if test_mode else 0.75)
	fade.tween_property(camera,"zoom",Vector2.ONE*base_zoom,0.01 if test_mode else 0.75)
	await fade.finished
	memory.visible = false

func paper_arrives() -> void:
	if GameState.has_flag("red_paper_spawned"):
		return
	paper.position = Vector2(655,1035)
	paper.rotation = -0.3
	paper.visible = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(paper,"position",Vector2(660,850),0.01 if test_mode else 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(paper,"rotation",0.15,0.01 if test_mode else 1.6)
	await tween.finished
	GameState.set_flag("red_paper_spawned")
	hotspots.paper.set_enabled(true)

func door() -> void:
	if room_id == "bedroom":
		if not GameState.has_flag("bedroom_memory_complete"):
			await say("locked_exit")
			return
		if not GameState.has_flag("bedroom_exit_intro_done"):
			await say("bedroom_exit")
			GameState.set_flag("bedroom_exit_intro_done")
		go("kitchen")
	elif room_id == "kitchen":
		var options := {"bedroom":"回卧室", "cancel":"留在厨房"}
		if GameState.has_flag("kitchen_memory_complete"):
			options["living"] = "去客厅"
		var target := "cancel" if test_mode else await ui.choose(options)
		if target != "cancel": go(target)
	else:
		var options := {"kitchen":"回厨房", "outside":"出门看看", "cancel":"留在客厅"}
		var target := "outside" if test_mode else await ui.choose(options)
		if target == "kitchen": go("kitchen")
		elif target == "outside":
			if not GameState.has_flag("ch1_can_leave_home"):
				await say("locked_exit")
				return
			await say("leave")
			GameState.set_flag("ch1_completed")
			GameState.story_phase = GameState.StoryPhase.LITTLE_PIG_DARK_FOREST
			last_route = "res://scenes/chapter_02_dark_forest/forest_clearing.tscn"
			if route_on_exit:
				routing = true
				SceneRouter.change_scene(last_route)

func go(target: String) -> void:
	last_route = "res://scenes/chapter1/%s.tscn" % target
	if route_on_exit:
		routing = true
		SceneRouter.change_scene(last_route)
