extends Node2D
## Shared presentation only for the two new Act II scenes.
signal menu_chosen(key: String)
const MENU := "res://scenes/bootstrap/main.tscn"
const PLAYER = preload("res://actors/shared/player.tscn")
const PIG_SCRIPT = preload("res://scenes/chapter2/pig.gd")
var player: PiggyPlayer
var dialogue: DialogueUI
var ui: GameUI
var world: Node2D
var camera: Camera2D
var curtain: ColorRect
var title: Label
var busy := false
var allow_save := true

func build(background: Texture2D, spawn: Vector2) -> void:
	var art := Sprite2D.new()
	art.texture = background
	art.centered = false
	add_child(art)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	player = PLAYER.instantiate()
	player.set_script(PIG_SCRIPT)
	player.position = spawn
	world.add_child(player)
	player.get_node("Camera2D").enabled = false
	camera = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = Vector2(724,543)
	add_child(camera)
	fit_camera()
	get_viewport().size_changed.connect(fit_camera)
	ui = preload("res://ui/game_ui.tscn").instantiate()
	add_child(ui)
	dialogue = preload("res://systems/dialogue/dialogue_ui.tscn").instantiate()
	add_child(dialogue)
	player.prompt_changed.connect(ui.set_prompt)
	ui.set_heart_visible(false)
	ui.set_objective("")
	ui.status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ui.status.offset_top = -105
	ui.status.offset_bottom = -65
	ui.status.add_theme_font_size_override("font_size",17)
	ui.objective.add_theme_font_size_override("font_size",18)
	ui.prompt.get_parent().visible = false
	player.prompt_changed.connect(func(text: String): ui.prompt.get_parent().visible = not text.is_empty() and not busy)
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	curtain = ColorRect.new()
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.color = Color(0.025,0.018,0.05,0)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(curtain)
	title = Label.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(title)
	# TODO: Missing asset — no forest wind, branch crack or impact audio supplied.
	var ambient := AudioStreamPlayer.new()
	ambient.name = "ForestAmbient"
	add_child(ambient)

func fit_camera() -> void:
	var size := get_viewport_rect().size
	camera.zoom = Vector2.ONE * minf(size.x/1448.0, size.y/1086.0)

func wall(points: PackedVector2Array) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionPolygon2D.new()
	shape.polygon = points
	body.add_child(shape)
	add_child(body)
	return body

func rectangle(rect: Rect2) -> StaticBody2D:
	return wall(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))

func hotspot(at: Vector2, prompt: String, callback: Callable, texture: Texture2D = null) -> Interactable:
	var item := Interactable.new()
	item.position = at
	item.prompt_text = prompt
	item.collision_layer = 4
	item.collision_mask = 0
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 45
	collision.shape = circle
	item.add_child(collision)
	if texture:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2.ONE * 65.0 / maxf(texture.get_width(),texture.get_height())
		item.add_child(sprite)
	item.interacted.connect(func(_actor: Node):
		if not busy: callback.call())
	world.add_child(item)
	return item

func trigger(rect: Rect2, callback: Callable) -> void:
	var area := Area2D.new()
	area.position = rect.get_center()
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(func(body: Node):
		if body == player and not busy: callback.call())
	add_child(area)

func lock(value: bool) -> void:
	busy = value
	player.set_input_enabled(not value)
	ui.set_prompt("")
	ui.prompt.get_parent().visible = false
	if not value: player._nearest_interactable = null

func beat(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func fade(alpha: float, duration := 0.6) -> void:
	var tween := create_tween()
	tween.tween_property(curtain,"color:a",alpha,duration)
	await tween.finished

func checkpoint() -> void:
	if allow_save: SaveManager.save_game(scene_file_path)

func shake() -> void:
	for i in 6:
		player.sprite.offset.x = 3.0 if i%2==0 else -3.0
		await beat(0.06)
	player.sprite.offset = Vector2.ZERO

## Esc freezes the whole forest, the slime included, and offers Act I's choice.
func open_pause_menu() -> void:
	if SceneRouter.is_busy(): return
	lock(true)
	get_tree().paused = true
	var layer := CanvasLayer.new()
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035,0.028,0.025,0.88)
	layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 420
	column.add_theme_constant_override("separation",12)
	center.add_child(column)
	# Esc again simply resumes.
	var resume := Shortcut.new()
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	resume.events = [cancel]
	var options := {"stay":"继续探索", "save":"保存并回主菜单"}
	for key in options:
		var button := Button.new()
		button.name = key
		button.text = options[key]
		button.custom_minimum_size.y = 56
		button.add_theme_font_size_override("font_size",20)
		button.pressed.connect(func(): menu_chosen.emit(key))
		if key == "stay":
			button.shortcut = resume
			button.shortcut_in_tooltip = false
		column.add_child(button)
	column.get_child(0).grab_focus()
	var choice: String = await menu_chosen
	layer.queue_free()
	get_tree().paused = false
	if choice == "save":
		if not allow_save or SaveManager.save_game(scene_file_path):
			# Keep the forest still while the screen fades out.
			world.process_mode = Node.PROCESS_MODE_DISABLED
			SceneRouter.change_scene(MENU)
			return
		ui.set_status("保存失败，请再试一次。",3)
	lock(false)

func _unhandled_input(event: InputEvent) -> void:
	if busy: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		open_pause_menu()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for item in world.get_children():
			if item is Interactable and item.enabled and player.position.distance_to(item.position)<140 and get_global_mouse_position().distance_to(item.position)<65:
				item.interact(player)
				get_viewport().set_input_as_handled()
				break
