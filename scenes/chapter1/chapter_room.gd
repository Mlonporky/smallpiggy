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
var auto_exit_enabled := true

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
	if ChapterRoomLayout.pending_entry.get("room", "") == room_id:
		player.position = ChapterRoomLayout.pending_entry.position
	ChapterRoomLayout.pending_entry.clear()
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
		ui.prompt.text = ("点击物品 / E\n"+text if not text.is_empty() else ChapterPresentation.HELP))
	for item in ChapterRoomLayout.DATA[room_id].hotspots:
		add_hotspot(item[0],item[1],item[2])
	memory = Sprite2D.new()
	memory.name = "MemoryShadow"
	memory.visible = false
	memory.z_index = 22
	var soften := ShaderMaterial.new()
	soften.shader = preload("res://scenes/chapter1/memory_soften.gdshader")
	memory.material = soften
	add_child(memory)
	if room_id == "bedroom":
		var painting := Sprite2D.new()
		painting.texture = preload("res://assets/prologue/bigidea_after.png")
		painting.position = Vector2(375,170)
		painting.scale = Vector2(128,137) / painting.texture.get_size()
		painting.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(painting)
	elif room_id == "kitchen":
		var corrected_cup := Sprite2D.new()
		corrected_cup.name = "CorrectedCabbageCup"
		# This opaque patch corrects the background; it must stay behind actors.
		corrected_cup.z_index = -9
		corrected_cup.texture = preload("res://assets/chapter1/kitchen_cabbage_cup_edit.png")
		corrected_cup.region_enabled = true
		corrected_cup.region_rect = Rect2(1032,310,76,66)
		corrected_cup.centered = false
		corrected_cup.position = Vector2(1032,310)
		corrected_cup.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(corrected_cup)
		steam = AnimatedSprite2D.new()
		steam.sprite_frames = SpriteFrames.new()
		steam.sprite_frames.set_animation_speed("default",4)
		var sheet := preload("res://assets/chapter1/steam.png")
		for rect in SpriteAtlas.bounds(sheet,3,1):
			steam.sprite_frames.add_frame("default",SpriteAtlas.frame(sheet,rect))
		steam.position = Vector2(1120,293)
		steam.scale = Vector2.ONE*0.12
		steam.modulate.a = 0.48
		steam.visible = GameState.has_flag("coffee_made")
		add_child(steam)
		steam.play()
		hotspots.cup.set_enabled(GameState.has_flag("coffee_made"))
	elif room_id == "living":
		paper = Sprite2D.new()
		paper.name = "RedWrappingPaper"
		paper.texture = preload("res://assets/chapter1/gift_fragment_hd.png")
		paper.scale = Vector2.ONE*0.075
		paper.position = Vector2(710,875)
		paper.visible = GameState.has_flag("red_paper_spawned")
		$Depth.add_child(paper)
		add_hotspot("paper","红色包装纸",paper.position)
		hotspots.paper.set_enabled(paper.visible)
	add_child(preload("res://scenes/chapter1/exploration_light.gd").new())
	add_child(preload("res://scenes/chapter1/room_exits.gd").new())
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not busy:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		for id in hotspots:
			if clickable_rect(id).has_point(point) and can_reach(id,player.position):
				get_viewport().set_input_as_handled()
				interact(id)
				return
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
				await player.walk_to(Vector2(player.position.x,530))
				await player.walk_to(Vector2(1010,530))
				await dialogue.say("","你习惯性地伸手去拿自己的杯子。")
			GameState.set_flag("coffee_made")
			hotspots.cup.set_enabled(true)
		"trash":
			await say("trash")
			GameState.set_flag("trash_checked")
		"cup":
			await ui.inspect(preload("res://assets/chapter1/pig_cup_hd.png"))
			await say("cup_repeat" if GameState.has_flag("pig_cup_checked") else "cup")
			GameState.set_flag("pig_cup_checked")
			await check_kitchen_memory()
		"tableware":
			await ui.inspect(preload("res://assets/chapter1/cabbage_bowl_hd.png"),preload("res://assets/chapter1/pig_bowl_hd.png"))
			GameState.set_flag("double_tableware_checked")
			await check_kitchen_memory()
		"pillow":
			await ui.inspect(preload("res://assets/chapter1/pillow_plush_hd.png"))
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
			var rects := {"blanket":Rect2(740,320,140,265),"basket":Rect2(1200,805,180,135),"window":Rect2(550,70,300,225)}
			await ui.inspect(SpriteAtlas.frame($Background.texture,rects[id]))
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
	(memory.material as ShaderMaterial).set_shader_parameter("blur",[0.005,0.004,0.003][index-1])
	memory.position = $MemoryAnchor.position
	memory.scale = $MemoryAnchor.scale
	memory.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	memory.modulate = $MemoryAnchor.modulate
	memory.modulate.a = 0.0
	memory.visible = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(memory,"modulate:a",$MemoryAnchor.modulate.a,0.01 if test_mode else 0.65)
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
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(memory,"modulate:a",0,0.01 if test_mode else 0.75)
	await fade.finished
	memory.visible = false

