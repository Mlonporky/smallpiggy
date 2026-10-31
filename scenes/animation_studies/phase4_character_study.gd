extends Control
## Isolated visual study. Does not alter GameState, saves, or the user's pig assembly.
const Boy = preload("res://scenes/animation_studies/handpainted_boy.gd")
const Actor = preload("res://scenes/finale/finale_actor.gd")
const Wizard = preload("res://scenes/finale/finale_wizard.gd")
const SIZE := Vector2(1152,648)
const DURATION := 14.0
var stage: Control
var gallery: Control
var motion: Control
var assembly: Control
var caption: Label
var description: Label
var clock := 0.0
var paused := false
var view := 0
var calibrated := false
var gallery_cells: Array[Dictionary] = []
var measurements: Array[Dictionary] = []
var boy: Node2D
var old_boy: Node2D
var diagram_boy: Node2D
var marker_layer: Node2D

func _ready() -> void:
 var backdrop := ColorRect.new()
 backdrop.color = Color("f4eddf")
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(backdrop)
 stage = Control.new()
 stage.size = SIZE
 add_child(stage)
 label(stage,"第四阶段 · 角色画风与运动样片",Vector2(32,20),27)
 label(stage,"男孩手绘候选 v1  ·  仅独立样片，待观感反馈",Vector2(34,59),16,Color("826b55"))
 for i in 3:
  var button := Button.new()
  button.text = ["1  同比例对照","2  行走对照","3  部件与关节"][i]
  button.position = Vector2(578+i*182,26)
  button.size = Vector2(174,44)
  button.pressed.connect(set_view.bind(i))
  stage.add_child(button)
 gallery = pane()
 motion = pane()
 assembly = pane()
 _build_gallery()
 _build_motion()
 _build_assembly()
 caption = label(stage,"",Vector2(34,568),20)
 description = label(stage,"",Vector2(34,599),15,Color("826b55"))
 get_viewport().size_changed.connect(layout)
 layout()
 set_view(0)
 call_deferred("calibrate_gallery")

func pane() -> Control:
 var node := Control.new()
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 node.size = SIZE
 stage.add_child(node)
 return node

func label(parent: Node, text: String, at: Vector2, font_size: int, color := Color("483b32")) -> Label:
 var node := Label.new()
 node.text = text
 node.position = at
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",color)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 return node

func _build_gallery() -> void:
 var names := ["现有男孩","森林小猪","回忆／最终章小猪","手绘男孩候选","最终章巫师"]
 for i in 5:
  var container := SubViewportContainer.new()
  container.position = Vector2(26+i*222,135)
  container.size = Vector2(208,280)
  container.mouse_filter = Control.MOUSE_FILTER_IGNORE
  gallery.add_child(container)
  var viewport := SubViewport.new()
  viewport.size = Vector2i(208,280)
  viewport.transparent_bg = true
  viewport.disable_3d = true
  viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  container.add_child(viewport)
  var holder := Node2D.new()
  holder.position = Vector2(104,240)
  viewport.add_child(holder)
  var actor: Node2D
  if i == 1:
   actor = Node2D.new()
   var sprite := Sprite2D.new()
   var sheet := preload("res://assets/chapter2/pig_unified/cape.png")
   var bounds := SpriteAtlas.bounds(sheet,4,4,[],0.1)
   sprite.texture = SpriteAtlas.frame(sheet,bounds[12])
   sprite.centered = false
   sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
   sprite.scale = Vector2.ONE*(170.0/bounds[12].size.y)
   sprite.position = Vector2(-bounds[12].size.x*0.5,-bounds[12].size.y)*sprite.scale
   actor.add_child(sprite)
  elif i == 3: actor = Boy.new()
  elif i == 4: actor = Wizard.new()
  else:
   actor = Actor.new()
   actor.kind = "boy" if i==0 else "pig"
  if i!=1: actor.height = 170.0
  holder.add_child(actor)
  if i==4: actor.sample("protect",3.2)
  gallery_cells.append({"viewport":viewport,"holder":holder,"actor":actor,"name":names[i]})
  label(gallery,names[i],Vector2(38+i*222,432),18)
  label(gallery,["原12姿势 atlas","原森林 atlas","沿用用户装配","新5部件候选","现行手绘部件"][i],Vector2(38+i*222,463),14,Color("826b55"))
 label(gallery,"按可见轮廓统一到 170 px 高度，用于比较笔触与造型；不是故事中的身高设定。",Vector2(34,104),18)

