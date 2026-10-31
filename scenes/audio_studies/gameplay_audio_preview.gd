extends Control
## Four short audio scenes, using the same bank/gains as gameplay. No save writes.
const Bank=preload("res://systems/audio/gameplay_audio.gd")
const SECTIONS := [
 {"title":"森林 · 风、树叶与泥地脚步", "profile":"forest", "events":[[1.5,"step_1"],[1.95,"step_2"],[2.4,"step_3"],[3.5,"wood_pickup"],[5.0,"jump"],[5.65,"land"]]},
 {"title":"山洞 · 空气、水滴与礼物碎片", "profile":"cave", "events":[[1.5,"step_2"],[2.0,"step_1"],[3.0,"swing"],[3.2,"hit"],[4.5,"purify"],[6.1,"gift"]]},
 {"title":"苔根小径 · 弹跳、萤火与装备", "profile":"platform", "events":[[1.0,"jump"],[1.7,"land"],[2.4,"bounce"],[3.5,"chime"],[3.8,"chime"],[4.1,"chime"],[5.2,"crack"],[6.2,"equip"]]},
 {"title":"包装纸 · 拾起、拼合与完成", "profile":"", "events":[[.8,"paper"],[2.0,"paper"],[3.2,"paper"],[4.4,"paper"],[5.5,"complete"]]}]
var stage: Control
var title: Label
var status: Label
var meter: ProgressBar
var event_text: Label
var audio: Node
var section := 0
var section_time := 0.0
var total_time := 0.0
var paused := false
var finished := false
var next_event := 0

func _ready() -> void:
 var bg:=ColorRect.new()
 bg.color=Color("1d292b")
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 stage=Control.new()
 stage.size=Vector2(1152,648)
 add_child(stage)
 text("第五阶段 · 声音试听",Vector2(60,43),32,Color("eee5cb"))
 text("森林 → 山洞 → 苔根小径 → 包装纸  ·  32 秒",Vector2(62,95),19)
 for i in 4:
  var button:=Button.new()
  button.text=["1  森林","2  山洞","3  平台","4  包装纸"][i]
  button.position=Vector2(60+i*260,153)
  button.size=Vector2(248,52)
  button.pressed.connect(start_section.bind(i))
  stage.add_child(button)
 title=text("",Vector2(62,266),29,Color("f0d4a0"))
 event_text=text("",Vector2(65,329),21)
 meter=ProgressBar.new()
 meter.position=Vector2(62,406)
 meter.size=Vector2(1028,10)
 meter.show_percentage=false
 meter.max_value=32
 stage.add_child(meter)
 status=text("",Vector2(62,444),20)
 text("空格 / Esc 暂停  ·  R 重播  ·  M 静音  ·  F1 分类音量",Vector2(62,508),18)
 text("原创合成声音 · 无人声或实地录音 · 本预览不修改剧情与存档",Vector2(62,555),17,Color("a4b2ad"))
 get_viewport().size_changed.connect(layout)
 layout()
 start_section(0)

func text(value: String, at: Vector2, size: int, color:=Color("ced8d0")) -> Label:
 var label:=Label.new()
 label.text=value
 label.position=at
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",color)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 stage.add_child(label)
 return label

func layout() -> void:
 var size:=get_viewport_rect().size
 var factor:=minf(size.x/1152,size.y/648)
 stage.scale=Vector2.ONE*factor
 stage.position=(size-Vector2(1152,648)*factor)*.5

func start_section(index: int) -> void:
 if audio!=null: audio.free()
 audio=Bank.attach(self,SECTIONS[index].profile)
 section=index
 section_time=0
 total_time=index*8
 next_event=0
 paused=false
 finished=false
 title.text=SECTIONS[index].title
 event_text.text="环境声渐入" if index<3 else "纸张操作"
 refresh()

func refresh() -> void:
 meter.value=total_time
 status.text=("片段结束 · R 重播" if finished else ("已暂停" if paused else "正在播放"))+"     %.1f / 32 秒" % total_time

func _process(delta: float) -> void:
 if paused or finished: return
 section_time+=delta
 total_time=section*8+minf(section_time,8)
 var events: Array=SECTIONS[section].events
 while next_event<events.size() and section_time>=float(events[next_event][0]):
  var kind: String=events[next_event][1]
  audio.cue(kind)
  event_text.text={"wood_pickup":"捡起树枝", "gift":"找回礼物碎片", "paper":"纸张轻响", "complete":"拼合完成", "equip":"装备武器", "jump":"起跳", "land":"落地", "bounce":"蘑菇弹跳", "chime":"萤火", "crack":"石板裂响", "swing":"挥击", "hit":"击中", "purify":"净化"}.get(kind,"泥地脚步")
  next_event+=1
 if section_time>=7.7: audio.exiting=true
 if section_time>=8:
  if section<3: start_section(section+1)
  else:
   total_time=32
   finished=true
   audio.set_audio_paused(true)
 refresh()

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]: start_section(event.keycode-KEY_1)
 elif event.keycode==KEY_R: start_section(0)
 elif event.keycode in [KEY_SPACE,KEY_ESCAPE]:
  paused=not paused
  audio.set_audio_paused(paused or finished)
  refresh()
 else: return
 get_viewport().set_input_as_handled()
