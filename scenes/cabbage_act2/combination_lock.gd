extends Control
## Illustrated lock with separately moving shackle and live numeric windows.
signal finished(accepted: bool)
const DESIGN := Vector2(640,690)
var stage: Control
var heading: Label
var assembly: Control
var shackle: Node2D
var body: TextureRect
var code_input: LineEdit
var status: Label
var submit_button: Button
var cancel_button: Button
var wheels: Array[Label] = []
var digit_buttons: Array[Button] = []
var digit_tweens: Array[Tween] = []
var input_text := ""
var animating := false
var opened := false
var resolved := false
var motion: Tween
var audio: AudioStreamPlayer

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_STOP
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 stage = Control.new()
 stage.size = DESIGN
 add_child(stage)
 heading = label("蘑菇屋 · 密码锁",Rect2(0,0,640,40),25)
 assembly = Control.new()
 assembly.size = Vector2(640,480)
 stage.add_child(assembly)
 shackle = Node2D.new()
 shackle.position = Vector2(220,195)
 assembly.add_child(shackle)
 # Gold strokes remain independent from the painted body so the bow can open.
 var path := PackedVector2Array([Vector2(0,0),Vector2(0,-30)])
 for i in 33:
  var angle := PI + PI*float(i)/32.0
  path.append(Vector2(98,-30)+Vector2(cos(angle)*98,sin(angle)*80))
 path.append(Vector2(196,0))
 for spec in [[35.0,Color("51391d")],[29.0,Color("ad7736")],[22.0,Color("e7b964")],[10.0,Color("f8d995")]]:
  var line := Line2D.new()
  line.points = path
  line.width = spec[0]
  line.default_color = spec[1]
  line.antialiased = true
  line.begin_cap_mode = Line2D.LINE_CAP_ROUND
  line.end_cap_mode = Line2D.LINE_CAP_ROUND
  shackle.add_child(line)
 body = TextureRect.new()
 var atlas := AtlasTexture.new()
 atlas.atlas = preload("res://assets/cabbage_act2/combination_lock_body_v1.png")
 atlas.region = Rect2(62,178,1136,906)
 body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 body.texture = atlas
 body.position = Vector2(130,168)
 body.size = Vector2(380,310)
 body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 body.mouse_filter = Control.MOUSE_FILTER_IGNORE
 assembly.add_child(body)
 for i in 4:
  var wheel := Label.new()
  wheel.position = Vector2(173+i*74,310)
  wheel.size = Vector2(70,66)
  wheel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  wheel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  wheel.text = "·"
  wheel.add_theme_font_size_override("font_size",40)
  wheel.add_theme_color_override("font_color",Color("fff0c9"))
  var style := StyleBoxFlat.new()
  style.bg_color = Color("382b1c")
  style.border_color = Color("b69254")
  style.set_border_width_all(2)
  style.set_corner_radius_all(7)
  wheel.add_theme_stylebox_override("normal",style)
  assembly.add_child(wheel)
  wheels.append(wheel)
  digit_tweens.append(null)
 code_input = LineEdit.new()
 code_input.position = Vector2(173,310)
 code_input.size = Vector2(292,66)
 code_input.max_length = 4
 code_input.keep_editing_on_text_submit = true
 code_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
 # Keep a genuine editable control for keyboard, paste, selection and backspace.
 code_input.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
 code_input.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 code_input.add_theme_color_override("font_color",Color.TRANSPARENT)
 code_input.add_theme_color_override("font_selected_color",Color.TRANSPARENT)
 code_input.add_theme_color_override("selection_color",Color.TRANSPARENT)
 code_input.add_theme_color_override("caret_color",Color.TRANSPARENT)
 code_input.self_modulate.a = 0.0
 code_input.mouse_default_cursor_shape = Control.CURSOR_IBEAM
 assembly.add_child(code_input)
 code_input.text_changed.connect(update_digits)
 code_input.text_submitted.connect(submit)
 status = label("输入四位数字",Rect2(0,480,640,32),20)
 label("键盘输入 / 点击数字 · 退格删除 · 回车开锁",Rect2(0,516,640,30),16)
 for i in 10:
  var digit := (i+1)%10
  var button := button_at(str(digit),Rect2(150+(i%5)*68,553+(i/5)*43,60,37))
  button.pressed.connect(func():
   if not animating:
    if code_input.has_selection():
     var from := code_input.get_selection_from_column()
     code_input.delete_text(from,code_input.get_selection_to_column())
     code_input.caret_column = from
    code_input.insert_text_at_caret(str(digit))
    update_digits(code_input.text)
    code_input.grab_focus())
  digit_buttons.append(button)
 submit_button = button_at("打开",Rect2(210,646,140,40))
 submit_button.pressed.connect(submit)
 cancel_button = button_at("返回",Rect2(360,646,120,40))
 cancel_button.pressed.connect(cancel)
 var backspace := button_at("删",Rect2(150,646,50,40))
 backspace.pressed.connect(func():
  if not animating:
   code_input.text = code_input.text.left(maxi(0,code_input.text.length()-1))
   code_input.caret_column = code_input.text.length()
   update_digits(code_input.text)
   code_input.grab_focus())
 digit_buttons.append(backspace)
 audio = AudioStreamPlayer.new()
 add_child(audio)
 get_viewport().size_changed.connect(layout)
 layout()
 stage.modulate.a = 0
 create_tween().tween_property(stage,"modulate:a",1.0,0.25)
 code_input.grab_focus()