static func alpha_bounds(img: Image) -> Rect2i:
 var low := img.get_size()
 var high := Vector2i(-1,-1)
 for y in img.get_height():
  for x in img.get_width():
   if img.get_pixel(x,y).a>0.25:
    low.x=mini(low.x,x);low.y=mini(low.y,y)
    high.x=maxi(high.x,x);high.y=maxi(high.y,y)
 return Rect2i(low,high-low+Vector2i.ONE) if high.x>=0 else Rect2i()

func calibrate_gallery() -> void:
 if DisplayServer.get_name()=="headless": calibrated=true;return
 await _calibration_draw()
 for cell in gallery_cells:
  var bounds := alpha_bounds(cell.viewport.get_texture().get_image())
  if bounds.size.y<=0: continue
  var factor := 170.0/bounds.size.y
  cell.holder.scale *= factor
  cell.holder.position += Vector2((104-bounds.get_center().x)*factor,(240-bounds.end.y)*factor)
 await _calibration_draw()
 for cell in gallery_cells:
  var bounds := alpha_bounds(cell.viewport.get_texture().get_image())
  measurements.append({"name":cell.name,"visible_height":bounds.size.y,"feet_y":bounds.end.y,"scale":cell.holder.scale.x})
 calibrated = true

func _calibration_draw() -> void:
 if not Engine.get_write_movie_path().is_empty():
  # MovieMaker's driver already draws each frame. Do not insert extra frames.
  await RenderingServer.frame_post_draw
 else:
  await get_tree().process_frame
  RenderingServer.force_draw(false)

func _build_motion() -> void:
 var landscape := Control.new()
 landscape.position = Vector2(24,102)
 landscape.size = Vector2(1104,445)
 landscape.clip_contents = true
 landscape.mouse_filter = Control.MOUSE_FILTER_IGNORE
 motion.add_child(landscape)
 var background := TextureRect.new()
 background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 background.texture = preload("res://assets/finale/reunion_forest_v1.png")
 background.modulate = Color(0.86,0.88,0.86)
 landscape.add_child(background)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 old_boy = Actor.new()
 old_boy.kind = "boy"
 old_boy.height = 205
 motion.add_child(old_boy)
 boy = Boy.new()
 boy.height = 205
 motion.add_child(boy)
 label(motion,"现有男孩 · 已修正方向与停步取帧",Vector2(72,120),19,Color("f5ead7"))
 label(motion,"手绘男孩候选 · 固定关节连续摆动",Vector2(630,120),19,Color("f5ead7"))
 var floor := Node2D.new()
 motion.add_child(floor)
 floor.draw.connect(func():
  floor.draw_line(Vector2(60,507),Vector2(1092,507),Color(0.93,0.85,0.65,0.38),1.0,true)
  floor.draw_line(Vector2(576,164),Vector2(576,524),Color(0.93,0.85,0.65,0.25),1.0,true))

func _build_assembly() -> void:
 diagram_boy = Boy.new()
 diagram_boy.height = 365
 diagram_boy.position = Vector2(504,535)
 assembly.add_child(diagram_boy)
 label(assembly,"同一头身部件 · 四肢只绕固定肩／髋点转动",Vector2(34,104),18)
 label(assembly,"编号仅对应素材与装配；不借此确认小猪的解剖左右。",Vector2(34,135),16,Color("826b55"))
 marker_layer = Node2D.new()
 assembly.add_child(marker_layer)
 marker_layer.draw.connect(_draw_joint_guides)
 for i in 4:
  label(assembly,["02  Arm_A · 肩点","03  Arm_B · 肩点","04  Leg_A · 髋点","05  Leg_B · 髋点"][i],Vector2(800,245+i*61),18)
 label(assembly,"01  头、领口、衣身与披风相连",Vector2(690,186),17)

