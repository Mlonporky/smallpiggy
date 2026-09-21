extends Node2D
## Room-only paper collection; independent from Little Pig's gift_fragments.
const POSITIONS := [Vector2(955,826),Vector2(704,281),Vector2(449,799)]
const STANDS := [Vector2(895,830),Vector2(704,345),Vector2(510,803)]
var host: Node2D
var scraps: Array[Sprite2D] = []
var hint: Label
var count_label: Label
var time := 0.0

func _ready() -> void:
 host = get_parent()
 for i in 3:
  var scrap := Sprite2D.new()
  scrap.texture = load("res://assets/cabbage_act2/wrapping/piece_%d.png" % (i+2))
  scrap.position = POSITIONS[i]
  scrap.scale = Vector2.ONE*(66.0/scrap.texture.get_width())
  scrap.rotation = [-0.22,0.12,-0.28][i]
  scrap.z_index = -5
  scrap.visible = not GameState.has_flag(flag(i+1))
  add_child(scrap)
  scraps.append(scrap)
  # Thin matching-background foreground lip tucks the paper under furniture.
  # Below the character layer: it cannot cut into the boy's head.
  var cover := Sprite2D.new()
  var atlas := AtlasTexture.new()
  atlas.atlas = preload("res://assets/cabbage_act2/mushroom_interior_day_v1.png")
  var rect := Rect2(POSITIONS[i]-Vector2(40,23),Vector2(80,14))
  var ratio := atlas.atlas.get_size()/Vector2(1434,1097)
  atlas.region = Rect2(rect.position*ratio,rect.size*ratio)
  cover.texture = atlas
  cover.centered = false
  cover.position = rect.position
  cover.scale = Vector2.ONE/ratio
  cover.z_index = -4
  add_child(cover)
 hint = Label.new()
 hint.text = "E · 拾起纸片"
 hint.add_theme_font_size_override("font_size",20)
 hint.add_theme_constant_override("outline_size",5)
 hint.add_theme_color_override("font_outline_color",Color("40382c"))
 hint.z_index = 4
 add_child(hint)
 count_label = host.ui.label(Vector2(28,400),17)
 refresh()

static func flag(index: int) -> String:
 return "wrapping_piece_%d_found" % (index+1)

func collected_count() -> int:
 var count := 0
 for i in 4:
  if GameState.has_flag(flag(i)): count += 1
 return count

func refresh() -> void:
 for i in 3: scraps[i].visible = not GameState.has_flag(flag(i+1))
 count_label.visible = GameState.has_flag(flag(0))
 count_label.text = "包装纸 %d / 4" % collected_count()
 host.paper_label.text = "E · 查看包装纸" if GameState.has_flag("wrapping_puzzle_completed") else ("E · 拼合包装纸" if collected_count() == 4 else "E · 检查包装纸")

func nearby_piece() -> int:
 if not GameState.has_flag(flag(0)): return -1
 for i in 3:
  if not GameState.has_flag(flag(i+1)) and host.player.position.distance_to(STANDS[i]) < 82: return i
 return -1

func _process(delta: float) -> void:
 time += delta
 var nearby := nearby_piece()
 hint.visible = nearby >= 0 and not host.busy
 if nearby >= 0:
  hint.position = STANDS[nearby]+Vector2(-50,20)
 queue_redraw()

func _draw() -> void:
 if not GameState.has_flag(flag(0)) or host.busy: return
 for i in 3:
  if GameState.has_flag(flag(i+1)): continue
  if host.player.position.distance_to(STANDS[i]) > 165: continue
  var point: Vector2 = POSITIONS[i]+Vector2(10,-10)
  var color := Color(1.0,0.90,0.68,0.4+0.25*sin(time*2.5))
  draw_line(point-Vector2(5,0),point+Vector2(5,0),color,1.6,true)
  draw_line(point-Vector2(0,7),point+Vector2(0,7),color,1.6,true)

func collect(index: int) -> void:
 if index < 0 or index >= 3 or host.busy: return
 if GameState.has_flag(flag(index+1)) or not GameState.has_flag(flag(0)): return
 if host.player.position.distance_to(STANDS[index]) >= 82: return
 host.busy = true
 host.player.set_input_enabled(false)
 host.player.face(POSITIONS[index]-host.player.position)
 var scrap := scraps[index]
 scrap.z_index = 3
 var tween := create_tween().set_parallel(true)
 tween.tween_property(scrap,"position",host.player.position+Vector2(48,-52),0.35)
 tween.tween_property(scrap,"rotation",0.0,0.35)
 await tween.finished
 tween = create_tween()
 tween.tween_property(scrap,"modulate:a",0.0,0.25)
 await tween.finished
 GameState.set_flag(flag(index+1))
 refresh()
 host.ui.prompt.text = "这些碎片好像可以拼起来。\n\n回到桌边看看。" if collected_count() == 4 else "找到一块包装纸碎片。"
 host.clear_objective_later()
 await host.story.release()