func layout() -> void:
 var viewport := get_viewport().get_visible_rect().size
 var factor := minf(1.0,minf((viewport.x-32)/DESIGN.x,(viewport.y-24)/DESIGN.y))
 stage.scale = Vector2.ONE*factor
 stage.position = (viewport-DESIGN*factor)*0.5

func label(text: String, rect: Rect2, font_size: int) -> Label:
 var node := Label.new()
 node.text = text
 node.position = rect.position
 node.size = rect.size
 node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",Color("f9e7bd"))
 stage.add_child(node)
 return node

func button_at(text: String, rect: Rect2) -> Button:
 var button := Button.new()
 button.text = text
 button.position = rect.position
 button.size = rect.size
 button.add_theme_font_size_override("font_size",20)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("453322")
 style.border_color = Color("ad8246")
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 button.add_theme_stylebox_override("normal",style)
 var hover := style.duplicate()
 hover.bg_color = Color("705235")
 button.add_theme_stylebox_override("hover",hover)
 stage.add_child(button)
 return button

func update_digits(text: String) -> void:
 var numeric := ""
 for ch in text:
  if ch >= "0" and ch <= "9": numeric += ch
 numeric = numeric.left(4)
 if numeric != code_input.text:
  code_input.text = numeric
  code_input.caret_column = numeric.length()
 for i in 4:
  var next := numeric[i] if i < numeric.length() else "·"
  if wheels[i].text == next: continue
  if digit_tweens[i]: digit_tweens[i].kill()
  wheels[i].text = next
  wheels[i].position.y = 300
  wheels[i].modulate.a = 0.3
  var tween := create_tween().set_parallel(true)
  tween.tween_property(wheels[i],"position:y",310.0,0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  tween.tween_property(wheels[i],"modulate:a",1.0,0.16)
  digit_tweens[i] = tween
 if numeric != input_text: sound("digit")
 input_text = numeric
 status.text = "按回车或打开" if numeric.length() == 4 else "输入四位数字"

func set_controls_enabled(value: bool) -> void:
 code_input.editable = value
 submit_button.disabled = not value
 cancel_button.disabled = not value
 for button in digit_buttons: button.disabled = not value

func submit(_text: String = "") -> void:
 if animating or resolved: return
 update_digits(code_input.text)
 if code_input.text.length() != 4:
  status.text = "请先输入四位数字"
  code_input.grab_focus()
  return
 animating = true
 set_controls_enabled(false)
 if code_input.text != "2129":
  status.text = "密码不对，再试试。"
  sound("error")
  motion = create_tween()
  for offset in [-9.0,8.0,-6.0,4.0,0.0]:
   motion.tween_property(assembly,"position:x",offset,0.07)
  await motion.finished
  animating = false
  set_controls_enabled(true)
  code_input.select_all()
  code_input.grab_focus()
  return
 status.text = ""
 create_tween().tween_property(heading,"modulate:a",0.0,0.2)
 for wheel in wheels:
  create_tween().tween_property(wheel,"modulate",Color("cbeaaa"),0.25)
 await get_tree().create_timer(0.25).timeout
 sound("open")
 motion = create_tween()
 motion.tween_property(shackle,"position:y",157.0,0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 motion.tween_property(shackle,"rotation",-0.24,0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
 await motion.finished
 opened = true
 status.text = "锁开了"
 await get_tree().create_timer(0.75).timeout
 resolved = true
 finished.emit(true)

func cancel() -> void:
 if animating or resolved: return
 resolved = true
 finished.emit(false)

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  cancel()

func sound(kind: String) -> void:
 if not is_instance_valid(audio): return
 var duration := 0.20 if kind == "open" else 0.065
 var rate := 22050
 var data := PackedByteArray()
 data.resize(int(rate*duration)*2)
 for i in int(rate*duration):
  var t := float(i)/rate
  var frequency := 1400.0 if kind == "digit" else (750.0 if kind == "open" else 130.0)
  var wave := sin(TAU*frequency*t)*exp(-t*55)*0.25
  if kind == "open" and t > 0.065: wave += sin(TAU*1900*t)*exp(-(t-0.065)*70)*0.2
  data.encode_s16(i*2,int(wave*32767))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = rate
 stream.data = data
 audio.stream = stream
 audio.volume_db = -16
 audio.play()
