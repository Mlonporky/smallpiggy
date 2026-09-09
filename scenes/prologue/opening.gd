extends Node2D
## Illustrated cinematic: a deterministic clock, no orphaned async timers.
signal shot_changed(id: String)
signal completed

const DESIGN_SIZE := Vector2(1152, 648)
const CHAPTER := "res://scenes/chapter1/bedroom.tscn"
const FX_SCRIPT = preload("res://scenes/prologue/story_effects.gd")
const PLATE_SHADER = preload("res://scenes/prologue/plate_transition.gdshader")
@export var autoplay := true
@export var route_on_finish := true
var shots: Array = []
var textures: Dictionary = {}
var shot_index := 0
var shot_time := 0.0
var paused := false
var finished := false
var muted := false
var transition_progress := 0.0
var stage: Node2D
var picture: TextureRect
var effects: Node2D
var shade: ColorRect
var caption: Label
var speaker: Label
var location_label: Label
var title_label: Label
var audio_player: AudioStreamPlayer
var plate_material: ShaderMaterial
var _cue_index := -1
var _last_bell := -1
var painting_before: Polygon2D
var painting_after: Polygon2D
var painting_blend := 0.0
var crystal_vision: TextureRect

func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/opening_v2.json"))
	if not parsed is Dictionary or not parsed.get("shots") is Array:
		push_error("Opening timeline is missing or invalid")
		return
	shots = parsed["shots"]
	for shot in shots:
		for key in ["image", "after"]:
			if shot.has(key) and not textures.has(shot[key]):
				textures[shot[key]] = load("res://assets/prologue/" + str(shot[key]) + ".png")
	_build_stage()
	get_viewport().size_changed.connect(_fit_stage)
	_fit_stage()
	GameState.story_phase = GameState.StoryPhase.PROLOGUE
	set_shot(0)
	set_process(autoplay)

