extends Control
signal changed(board: Array, moves: int)
signal completed
signal closed
signal memory_requested
const Model := preload("res://scenes/cabbage_act2/table_slide_model.gd")
const ART := preload("res://assets/cabbage_act2/table_puzzle/garden_inlay_v1.png")
const DESIGN := Vector2(1280,800)
const BOARD := Vector2(260,158)
const CELL := 184.0
var initial_board: Array = []
var initial_moves := 0
var memory_enabled := false
var memory_button: Button
var board: Array = []
var moves := 0
var stage: Control
var tiles: Array[Button] = []
var badges: Array[Label] = []
var status: Label
var move_label: Label
var undo_button: Button
var shuffle_button: Button
var reveal: TextureRect
var solved := false
var animating := false
var resolved := false
var undo_history: Array[Array] = []
var opening_tween: Tween

class WoodSurface extends Control:
 func _draw() -> void:
  draw_rect(Rect2(Vector2.ZERO,size),Color("745039"))
  var rng := RandomNumberGenerator.new()
  rng.seed = 9173
  for band in 12:
   var y := band*size.y/12.0
   draw_rect(Rect2(0,y,size.x,size.y/12.0-2),Color("a97850").darkened(rng.randf_range(0.05,0.19)))
   for grain in 5:
    var points := PackedVector2Array()
    var base := y+rng.randf_range(5,size.y/12.0-5)
    var phase := rng.randf()*TAU
    for x in range(0,int(size.x)+20,20): points.append(Vector2(x,base+3*sin(x*0.009+phase)+sin(x*0.033+phase)))
    draw_polyline(points,Color(0.30,0.17,0.10,0.17),1.0,true)

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 var shade := ColorRect.new()
 shade.color = Color("251b16")
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(shade)
 stage = Control.new()
 stage.size = DESIGN
 stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(stage)
 var wood := WoodSurface.new()
 wood.size = DESIGN
 wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(wood)
 label("蘑菇屋 · 桌面机关",Rect2(54,34,900,44),32)
 label("滑动木片，让花园重新连在一起",Rect2(54,87,900,32),21)
 button("收起 · Esc",Rect2(1082,36,150,48)).pressed.connect(close)
 panel(Rect2(BOARD-Vector2(18,18),Vector2.ONE*(CELL*3+36)),Color("c59a65"),Color("e2be85"),5)
 panel(Rect2(BOARD-Vector2(4,4),Vector2.ONE*(CELL*3+8)),Color("493323"),Color("64432c"),2)
 for i in 9:
  panel(Rect2(cell_position(i)+Vector2(3,3),Vector2.ONE*(CELL-6)),Color("513a29"),Color("3c281d"),1)
 label("完成图案",Rect2(890,158,300,32),22)
 panel(Rect2(929,202,222,222),Color("f1d6a5"),Color("d7b782"),3)
 var reference := TextureRect.new()
 reference.texture = ART
 reference.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 reference.position = Vector2(935,208)
 reference.size = Vector2.ONE*210
 reference.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(reference)
 label("点击空格旁的木片\n也可用方向键移动木片",Rect2(865,446,350,70),21)
 move_label = label("",Rect2(900,532,280,32),20)
 undo_button = button("撤回一步",Rect2(922,590,236,48))
 undo_button.pressed.connect(undo)
 shuffle_button = button("重新打乱",Rect2(922,652,236,48))
 shuffle_button.pressed.connect(reshuffle)
 memory_button = button("打开桌面 · 橡子回忆",Rect2(900,590,304,52))
 memory_button.visible = false
 memory_button.pressed.connect(request_memory)
 var numbers := CheckButton.new()
 numbers.text = "显示编号"
 numbers.position = Vector2(54,658)
 numbers.size = Vector2(170,46)
 numbers.button_pressed = true
 numbers.add_theme_font_size_override("font_size",19)
 numbers.toggled.connect(func(on):
  for badge in badges: badge.visible = on)
 stage.add_child(numbers)
 status = label("空格只接纳相邻的木片",Rect2(48,740,1184,34),21)
 if Model.valid(initial_board):
  # JSON reloads numbers as floats; normalize before find/equality/input logic.
  for value in initial_board: board.append(int(value))
 else: board = new_board()
 moves = maxi(0,initial_moves) if Model.valid(initial_board) else 0
 for tile in 8:
  var piece := button("",Rect2(cell_position(board.find(tile))+Vector2(3,3),Vector2.ONE*(CELL-6)))
  piece.focus_mode = Control.FOCUS_NONE
  piece.clip_contents = true
  var atlas := AtlasTexture.new()
  atlas.atlas = ART
  var source_cell := ART.get_size()/3.0
  atlas.region = Rect2(Vector2(tile%3,tile/3)*source_cell,source_cell)
  atlas.filter_clip = true
  var image := TextureRect.new()
  image.texture = atlas
  image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  image.position = Vector2(3,3)
  image.size = piece.size-Vector2(6,6)
  image.mouse_filter = Control.MOUSE_FILTER_IGNORE
  piece.add_child(image)
  var badge := Label.new()
  badge.text = str(tile+1)
  badge.position = Vector2(10,CELL-43)
  badge.add_theme_font_size_override("font_size",19)
  badge.add_theme_constant_override("outline_size",5)
  badge.add_theme_color_override("font_outline_color",Color("4b3328"))
  badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
  piece.add_child(badge)
  badges.append(badge)
  piece.pressed.connect(func(): move_tile(tile))
  tiles.append(piece)
 reveal = TextureRect.new()
 reveal.texture = ART
 reveal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 reveal.position = BOARD+Vector2(6,6)
 reveal.size = Vector2.ONE*(CELL*3-12)
 reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
 reveal.visible = false
 stage.add_child(reveal)
 get_viewport().size_changed.connect(layout)
 layout()
 solved = board == Model.GOAL
 if solved: show_complete()
 else: update_ui()
 stage.modulate.a = 0
 var full_scale := stage.scale
 var full_position := stage.position
 stage.scale *= 0.94
 stage.position += DESIGN*full_scale*0.03
 opening_tween = create_tween().set_parallel(true)
 opening_tween.tween_property(stage,"modulate:a",1.0,0.3)
 opening_tween.tween_property(stage,"scale",full_scale,0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 opening_tween.tween_property(stage,"position",full_position,0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func new_board() -> Array:
 var rng := RandomNumberGenerator.new()
 rng.randomize()
 return Model.shuffle(rng)

func cell_position(cell: int) -> Vector2:
 return BOARD+Vector2(cell%3,cell/3)*CELL

func layout() -> void:
 if opening_tween and opening_tween.is_running():
  opening_tween.kill()
  stage.modulate.a = 1.0
 var viewport := get_viewport().get_visible_rect().size
 var factor := minf(viewport.x/DESIGN.x,viewport.y/DESIGN.y)
 stage.scale = Vector2.ONE*factor
 stage.position = (viewport-DESIGN*factor)*0.5

func panel(rect: Rect2, color: Color, edge: Color, width: int) -> Panel:
 var node := Panel.new()
 node.position = rect.position
 node.size = rect.size
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.border_color = edge
 style.set_border_width_all(width)
 style.set_corner_radius_all(5)
 node.add_theme_stylebox_override("panel",style)
 stage.add_child(node)
 return node

func label(text: String, rect: Rect2, font_size: int) -> Label:
 var node := Label.new()
 node.text = text
 node.position = rect.position
 node.size = rect.size
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",Color("fff0d2"))
 node.add_theme_constant_override("outline_size",2)
 node.add_theme_color_override("font_outline_color",Color("68432f"))
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(node)
 return node

func button(text: String, rect: Rect2) -> Button:
 var node := Button.new()
 node.text = text
 node.position = rect.position
 node.size = rect.size
 node.add_theme_font_size_override("font_size",20)
 for state in ["normal","hover","pressed","disabled","focus"]:
  var style := StyleBoxFlat.new()
  style.bg_color = Color("89613f") if state == "normal" else Color("b18a56")
  style.border_color = Color("edd09a") if state in ["hover","focus"] else Color("c39b69")
  style.set_border_width_all(2)
  style.set_corner_radius_all(5)
  style.shadow_color = Color(0.13,0.08,0.04,0.4)
  style.shadow_size = 3
  style.shadow_offset = Vector2(0,3)
  node.add_theme_stylebox_override(state,style)
 stage.add_child(node)
 return node

func update_ui() -> void:
 move_label.text = "移动了 %d 步" % moves
 undo_button.disabled = animating or solved or undo_history.is_empty()
 shuffle_button.disabled = animating or solved
 for tile in 8:
  # Non-neighbors remain clickable so the message can explain the rule.
  tiles[tile].modulate = Color.WHITE if solved or board.find(tile) in Model.neighbors(board.find(Model.EMPTY)) else Color(0.88,0.85,0.80)

func move_tile(tile: int) -> void:
 if resolved or animating or solved or tile < 0 or tile >= 8: return
 var from := board.find(tile)
 var empty := board.find(Model.EMPTY)
 if not from in Model.neighbors(empty):
  status.text = "这块木片离空格太远了，试试紧挨空格的木片。"
  return
 undo_history.append(board.duplicate())
 board[empty] = tile
 board[from] = Model.EMPTY
 moves += 1
 animating = true
 status.text = "让小路、屋顶和叶片重新连在一起"
 update_ui()
 var tween := create_tween()
 tween.tween_property(tiles[tile],"position",cell_position(empty)+Vector2(3,3),0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 await tween.finished
 animating = false
 changed.emit(board.duplicate(),moves)
 if board == Model.GOAL:
  solved = true
  show_complete()
  completed.emit()
 else: update_ui()

func show_complete() -> void:
 for tile in tiles: tile.visible = false
 reveal.visible = true
 reveal.modulate.a = 0
 create_tween().tween_property(reveal,"modulate:a",1.0,0.35)
 status.text = "回忆已解锁"
 if memory_enabled:
  undo_button.visible = false
  shuffle_button.visible = false
  memory_button.visible = true
 update_ui()

func request_memory() -> void:
 if not memory_enabled or not solved or resolved or animating: return
 animating = true
 memory_button.disabled = true
 memory_requested.emit()

func undo() -> void:
 if resolved or animating or solved or undo_history.is_empty(): return
 var previous: Array = undo_history.pop_back()
 animating = true
 update_ui()
 var tween := create_tween().set_parallel(true)
 for tile in 8:
  tween.tween_property(tiles[tile],"position",cell_position(previous.find(tile))+Vector2(3,3),0.18).set_trans(Tween.TRANS_SINE)
 await tween.finished
 board = previous
 moves = maxi(0,moves-1)
 animating = false
 status.text = "已撤回一步"
 changed.emit(board.duplicate(),moves)
 update_ui()

func reshuffle() -> void:
 if resolved or animating or solved: return
 board = new_board()
 moves = 0
 undo_history.clear()
 for tile in 8: tiles[tile].position = cell_position(board.find(tile))+Vector2(3,3)
 status.text = "已重新打乱 · 每次都能拼好"
 changed.emit(board.duplicate(),moves)
 update_ui()

func _input(event: InputEvent) -> void:
 if resolved: return
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  close()
 elif event is InputEventKey and event.pressed and not event.echo:
  var offset := Vector2i.ZERO
  match event.keycode:
   KEY_LEFT: offset = Vector2i(1,0)
   KEY_RIGHT: offset = Vector2i(-1,0)
   KEY_UP: offset = Vector2i(0,1)
   KEY_DOWN: offset = Vector2i(0,-1)
  if offset == Vector2i.ZERO: return
  get_viewport().set_input_as_handled()
  var empty := board.find(Model.EMPTY)
  var source := Vector2i(empty%3,empty/3)+offset
  if source.x >= 0 and source.x < 3 and source.y >= 0 and source.y < 3:
   move_tile(board[source.y*3+source.x])

func close() -> void:
 if resolved or animating: return
 resolved = true
 closed.emit()
