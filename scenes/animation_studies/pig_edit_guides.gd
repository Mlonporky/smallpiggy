@tool
extends Node2D
## Read-only annotation. The saved scene owns every transform and layer.
@export var draw_backdrop := false
const FONT := preload("res://assets/fonts/game_font.tres")
const INK := Color("634e46")
const MUTED := Color("8c7568")
const TEAL := Color("267c80")
const CORAL := Color("b15c49")
const JOINTS := ["Arm_A", "Arm_B", "Leg_A", "Leg_B"]

func _process(_delta: float) -> void:
 if not draw_backdrop:
  queue_redraw()

func label_at(point: Vector2, value: String, size: int = 18, color: Color = INK) -> void:
 draw_string(FONT, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
 if draw_backdrop:
  draw_rect(Rect2(0, 0, 1152, 648), Color("f6eedf"))
  draw_rect(Rect2(24, 104, 270, 476), Color("eee1cf"))
  draw_line(Vector2(322, 536), Vector2(1080, 536), Color("d4c1a8"), 2, true)
  return
 label_at(Vector2(40, 53), "小猪 · 可编辑角色", 29)
 label_at(Vector2(40, 83), "静止装配待核对   /   A、B 是素材编号，尚未对应角色自身左右", 17, MUTED)
 label_at(Vector2(44, 140), "在 Godot 的 2D 编辑器里", 20)
 label_at(Vector2(44, 184), "1  展开 Pig → BodyPivot")
 label_at(Vector2(44, 218), "2  选择 Arm_A / Arm_B")
 label_at(Vector2(65, 245), "或 Leg_A / Leg_B")
 label_at(Vector2(44, 286), "3  右侧 Transform 调整")
 label_at(Vector2(65, 314), "Position：肩／髋安装点")
 label_at(Vector2(65, 342), "Rotation：绕关节摆动")
 label_at(Vector2(44, 385), "4  Ordering → Z Index")
 label_at(Vector2(65, 413), "数值越大，越靠前")
 label_at(Vector2(44, 458), "⌘S 保存   ·   F6 预览", 20)
 label_at(Vector2(44, 492), "⌘Z 撤销   ·   眼睛隐藏部件", 17)
 label_at(Vector2(44, 548), "保留肢体长度：不要改 Scale", 16, MUTED)
 label_at(Vector2(40, 619), "隐藏 Guides 可看干净装配  ·  F6 只预览已保存姿势；回编辑器调整并保存", 18, MUTED)
 var body := get_node_or_null("../Pig/BodyPivot/Body") as Sprite2D
 if body == null:
  return
 var face := to_local(body.to_global(Vector2(60, -550)))
 var forward := (to_local(body.to_global(Vector2(130, -550))) - face).normalized()
 var arrow_start := face + forward * 120.0
 var arrow_end := arrow_start + forward * 90.0
 draw_line(arrow_start, arrow_end, MUTED, 2, true)
 draw_line(arrow_end, arrow_end - forward.rotated(0.5) * 12, MUTED, 2, true)
 draw_line(arrow_end, arrow_end - forward.rotated(-0.5) * 12, MUTED, 2, true)
 label_at(arrow_start + Vector2(0, -12), "鼻尖朝向", 17, MUTED)
 label_at(Vector2(792, 148), "01  完整头身", 19)
 label_at(Vector2(792, 175), "Body · Z %d" % body.z_index, 16, MUTED)
 var captions := [Vector2(322, 366), Vector2(865, 355), Vector2(322, 493), Vector2(865, 482)]
 var names := ["02  A 臂", "03  B 臂", "04  A 腿", "05  B 腿"]
 for i in range(JOINTS.size()):
  var joint := get_node_or_null("../Pig/BodyPivot/" + JOINTS[i]) as Node2D
  if joint == null:
   continue
  var tint := TEAL if i % 2 == 0 else CORAL
  var origin := to_local(joint.global_position)
  var caption: Vector2 = captions[i]
  var endpoint := caption + Vector2(110 if i % 2 == 0 else -12, -7)
  draw_line(origin, endpoint, Color(tint, 0.6), 1.5, true)
  draw_circle(origin, 6, Color("fff9ef"))
  draw_arc(origin, 6, 0, TAU, 32, tint, 2, true)
  draw_line(origin - Vector2(9, 0), origin + Vector2(9, 0), tint, 1, true)
  draw_line(origin - Vector2(0, 9), origin + Vector2(0, 9), tint, 1, true)
  label_at(caption, names[i], 19, tint)
  label_at(caption + Vector2(0, 24), "%s · Z %d" % [JOINTS[i], joint.z_index], 16, tint)
  var tip := joint.get_node_or_null("Artwork/Tip") as Marker2D
  if tip != null:
   var toe := to_local(tip.global_position)
   draw_line(origin, toe, Color(tint, 0.5), 1, true)
   draw_circle(toe, 3, tint)
   if i < 2:
    draw_dashed_line(Vector2(460, toe.y), Vector2(816, toe.y), Color(tint, 0.3), 1, 6)
