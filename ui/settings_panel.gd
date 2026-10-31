extends PanelContainer
var manager: Node
var sliders: Dictionary = {}
var values: Dictionary = {}
var mute: CheckBox
var status: Label
var retry: Button
var tabs: TabContainer
var story_speed: OptionButton

func _ready() -> void:
	name = "SettingsPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("201e29")
	style.border_color = Color("ad8c59")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(side,24)
	add_theme_stylebox_override("panel",style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	add_child(column)
	_label(column,"设置与操作",26)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	var sound := _page("声音")
	mute = CheckBox.new()
	mute.text = "全部声音静音（M）"
	mute.custom_minimum_size.y = 42
	sound.add_child(mute)
	mute.toggled.connect(manager.set_muted)
	for entry in [["Music","音乐"],["Effects","音效"],["Ambience","环境声"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		sound.add_child(row)
		_label(row,entry[1],18).custom_minimum_size.x = 72
		var slider := HSlider.new()
		slider.name = entry[0]+"Volume"
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 5
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y = 40
		slider.tooltip_text = entry[1]+"音量；左右方向键调整"
		row.add_child(slider)
		sliders[entry[0]] = slider
		values[entry[0]] = _label(row,"100%",18)
		values[entry[0]].custom_minimum_size.x = 54
		slider.value_changed.connect(func(value): manager.set_volume(entry[0],value/100.0))
	_label(sound,"调整会即时生效，并在下次启动时保留。",16)
	status = _label(column,"",16)
	retry = _button(column,"重试保存设置",func(): manager.save_preferences(); refresh())
	_button(sound,"恢复默认音量",manager.restore_defaults)
	var controls := _page("操作说明")
	var scene := get_tree().current_scene
	_label(controls,manager.HINTS.for_scene(scene.scene_file_path if scene else ""),18)
	_label(controls,manager.HINTS.COMMON,16)
	var story := _page("剧情")
	_label(story,"剧情播放速度",22)
	story_speed = OptionButton.new()
	story_speed.name = "StorySpeed"
	story_speed.add_item("1× · 原速")
	story_speed.add_item("1.5× · 更紧凑（默认）")
	story_speed.custom_minimum_size.y = 44
	story.add_child(story_speed)
	story_speed.item_selected.connect(func(index): manager.set_story_speed(1.0 if index == 0 else 1.5))
	_label(story,"加快自动演出、回忆和转场；关键情绪停顿保留。\n对白仍可按 E / 空格继续。开场用空格跳到下一句，Esc / P 暂停阅读。\n移动、跳跃和战斗保持原速，音乐保持正常音高。",18)
	_label(story,"切换即时生效，并在下次启动时保留。",16)
	_button(column,"返回 · Esc / F1",manager.close_panel)
	manager.changed.connect(refresh)
	get_viewport().size_changed.connect(layout)
	# Wrapped labels settle after the first container layout. Refit after that
	# minimum changes so a newly opened tab cannot leave the panel off-screen.
	minimum_size_changed.connect(func(): layout.call_deferred())
	refresh()
	layout()
	mute.grab_focus()

func _page(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	tabs.add_child(scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	return body

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("f5e4c5"))
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func refresh() -> void:
	story_speed.select(0 if manager.story_speed == 1.0 else 1)
	mute.set_pressed_no_signal(manager.muted)
	mute.text = "全部声音：已静音（M 恢复）" if manager.muted else "全部声音：已开启（M 静音）"
	for bus in sliders:
		sliders[bus].set_value_no_signal(manager.volumes[bus]*100)
		values[bus].text = "%d%%" % roundi(manager.volumes[bus]*100)
	status.text = "设置保存失败；当前调整仍生效，可重试。" if manager.persistence_error else "设置即时生效并跨章节保留"
	retry.visible = manager.persistence_error

func layout() -> void:
	var extent := get_viewport_rect().size
	size = Vector2(minf(620,extent.x-32),minf(560,extent.y-32))
	position = (extent-size)*0.5
