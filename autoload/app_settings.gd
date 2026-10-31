extends Node
## Preferences live separately from story progress. Tests override the path via env.
signal changed
signal panel_closed
const HINTS = preload("res://ui/control_hints.gd")
const PANEL = preload("res://ui/settings_panel.gd")
const DEFAULT_PATH := "user://piggy_manor_settings.cfg"
var settings_path := DEFAULT_PATH
var muted := false
var volumes := {"Music":1.0, "Effects":1.0, "Ambience":1.0}
var story_speed := 1.5
var story_tweens: Array[Tween] = []
var persistence_error := false
var overlay: CanvasLayer
var panel: Control
var previous_pause := false
var previous_focus: WeakRef
var paused_audio: Array[Dictionary] = []
var toast_layer: CanvasLayer
var toast: PanelContainer
var toast_text: Label
var toast_time := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var override := OS.get_environment("PIGGY_SETTINGS_PATH")
	if not override.is_empty(): settings_path = override
	for bus in volumes:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus), "Master")
	load_preferences()
	_build_toast()
	SaveManager.save_completed.connect(_save_completed)
	get_viewport().size_changed.connect(_layout_toast)

func load_preferences() -> void:
	muted = false
	story_speed = 1.5
	volumes = {"Music":1.0, "Effects":1.0, "Ambience":1.0}
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		var speed: Variant = config.get_value("story", "speed", 1.5)
		if (speed is float or speed is int) and float(speed) in [1.0, 1.5]: story_speed = float(speed)
		var value: Variant = config.get_value("audio", "muted", false)
		if value is bool: muted = value
		for bus in volumes:
			value = config.get_value("audio", bus, 1.0)
			if (value is float or value is int) and is_finite(float(value)):
				volumes[bus] = clampf(float(value), 0.0, 1.0)
	_apply()
	_update_story_tweens()
	changed.emit()

func save_preferences() -> bool:
	var config := ConfigFile.new()
	config.set_value("audio", "muted", muted)
	config.set_value("story", "speed", story_speed)
	for bus in volumes: config.set_value("audio", bus, volumes[bus])
	var temp := settings_path + ".tmp"
	var error := config.save(temp)
	if error == OK: error = DirAccess.rename_absolute(temp, settings_path)
	persistence_error = error != OK
	if persistence_error: DirAccess.remove_absolute(temp)
	return not persistence_error

func _apply() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	for bus in volumes:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_mute(index, muted or volumes[bus] == 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, volumes[bus])))

func set_muted(value: bool) -> void:
	muted = value
	_apply()
	save_preferences()
	changed.emit()

func set_volume(bus: String, value: float) -> void:
	if not volumes.has(bus) or not is_finite(value): return
	volumes[bus] = clampf(value, 0.0, 1.0)
	_apply()
	save_preferences()
	changed.emit()

func restore_defaults() -> void:
	muted = false
	for bus in volumes: volumes[bus] = 1.0
	_apply()
	save_preferences()
	changed.emit()

func set_story_speed(value: float) -> void:
	if value not in [1.0, 1.5]: return
	story_speed = value
	_update_story_tweens()
	save_preferences()
	changed.emit()

# Only explicitly registered story animations use this clock. Physics, player
# input and audio playback retain their normal time and pitch.
func story_tween(host: Node) -> Tween:
	var tween := host.create_tween().set_speed_scale(story_speed)
	story_tweens.append(tween)
	return tween

func story_wait(host: Node, seconds: float) -> Tween:
	var tween := story_tween(host)
	tween.tween_interval(seconds)
	return tween

func _update_story_tweens() -> void:
	for tween in story_tweens:
		if tween.is_valid(): tween.set_speed_scale(story_speed)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key: int = event.physical_keycode if event.physical_keycode else event.keycode
	if key == KEY_F1:
		if is_instance_valid(overlay): close_panel()
		else: open_panel()
		get_viewport().set_input_as_handled()
	elif key == KEY_ESCAPE and is_instance_valid(overlay):
		close_panel()
		get_viewport().set_input_as_handled()
	elif key == KEY_M:
		set_muted(not muted)
		notify("全部声音已静音 · M 恢复" if muted else "声音已恢复 · M 静音")
		if persistence_error: notify("声音已调整，但设置保存失败 · F1 打开设置重试", 8)
		get_viewport().set_input_as_handled()

func open_panel() -> void:
	if is_instance_valid(overlay) or SceneRouter.is_busy(): return
	previous_pause = get_tree().paused
	var focus := get_viewport().gui_get_focus_owner()
	previous_focus = weakref(focus) if focus else null
	paused_audio.clear()
	# The persistent score processes while paused; freeze it without losing its prior state.
	for player in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		paused_audio.append({"node":weakref(player), "paused":player.stream_paused})
		player.stream_paused = true
	get_tree().paused = true
	overlay = CanvasLayer.new()
	overlay.name = "SettingsOverlay"
	overlay.layer = 120
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025,0.025,0.035,0.88)
	overlay.add_child(shade)
	panel = PANEL.new()
	panel.manager = self
	overlay.add_child(panel)

func close_panel() -> void:
	if not is_instance_valid(overlay): return
	# Restore only the pause owned by this overlay; an underlying pause menu stays paused.
	overlay.queue_free()
	overlay = null
	panel = null
	for item in paused_audio:
		var player = item.node.get_ref()
		if is_instance_valid(player): player.stream_paused = item.paused
	paused_audio.clear()
	get_tree().paused = previous_pause
	if previous_focus and is_instance_valid(previous_focus.get_ref()): previous_focus.get_ref().grab_focus()
	panel_closed.emit()

func _build_toast() -> void:
	toast_layer = CanvasLayer.new()
	toast_layer.layer = 115
	add_child(toast_layer)
	toast = PanelContainer.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04,0.05,0.065,0.96)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	toast.add_theme_stylebox_override("panel", style)
	toast_layer.add_child(toast)
	toast_text = Label.new()
	toast_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_text.add_theme_font_size_override("font_size", 18)
	toast_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(toast_text)
	toast.hide()
	_layout_toast()

func _layout_toast() -> void:
	if not is_instance_valid(toast): return
	var extent := get_viewport().get_visible_rect().size
	toast.size = Vector2(minf(420,extent.x-40),0)
	toast.position = Vector2(extent.x-toast.size.x-20,20)

func notify(message: String, seconds := 3.0) -> void:
	toast_text.text = message
	toast_time = seconds
	toast.show()
	_layout_toast()

func _save_completed(success: bool, notify_success: bool) -> void:
	if success and not notify_success: return
	var label := "测试进度已保存 · 正式存档不变" if SaveManager.preview_mode else "进度已保存"
	notify(label if success else "保存失败 · 请保留游戏窗口，在暂停菜单中重试保存", 3.0 if success else 8.0)

func _process(delta: float) -> void:
	for i in range(story_tweens.size()-1, -1, -1):
		if not story_tweens[i].is_valid(): story_tweens.remove_at(i)
	if toast_time > 0 and not is_instance_valid(overlay):
		toast_time -= delta
		if toast_time <= 0: toast.hide()
