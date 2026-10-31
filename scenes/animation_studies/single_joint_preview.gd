extends Control
## Isolated motion study. Does not read or write story/save state.
@export var pig_script: Script = preload("res://scenes/animation_studies/single_joint_pig.gd")
@export var preview_title := "一段式手臂"
@export var hand_anchor := "far_hand"
@export var prop_z_index := 0
const Art := preload("res://scenes/cabbage_act2/acorn_memory_art.gd")
const LENGTH := 12.0
const START := Vector2(390,505)
const FINISH := Vector2(662.8,505) # Four complete strides, ending on planted feet.
const FACTOR := 1.55
var stage: Node2D
var pig: Node2D
var nut: Sprite2D
var time := 0.0
var playing := true
var title_label: Label
var slider: HSlider
var previous: Button
var phase := ""
var ground_nut := Vector2.ZERO
var attached := false
var slow := false
var updating_slider := false
var root_top := Vector2.ZERO

func _ready() -> void:
 stage = Node2D.new()
 add_child(stage)
 pig = pig_script.new()
 pig.scale = Vector2.ONE*FACTOR
 stage.add_child(pig)
 pig.reach = 1.0
 pig.update_pose()
 ground_nut = FINISH+pig.get(hand_anchor)*FACTOR
 root_top = ground_nut+Vector2(0,13)
 nut = Sprite2D.new()
 nut.z_index = prop_z_index
 nut.texture = Art.acorn()
 nut.scale = Vector2.ONE*(26.0/Art.ACORN_REGION.size.y)
 stage.add_child(nut)
 title_label = Label.new()
 title_label.position = Vector2(48,32)
 title_label.add_theme_font_size_override("font_size",27)
 title_label.add_theme_color_override("font_color",Color("694737"))
 stage.add_child(title_label)
 var hint := Label.new()
 hint.text = "空格 暂停／继续    R 重播    S 慢放    ← → 逐帧    拖动进度检查姿势"
 hint.position = Vector2(48,562)
 hint.add_theme_font_size_override("font_size",19)
 hint.add_theme_color_override("font_color",Color("735b4c"))
 stage.add_child(hint)
 slider = HSlider.new()
 slider.position = Vector2(48,607)
 slider.size = Vector2(1056,22)
 slider.min_value = 0
 slider.max_value = LENGTH
 slider.step = 1.0/60.0
 slider.value_changed.connect(func(value: float):
  if not updating_slider:
   time = value
   playing = false
   evaluate())
 stage.add_child(slider)
 resized.connect(layout)
 layout()
 evaluate()

func layout() -> void:
 var ratio := minf(size.x/1152.0,size.y/648.0)
 stage.scale = Vector2.ONE*ratio
 stage.position = (size-Vector2(1152,648)*ratio)*0.5
 queue_redraw()

func smooth(a: float, b: float) -> float:
 return smoothstep(a,b,time)

func evaluate() -> void:
 var progress := smooth(1.0,5.5)
 pig.position = START.lerp(FINISH,progress)
 # World displacement is converted back to the rig's own units.
 pig.travel = (pig.position.x-START.x)/FACTOR
 pig.movement = smooth(1.0,1.55)*(1.0-smooth(4.9,5.5))
 pig.reach = smooth(6.0,7.2)*(1.0-smooth(8.0,9.4))
 pig.hold = smooth(8.0,9.4)
 pig.update_pose()
 attached = time>=7.5
 nut.position = pig.position+pig.get(hand_anchor)*FACTOR if attached else ground_nut
 nut.rotation = -0.08*pow(sin(smooth(8.0,9.4)*PI),2)
 if time<1.0: phase="站稳"
 elif time<5.5: phase="走近"
 elif time<6.0: phase="停稳"
 elif time<7.5: phase="前倾，碰到橡子"
 elif time<8.0: phase="拿稳"
 elif time<9.4: phase="抬起，收回身前"
 else: phase="持橡子"
 title_label.text = preview_title+" · "+phase
 updating_slider = true
 slider.value = time
 updating_slider = false
 queue_redraw()

func _process(delta: float) -> void:
 if playing:
  time = minf(time+delta*(0.35 if slow else 1.0),LENGTH)
  if time>=LENGTH: playing=false
  evaluate()

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("f6eedf"))
 if not is_instance_valid(stage): return
 draw_set_transform(stage.position,0,stage.scale)
 draw_line(Vector2(100,505),Vector2(1050,505),Color("d8c6ae"),2,true)
 # A low exposed root gives the short arm a reachable contact surface.
 var x := root_top.x
 var top := root_top.y
 var root_shape := PackedVector2Array([Vector2(x-28,505),Vector2(x-24,top+20),Vector2(x-16,top+3),Vector2(x-9,top),Vector2(x+10,top),Vector2(x+19,top+10),Vector2(x+25,496),Vector2(x+36,505)])
 draw_colored_polygon(root_shape,Color("a48360"))
 draw_polyline(root_shape,Color("846347"),2,true)
 draw_polyline(PackedVector2Array([Vector2(x-21,505),Vector2(x-11,top+13),Vector2(x+8,top+12),Vector2(x+25,503)]),Color("c4a174"),3,true)
 var shadow_center: Vector2 = pig.position+Vector2(0,1)
 draw_set_transform(stage.position+shadow_center*stage.scale,0,stage.scale*Vector2(1,0.17))
 draw_circle(Vector2.ZERO,70,Color(0.34,0.25,0.17,0.13))
 draw_set_transform(Vector2.ZERO)

func _unhandled_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed: return
 match event.keycode:
  KEY_SPACE:
   if time>=LENGTH: time=0
   playing = not playing
  KEY_R:
   time=0
   playing=true
  KEY_S: slow=not slow
  KEY_LEFT:
   playing=false
   time=maxf(0,time-1.0/60.0)
  KEY_RIGHT:
   playing=false
   time=minf(LENGTH,time+1.0/60.0)
 evaluate()
 get_viewport().set_input_as_handled()
