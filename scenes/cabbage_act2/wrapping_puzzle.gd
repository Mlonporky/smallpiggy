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
var keyboard_piece := -1
var piece_buttons: Array[Button] = []

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
  var selector := make_button("选取 %d" % (i+1),Rect2(HOMES[i]+Vector2(-60,94),Vector2(120,40)))
  selector.pressed.connect(select_piece.bind(i))
  piece_buttons.append(selector)
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
 make_label("鼠标拖拽 / 1–4 选取 · 方向键移动 · Shift 慢移 · Enter / 空格放下 · Tab 切换按钮",Rect2(0,688,1200,28),17)
 make_label("不用旋转 · 靠近正确位置再放下，碎片会轻轻吸合",Rect2(0,717,1200,23),16)
 get_viewport().size_changed.connect(layout)
 layout()
 update_count()
 if placed.all(func(value): return value): reveal_whole(false)
 else: focus_next_piece()

func target(index: int) -> Vector2:
 return BOARD+Art.center(index)

func layout() -> void:
 cancel_keyboard_piece()
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
 var focus := StyleBoxFlat.new()
 focus.bg_color = Color.TRANSPARENT
 focus.border_color = Color("ffe5a1")
 focus.set_border_width_all(3)
 focus.set_corner_radius_all(8)
 button.add_theme_stylebox_override("focus",focus)
 stage.add_child(button)
 return button

func _input(event: InputEvent) -> void:
 if resolved: return
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  close()
  return
 if animating or solved: return
 if event is InputEventKey:
  var code: int = event.physical_keycode if event.physical_keycode else event.keycode
  if event.pressed and not event.echo and code >= KEY_1 and code <= KEY_4:
   select_piece(code-KEY_1)
   get_viewport().set_input_as_handled()
   return
  if keyboard_piece >= 0:
   if code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
    get_viewport().set_input_as_handled()
    return
   if event.is_action_pressed("ui_accept") and not event.echo:
    var index := keyboard_piece
    keyboard_piece = -1
    pieces[index].modulate = Color.WHITE
    get_viewport().set_input_as_handled()
    drop_piece(index)
    return
   if event.pressed and code == KEY_TAB:
    cancel_keyboard_piece()
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  var point: Vector2 = stage.get_global_transform().affine_inverse()*event.position
  if event.pressed:
   for i in range(3,-1,-1):
    if placed[i]: continue
    var local: Vector2 = (point-pieces[i].position)/pieces[i].scale+Art.center(i)
    if Geometry2D.is_point_in_polygon(local,Art.polygons()[i]):
     if keyboard_piece == i:
      keyboard_piece = -1
      pieces[i].modulate = Color.WHITE
     else: cancel_keyboard_piece()
     dragging = i
     drag_offset = local-Art.center(i)
     pieces[i].scale = Vector2.ONE
     pieces[i].position = point-drag_offset
     pieces[i].z_index = 10
     piece_buttons[i].grab_focus()
     get_viewport().set_input_as_handled()
     return
   cancel_keyboard_piece()
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

func _process(delta: float) -> void:
 if keyboard_piece < 0 or resolved or animating: return
 var movement := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
 var speed := 80.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 300.0
 var piece := pieces[keyboard_piece]
 piece.position += movement*speed*delta
 # Keep the full irregular fragment on the play surface at any window size.
 var half := Art.bounds(keyboard_piece).size*0.5
 piece.position = piece.position.clamp(Vector2(16,120)+half,Vector2(1184,680)-half)

func select_piece(index: int) -> void:
 if resolved or solved or animating or dragging >= 0 or placed[index]: return
 cancel_keyboard_piece()
 keyboard_piece = index
 pieces[index].scale = Vector2.ONE
 pieces[index].z_index = 10
 pieces[index].modulate = Color(1.08,1.08,1.0)
 piece_buttons[index].grab_focus()
 status.text = "正在移动第 %d 块 · 方向键移动，Enter / 空格放下" % (index+1)

func cancel_keyboard_piece() -> void:
 if keyboard_piece < 0: return
 var index := keyboard_piece
 keyboard_piece = -1
 pieces[index].position = HOMES[index]
 pieces[index].scale = Vector2.ONE*0.70
 pieces[index].z_index = 0
 pieces[index].modulate = Color.WHITE
 update_count()

func focus_next_piece() -> void:
 for i in 4:
  if not placed[i]:
   piece_buttons[i].grab_focus()
   return

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
 elif correct: focus_next_piece()
 else:
  status.text = "还没对齐 · 再试一次（已拼好 %d / 4 块）" % placed.count(true)
  piece_buttons[index].grab_focus()

func update_count() -> void:
 status.text = "已拼好 %d / 4 块" % placed.count(true)
 for i in piece_buttons.size():
  piece_buttons[i].disabled = placed[i]
  piece_buttons[i].text = "已拼好" if placed[i] else "选取 %d" % (i+1)

func reveal_whole(animate: bool) -> void:
 solved = true
 animating = true
 if animate:
  status.text = "拼好了。"
  paper_sound(true)
  await get_tree().create_timer(0.35,false).timeout
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
 flip_button.grab_focus()

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
 preload("res://systems/audio/gameplay_audio.gd").play_at(self,"complete" if complete else "paper")