func _draw_joint_guides() -> void:
 var index := 0
 for key in ["Arm_A","Arm_B","Leg_A","Leg_B"]:
  var at: Vector2 = marker_layer.to_local(diagram_boy.joints[key].global_position)
  marker_layer.draw_circle(at,5,Color("b05c3b"),false,1.8,true)
  marker_layer.draw_line(at,Vector2(787,258+index*61),Color("b05c3b"),1.0,true)
  index += 1
 marker_layer.draw_line(Vector2(575,264),Vector2(695,264),Color("826b55"),2,true)
 marker_layer.draw_line(Vector2(695,264),Vector2(683,258),Color("826b55"),2,true)
 marker_layer.draw_line(Vector2(695,264),Vector2(683,270),Color("826b55"),2,true)

func layout() -> void:
 var factor := minf(get_viewport_rect().size.x/SIZE.x,get_viewport_rect().size.y/SIZE.y)
 stage.scale = Vector2.ONE*factor
 stage.position = (get_viewport_rect().size-SIZE*factor)*0.5

func set_view(index: int) -> void:
 view = index
 gallery.visible = index==0
 motion.visible = index==1
 assembly.visible = index==2
 clock = 0
 paused = false
 sample(0)

static func smooth_step(u: float) -> float:
 u=clampf(u,0,1)
 return u*u*u*(u*(u*6-15)+10)

func sample(seconds: float) -> void:
 var t := clampf(seconds,0,DURATION)
 var outbound := smooth_step((t-1.5)/4.0)
 var inbound := smooth_step((t-7)/4.0)
 var x := 220.0*(outbound-inbound)
 var traveled := 220.0*(outbound+inbound)
 var u := clampf((t-1.5)/4.0,0,1) if t<6 else clampf((t-7)/4.0,0,1)
 var speed := 220.0/4.0*30.0*u*u*(1-u)*(1-u)
 var direction := 1.0 if t<6.5 else -1.0
 var amount := minf(speed/72,1)
 old_boy.position = Vector2(162+x,507)
 old_boy.facing = direction
 old_boy.distance = traveled
 old_boy.pose(speed>0.1,amount)
 boy.position = Vector2(718+x,507)
 boy.sample(traveled,amount,direction)
 if view==0:
  caption.text = "五种角色同高度比较 · 候选男孩保持原发型、配色与服装"
  description.text = "1 / 2 / 3 切换查看 · 新素材仅用于本样片，正式章节仍使用现有男孩图集"
 elif view==1:
  caption.text = ("已暂停" if paused else ("片段结束 · R 重播" if t>=DURATION else "起步 → 行走 → 减速停步 → 反向返回"))+"    %.1f / 14 秒" % t
  description.text = "空格 / Esc 暂停 · R 重播 · 当前只有侧向动作；转向为停步后镜像，尚无专用转身、表情或声音"
 else:
  caption.text = "固定肩髋 · 肢体长度不变 · 头身保持连接"
  description.text = "候选部件与遮挡检查；A / B 为素材编号。未修改用户小猪装配。"

func _process(delta: float) -> void:
 if view==1 and not paused:
  clock = minf(DURATION,clock+delta)
  sample(clock)

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode in [KEY_1,KEY_2,KEY_3]: set_view(event.keycode-KEY_1)
 elif event.keycode in [KEY_SPACE,KEY_ESCAPE]: paused=not paused;sample(clock)
 elif event.keycode==KEY_R: clock=0;paused=false;sample(0)
 else: return
 get_viewport().set_input_as_handled()
