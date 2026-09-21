extends Control
signal piece_placed(index: int)
signal completed
signal back_revealed
signal closed
const Art := preload("res://scenes/cabbage_act2/wrapping_art.gd")
const DESIGN := Vector2(1200,740)
const BOARD := Vector2(300,150)
const HOMES := [Vector2(1040,520),Vector2(160,220),Vector2(1040,230),Vector2(155,530)]
var initial_placed: Array[bool] = [false,false,false,false]
var placed: Array[bool] = []
var pieces: Array[Node2D] = []
var stage: Control
var status: Label
var flip_button: Button
var whole: Node2D
var front: Node2D
var back: Node2D
var solved := false
var showing_back := false
var animating := false
var dragging := -1
var drag_offset := Vector2.ZERO
var resolved := false

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 var shade := ColorRect.new()
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.color = Color(0.10,0.075,0.06,0.97)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(shade)
 stage = Control.new()
 stage.size = DESIGN
 stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(stage)
 make_label("把包装纸拼起来",Rect2(0,22,1200,40),29)
 status = make_label("拖动四块碎片，拼回中间的纸张",Rect2(0,75,1200,32),20)
 var close_button := make_button("收起 · Esc",Rect2(1040,24,140,44))
 close_button.pressed.connect(close)
 for i in 4:
  var outline := Polygon2D.new()
  outline.polygon = Art.polygons()[i]
  outline.position = BOARD
  outline.color = Color(0.95,0.85,0.68,0.075)
  stage.add_child(outline)
  var edge := Line2D.new()
  edge.position = BOARD
  edge.points = Art.polygons()[i]
  edge.closed = true
  edge.width = 1.5
  edge.default_color = Color(0.96,0.88,0.72,0.28)
  edge.antialiased = true
  stage.add_child(edge)
  var piece := Art.make_piece(i)
  piece.position = target(i) if initial_placed[i] else HOMES[i]
  piece.scale = Vector2.ONE if initial_placed[i] else Vector2.ONE*0.70
  stage.add_child(piece)
  pieces.append(piece)
  placed.append(initial_placed[i])
 whole = Node2D.new()
 whole.position = BOARD+Art.SIZE*0.5
 whole.visible = false
 stage.add_child(whole)
 front = Art.make_whole()
 front.position = -Art.SIZE*0.5
 whole.add_child(front)
 back = Art.make_whole(true)
 back.position = -Art.SIZE*0.5
 back.visible = false
 whole.add_child(back)
 flip_button = make_button("翻过来看看",Rect2(495,630,210,52))
 flip_button.visible = false
 flip_button.pressed.connect(flip)
 make_label("不用旋转 · 靠近正确位置时松手，碎片会轻轻吸合",Rect2(0,700,1200,30),17)
 get_viewport().size_changed.connect(layout)
 layout()
 if placed.all(func(value): return value): reveal_whole(false)
 else: update_count()

func target(index: int) -> Vector2:
 return BOARD+Art.center(index)

func layout() -> void:
 # Resizing during a drag returns that piece safely to its tray.
 if dragging >= 0:
  pieces[dragging].position = HOMES[dragging]
  pieces[dragging].scale = Vector2.ONE*0.70
  pieces[dragging].z_index = 0
  dragging = -1
 var viewport := get_viewport().get_visible_rect().size
 var factor := minf(1.0,minf((viewport.x-24)/DESIGN.x,(viewport.y-24)/DESIGN.y))
 stage.scale = Vector2.ONE*factor
 stage.position = (viewport-DESIGN*factor)*0.5

func make_label(text: String, rect: Rect2, font_size: int) -> Label:
 var label := Label.new()
 label.text = text
 label.position = rect.position
 label.size = rect.size
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("f3dfbd"))
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(label)
 return label