func paper_arrives() -> void:
	if GameState.has_flag("red_paper_spawned"):
		return
	paper.position = Vector2(710,970)
	paper.rotation = -0.3
	paper.visible = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(paper,"position",Vector2(710,875),0.01 if test_mode else 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(paper,"rotation",0.15,0.01 if test_mode else 1.6)
	await tween.finished
	GameState.set_flag("red_paper_spawned")
	hotspots.paper.set_enabled(true)

func exit_options() -> Dictionary:
	match room_id:
		"bedroom": return {"kitchen":"去厨房"}
		"kitchen": return {"bedroom":"回卧室", "living":"去客厅"}
	return {"kitchen":"回厨房", "outside":"去屋外"}

func exit_locks() -> Dictionary:
	if room_id == "bedroom" and not GameState.has_flag("bedroom_memory_complete"):
		return {"kitchen":"先调查床头的画"}
	if room_id == "kitchen" and not GameState.has_flag("kitchen_memory_complete"):
		return {"living":"先调查猪猪杯和双人餐具"}
	if room_id == "living" and not GameState.has_flag("ch1_can_leave_home"):
		return {"outside":"先完成屋内调查"}
	return {}

func open_exit_menu(destination := "") -> void:
	if busy or routing: return
	lock(true)
	var options := exit_options()
	if not destination.is_empty(): options = {destination:options[destination]}
	options["cancel"] = "继续探索"
	var target := await ui.choose(options,exit_locks(),"要去哪里？")
	if target != "cancel": await travel(target)
	await get_tree().process_frame
	if not routing: lock(false)

func travel(target: String) -> void:
	# Recheck the story gate here as well as disabling the corresponding button.
	if not exit_options().has(target) or exit_locks().has(target): return
	if room_id == "bedroom" and not GameState.has_flag("bedroom_exit_intro_done"):
		await say("bedroom_exit")
		GameState.set_flag("bedroom_exit_intro_done")
	if target != "outside":
		go(target)
		return
	await say("leave")
	GameState.set_flag("ch1_completed")
	# The first departure cuts to the pig; returning home later must not replay her act.
	var pig_finished := GameState.has_flag("forest_slime_defeated")
	GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART if pig_finished else GameState.StoryPhase.LITTLE_PIG_DARK_FOREST
	last_route = "res://scenes/cabbage_act2/villa.tscn" if pig_finished else "res://scenes/chapter_02_dark_forest/forest_clearing.tscn"
	if route_on_exit:
		routing = true
		SceneRouter.change_scene(last_route)

func entry_position(target: String) -> Vector2:
	if target == "bedroom": return Vector2(1010,610)
	if target == "kitchen" and room_id == "living": return Vector2(1140,565)
	return ChapterRoomLayout.DATA[target].spawn

func go(target: String) -> void:
	last_route = "res://scenes/chapter1/%s.tscn" % target
	if route_on_exit:
		ChapterRoomLayout.pending_entry = {"room":target,"position":entry_position(target)}
		routing = true
		SceneRouter.change_scene(last_route)

# Click bounds are on the visible prop; reach zones are on surrounding walkable floor.
func clickable_rect(id: String) -> Rect2:
	var regions := {"trash":Rect2(1165,390,140,140),"painting":Rect2(300,90,150,155),"coffee":Rect2(1070,205,205,170),"cup":Rect2(970,312,70,65),"tableware":Rect2(530,590,390,305),"pillow":Rect2(610,355,160,150),"paper":Rect2(665,825,100,100)}
	return regions.get(id,Rect2(hotspots[id].position-Vector2(50,100),Vector2(100,130)))

func can_reach(id: String, feet: Vector2) -> bool:
	if not hotspots[id].enabled: return false
	if id == "cup": return Rect2(900,480,215,145).has_point(feet)
	if id == "coffee": return Rect2(1070,480,215,145).has_point(feet)
	if id == "tableware": return Rect2(345,500,740,470).has_point(feet)
	return feet.distance_to(hotspots[id].position) <= 155.0

func nearest_reachable(feet: Vector2) -> Interactable:
	var nearest: Interactable
	var distance := INF
	for id in hotspots:
		if can_reach(id,feet):
			var candidate := feet.distance_squared_to(hotspots[id].position)
			if candidate < distance:
				distance = candidate
				nearest = hotspots[id]
	return nearest
