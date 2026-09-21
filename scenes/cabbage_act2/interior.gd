extends Node2D

const SIZE := Vector2(1434,1097)
const PAPER_POSITION := Vector2(765,511)
const TABLE_BODY := Rect2(618,416,335,260)
const PAPER_TEXTURE := preload("res://assets/cabbage_act2/wrapping/piece_1.png")
const HELP := "WASD / 方向键\n移动\n\n靠近桌子按 E\n检查包装纸\n\nF5 保存\nEsc 菜单"
var player: PiggyPlayer
var camera: Camera2D
var ui: ChapterPresentation
var story: Node
var busy := false
var paper: Sprite2D
var paper_label: Label
var table_front: Polygon2D
var base_zoom := 1.0
var collectibles: Node2D
var puzzle: Control
var notice_version := 0

func _ready() -> void:
 GameState.story_phase = GameState.StoryPhase.CABBAGE_HOLLOW_HEART
 var bg := Sprite2D.new()
 bg.texture = preload("res://assets/cabbage_act2/mushroom_interior_day_v1.png")
 bg.z_index = -10
 bg.centered = false
 bg.scale = SIZE / bg.texture.get_size()
 add_child(bg)
 # Walkable floor excludes the bed, stove, cabinets and walls.
 var floor_points := PackedVector2Array([Vector2(515,300),Vector2(885,300),Vector2(945,385),Vector2(1080,410),Vector2(1080,670),Vector2(1025,740),Vector2(955,805),Vector2(915,885),Vector2(800,930),Vector2(800,1030),Vector2(620,1030),Vector2(620,930),Vector2(490,870),Vector2(445,760),Vector2(325,670),Vector2(340,580),Vector2(505,565)])
 var walls := StaticBody2D.new()
 add_child(walls)
 for i in floor_points.size():
  var shape := SegmentShape2D.new()
  shape.a = floor_points[i]
  shape.b = floor_points[(i+1)%floor_points.size()]
  var collision := CollisionShape2D.new()
  collision.shape = shape
  walls.add_child(collision)
 # The table and its stools form a solid island; the left aisle reaches the clue.
 for rect in [TABLE_BODY,Rect2(646,682,82,64),Rect2(875,660,103,95),Rect2(848,370,66,61)]:
  var body := StaticBody2D.new()
  body.position = rect.get_center()
  var shape := RectangleShape2D.new()
  shape.size = rect.size
  var collision := CollisionShape2D.new()
  collision.shape = shape
  body.add_child(collision)
  add_child(body)
 player = preload("res://actors/shared/player.tscn").instantiate()
 player.handpainted_room = true
 player.sheet_override = preload("res://assets/chapter1/boy.png")
 player.sheet_row_edges = PackedInt32Array([0,368,694,1028,1448])
 player.visible_height = 190
 player.move_speed = 155
 player.position = Vector2(730,850)
 player.get_node("Camera2D").enabled = false
 add_child(player)
 player.reset_physics_interpolation()
 table_front = Polygon2D.new()
 table_front.texture = bg.texture
 table_front.polygon = PackedVector2Array([Vector2(616,545),Vector2(628,486),Vector2(682,442),Vector2(760,418),Vector2(840,427),Vector2(907,470),Vector2(950,536),Vector2(944,595),Vector2(908,641),Vector2(852,674),Vector2(742,688),Vector2(659,657),Vector2(620,608)])
 var uvs := PackedVector2Array()
 for point in table_front.polygon: uvs.append(point * bg.texture.get_size() / SIZE)
 table_front.uv = uvs
 add_child(table_front)
 paper = Sprite2D.new()
 paper.texture = PAPER_TEXTURE
 paper.z_index = 3
 paper.position = PAPER_POSITION
 paper.scale = Vector2.ONE * 0.065
 paper.rotation = -0.18
 add_child(paper)
 paper.visible = not GameState.has_flag("wrapping_piece_1_found")
 paper_label = marker(Vector2(530,540),"E · 检查包装纸")
 marker(Vector2(635,990),"E · 返回院子")
 camera = Camera2D.new()
 camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
 camera.position = SIZE * 0.5
 add_child(camera)
 ui = ChapterPresentation.new()
 add_child(ui)
 ui.room_name.text = "白菜 · 第二幕｜蘑菇屋"
 ui.prompt.text = HELP
 story = preload("res://scenes/cabbage_act2/mushroom_story.gd").new()
 add_child(story)
 get_viewport().size_changed.connect(_fit)
 _fit()
 collectibles = preload("res://scenes/cabbage_act2/wrapping_collectibles.gd").new()
 add_child(collectibles)

func marker(at: Vector2, text: String) -> Label:
 var label := Label.new()
 label.position = at
 label.text = text
 label.add_theme_font_size_override("font_size",21)
 label.add_theme_constant_override("outline_size",6)
 label.add_theme_color_override("font_outline_color",Color("40382c"))
 add_child(label)
 return label

func _fit() -> void:
 var size := get_viewport().get_visible_rect().size
 base_zoom = minf(size.x / SIZE.x, size.y / SIZE.y)
 if not busy: camera.zoom = Vector2.ONE * base_zoom
 story.dialogue.panel.position = Vector2(size.x * 0.11,size.y-200)
 story.dialogue.panel.size.x = size.x * 0.78

func near_paper() -> bool:
 return player.position.distance_to(Vector2(568,585)) < 112