func _build_stage() -> void:
	stage = Node2D.new()
	stage.name = "Stage"
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(stage)
	picture = TextureRect.new()
	picture.name = "Picture"
	picture.size = DESIGN_SIZE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(picture)
	# Original user artwork is texture-mapped onto the existing bedroom frame.
	painting_before = _painting("BigIdeaBefore", "res://assets/prologue/bigidea_before.png")
	painting_after = _painting("BigIdeaAfter", "res://assets/prologue/bigidea_after.png")
	crystal_vision = TextureRect.new()
	crystal_vision.name = "CrystalVision"
	crystal_vision.position = Vector2(409, 229)
	crystal_vision.size = Vector2(119, 120)
	crystal_vision.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crystal_vision.texture = textures["gift_wrapping"]
	crystal_vision.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vision_material := ShaderMaterial.new()
	vision_material.shader = preload("res://scenes/prologue/crystal_vision.gdshader")
	crystal_vision.material = vision_material
	picture.add_child(crystal_vision)
	plate_material = ShaderMaterial.new()
	plate_material.shader = PLATE_SHADER
	effects = Node2D.new()
	effects.name = "StoryEffects"
	effects.set_script(FX_SCRIPT)
	stage.add_child(effects)
	shade = ColorRect.new()
	shade.name = "TransitionShade"
	shade.size = DESIGN_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(shade)
	var bar := ColorRect.new()
	bar.position = Vector2(0, 536)
	bar.size = Vector2(1152, 112)
	bar.color = Color(0.025, 0.02, 0.045, 0.88)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bar)
	speaker = _label("Speaker", Vector2(70, 550), Vector2(1012, 24), 17, Color("f1cd98"))
	caption = _label("Caption", Vector2(70, 580), Vector2(1012, 56), 23, Color("fff4e3"))
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	location_label = _label("Location", Vector2(36, 25), Vector2(640, 28), 18, Color("efddc8"))
	title_label = _label("Title", Vector2(120, 208), Vector2(912, 180), 42, Color("ffe3ae"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var skip := Button.new()
	skip.name = "SkipButton"
	skip.position = Vector2(984, 20)
	skip.size = Vector2(138, 36)
	skip.text = "跳过开场  Esc"
	skip.pressed.connect(skip_to_chapter)
	stage.add_child(skip)
	_label("Hint", Vector2(700, 62), Vector2(425, 22), 13, Color("d7cfdb")).text = "空格 下一句  ·  P 暂停  ·  R 重播  ·  M 静音"
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "AlarmAudio"
	audio_player.volume_db = -20
	add_child(audio_player)

func _painting(node_name: String, path: String) -> Polygon2D:
	var art := Polygon2D.new()
	art.name = node_name
	art.texture = load(path)
	art.polygon = PackedVector2Array([Vector2(274, -82), Vector2(470, -96), Vector2(486, 156), Vector2(274, 175)])
	# Map just the wooden frame, excluding the source image's white margin.
	var dimensions := art.texture.get_size()
	art.uv = PackedVector2Array([Vector2(0.086, 0.033) * dimensions, Vector2(0.912, 0.033) * dimensions, Vector2(0.912, 0.95) * dimensions, Vector2(0.086, 0.95) * dimensions])
	art.color = Color(0.77, 0.67, 0.57, 1.0)
	picture.add_child(art)
	return art

func _label(node_name: String, pos: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = pos
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.03, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	stage.add_child(label)
	return label

func _fit_stage() -> void:
	var window := get_viewport_rect().size
	var factor := minf(window.x / DESIGN_SIZE.x, window.y / DESIGN_SIZE.y)
	stage.scale = Vector2.ONE * factor
	stage.position = (window - DESIGN_SIZE * factor) * 0.5

func _process(delta: float) -> void:
	if not paused and not finished and not shots.is_empty():
		advance(delta)

func advance(delta: float) -> void:
	if finished:
		return
	shot_time += maxf(delta, 0.0)
	while shot_time >= float(shots[shot_index]["duration"]):
		var remainder := shot_time - float(shots[shot_index]["duration"])
		if shot_index + 1 >= shots.size():
			_finish()
			return
		set_shot(shot_index + 1)
		shot_time = remainder
	_render_shot()

func set_shot(index: int, time := 0.0) -> void:
	shot_index = clampi(index, 0, shots.size() - 1)
	shot_time = clampf(time, 0.0, float(shots[shot_index]["duration"]))
	_cue_index = -1
	_last_bell = -1
	var shot: Dictionary = shots[shot_index]
	picture.texture = textures[shot["image"]]
	picture.material = null
	if shot.has("after"):
		picture.material = plate_material
		plate_material.set_shader_parameter("after_image", textures[shot["after"]])
		var focus: Array = shot.get("focus", [0.31, 0.46])
		var radius: Array = shot.get("radius", [0.14, 0.16])
		plate_material.set_shader_parameter("focus", Vector2(focus[0], focus[1]))
		plate_material.set_shader_parameter("radius", Vector2(radius[0], radius[1]))
		var focus2: Array = shot.get("focus2", [-10.0, -10.0])
		var radius2: Array = shot.get("radius2", [0.01, 0.01])
		plate_material.set_shader_parameter("focus2", Vector2(focus2[0], focus2[1]))
		plate_material.set_shader_parameter("radius2", Vector2(radius2[0], radius2[1]))
	_render_shot()
	shot_changed.emit(str(shot["id"]))

func _render_shot() -> void:
	var shot: Dictionary = shots[shot_index]
	var duration := float(shot["duration"])
	var phase := clampf(shot_time / duration, 0.0, 1.0)
	var zoom := lerpf(float(shot.get("zoom_start", 1.0)), float(shot.get("zoom_end", 1.035)), smoothstep(0.0, 1.0, phase))
	var anchor: Array = shot.get("anchor", [0.5, 0.5])
	var pivot := Vector2(anchor[0], anchor[1]) * DESIGN_SIZE
	picture.scale = Vector2.ONE * zoom
	picture.position = pivot * (1.0 - zoom)
	transition_progress = smoothstep(float(shot.get("change_start", 2.0)), float(shot.get("change_end", 5.0)), shot_time) if shot.has("after") else 0.0
	plate_material.set_shader_parameter("progress", transition_progress)
	var painting_mode := str(shot.get("painting", ""))
	painting_before.visible = not painting_mode.is_empty()
	painting_after.visible = not painting_mode.is_empty()
	painting_blend = transition_progress if painting_mode == "changing" else (1.0 if painting_mode == "after" else 0.0)
	painting_after.modulate.a = painting_blend
	crystal_vision.visible = shot["id"] == "discovery"
	crystal_vision.modulate.a = smoothstep(0.8, 2.4, shot_time)
	effects.position = picture.position
	effects.scale = picture.scale
	effects.set("shot_id", str(shot["id"]))
	effects.set("clock", shot_time)
	effects.set("change", transition_progress)
	effects.queue_redraw()
	var fade_in := 1.0 - smoothstep(0.0, 0.65, shot_time)
	var fade_out := smoothstep(duration - 0.55, duration, shot_time)
	shade.color = Color(0.025, 0.02, 0.04, maxf(fade_in, fade_out))
	location_label.text = str(shot.get("location", "")) + ("  ·  已暂停" if paused else "")
	title_label.text = "猪 猪 山 庄\n—— 被遗忘的快乐 ——" if shot["id"] == "title" else ""
	title_label.modulate.a = smoothstep(0.5, 2.0, shot_time)
	var cues: Array = shot.get("cues", [])
	var selected := -1
	for i in cues.size():
		if shot_time >= float(cues[i][0]):
			selected = i
	if selected != _cue_index:
		_cue_index = selected
		caption.text = str(cues[selected][2]) if selected >= 0 else ""
		speaker.text = str(cues[selected][1]) if selected >= 0 else ""
	if shot["id"] == "alarm" and not paused and not muted:
		var bell := int(shot_time / 0.7)
		if bell != _last_bell:
			_last_bell = bell
			_play_bell(660.0 + bell * 55.0)

func _play_bell(frequency: float) -> void:
	var bytes := PackedByteArray()
	bytes.resize(6615 * 2)
	for i in 6615:
		var t := float(i) / 22050.0
		var envelope := minf(t / 0.008, 1.0) * exp(-t * 16.0)
		bytes.encode_s16(i * 2, int(sin(TAU * frequency * t) * envelope * 18000.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	sound.data = bytes
	audio_player.stream = sound
	audio_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		skip_to_chapter()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_P:
				paused = not paused
				audio_player.stream_paused = paused
				_render_shot()
			KEY_M:
				muted = not muted
				audio_player.volume_db = -80 if muted else -20
			KEY_R:
				if not finished:
					paused = false
					audio_player.stop()
					audio_player.stream_paused = false
					set_shot(0)
			KEY_SPACE:
				# Never skip transformation/teleport visual beats with dialogue input.
				var cues: Array = shots[shot_index].get("cues", [])
				if not paused and not shots[shot_index].has("after") and _cue_index + 1 < cues.size():
					shot_time = float(cues[_cue_index + 1][0])
					_render_shot()

func skip_to_chapter() -> void:
	_finish()

func _finish() -> void:
	if finished:
		return
	finished = true
	set_process(false)
	audio_player.stop()
	GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART
	GameState.cabbage_emotional_state = GameState.CabbageEmotionalState.HOLLOW
	GameState.set_flag("prologue_completed")
	GameState.set_flag("cabbage_forgot_pig")
	GameState.set_flag("pig_teleported")
	GameState.set_flag("gift_teleported")
	GameState.set_flag("gift_torn_by_wizard")
	GameState.set_flag("gift_fragments_scattered")
	completed.emit()
	if route_on_finish:
		SceneRouter.change_scene(CHAPTER, 0.4)