func make_button(text: String, rect: Rect2) -> Button:
 var button := Button.new()
 button.text = text
 button.position = rect.position
 button.size = rect.size
 button.add_theme_font_size_override("font_size",20)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("604733")
 style.border_color = Color("c7a779")
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 button.add_theme_stylebox_override("normal",style)
 stage.add_child(button)
 return button

func _input(event: InputEvent) -> void:
 if resolved: return
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  close()
  return
 if animating or solved: return
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  var point: Vector2 = stage.get_global_transform().affine_inverse()*event.position
  if event.pressed:
   for i in range(3,-1,-1):
    if placed[i]: continue
    var local: Vector2 = (point-pieces[i].position)/pieces[i].scale+Art.center(i)
    if Geometry2D.is_point_in_polygon(local,Art.polygons()[i]):
     dragging = i
     drag_offset = local-Art.center(i)
     pieces[i].scale = Vector2.ONE
     pieces[i].position = point-drag_offset
     pieces[i].z_index = 10
     get_viewport().set_input_as_handled()
     return
  elif dragging >= 0:
   var index := dragging
   pieces[index].position = point-drag_offset
   dragging = -1
   get_viewport().set_input_as_handled()
   drop_piece(index)
 elif event is InputEventMouseMotion and dragging >= 0:
  var point: Vector2 = stage.get_global_transform().affine_inverse()*event.position
  pieces[dragging].position = point-drag_offset
  get_viewport().set_input_as_handled()

func drop_piece(index: int) -> void:
 animating = true
 var correct := pieces[index].position.distance_to(target(index)) < 44
 var tween := create_tween().set_parallel(true)
 tween.tween_property(pieces[index],"position",target(index) if correct else HOMES[index],0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 tween.tween_property(pieces[index],"scale",Vector2.ONE if correct else Vector2.ONE*0.70,0.22)
 await tween.finished
 pieces[index].z_index = 0
 if correct:
  placed[index] = true
  piece_placed.emit(index)
  paper_sound(false)
 update_count()
 animating = false
 if placed.all(func(value): return value): await reveal_whole(true)

func update_count() -> void:
 status.text = "已拼好 %d / 4 块" % placed.count(true)

func reveal_whole(animate: bool) -> void:
 solved = true
 animating = true
 if animate:
  status.text = "拼好了。"
  paper_sound(true)
  await get_tree().create_timer(0.35).timeout
 for piece in pieces: piece.visible = false
 whole.visible = true
 if animate:
  whole.modulate = Color(1.12,1.08,1.0)
  var settle := create_tween()
  settle.tween_property(whole,"modulate",Color.WHITE,0.4)
  await settle.finished
  completed.emit()
 status.text = "拼回的残片背面，似乎有字……"
 flip_button.visible = true
 animating = false

func flip() -> void:
 if not solved or animating: return
 animating = true
 flip_button.disabled = true
 var tween := create_tween()
 tween.tween_property(whole,"scale:x",0.015,0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
 await tween.finished
 showing_back = not showing_back
 front.visible = not showing_back
 back.visible = showing_back
 paper_sound(false)
 tween = create_tween()
 tween.tween_property(whole,"scale:x",1.0,0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 await tween.finished
 status.text = "包装纸背面的留言" if showing_back else "拼合的包装纸"
 flip_button.text = "看正面" if showing_back else "翻过来看看"
 flip_button.disabled = false
 animating = false
 if showing_back: back_revealed.emit()

func close() -> void:
 if animating or resolved: return
 resolved = true
 closed.emit()

func paper_sound(complete: bool) -> void:
 var audio := AudioStreamPlayer.new()
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 var data := PackedByteArray()
 var count := 7500 if complete else 1800
 data.resize(count*2)
 for i in count:
  var t := float(i)/22050
  var wave := sin(TAU*(660 if complete else 380)*t)*exp(-t*20)*0.12
  data.encode_s16(i*2,int(wave*32767))
 stream.data = data
 audio.stream = stream
 audio.volume_db = -18
 add_child(audio)
 audio.finished.connect(audio.queue_free)
 audio.play()