func _physics_process(_delta: float) -> void:
 # Only the rear aisle is behind the table. The left/right aisles run alongside
 # it: covering those characters with the painted tabletop cuts into their heads.
 if is_instance_valid(table_front): table_front.visible = player.position.y < TABLE_BODY.position.y
 if is_instance_valid(paper_label):
  paper_label.modulate.a = 1.0 if near_paper() else 0.6

func _unhandled_input(event: InputEvent) -> void:
 if busy or SceneRouter.is_busy(): return
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  pause_menu()
 elif event.is_action_pressed("interact"):
  if collectibles.nearby_piece() >= 0:
   get_viewport().set_input_as_handled()
   collectibles.collect(collectibles.nearby_piece())
  elif near_paper():
   get_viewport().set_input_as_handled()
   inspect_paper()
  elif player.position.distance_to(Vector2(715,985)) < 115:
   get_viewport().set_input_as_handled()
   leave()
 elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  var nearby: int = collectibles.nearby_piece()
  var click_world: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
  if nearby >= 0 and click_world.distance_to(collectibles.POSITIONS[nearby]) < 65:
   get_viewport().set_input_as_handled()
   collectibles.collect(nearby)
  elif near_paper() and click_world.distance_to(PAPER_POSITION) < 95:
   get_viewport().set_input_as_handled()
   inspect_paper()

func inspect_paper() -> void:
 if busy: return
 if collectibles.collected_count() == 4:
  await open_puzzle()
  return
 busy = true
 player.set_input_enabled(false)
 player.face(Vector2.RIGHT)
 if GameState.has_flag("wrapping_piece_1_found"):
  await ui.inspect(PAPER_TEXTURE)
 else:
  var zoom := create_tween().set_parallel(true)
  zoom.tween_property(camera,"zoom",Vector2.ONE * base_zoom * 1.10,0.5)
  zoom.tween_property(camera,"position",Vector2(730,570),0.5)
  await zoom.finished
  # Existing poses only: lift the clue toward the character, then inspect close up.
  var lift := create_tween().set_parallel(true)
  # Hold the paper beside the torso, below the oversized storybook head.
  lift.tween_property(paper,"position",player.position + Vector2(58,-52),0.55)
  lift.tween_property(paper,"rotation",0.12,0.55)
  await lift.finished
  await story.say([story.PAPER[0]])
  ui.show_closeup(PAPER_TEXTURE)
  # Leave room for the dialogue box under the paper close-up.
  ui.closeup.position.y = 30
  ui.closeup.size.y = maxf(120,get_viewport().get_visible_rect().size.y-260)
  await story.say(story.PAPER.slice(1))
  ui.hide_closeup()
  paper.visible = false
  GameState.set_flag("wrapping_piece_1_found")
  GameState.set_flag("QUEST_MUSHROOM_WRAPPING_PAPER")
  collectibles.refresh()
  var restore := create_tween().set_parallel(true)
  restore.tween_property(camera,"position",SIZE*0.5,0.45)
  restore.tween_property(camera,"zoom",Vector2.ONE*base_zoom,0.45)
  await restore.finished
  ui.prompt.text = "找到散落的包装纸碎片。"
  clear_objective_later()
 await story.release()

func clear_objective_later() -> void:
 notice_version += 1
 var version := notice_version
 await get_tree().create_timer(5).timeout
 if version != notice_version: return
 if collectibles.collected_count() == 4:
  ui.prompt.text = "回到桌边按 E\n查看包装纸\n\nF5 保存\nEsc 菜单" if GameState.has_flag("wrapping_puzzle_completed") else "回到桌边按 E\n拼合包装纸\n\nF5 保存\nEsc 菜单"
 else:
  ui.prompt.text = HELP

func leave() -> void:
 busy = true
 player.set_input_enabled(false)
 preload("res://scenes/cabbage_act2/exterior.gd").pending_entry = "interior"
 SceneRouter.change_scene("res://scenes/cabbage_act2/mushroom.tscn")

func pause_menu() -> void:
 busy = true
 player.set_input_enabled(false)
 var choice := await ui.choose({"stay":"继续探索","save":"保存并回主菜单"})
 if choice == "save" and SaveManager.save_game(scene_file_path):
  SceneRouter.change_scene("res://scenes/bootstrap/main.tscn")
  return
 if choice == "save": ui.prompt.text = "保存失败，请重试"
 await story.release()

func open_puzzle() -> void:
 if busy or collectibles.collected_count() != 4: return
 busy = true
 player.set_input_enabled(false)
 if not GameState.has_flag("wrapping_puzzle_started"):
  await story.say(["如果把这些拼起来……"])
  GameState.set_flag("wrapping_puzzle_started")
 puzzle = preload("res://scenes/cabbage_act2/wrapping_puzzle.gd").new()
 for i in 4:
  puzzle.initial_placed[i] = GameState.has_flag("wrapping_piece_%d_placed" % (i+1)) or GameState.has_flag("wrapping_puzzle_completed")
 puzzle.piece_placed.connect(func(index): GameState.set_flag("wrapping_piece_%d_placed" % (index+1)))
 puzzle.completed.connect(func():
  GameState.set_flag("wrapping_puzzle_completed")
  GameState.set_flag("QUEST_MUSHROOM_WRAPPING_PAPER",false)
  collectibles.refresh())
 puzzle.back_revealed.connect(func(): GameState.set_flag("wrapping_message_seen"))
 ui.add_child(puzzle)
 await puzzle.closed
 puzzle.queue_free()
 puzzle = null
 await story.release()
