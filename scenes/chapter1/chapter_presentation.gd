class_name ChapterPresentation
extends CanvasLayer

var heart: TextureRect
var prompt: Label
var room_name: Label
var shade: ColorRect
var companion: TextureRect
var closeup: TextureRect
var close_hint: Label
var menu: VBoxContainer
var inspecting := false
var choice := ""
var test_mode := false
var choosing := false
var heart_frames: Array[Rect2]
var heart_sheet := preload("res://assets/chapter1/heart.png")
const HELP := "WASD / 方向键\n移动\n\n靠近后点击物品\nE / 空格 调查\nF5 保存\n\n微光标记\n值得调查的物品\n\n走近门口微光处\n选择目的地"

func _ready() -> void:
	layer = 20
	heart_frames = SpriteAtlas.bounds(heart_sheet, 3, 3)
	heart = TextureRect.new()
	heart.position = Vector2(28,58)
	heart.size = Vector2(70,65)
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(heart)
	room_name = label(Vector2(28,22), 21)
	prompt = label(Vector2(28,145), 18)
	prompt.text = HELP
	prompt.add_theme_font_size_override("font_size",16)
	prompt.size.x = 110
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035,0.028,0.025,0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.visible = false
	add_child(shade)
	closeup = TextureRect.new()
	closeup.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	closeup.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	closeup.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	closeup.visible = false
	add_child(closeup)
	companion = closeup.duplicate()
	add_child(companion)
	close_hint = label(Vector2.ZERO,18)
	close_hint.text = "点击 / E / 空格　收起"
	close_hint.visible = false
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation",12)
	add_child(menu)
	update_heart(GameState.heart_progress)
	GameState.heart_changed.connect(update_heart)
	get_viewport().size_changed.connect(layout)
	layout()

func label(pos: Vector2, font_size: int) -> Label:
	var result := Label.new()
	result.position = pos
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",Color("f5e4c5"))
	result.add_theme_color_override("font_shadow_color",Color("30271f"))
	result.add_theme_constant_override("shadow_offset_x",1)
	result.add_theme_constant_override("shadow_offset_y",2)
	add_child(result)
	return result

func layout() -> void:
	var size := get_viewport().get_visible_rect().size
	closeup.position = Vector2(size.x * 0.2,30)
	closeup.size = Vector2(size.x * 0.6,size.y-110)
	if companion and companion.visible:
		closeup.position = Vector2(size.x*0.08,40)
		closeup.size = Vector2(size.x*0.41,size.y-130)
		companion.position = Vector2(size.x*0.51,40)
		companion.size = closeup.size
	close_hint.position = Vector2(size.x*0.5-70,size.y-56)
	menu.size.x = minf(480.0,size.x-48.0)
	menu.position = Vector2((size.x-menu.size.x)*0.5,maxf(24.0,(size.y-menu.get_combined_minimum_size().y)*0.5))

func update_heart(value: int) -> void:
	heart.texture = SpriteAtlas.frame(heart_sheet,heart_frames[clampi(value,0,3)])
	heart.pivot_offset = heart.size*0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(heart,"modulate",Color(1.2,1.08,1.02),0.15)
	tween.tween_property(heart,"scale",Vector2.ONE*1.07,0.15)
	tween.chain().tween_property(heart,"modulate",Color.WHITE,0.65)
	tween.tween_property(heart,"scale",Vector2.ONE,0.65)

func _input(event: InputEvent) -> void:
	if inspecting and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		inspecting = false
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if choosing and event.is_action_pressed("ui_cancel"):
		choice = "cancel"
		get_viewport().set_input_as_handled()
		return
	if inspecting and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		inspecting = false
		get_viewport().set_input_as_handled()

func inspect(texture: Texture2D, paired: Texture2D = null) -> void:
	show_closeup(texture)
	if paired:
		companion.texture = paired
		companion.visible = true
		layout()
	close_hint.visible = true
	inspecting = true
	if test_mode:
		await get_tree().process_frame
	else:
		while inspecting:
			await get_tree().process_frame
	inspecting = false
	hide_closeup()

func show_closeup(texture: Texture2D) -> void:
	companion.visible = false
	layout()
	shade.visible = true
	closeup.texture = texture
	closeup.visible = true

func hide_closeup() -> void:
	companion.visible = false
	shade.visible = false
	closeup.visible = false
	close_hint.visible = false

func flash(fast: bool, peak := 0.65) -> void:
	var light := ColorRect.new()
	light.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	light.color = Color(1.0,0.96,0.85,0)
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(light)
	var tween := create_tween()
	tween.tween_property(light,"color:a",peak,0.01 if fast else 0.16)
	tween.tween_property(light,"color:a",0.0,0.01 if fast else 0.6)
	await tween.finished
	light.queue_free()

func fade_from_black(fast: bool) -> void:
	var black := ColorRect.new()
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.color = Color(0.015,0.012,0.01,1)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	var tween := create_tween()
	tween.tween_property(black,"color:a",0,0.01 if fast else 1.1)
	await tween.finished
	black.queue_free()

func choose(options: Dictionary, disabled: Dictionary = {}, title := "") -> String:
	choice = ""
	choosing = true
	shade.visible = true
	if not title.is_empty():
		var heading := Label.new()
		heading.text = title
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heading.add_theme_font_size_override("font_size",26)
		menu.add_child(heading)
	var first: Button
	for key in options:
		var button := Button.new()
		button.name = key
		button.text = options[key]
		button.disabled = disabled.has(key)
		if button.disabled: button.text += "\n"+disabled[key]
		button.custom_minimum_size = Vector2(0,76 if button.disabled else 56)
		button.add_theme_font_size_override("font_size",20)
		button.add_theme_color_override("font_disabled_color",Color("aaa5a0"))
		button.pressed.connect(func(): choice = key)
		menu.add_child(button)
		if not first and not button.disabled: first = button
	if first: first.grab_focus()
	layout()
	while choice.is_empty():
		await get_tree().process_frame
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	choosing = false
	shade.visible = false
	return choice
